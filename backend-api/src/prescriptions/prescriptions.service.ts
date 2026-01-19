import {
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreatePrescriptionDto } from './dto/create-prescription.dto';
import { Role } from '@prisma/client';

@Injectable()
export class PrescriptionsService {
  constructor(private prisma: PrismaService) { }

  /**
   * Doctor creates a prescription for a patient for an appointment.
   * Validations:
   * - request user must be DOCTOR (guard handles this)
   * - that appointment must exist
   * - that appointment must belong to this doctor
   * - that appointment must belong to that patient
   */
  async createPrescription(
    requester: { id: string; role: Role },
    dto: CreatePrescriptionDto,
  ) {
    // DEBUG: who is calling this?
    console.log('createPrescription() called by:', requester.id, requester.role);

    // 1. Load the appointment
    const appt = await this.prisma.appointment.findUnique({
      where: { id: dto.appointmentId },
      select: {
        id: true,
        doctorId: true,
        patientId: true,
      },
    });

    if (!appt) {
      throw new NotFoundException('Appointment not found');
    }

    // 2. Check permissions
    // If Doctor, must be THEIR appointment
    if (requester.role === Role.DOCTOR) {
      if (appt.doctorId !== requester.id) {
        throw new ForbiddenException(
          'You can only prescribe for your own appointment',
        );
      }
    }
    // If Admin, they can create for any appointment (no check needed)

    // 3. Check patient matches
    if (appt.patientId !== dto.patientId) {
      console.log(
        'AUTH FAIL -> appt.patientId !== dto.patientId',
        appt.patientId,
        '!==',
        dto.patientId,
      );
      throw new ForbiddenException(
        'Patient does not match this appointment',
      );
    }

    // 4. Transaction: Prescription + Medications + MedicalHistory
    const result = await this.prisma.$transaction(async (tx) => {
      // a) create prescription
      const prescription = await tx.prescription.create({
        data: {
          appointmentId: dto.appointmentId,
          doctorId: appt.doctorId, // Always use the appointment's doctor
          patientId: dto.patientId,
          diagnosis: dto.diagnosis,
          notes: dto.notes,
        },
      });

      // b) create medication rows linked to that prescription
      await tx.medication.createMany({
        data: dto.medications.map((m) => ({
          prescriptionId: prescription.id,
          name: m.name,
          dosage: m.dosage,
          frequency: m.frequency,
          duration: m.duration,
          instruction: m.instruction,
        })),
      });

      // c) ALSO write an entry to MedicalHistory for this patient
      await tx.medicalHistory.create({
        data: {
          patientId: dto.patientId,
          diagnosis: dto.diagnosis,
          details: dto.notes ?? null,
        },
      });

      // d) return fully populated prescription
      return tx.prescription.findUnique({
        where: { id: prescription.id },
        include: {
          medications: true,
          doctor: {
            select: {
              id: true,
              name: true,
            },
          },
          patient: {
            select: {
              id: true,
              name: true,
            },
          },
          appointment: {
            select: {
              id: true,
              scheduledAt: true,
            },
          },
        },
      });
    });

    console.log('Prescription created OK with id:', result?.id);
    return result;
  }



  /**
   * Get a single prescription by ID.
   * Can be viewed by:
   * - the doctor who wrote it
   * - the patient it was written for
   * - admin
   */
  async getById(prescriptionId: string, requester: { id: string; role: Role }) {
    const prescription = await this.prisma.prescription.findUnique({
      where: { id: prescriptionId },
      include: {
        medications: true,
        doctor: {
          select: {
            id: true,
            name: true,
          },
        },
        patient: {
          select: {
            id: true,
            name: true,
          },
        },
        appointment: {
          select: {
            id: true,
            scheduledAt: true,
          },
        },
      },
    });

    if (!prescription) {
      throw new NotFoundException('Prescription not found');
    }

    const isOwnerDoctor = prescription.doctorId === requester.id;
    const isOwnerPatient = prescription.patientId === requester.id;
    const isAdmin = requester.role === Role.ADMIN;

    if (!isOwnerDoctor && !isOwnerPatient && !isAdmin) {
      throw new ForbiddenException('Not allowed to view this prescription');
    }

    return prescription;
  }

  /**
   * Patient: list my prescriptions
   */
  async getMyPrescriptionsPatient(userId: string) {
    return this.prisma.prescription.findMany({
      where: { patientId: userId },
      orderBy: { createdAt: 'desc' },
      include: {
        medications: true,
        doctor: {
          select: { id: true, name: true },
        },
        appointment: {
          select: { id: true, scheduledAt: true },
        },
      },
    });
  }

  /**
   * Doctor: list prescriptions I wrote
   */
  async getMyPrescriptionsDoctor(userId: string) {
    return this.prisma.prescription.findMany({
      where: { doctorId: userId },
      orderBy: { createdAt: 'desc' },
      include: {
        medications: true,
        patient: {
          select: { id: true, name: true },
        },
        appointment: {
          select: { id: true, scheduledAt: true },
        },
      },
    });
  }

  /**
   * Get prescription by Appointment ID
   * Accessible by: Doctor (owner), Patient (owner), Admin
   */
  async getByAppointmentId(appointmentId: string, requester: { id: string; role: Role }) {
    const prescription = await this.prisma.prescription.findFirst({
      where: { appointmentId },
      include: {
        medications: true,
        doctor: {
          select: { id: true, name: true },
        },
        patient: {
          select: { id: true, name: true },
        },
        appointment: {
          select: { id: true, scheduledAt: true },
        },
      },
    });

    if (!prescription) {
      return null; // Return null instead of throwing if not found, easier for UI
    }

    const isOwnerDoctor = prescription.doctorId === requester.id;
    const isOwnerPatient = prescription.patientId === requester.id;
    const isAdmin = requester.role === Role.ADMIN;

    if (!isOwnerDoctor && !isOwnerPatient && !isAdmin) {
      throw new ForbiddenException('Not allowed to view this prescription');
    }

    return prescription;
  }

  /**
   * Update a prescription
   * Only the doctor who created it can update it
   */
  async updatePrescription(
    prescriptionId: string,
    doctorUserId: string,
    dto: CreatePrescriptionDto, // Reusing create DTO for simplicity as it replaces content
  ) {
    const prescription = await this.prisma.prescription.findUnique({
      where: { id: prescriptionId },
    });

    if (!prescription) {
      throw new NotFoundException('Prescription not found');
    }

    if (prescription.doctorId !== doctorUserId) {
      throw new ForbiddenException('You can only update your own prescriptions');
    }

    // Transaction to update prescription and replace medications
    return this.prisma.$transaction(async (tx) => {
      // 1. Update prescription details
      const updated = await tx.prescription.update({
        where: { id: prescriptionId },
        data: {
          diagnosis: dto.diagnosis,
          notes: dto.notes,
        },
      });

      // 2. Delete existing medications
      await tx.medication.deleteMany({
        where: { prescriptionId },
      });

      // 3. Create new medications
      await tx.medication.createMany({
        data: dto.medications.map((m) => ({
          prescriptionId: prescriptionId,
          name: m.name,
          dosage: m.dosage,
          frequency: m.frequency,
          duration: m.duration,
          instruction: m.instruction,
        })),
      });

      // 4. Return updated prescription
      return tx.prescription.findUnique({
        where: { id: prescriptionId },
        include: {
          medications: true,
          doctor: { select: { id: true, name: true } },
          patient: { select: { id: true, name: true } },
        },
      });
    });
  }
}
