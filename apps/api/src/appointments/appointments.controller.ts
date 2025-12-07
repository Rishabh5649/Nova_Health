import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Patch,
  Post,
  Query,
  UseGuards,
  ForbiddenException,
} from '@nestjs/common';
import { AppointmentsService } from './appointments.service';
import { RescheduleService } from './reschedule.service';
import { CancellationService } from './cancellation.service';
import { JwtAuthGuard } from '../auth/jwt.guard';
import { Roles } from '../auth/roles.decorator';
import { RolesGuard } from '../auth/roles.guard';
import { CurrentUser } from '../auth/current-user.decorator';
import type { JwtUser } from '../auth/current-user.decorator';
import { AppointmentStatus } from '@prisma/client';

@Controller('appointments')
@UseGuards(JwtAuthGuard, RolesGuard)
export class AppointmentsController {
  constructor(
    private readonly svc: AppointmentsService,
    private readonly rescheduleService: RescheduleService,
    private readonly cancellationService: CancellationService,
  ) { }

  // -------------------------------------------------------------------
  // PATIENT creates an appointment request
  // -------------------------------------------------------------------
  @Post('request')
  @Roles('PATIENT', 'ADMIN')
  async requestAppointment(
    @Body('doctorUserId') doctorUserId: string,
    @Body('scheduledAt') scheduledAtIso: string,
    @Body('reason') reason: string | undefined,
    @Body('organizationId') organizationId: string | undefined,
    @Body('patientId') patientId: string | undefined,
    @CurrentUser() user: JwtUser,
  ) {
    let effectivePatientId = user.sub;
    if (user.role === 'ADMIN') {
      if (!patientId) {
        throw new ForbiddenException('Admin must provide patientId');
      }
      effectivePatientId = patientId;
    }
    return this.svc.request(
      effectivePatientId,
      doctorUserId,
      new Date(scheduledAtIso),
      reason,
      organizationId,
    );
  }

  // -------------------------------------------------------------------
  // ADMIN confirms an appointment
  // -------------------------------------------------------------------
  @Patch(':id/confirm')
  @Roles('ADMIN')
  async confirmAppointment(
    @Param('id') id: string,
    @Body('doctorUserId') doctorUserId: string,
    @Body('scheduledAt') scheduledAtIso: string | undefined,
    @CurrentUser() user: JwtUser,
  ) {
    const effectiveDoctorId = doctorUserId ?? user.sub;
    const scheduledAt = scheduledAtIso ? new Date(scheduledAtIso) : undefined;
    const isAdmin = user.role === 'ADMIN';
    return this.svc.confirm(id, effectiveDoctorId, scheduledAt, isAdmin);
  }

  // -------------------------------------------------------------------
  // ADMIN rejects an appointment
  // -------------------------------------------------------------------
  @Patch(':id/reject')
  @Roles('ADMIN')
  async rejectAppointment(@Param('id') id: string, @CurrentUser() user: JwtUser) {
    const isAdmin = user.role === 'ADMIN';
    return this.svc.reject(id, user.sub, isAdmin);
  }

  // -------------------------------------------------------------------
  // CANCEL endpoint – role based handling
  // -------------------------------------------------------------------
  @Patch(':id/cancel')
  async cancelAppointment(@Param('id') id: string, @CurrentUser() user: JwtUser, @Body('reason') reason?: string) {
    if (user.role === 'PATIENT') {
      // Patient cancellation – no refund
      return this.cancellationService.cancelAsPatient(id, user.sub, reason ?? 'Patient cancelled');
    }
    if (user.role === 'ADMIN' || (user.role as string) === 'RECEPTIONIST') {
      // Admin/receptionist cancellation – requires reason for refund
      if (!reason || reason.trim().length < 10) {
        throw new ForbiddenException('Cancellation reason must be at least 10 characters for admin/receptionist');
      }
      return this.cancellationService.cancelAsAdmin(id, user.sub, reason);
    }
    // Doctor – not allowed to cancel, must request reschedule
    return this.cancellationService.cancelAsDoctor();
  }

