import { ForbiddenException, Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { UpdatePatientDto } from './dto/update-patient.dto';

@Injectable()
export class PatientsService {
  constructor(private prisma: PrismaService) { }

  /**
   * Get the logged-in patient's profile (patient table joined with user basic info).
   */
  async getMe(userId: string) {
    const patient = await this.prisma.patient.findUnique({
      where: { userId },
      include: {
        user: {
          select: {
            email: true,
            role: true,
            phone: true,
            createdAt: true,
          },
        },
      },
    });

    if (!patient) {
      throw new ForbiddenException('Only patients can access this resource.');
    }

    return patient;
  }

  /**
   * Update logged-in patient's demographics / medical profile.
   * (name, gender, allergies, etc.)
   */
  async updateMe(userId: string, dto: UpdatePatientDto) {
    const patient = await this.prisma.patient.findUnique({
      where: { userId },
    });

    if (!patient) {
      throw new ForbiddenException('Only patients can update their profile.');
    }

    // We trust dto because UpdatePatientDto should already restrict allowed fields
    // Check for immutable fields
    if (dto.dob && patient.dob) {
      throw new ForbiddenException('Date of birth cannot be changed once set.');
    }
    if (dto.bloodGroup && patient.bloodGroup) {
      throw new ForbiddenException('Blood group cannot be changed once set.');
    }
    if (dto.gender && patient.gender) {
      throw new ForbiddenException('Gender cannot be changed once set.');
    }

    // Separate User fields
    const { email, phone, ...patientData } = dto;

    // Update User if email/phone provided
    if (email || phone) {
      await this.prisma.user.update({
        where: { id: userId },
        data: {
          ...(email && { email }),
          ...(phone && { phone }),
        },
      });
    }

    return this.prisma.patient.update({
      where: { userId },
      data: {
        ...patientData,
        // Ensure that if we are "setting" it for the first time, it works.
        // If it was already set, we threw exception above.
      } as any,
    });
  }

  /**
   * Patient can view their own prescriptions.
   * Sorted newest first.
   */
  async listMyPrescriptions(userId: string) {
    const prescriptions = await this.prisma.prescription.findMany({
      where: { patientId: userId },
      orderBy: { createdAt: 'desc' },
    });

    // hydrate doctor basic info + maybe appointment info for context
    const result = await Promise.all(
      prescriptions.map(async (rx) => {
        const [doctorUser, appt] = await Promise.all([
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
          appointment: appt,
        };
      }),
    );

    return result;
  }

  /**
   * Patient can view their own medical history entries
   * (conditions, notes added over time).
   * Sorted newest first using recordedAt.
   */
  async listMyRecords(userId: string) {
    return this.prisma.medicalHistory.findMany({
      where: { patientId: userId },
      orderBy: { recordedAt: 'desc' },
    });
  }

  /**
   * Patient can add a new medical history entry.
   * We'll allow them to add { condition, details }.
   *
   * NOTE: This is different from "file upload" style records.
   * Your schema today does not support fileUrl / metadata,
   * so we stick to condition + details.
   */
  async addRecord(
    userId: string,
    data: { diagnosis: string; details?: string },
  ) {
    // Make sure this user is actually a patient
    const patient = await this.prisma.patient.findUnique({
      where: { userId },
    });

    if (!patient) {
      throw new ForbiddenException('Only patients can add records.');
    }

    return this.prisma.medicalHistory.create({
      data: {
        patientId: userId,
        diagnosis: data.diagnosis,
        details: data.details ?? null,
        // recordedAt auto defaults in schema
      },
    });
  }

  /**
   * Generates a summary of the patient's medical history and prescriptions.
   * This mimics an AI summarizer bot.
   */
  async getSummary(userId: string) {
    const records = await this.listMyRecords(userId);
    const prescriptions = await this.listMyPrescriptions(userId);

    if (records.length === 0 && prescriptions.length === 0) {
      return { summary: 'No medical history or prescriptions found for this patient.' };
    }

    const conditions = records.map((r) => r.diagnosis).filter(Boolean);
    const uniqueConditions = [...new Set(conditions)];

    let summary = `**Patient Content Summary**\n\n`;

    if (uniqueConditions.length > 0) {
      summary += `**Diagnosed Conditions:**\n${uniqueConditions.join(', ')}\n\n`;
    } else {
      summary += `No specific diagnoses recorded in history.\n\n`;
    }

    if (records.length > 0) {
      const recent = records[0];
      summary += `**Most Recent Record:**\n${recent.diagnosis} (${recent.recordedAt.toDateString()})\n${recent.details || ''}\n\n`;
    }

    if (prescriptions.length > 0) {
      const recentRx = prescriptions[0];
      summary += `**Latest Prescription:**\nDate: ${recentRx.createdAt.toDateString()}\n`;
      if (recentRx['medications']) {
        const meds = (recentRx['medications'] as any[]).map(m => m.name).join(', ');
        summary += `Medications: ${meds}\n`;
      }
    }

    summary += `\n**Overview:**\nThis patient has ${records.length} history records and ${prescriptions.length} prescriptions on file.`;

    return { summary };
  }
}
