import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateOrganizationDto } from './dto/create-organization.dto';
import { UpdateOrganizationDto } from './dto/update-organization.dto';
import { UpdateDoctorDto } from '../doctors/dto/update-doctor.dto';

import * as bcrypt from 'bcrypt';

@Injectable()
export class OrganizationsService {
  constructor(private prisma: PrismaService) { }

  async create(createOrganizationDto: CreateOrganizationDto) {
    if (createOrganizationDto.adminUser) {
      const { adminUser, ...orgData } = createOrganizationDto;
      const hashedPassword = await bcrypt.hash(adminUser.password, 10);

      return this.prisma.$transaction(async (tx) => {
        // 1. Create User (Role: DOCTOR or appropriate)
        // Check if email exists
        const existingUser = await tx.user.findUnique({ where: { email: adminUser.email } });
        if (existingUser) {
          throw new Error('User with this email already exists');
        }

        const user = await tx.user.create({
          data: {
            name: adminUser.name,
            email: adminUser.email,
            password: hashedPassword,
            phone: adminUser.phone,
            role: 'DOCTOR', // Default role for org creator
          },
        });

        // 2. Create Organization
        const org = await tx.organization.create({
          data: {
            ...orgData,
            status: 'PENDING',
            feeControlMode: orgData.feeControlMode || 'doctor_controlled', // Default
            yearEstablished: orgData.yearEstablished && Number(orgData.yearEstablished), // Ensure number
            latitude: orgData.latitude && Number(orgData.latitude),
            longitude: orgData.longitude && Number(orgData.longitude),
            branches: orgData.branches || [],
            settings: {
              create: {
                // Default settings
              }
            }
          },
        });

        // 3. Create Membership
        await tx.organizationMembership.create({
          data: {
            userId: user.id,
            organizationId: org.id,
            role: 'ORG_ADMIN',
            status: 'APPROVED',
          },
        });

        return org;
      });
    }

    return this.prisma.organization.create({
      data: createOrganizationDto,
    });
  }

  async findAll(status?: string) {
    return this.prisma.organization.findMany({
      where: status ? { status } : undefined,
    });
  }

  async updateStatus(id: string, status: 'APPROVED' | 'REJECTED') {
    return this.prisma.organization.update({
      where: { id },
      data: { status },
    });
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
