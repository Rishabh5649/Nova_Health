import {
  Injectable,
  ForbiddenException,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateMedicalHistoryDto } from './dto/create-medical-history.dto';
import { Role } from '@prisma/client';

@Injectable()
export class MedicalHistoryService {
  constructor(private prisma: PrismaService) {}

  /**
   * Create a medical history record for a patient.
   * Only DOCTOR or ADMIN should be able to do this.
   * We also make sure the patient actually exists.
   */
  async createEntry(
    creator: { id: string; role: Role },
    dto: CreateMedicalHistoryDto,
  ) {
    // Safety: allow only doctor or admin to add
    if (creator.role !== Role.DOCTOR && creator.role !== Role.ADMIN) {
      throw new ForbiddenException('Only doctors/admin can add history');
    }

    // Check that this patient user exists and is actually a PATIENT
    const patientUser = await this.prisma.user.findUnique({
      where: { id: dto.patientId },
      select: {
        id: true,
        role: true,
        name: true,
      },
    });

    if (!patientUser) {
      throw new NotFoundException('Patient not found');
    }

    if (patientUser.role !== Role.PATIENT) {
      throw new ForbiddenException('Target user is not a patient');
    }

    // Save the medical history record
    const history = await this.prisma.medicalHistory.create({
      data: {
        patientId: dto.patientId,
        diagnosis: dto.diagnosis,
        details: dto.details,
        // recordedAt auto @default(now())
      },
      include: {
        patient: {
          select: {
            id: true,
            name: true,
          },
        },
      },
    });

    return history;
  }

  /**
   * Patient: view MY OWN medical history timeline
   * Role: PATIENT
   */
  async getMyHistory(patientUserId: string) {
    return this.prisma.medicalHistory.findMany({
      where: { patientId: patientUserId },
      orderBy: { recordedAt: 'desc' },
      select: {
        id: true,
        diagnosis: true,
        details: true,
        recordedAt: true,
      },
    });
  }

  /**
   * Doctor/Admin: view a specific patient's medical history
   * This is helpful for doctor dashboard when viewing a patient.
   * Only DOCTOR or ADMIN.
   */
  async getPatientHistory(
    requester: { id: string; role: Role },
    patientId: string,
  ) {
    if (requester.role !== Role.DOCTOR && requester.role !== Role.ADMIN) {
      throw new ForbiddenException('Not allowed');
    }

    // Confirm patient exists
    const target = await this.prisma.user.findUnique({
      where: { id: patientId },
      select: {
        id: true,
        role: true,
        name: true,
      },
    });

    if (!target) {
      throw new NotFoundException('Patient not found');
    }

    if (target.role !== Role.PATIENT) {
      throw new ForbiddenException('Target user is not a patient');
    }

    const historyList = await this.prisma.medicalHistory.findMany({
      where: { patientId },
      orderBy: { recordedAt: 'desc' },
      select: {
        id: true,
        diagnosis: true,
        details: true,
        recordedAt: true,
      },
    });

    return {
      patient: {
        id: target.id,
        name: target.name,
      },
      history: historyList,
    };
  }

  /**
   * Get a single medical history record by ID.
   * Allowed:
   * - The patient themself
   * - Any doctor
   * - Admin
   */
  async getHistoryEntryById(
    requester: { id: string; role: Role },
    entryId: string,
  ) {
    const entry = await this.prisma.medicalHistory.findUnique({
      where: { id: entryId },
      include: {
        patient: {
          select: {
            id: true,
            name: true,
            role: true,
          },
        },
      },
    });

    if (!entry) {
      throw new NotFoundException('Record not found');
    }

    const isOwnerPatient = entry.patient.id === requester.id;
    const isDoctor = requester.role === Role.DOCTOR;
    const isAdmin = requester.role === Role.ADMIN;

    if (!isOwnerPatient && !isDoctor && !isAdmin) {
      throw new ForbiddenException('Not allowed to view this record');
    }

    // Shape the response a little cleaner
    return {
      id: entry.id,
      diagnosis: entry.diagnosis,
      details: entry.details,
      recordedAt: entry.recordedAt,
      patient: {
        id: entry.patient.id,
        name: entry.patient.name,
      },
    };
  }
}
