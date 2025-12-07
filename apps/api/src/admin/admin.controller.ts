import { Body, Controller, Get, Param, Patch, Query, UseGuards } from '@nestjs/common';
import { AdminService } from './admin.service';
import { JwtAuthGuard } from '../auth/jwt.guard';
import { Roles } from '../auth/roles.decorator';
import { RolesGuard } from '../auth/roles.guard';
import { PaginatedQueryDto } from './dto/paginated-query.dto';
import { VerifyDoctorDto } from './dto/verify-doctor.dto';
import { Transform } from 'class-transformer';
import { IsIn, IsOptional } from 'class-validator';

// Inherit q, page, pageSize from PaginatedQueryDto. Do NOT redeclare q here.
class DoctorsQueryDto extends PaginatedQueryDto {
  @IsOptional()
  @IsIn(['PENDING', 'APPROVED', 'REJECTED'])
  @Transform(({ value }) => value?.toUpperCase())
  status?: 'PENDING' | 'APPROVED' | 'REJECTED';
}

class AppointmentsQueryDto extends PaginatedQueryDto {
  @IsOptional()
  @IsIn(['REQUESTED', 'ACCEPTED', 'RESCHEDULED', 'REJECTED', 'CANCELLED', 'COMPLETED'])
  @Transform(({ value }) => value?.toUpperCase())
  status?: string;
}

@UseGuards(JwtAuthGuard, RolesGuard)
@Roles('ADMIN')
@Controller('admin')
export class AdminController {
  constructor(private readonly svc: AdminService) {}

  // Users
  @Get('users')
  users(@Query() q: PaginatedQueryDto) {
    return this.svc.listUsers(q);
  }

  // Doctors
  @Get('doctors')
  doctors(@Query() q: DoctorsQueryDto) {
    return this.svc.listDoctors(q);
  }

  @Patch('doctors/:userId/verify')
  verify(@Param('userId') userId: string, @Body() body: VerifyDoctorDto) {
    return this.svc.verifyDoctor(userId, body.status);
  }

  // Patients
  @Get('patients')
  patients(@Query() q: PaginatedQueryDto) {
    return this.svc.listPatients(q);
  }

  // Appointments
  @Get('appointments')
  appointments(@Query() q: AppointmentsQueryDto) {
    return this.svc.listAppointments(q);
  }

  // Prescriptions
  @Get('prescriptions')
  prescriptions(@Query() q: PaginatedQueryDto) {
    return this.svc.listPrescriptions(q);
  }
}
