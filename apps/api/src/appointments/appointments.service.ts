import {
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { AppointmentStatus, Prisma } from '@prisma/client';

@Injectable()
export class AppointmentsService {
  constructor(private prisma: PrismaService) { }

  /**
   * PATIENT creates an appointment request with a doctor.
   * Stored initially as PENDING.
   *
   * We assume:
   * - patientUserId is User.id of the logged-in PATIENT
   * - doctorUserId is User.id of the DOCTOR they want to see
   * - scheduledAt is a Date object already validated/parsed in controller
   */
  async request(
    patientUserId: string,
    doctorUserId: string,
    scheduledAt: Date,
    reason?: string,
    organizationId?: string,
  ) {
    // 1. Fetch doctor profile with user memberships to find organization if not provided
    const doctorUser = await this.prisma.user.findUnique({
      where: { id: doctorUserId },
      include: {
        doctorProfile: true,
        memberships: {
          include: { organization: true },
        },
      },
    });

    if (!doctorUser || !doctorUser.doctorProfile) {
      throw new NotFoundException('Doctor not found');
    }

    // Determine Organization
    let org: any = null;
    if (organizationId) {
      org = await this.prisma.organization.findUnique({ where: { id: organizationId } });
    } else if (doctorUser.memberships.length > 0) {
      // Default to the first organization the doctor belongs to
      org = doctorUser.memberships[0].organization;
    }

    // 2. Ensure requester is a patient
    const patientUser = await this.prisma.user.findUnique({
      where: { id: patientUserId },
    });
    if (!patientUser || patientUser.role !== 'PATIENT') {
      throw new ForbiddenException('Only patients can create appointments');
    }

    // 3. Fee Calculation Logic
    const feeControlMode = org?.feeControlMode || 'doctor_controlled';
    const doctorProfile = doctorUser.doctorProfile;

    // Default fees from doctor profile
    let baseFee = doctorProfile.baseFee;
    let followUpFee = doctorProfile.followUpFee;
    let followUpDays = doctorProfile.followUpDays;

    // If organization controlled, we might want to override (logic can be expanded here)
    // For now, we assume organization sets these values on the doctor profile directly
    // or we could have a separate OrganizationDoctorFee model. 
    // Given the prompt: "Organization admin sets the base_fee for each doctor."
    // This implies the value on Doctor model IS the source of truth, but who can EDIT it changes.
    // So reading from doctorProfile is correct for both modes.

    // 4. Check for Follow-up Eligibility
    // Rules: Same patient, same doctor, last appointment COMPLETED, within followUpDays
    const lastAppointment = await this.prisma.appointment.findFirst({
      where: {
        patientId: patientUserId,
        doctorId: doctorUserId,
        status: 'COMPLETED',
        createdAt: {
          gte: new Date(Date.now() - followUpDays * 24 * 60 * 60 * 1000),
        },
        // Ensure this appointment hasn't already been used for a follow-up
        followUpChildren: {
          none: {},
        },
      },
      orderBy: {
        createdAt: 'desc',
      },
    });

    let isFollowUp = false;
    let followUpParentId: string | undefined = undefined;
    let chargedFee = baseFee;

    if (lastAppointment) {
      isFollowUp = true;
      followUpParentId = lastAppointment.id;
      chargedFee = followUpFee;
    }

    // 5. Create appointment
    const created = await this.prisma.appointment.create({
      data: {
        patientId: patientUserId,
        doctorId: doctorUserId,
        scheduledAt,
        reason: reason ?? undefined,
        status: AppointmentStatus.PENDING,
        organizationId: org?.id ?? undefined,
        isFollowUp,
        followUpParentId,
        chargedFee,
      },
    });

    // 6. Return response
    return {
      ...created,
      doctor: {
        id: doctorUser.id,
        name: doctorUser.name,
        email: doctorUser.email,
        phone: doctorUser.phone,
        role: doctorUser.role,
      },
      patient: {
        id: patientUser.id,
        name: patientUser.name,
        email: patientUser.email,
        phone: patientUser.phone,
        role: patientUser.role,
      },
    };
  }

  /**
   * DOCTOR or ADMIN confirms an appointment -> status = CONFIRMED.
   * Only that doctor can confirm, unless caller is admin.
   * Optionally allows updating the scheduledAt field if doctor picks a slot.
   */
  async confirm(
    appointmentId: string,
    userId: string,
    scheduledAt?: Date,
    isAdmin = false,
  ) {
    const appt = await this.prisma.appointment.findUnique({
      where: { id: appointmentId },
    });

    if (!appt) {
      throw new NotFoundException('Appointment not found');
    }

    // Only check ownership if not admin
    if (!isAdmin && appt.doctorId !== userId) {
      throw new ForbiddenException('Not your appointment');
    }

    const data: Prisma.AppointmentUpdateInput = {
      status: AppointmentStatus.CONFIRMED,
    };

    if (scheduledAt) {
      data.scheduledAt = scheduledAt;
    }

    return this.prisma.appointment.update({
      where: { id: appointmentId },
      data,
    });
  }

  /**
   * DOCTOR or ADMIN rejects an appointment.
   * We map this to CANCELLED.
   */
  async reject(appointmentId: string, userId: string, isAdmin = false) {
    const appt = await this.prisma.appointment.findUnique({
      where: { id: appointmentId },
    });

    if (!appt) {
      throw new NotFoundException('Appointment not found');
    }

    // Only check ownership if not admin
    if (!isAdmin && appt.doctorId !== userId) {
      throw new ForbiddenException('Not your appointment');
    }

    return this.prisma.appointment.update({
      where: { id: appointmentId },
      data: { status: AppointmentStatus.CANCELLED },
    });
  }

  /**
   * PATIENT / DOCTOR / ADMIN cancels.
   * Rules:
   * - PATIENT can cancel only if they own it
   * - DOCTOR can cancel only if they own it
   * - ADMIN can cancel any
   */
  async cancel(
    appointmentId: string,
    userId: string,
    role: 'PATIENT' | 'DOCTOR' | 'ADMIN',
  ) {
    const appt = await this.prisma.appointment.findUnique({
      where: { id: appointmentId },
    });

    if (!appt) {
      throw new NotFoundException('Appointment not found');
    }

    if (role === 'PATIENT' && appt.patientId !== userId) {
      throw new ForbiddenException('Not your appointment');
    }
    if (role === 'DOCTOR' && appt.doctorId !== userId) {
      throw new ForbiddenException('Not your appointment');
    }
    // role === 'ADMIN' skips the ownership check

    return this.prisma.appointment.update({
      where: { id: appointmentId },
      data: { status: AppointmentStatus.CANCELLED },
    });
  }

  /**
   * DOCTOR or ADMIN marks appointment completed -> status = COMPLETED.
   */
  async complete(appointmentId: string, userId: string, isAdmin = false) {
    const appt = await this.prisma.appointment.findUnique({
      where: { id: appointmentId },
    });

    if (!appt) {
      throw new NotFoundException('Appointment not found');
    }

    // Only check ownership if not admin
    if (!isAdmin && appt.doctorId !== userId) {
      throw new ForbiddenException('Not your appointment');
    }

    return this.prisma.appointment.update({
      where: { id: appointmentId },
      data: { status: AppointmentStatus.COMPLETED },
    });
  }

  /**
   * Get one appointment + expanded doctor/patient info.
   */
  async get(id: string) {
    const appt = await this.prisma.appointment.findUnique({
      where: { id },
      include: {
        organization: true,
      }
    });

    if (!appt) {
      throw new NotFoundException('Appointment not found');
    }

    // fetch related user info
    const [doctorUser, patientUser] = await Promise.all([
      this.prisma.user.findUnique({
        where: { id: appt.doctorId },
        select: {
          id: true,
          name: true,
          email: true,
          phone: true,
          role: true,
        },
      }),
      this.prisma.user.findUnique({
        where: { id: appt.patientId },
        select: {
          id: true,
          name: true,
          email: true,
          phone: true,
          role: true,
        },
      }),
    ]);

    return {
      ...appt,
      doctor: doctorUser,
      patient: patientUser,
    };
  }

  /**
   * List appointments (filter doctorId/patientId/status),
   * newest first, each with doctor+patient info.
   */
  async list(filter: {
    doctorId?: string;
    patientId?: string;
    organizationId?: string;
    status?: AppointmentStatus;
  }) {
    const where: Prisma.AppointmentWhereInput = {};

    if (filter.doctorId) {
      where.doctorId = filter.doctorId;
    }
    if (filter.patientId) {
      where.patientId = filter.patientId;
    }
    if (filter.organizationId) {
      where.organizationId = filter.organizationId;
    }
    if (filter.status) {
      where.status = filter.status;
    }

    const appts = await this.prisma.appointment.findMany({
      where,
      orderBy: { createdAt: 'desc' },
      include: {
        organization: true,
        review: true,
      }
    });

    // Attach doctor/patient info to each
    const results = await Promise.all(
      appts.map(async (a) => {
        const [doctorUser, patientUser] = await Promise.all([
          this.prisma.user.findUnique({
            where: { id: a.doctorId },
            select: {
              id: true,
              name: true,
              email: true,
              phone: true,
              role: true,
            },
          }),
          this.prisma.user.findUnique({
            where: { id: a.patientId },
            select: {
              id: true,
              name: true,
              email: true,
              phone: true,
              role: true,
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

    return results;
  }

  // PATIENT or DOCTOR requests to reschedule an appointment.
  // Creates a reschedule request that admin can approve.
  async requestReschedule(
    appointmentId: string,
    userId: string,
    role: 'PATIENT' | 'DOCTOR',
    requestedDateTime: Date,
    reason?: string,
  ) {
    const appt = await this.prisma.appointment.findUnique({
      where: { id: appointmentId },
    });

    if (!appt) {
      throw new NotFoundException('Appointment not found');
    }

    // Check if user is authorized (patient or doctor of this appointment)
    if (role === 'PATIENT' && appt.patientId !== userId) {
      throw new ForbiddenException('You can only request reschedule for your own appointments');
    }
    if (role === 'DOCTOR' && appt.doctorId !== userId) {
      throw new ForbiddenException('You can only request reschedule for your own appointments');
    }

    // Create reschedule request
    const rescheduleRequest = await this.prisma.rescheduleRequest.create({
      data: {
        appointmentId,
        requestedById: userId,
        requestedDateTime,
        reason,
        status: 'PENDING',
      },
      include: {
        appointment: {
          include: {
            doctor: true,
            patient: true,
          },
        },
        requestedBy: true,
      },
    });

    return rescheduleRequest;
  }

  // ADMIN reschedules an appointment.
  // Updates the scheduledAt time and marks any pending reschedule requests as approved.
  async reschedule(appointmentId: string, newScheduledAt: Date) {
    const appt = await this.prisma.appointment.findUnique({
      where: { id: appointmentId },
      include: {
        rescheduleRequests: {
          where: { status: 'PENDING' },
        },
      },
    });

    if (!appt) {
      throw new NotFoundException('Appointment not found');
    }

    // Update appointment time
    const updated = await this.prisma.appointment.update({
      where: { id: appointmentId },
      data: {
        scheduledAt: newScheduledAt,
      },
      include: {
        doctor: true,
        patient: true,
      },
    });

    // Mark all pending reschedule requests as approved
    if (appt.rescheduleRequests.length > 0) {
      await this.prisma.rescheduleRequest.updateMany({
        where: {
          appointmentId,
          status: 'PENDING',
        },
        data: {
          status: 'APPROVED',
        },
      });
    }

    return updated;
  }

  // Get all reschedule requests (for admin)
  async getRescheduleRequests(status?: string) {
    return this.prisma.rescheduleRequest.findMany({
      where: status ? { status } : undefined,
      include: {
        appointment: {
          include: {
            doctor: true,
            patient: true,
          },
        },
        requestedBy: true,
      },
      orderBy: {
        createdAt: 'desc',
      },
    });
  }

  /**
   * Check eligibility for follow-up and calculate fee.
   */
  async checkEligibility(patientId: string, doctorId: string) {
    // Fetch doctor profile
    const doctorUser = await this.prisma.user.findUnique({
      where: { id: doctorId },
      include: {
        doctorProfile: true,
      },
    });

    if (!doctorUser || !doctorUser.doctorProfile) {
      throw new NotFoundException('Doctor not found');
    }

    const doctorProfile = doctorUser.doctorProfile;
    const baseFee = doctorProfile.baseFee;
    const followUpFee = doctorProfile.followUpFee;
    const followUpDays = doctorProfile.followUpDays;

    // Check for last completed appointment
    const lastAppointment = await this.prisma.appointment.findFirst({
      where: {
        patientId: patientId,
        doctorId: doctorId,
        status: 'COMPLETED',
        createdAt: {
          gte: new Date(Date.now() - followUpDays * 24 * 60 * 60 * 1000),
        },
        followUpChildren: {
          none: {},
        },
      },
      orderBy: {
        createdAt: 'desc',
      },
    });

    if (lastAppointment) {
      return {
        isFollowUp: true,
        chargedFee: followUpFee,
        originalFee: baseFee,
        followUpParentId: lastAppointment.id,
      };
    }

    return {
      isFollowUp: false,
      chargedFee: baseFee,
      originalFee: baseFee,
      followUpParentId: null,
    };
  }
}