  // -------------------------------------------------------------------
  // MARK appointment completed – doctor or admin
  // -------------------------------------------------------------------
  @Patch(':id/complete')
  @Roles('DOCTOR', 'ADMIN')
  async completeAppointment(@Param('id') id: string, @CurrentUser() user: JwtUser) {
    const isAdmin = user.role === 'ADMIN';
    return this.svc.complete(id, user.sub, isAdmin);
  }

  // -------------------------------------------------------------------
  // LIST appointments with optional filters
  // -------------------------------------------------------------------
  @Get()
  async listAppointments(
    @Query('doctorId') doctorId?: string,
    @Query('patientId') patientId?: string,
    @Query('organizationId') organizationId?: string,
    @Query('status') status?: string,
  ) {
    const normalizedStatus = status as AppointmentStatus | undefined;
    return this.svc.list({ doctorId, patientId, organizationId, status: normalizedStatus });
  }

  // -------------------------------------------------------------------
  // RESCHEDULE REQUESTS – old compatibility endpoints
  // -------------------------------------------------------------------
  @Get('reschedule-requests')
  @Roles('ADMIN')
  async getRescheduleRequests(@Query('status') status?: string) {
    return this.svc.getRescheduleRequests(status);
  }

  @Patch(':id/reschedule')
  @Roles('ADMIN')
  async rescheduleAppointment(@Param('id') id: string, @Body('scheduledAt') scheduledAtIso: string) {
    return this.svc.reschedule(id, new Date(scheduledAtIso));
  }

  // -------------------------------------------------------------------
  // Follow‑up eligibility check
  // -------------------------------------------------------------------
  @Get('check-eligibility')
  async checkEligibility(@Query('patientId') patientId: string, @Query('doctorId') doctorId: string) {
    return this.svc.checkEligibility(patientId, doctorId);
  }

  // -------------------------------------------------------------------
  // NEW RESCHEDULE MODULE ENDPOINTS
  // -------------------------------------------------------------------
  @Get('reschedule-requests/all')
  @Roles('ADMIN')
  async getAllRescheduleRequests(
    @Query('appointmentId') appointmentId?: string,
    @Query('status') status?: 'PENDING' | 'APPROVED' | 'REJECTED',
    @Query('organizationId') organizationId?: string,
  ) {
    return this.rescheduleService.getRescheduleRequests(appointmentId, status, organizationId);
  }

  @Get('reschedule-requests/:id')
  async getRescheduleRequest(@Param('id') id: string) {
    return this.rescheduleService.getRescheduleRequest(id);
  }

  @Get(':id')
  async getAppointment(@Param('id') id: string) {
    return this.svc.get(id);
  }

  @Post(':id/reschedule-request')
  @Roles('PATIENT', 'DOCTOR')
  async requestReschedule(
    @Param('id') appointmentId: string,
    @Body() body: { requestedDateTime: string; reason?: string },
    @CurrentUser() user: JwtUser,
  ) {
    return this.rescheduleService.requestReschedule(
      appointmentId,
      user.sub,
      new Date(body.requestedDateTime),
      body.reason,
    );
  }

  @Patch('reschedule-requests/:id/approve')
  @Roles('ADMIN')
  async approveReschedule(@Param('id') id: string) {
    return this.rescheduleService.approveReschedule(id);
  }

  @Patch('reschedule-requests/:id/reject')
  @Roles('ADMIN')
  async rejectReschedule(@Param('id') id: string) {
    return this.rescheduleService.rejectReschedule(id);
  }

  @Delete('reschedule-requests/:id')
  async cancelRescheduleRequest(@Param('id') id: string, @CurrentUser() user: JwtUser) {
    return this.rescheduleService.cancelRescheduleRequest(id, user.sub);
  }

  @Patch(':id/direct-reschedule')
  @Roles('ADMIN')
  async directReschedule(@Param('id') appointmentId: string, @Body() body: { scheduledAt: string }) {
    return this.rescheduleService.directReschedule(appointmentId, new Date(body.scheduledAt));
  }
}
