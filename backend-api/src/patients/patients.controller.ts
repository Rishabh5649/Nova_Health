import {
  Body,
  Controller,
  Get,
  Post,
  Patch,
  UseGuards,
} from '@nestjs/common';
import { PatientsService } from './patients.service';
import { JwtAuthGuard } from '../auth/jwt.guard';
import { Roles } from '../auth/roles.decorator';
import { RolesGuard } from '../auth/roles.guard';
import { CurrentUser } from '../auth/current-user.decorator';
import type { JwtUser } from '../auth/current-user.decorator';
import { UpdatePatientDto } from './dto/update-patient.dto';

@Controller('patients/me')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles('PATIENT')
export class PatientsController {
  constructor(private readonly svc: PatientsService) {}

  /**
   * GET /patients/me
   * Return my profile (patient row + basic user info)
   */
  @Get()
  me(@CurrentUser() user: JwtUser) {
    return this.svc.getMe(user!.sub);
  }

  /**
   * PATCH /patients/me
   * Update my demographics / medical info
   */
  @Patch()
  update(
    @CurrentUser() user: JwtUser,
    @Body() dto: UpdatePatientDto,
  ) {
    return this.svc.updateMe(user!.sub, dto);
  }

  /**
   * GET /patients/me/prescriptions
   * (planned) List prescriptions for the logged-in patient
   * NOTE: make sure PatientsService.listMyPrescriptions exists
   */
  @Get('prescriptions')
  myPrescriptions(@CurrentUser() user: JwtUser) {
    return this.svc.listMyPrescriptions(user!.sub);
  }

  /**
   * GET /patients/me/records
   * (planned) List medical records/history for the logged-in patient
   * NOTE: make sure PatientsService.listMyRecords exists
   */
  @Get('records')
  myRecords(@CurrentUser() user: JwtUser) {
    return this.svc.listMyRecords(user!.sub);
  }

  /**
   * POST /patients/me/records
   * (planned) Add new record / condition for this patient
   * NOTE: make sure PatientsService.addRecord exists
   */
  @Post('records')
  addRecord(
    @Body()
    body: {
      diagnosis: string;
      details?: string;
    },
    @CurrentUser() user: JwtUser,
  ) {
    return this.svc.addRecord(user!.sub, {
      diagnosis: body.diagnosis,
      details: body.details,
    });
  }
}
