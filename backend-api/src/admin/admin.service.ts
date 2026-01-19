import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import type { Prisma, AppointmentStatus } from '@prisma/client';

@Injectable()
export class AdminService {
  constructor(private prisma: PrismaService) {}

  // --- Users ---
  async listUsers(q: { q?: string; page: number; pageSize: number }) {
    const where: Prisma.UserWhereInput = q.q
      ? {
          OR: [
            // match by email
            {
              email: {
                contains: q.q,
                mode: 'insensitive',
              },
            },
            // match by patient profile name
            {
              patientProfile: {
                name: {
                  contains: q.q,
                  mode: 'insensitive',
                },
              },
            },
            // match by doctor profile name
            {
              doctorProfile: {
                name: {
                  contains: q.q,
                  mode: 'insensitive',
                },
              },
            },
          ],
        }
      : {};

    const skip = (q.page - 1) * q.pageSize;

    const [items, total] = await this.prisma.$transaction([
      this.prisma.user.findMany({
        where,
        select: {
          id: true,
          email: true,
          role: true,
          phone: true,
          createdAt: true,

          // pull profile name for display
          patientProfile: {
            select: {
              name: true,
            },
          },
          doctorProfile: {
            select: {
              name: true,
              verificationStatus: true,
              specialties: true,
            },
          },
        },
        orderBy: [{ createdAt: 'desc' }],
        skip,
        take: q.pageSize,
      }),
      this.prisma.user.count({ where }),
    ]);

    return {
      items,
      page: q.page,
      pageSize: q.pageSize,
      total,
      totalPages: Math.ceil(total / q.pageSize),
    };
  }

  // --- Doctors ---
  async listDoctors(q: {
    q?: string;
    status?: string; // e.g. 'PENDING' | 'APPROVED' | 'REJECTED'
    page: number;
    pageSize: number;
  }) {
    const where: Prisma.DoctorWhereInput = {};

    // filter by verificationStatus (doctor.verificationStatus is a String in schema)
    if (q.status) {
      where.verificationStatus = q.status;
    }

    if (q.q) {
      where.OR = [
        { name: { contains: q.q, mode: 'insensitive' } },
        { specialties: { has: q.q } },
        { qualifications: { has: q.q } },
        {
          user: {
            email: { contains: q.q, mode: 'insensitive' },
          },
        },
      ];
    }

    const skip = (q.page - 1) * q.pageSize;

    const [items, total] = await this.prisma.$transaction([
      this.prisma.doctor.findMany({
        where,
        select: {
          userId: true,
          name: true,
          verificationStatus: true,
          specialties: true,
          qualifications: true,
          yearsExperience: true,
          baseFee: true,
          ratingAvg: true,
          ratingCount: true,
          timezone: true,
          user: {
            select: {
              email: true,
              phone: true,
              role: true,
              createdAt: true,
            },
          },
        },
        orderBy: [{ verificationStatus: 'asc' }, { name: 'asc' }],
        skip,
        take: q.pageSize,
      }),
      this.prisma.doctor.count({ where }),
    ]);

    return {
      items,
      page: q.page,
      pageSize: q.pageSize,
      total,
      totalPages: Math.ceil(total / q.pageSize),
    };
  }

  async verifyDoctor(userId: string, status: 'APPROVED' | 'REJECTED') {
    const exists = await this.prisma.doctor.findUnique({ where: { userId } });
    if (!exists) throw new NotFoundException('Doctor not found');

    return this.prisma.doctor.update({
      where: { userId },
      data: { verificationStatus: status },
    });
  }

