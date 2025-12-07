import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateOrganizationDto } from './dto/create-organization.dto';
import { UpdateOrganizationDto } from './dto/update-organization.dto';
import { UpdateDoctorDto } from '../doctors/dto/update-doctor.dto';

@Injectable()
export class OrganizationsService {
  constructor(private prisma: PrismaService) { }

  async create(createOrganizationDto: CreateOrganizationDto) {
    return this.prisma.organization.create({
      data: createOrganizationDto,
    });
  }

  async findAll() {
    return this.prisma.organization.findMany();
  }

  async findOne(id: string) {
    const org = await this.prisma.organization.findUnique({
      where: { id },
      include: {
        members: {
          where: { role: 'DOCTOR' },
          include: {
            user: {
              select: {
                id: true,
                name: true,
                email: true,
                role: true,
                doctorProfile: true,
              },
            },
          },
        },
      },
    });

    if (org && org.members) {
      // Sort doctors by seniority (yearsExperience) descending
      org.members.sort((a, b) => {
        const expA = a.user.doctorProfile?.yearsExperience || 0;
        const expB = b.user.doctorProfile?.yearsExperience || 0;
        return expB - expA;
      });
    }

    return org;
  }

  async update(id: string, updateOrganizationDto: UpdateOrganizationDto) {
    return this.prisma.organization.update({
      where: { id },
      data: updateOrganizationDto,
    });
  }

  async remove(id: string) {
    return this.prisma.organization.delete({
      where: { id },
    });
  }

  async addMember(organizationId: string, userId: string, role: 'ORG_ADMIN' | 'RECEPTIONIST' | 'DOCTOR') {
    return this.prisma.organizationMembership.create({
      data: {
        organizationId,
        userId,
        role,
        status: 'PENDING', // New members start as pending
      },
    });
  }

  /**
   * Get pending staff awaiting approval
   */
  async getPendingStaff(organizationId: string) {
    return this.prisma.organizationMembership.findMany({
      where: {
        organizationId,
        status: 'PENDING',
      },
      include: {
        user: {
          select: {
            id: true,
            name: true,
            email: true,
            phone: true,
            role: true,
            doctorProfile: true,
          },
        },
      },
      orderBy: {
        createdAt: 'desc',
      },
    });
  }

  /**
   * Get all staff (with filtering)
   */
  async getAllStaff(organizationId: string, status?: 'PENDING' | 'APPROVED' | 'REJECTED') {
    return this.prisma.organizationMembership.findMany({
      where: {
        organizationId,
        ...(status && { status }),
      },
      include: {
        user: {
          select: {
            id: true,
            name: true,
            email: true,
            phone: true,
            role: true,
            doctorProfile: true,
          },
        },
        approver: {
          select: {
            id: true,
            name: true,
            email: true,
          },
        },
      },
      orderBy: {
        createdAt: 'desc',
      },
    });
  }

  /**
   * Approve or reject a staff membership
   */
  async updateMembershipStatus(
    membershipId: string,
    status: 'APPROVED' | 'REJECTED',
    approvedBy: string
  ) {
    return this.prisma.organizationMembership.update({
      where: { id: membershipId },
      data: {
        status,
        approvedBy,
        approvedAt: new Date(),
      },
    });
  }

  /**
   * Remove a staff member
   */
  async removeMember(membershipId: string) {
    return this.prisma.organizationMembership.delete({
      where: { id: membershipId },
    });
  }

  /**
   * Check if user is an admin of the organization
   */
  async isOrgAdmin(organizationId: string, userId: string): Promise<boolean> {
    const membership = await this.prisma.organizationMembership.findUnique({
      where: {
        userId_organizationId: { userId, organizationId },
      },
    });

    return membership?.role === 'ORG_ADMIN' && membership?.status === 'APPROVED';
  }

  /**
   * Check if user has approved membership in organization
   */
  async hasApprovedMembership(organizationId: string, userId: string): Promise<boolean> {
    const membership = await this.prisma.organizationMembership.findUnique({
      where: {
        userId_organizationId: { userId, organizationId },
      },
    });

    return membership?.status === 'APPROVED';
  }

  async getPatients(organizationId: string, search?: string) {
    return this.prisma.user.findMany({
      where: {
        role: 'PATIENT',
        appointmentsAsPatient: {
          some: {
            organizationId: organizationId,
          },
        },
        ...(search ? {
          OR: [
            { name: { contains: search, mode: 'insensitive' } },
            { email: { contains: search, mode: 'insensitive' } },
          ],
        } : {}),
      },
      select: {
        id: true,
        name: true,
        email: true,
        phone: true,
        _count: {
          select: { appointmentsAsPatient: { where: { organizationId } } }
        }
      },
    });
  }

  async updateDoctorProfile(organizationId: string, userId: string, dto: UpdateDoctorDto) {
    const membership = await this.prisma.organizationMembership.findUnique({
      where: {
        userId_organizationId: {
          organizationId,
          userId
        }
      }
    });

    if (!membership || membership.role !== 'DOCTOR') {
      throw new Error('Doctor not found in this organization');
    }

    return this.prisma.doctor.update({
      where: { userId },
      data: dto,
    });
  }
}
