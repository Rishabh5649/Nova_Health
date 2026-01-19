import {
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { QueryDoctorsDto } from './dto/query-doctors.dto';
import { UpdateDoctorDto } from './dto/update-doctor.dto';

@Injectable()
export class DoctorsService {
  constructor(private prisma: PrismaService) { }

  /**
   * PUBLIC LIST
   * Supports:
   * - q.specialty (exact match in specialties[])
   * - q.q (text search across name / specialties / qualifications)
   * - pagination (page, pageSize)
   * Output: { items, page, pageSize, total, totalPages }
   */
  async list(q: QueryDoctorsDto) {
    // Safe pagination defaults
    const page = q.page && q.page > 0 ? q.page : 1;
    const requestedPageSize = q.pageSize && q.pageSize > 0 ? q.pageSize : 10;
    const pageSize = Math.min(requestedPageSize, 50); // clamp to prevent abuse
    const skip = (page - 1) * pageSize;

    const where: any = {};

    // Filter by specialty (string value in specialties[] array)
    if (q.specialty && q.specialty.trim() !== '') {
      where.specialties = { has: q.specialty.trim() };
    }

    // Text search across name / specialties / qualifications
    if (q.q && q.q.trim() !== '') {
      const term = q.q.trim();
      where.OR = [
        { name: { contains: term, mode: 'insensitive' } },
        // "has" matches exact entries in string[]
        { specialties: { has: term } },
        { qualifications: { has: term } },
      ];
    }

    const [items, total] = await this.prisma.$transaction([
      this.prisma.doctor.findMany({
        where,
        select: {
          userId: true,
          name: true,
          qualifications: true,
          specialties: true,
          yearsExperience: true,
          bio: true,
          baseFee: true,
          ratingAvg: true,
          ratingCount: true,
          timezone: true,
          user: {
            select: {
              email: true,
              memberships: {
                select: {
                  organization: {
                    select: {
                      id: true,
                      name: true,
                      latitude: true,
                      longitude: true,
                      address: true,
                      ratingAvg: true,
                      ratingCount: true,
                    }
                  }
                }
              }
            }
          },
        },
        // stable sort: best rating, then most experienced, then name A→Z
        orderBy: [
          { ratingAvg: 'desc' },
          { yearsExperience: 'desc' },
          { name: 'asc' },
        ],
        skip,
        take: pageSize,
      }),
      this.prisma.doctor.count({ where }),
    ]);

    return {
      items,
      page,
      pageSize,
      total,
      totalPages: Math.ceil(total / pageSize),
    };
  }

  /**
   * PUBLIC PROFILE
   * Lookup a single doctor by userId
   */
  async getProfile(userId: string) {
    const doc = await this.prisma.doctor.findUnique({
      where: { userId },
      select: {
        userId: true,
        name: true,
        age: true,
        bio: true,
        yearsExperience: true,
        qualifications: true,
        specialties: true,
        baseFee: true,
        fees: true,
        ratingAvg: true,
        ratingCount: true,
        timezone: true,
        user: {
          select: {
            email: true,
            memberships: {
              include: {
                organization: {
                  select: { id: true, name: true, type: true, address: true }
                }
              }
            }
          }
        },
      },
    });

    if (!doc) {
      throw new NotFoundException('Doctor not found');
    }

    return doc;
  }

  /**
   * DOCTOR SELF-UPDATE
   * Only the logged-in doctor (actorId = JWT sub) can update themselves.
   * We allow only editable profile fields (no rating fields, etc.).
   */
  async updateSelf(actorId: string, dto: UpdateDoctorDto) {
    // Verify this user actually is a doctor and fetch org info
    const existing = await this.prisma.user.findUnique({
      where: { id: actorId },
      include: {
        doctorProfile: true,
        memberships: {
          include: { organization: true },
        },
      },
    });

    if (!existing || !existing.doctorProfile) {
      throw new ForbiddenException('Only doctors can update their profile.');
    }

    // Check Fee Control Mode
    let feeControlMode = 'doctor_controlled';
    if (existing.memberships.length > 0) {
      feeControlMode = existing.memberships[0].organization.feeControlMode;
    }

    // Normalize arrays (optional: trim & dedupe)
    const normArray = (arr?: string[]) =>
      Array.isArray(arr)
        ? Array.from(
          new Set(
            arr
              .map((s) => (typeof s === 'string' ? s.trim() : ''))
              .filter((s) => s.length > 0),
          ),
        )
        : undefined;

    const safeData: any = {
      name: dto.name?.trim() ?? undefined,
      age: dto.age ?? undefined,
      bio: dto.bio?.trim() ?? undefined,
      yearsExperience: dto.yearsExperience ?? undefined,
      specialties: normArray(dto.specialties),
      qualifications: normArray(dto.qualifications),
      timezone: dto.timezone?.trim() ?? undefined,
    };

    // Only allow updating fees if doctor_controlled
    if (feeControlMode === 'doctor_controlled') {
      if (dto.baseFee !== undefined) safeData.baseFee = dto.baseFee;
      if (dto.followUpDays !== undefined) safeData.followUpDays = dto.followUpDays;
      if (dto.followUpFee !== undefined) safeData.followUpFee = dto.followUpFee;
    }

    const updated = await this.prisma.doctor.update({
      where: { userId: actorId },
      data: safeData,
      select: {
        userId: true,
        name: true,
        age: true,
        bio: true,
        yearsExperience: true,
        qualifications: true,
        specialties: true,
        baseFee: true,
        followUpDays: true,
        followUpFee: true,
        ratingAvg: true,
        ratingCount: true,
        timezone: true,
        user: { select: { email: true } },
      },
    });

    return updated;
  }
  async getMyPatients(doctorId: string) {
    const appointments = await this.prisma.appointment.findMany({
      where: { doctorId },
      select: {
        patient: {
          select: {
            id: true,
            name: true,
            email: true,
            phone: true,
            // Include patient profile if needed
            patientProfile: true,
          },
        },
      },
      distinct: ['patientId'],
    });

    return appointments.map((a) => a.patient);
  }

  /**
   * ADMIN UPDATE DOCTOR
   * Admin can update any doctor's profile, including fees.
   */
  async updateDoctor(targetUserId: string, dto: UpdateDoctorDto) {
    const existing = await this.prisma.doctor.findUnique({
      where: { userId: targetUserId },
    });

    if (!existing) {
      throw new NotFoundException('Doctor not found');
    }

    // Normalize arrays
    const normArray = (arr?: string[]) =>
      Array.isArray(arr)
        ? Array.from(
          new Set(
            arr
              .map((s) => (typeof s === 'string' ? s.trim() : ''))
              .filter((s) => s.length > 0),
          ),
        )
        : undefined;

    const safeData: any = {
      name: dto.name?.trim() ?? undefined,
      age: dto.age ?? undefined,
      bio: dto.bio?.trim() ?? undefined,
      yearsExperience: dto.yearsExperience ?? undefined,
      specialties: normArray(dto.specialties),
      qualifications: normArray(dto.qualifications),
      baseFee: dto.baseFee ?? undefined,
      followUpDays: dto.followUpDays ?? undefined,
      followUpFee: dto.followUpFee ?? undefined,
      timezone: dto.timezone?.trim() ?? undefined,
    };

    const updated = await this.prisma.doctor.update({
      where: { userId: targetUserId },
      data: safeData,
      select: {
        userId: true,
        name: true,
        baseFee: true,
        followUpDays: true,
        followUpFee: true,
      },
    });

    return updated;
  }
}