  // --- Patients ---
  async listPatients(q: { q?: string; page: number; pageSize: number }) {
    const where: Prisma.PatientWhereInput = q.q
      ? {
          OR: [
            { name: { contains: q.q, mode: 'insensitive' } },
            {
              user: {
                email: {
                  contains: q.q,
                  mode: 'insensitive',
                },
              },
            },
          ],
        }
      : {};

    const skip = (q.page - 1) * q.pageSize;

    const [items, total] = await this.prisma.$transaction([
      this.prisma.patient.findMany({
        where,
        select: {
          userId: true,
          name: true,
          dob: true,
          gender: true,
          allergies: true,
          chronicConditions: true,
          user: {
            select: {
              email: true,
              phone: true,
              createdAt: true,
            },
          },
        },
        orderBy: [{ user: { createdAt: 'desc' } }],
        skip,
        take: q.pageSize,
      }),
      this.prisma.patient.count({ where }),
    ]);

    return {
      items,
      page: q.page,
      pageSize: q.pageSize,
      total,
      totalPages: Math.ceil(total / q.pageSize),
    };
  }

  // --- Appointments ---
  async listAppointments(q: {
    status?: AppointmentStatus | string;
    page: number;
    pageSize: number;
  }) {
    const where: Prisma.AppointmentWhereInput = {};

    if (q.status) {
      // cast string to AppointmentStatus enum if frontend sends plain string like "CONFIRMED"
      where.status = q.status as AppointmentStatus;
    }

    const skip = (q.page - 1) * q.pageSize;

    // We can't rely on Prisma include types because Appointment.doctor/patient
    // are relations to User, not Doctor/Patient profile.
    const appts = await this.prisma.appointment.findMany({
      where,
      orderBy: [{ scheduledAt: 'desc' }], // scheduledAt is the correct field now
      skip,
      take: q.pageSize,
    });

    // hydrate doctor + patient basic info (User)
    const items = await Promise.all(
      appts.map(async (a) => {
        const [doctorUser, patientUser] = await Promise.all([
          this.prisma.user.findUnique({
            where: { id: a.doctorId },
            select: {
              id: true,
              email: true,
              phone: true,
              role: true,
              // we COULD also join doctorProfile here for name
              doctorProfile: {
                select: {
                  name: true,
                },
              },
            },
          }),
          this.prisma.user.findUnique({
            where: { id: a.patientId },
            select: {
              id: true,
              email: true,
              phone: true,
              role: true,
              patientProfile: {
                select: {
                  name: true,
                },
              },
            },
          }),
        ]);

        return {
          ...a,
          doctor: doctorUser,
          patient: patientUser,
        };
      }),
    );

    const total = await this.prisma.appointment.count({ where });

    return {
      items,
      page: q.page,
      pageSize: q.pageSize,
      total,
      totalPages: Math.ceil(total / q.pageSize),
    };
  }

  // --- Prescriptions ---
  async listPrescriptions(q: { page: number; pageSize: number }) {
    const skip = (q.page - 1) * q.pageSize;

    // We no longer have issuedAt, use createdAt.
    // Also Prescription.doctor / .patient in schema are User.
    const prescriptions = await this.prisma.prescription.findMany({
      orderBy: [{ createdAt: 'desc' }],
      skip,
      take: q.pageSize,
    });

    const items = await Promise.all(
      prescriptions.map(async (rx) => {
        const [doctorUser, patientUser, appt] = await Promise.all([
          this.prisma.user.findUnique({
            where: { id: rx.doctorId },
            select: {
              id: true,
              email: true,
              phone: true,
              role: true,
              doctorProfile: {
                select: {
                  name: true,
                },
              },
            },
          }),
          this.prisma.user.findUnique({
            where: { id: rx.patientId },
            select: {
              id: true,
              email: true,
              phone: true,
              role: true,
              patientProfile: {
                select: {
                  name: true,
                },
              },
            },
          }),
          rx.appointmentId
            ? this.prisma.appointment.findUnique({
                where: { id: rx.appointmentId },
                select: {
                  id: true,
                  scheduledAt: true,
                  status: true,
                },
              })
            : Promise.resolve(null),
        ]);

        return {
          ...rx,
          doctor: doctorUser,
          patient: patientUser,
          appointment: appt,
        };
      }),
    );

    const total = await this.prisma.prescription.count();

    return {
      items,
      page: q.page,
      pageSize: q.pageSize,
      total,
      totalPages: Math.ceil(total / q.pageSize),
    };
  }
}
