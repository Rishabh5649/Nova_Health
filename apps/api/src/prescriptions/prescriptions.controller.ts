import {
  Controller,
  Post,
  Get,
  Put,
  Param,
  Body,
  UseGuards,
} from '@nestjs/common';
import { PrescriptionsService } from './prescriptions.service';
import { CreatePrescriptionDto } from './dto/create-prescription.dto';
import { JwtAuthGuard } from '../auth/jwt.guard';
import { RolesGuard } from '../auth/roles.guard';
import { Roles } from '../auth/roles.decorator';
import { CurrentUser } from '../auth/current-user.decorator';
import { Role } from '@prisma/client';

@UseGuards(JwtAuthGuard, RolesGuard)
@Controller('prescriptions')
export class PrescriptionsController {
  constructor(private readonly prescriptionsService: PrescriptionsService) { }

  /**
   * Create a new prescription (doctor only)
   * POST http://localhost:3000/prescriptions
   */
  @Post()
  @Roles(Role.DOCTOR, Role.ADMIN)
  createPrescription(
    @CurrentUser() user: { sub: string; role: Role },
    @Body() dto: CreatePrescriptionDto,
  ) {
    return this.prescriptionsService.createPrescription(
      { id: user.sub, role: user.role },
      dto,
    );
  }

  /**
   * Patient: get all my prescriptions
   * GET http://localhost:3000/prescriptions/me/patient
   */
  @Get('me/patient')
  @Roles(Role.PATIENT)
  getMinePatient(@CurrentUser() user: { sub: string; role: Role }) {
    // patient user id is also in sub
    return this.prescriptionsService.getMyPrescriptionsPatient(user.sub);
  }

  /**
   * Doctor: get all prescriptions I've written
   * GET http://localhost:3000/prescriptions/me/doctor
   */
  @Get('me/doctor')
  @Roles(Role.DOCTOR)
  getMineDoctor(@CurrentUser() user: { sub: string; role: Role }) {
    // doctor user id is also in sub
    return this.prescriptionsService.getMyPrescriptionsDoctor(user.sub);
  }

  /**
   * Get single prescription by ID
   * GET http://localhost:3000/prescriptions/:id
   *
   * Allowed:
   * - Doctor who wrote it
   * - Patient it was written for
   * - Admin
   */
  @Get(':id')
  getById(
    @Param('id') prescriptionId: string,
    @CurrentUser() user: { sub: string; role: Role },
  ) {
    // service.getById() expects { id: string; role: Role }
    return this.prescriptionsService.getById(prescriptionId, {
      id: user.sub,
      role: user.role,
    });
  }

  /**
   * Get prescription by Appointment ID
   * GET http://localhost:3000/prescriptions/appointment/:appointmentId
   */
  @Get('appointment/:appointmentId')
  getByAppointment(
    @Param('appointmentId') appointmentId: string,
    @CurrentUser() user: { sub: string; role: Role },
  ) {
    return this.prescriptionsService.getByAppointmentId(appointmentId, {
      id: user.sub,
      role: user.role,
    });
  }

  /**
   * Update prescription (doctor and admin)
   * PUT http://localhost:3000/prescriptions/:id
   */
  @Put(':id')
  @Roles(Role.DOCTOR, Role.ADMIN)
  updatePrescription(
    @Param('id') id: string,
    @CurrentUser() user: { sub: string; role: Role },
    @Body() dto: CreatePrescriptionDto,
  ) {
    return this.prescriptionsService.updatePrescription(id, user.sub, dto);
  }
}
