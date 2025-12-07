import {
  Controller,
  Post,
  Get,
  Param,
  Body,
  UseGuards,
} from '@nestjs/common';
import { MedicalHistoryService } from './medical-history.service';
import { CreateMedicalHistoryDto } from './dto/create-medical-history.dto';
import { JwtAuthGuard } from '../auth/jwt.guard';
import { RolesGuard } from '../auth/roles.guard';
import { Roles } from '../auth/roles.decorator';
import { CurrentUser } from '../auth/current-user.decorator';
import { Role } from '@prisma/client';

@UseGuards(JwtAuthGuard, RolesGuard)
@Controller('medical-history')
export class MedicalHistoryController {
  constructor(private readonly mhService: MedicalHistoryService) {}

  /**
   * POST http://localhost:3000/medical-history
   * Only doctor/admin can create a history entry for a patient.
   */
  @Post()
  @Roles(Role.DOCTOR, Role.ADMIN)
  createEntry(
    @CurrentUser() user: { sub: string; role: Role },
    @Body() dto: CreateMedicalHistoryDto,
  ) {
    // Service expects { id, role }
    return this.mhService.createEntry(
      { id: user.sub, role: user.role },
      dto,
    );
  }

  /**
   * GET http://localhost:3000/medical-history/me
   * PATIENT sees their own history timeline.
   */
  @Get('me')
  @Roles(Role.PATIENT)
  getMyHistory(@CurrentUser() user: { sub: string; role: Role }) {
    // Use JWT's sub as the patient userId
    return this.mhService.getMyHistory(user.sub);
  }

  /**
   * GET http://localhost:3000/medical-history/patient/:patientId
   * Doctor/Admin can view any patient's full timeline.
   */
  @Get('patient/:patientId')
  @Roles(Role.DOCTOR, Role.ADMIN)
  getPatientHistory(
    @CurrentUser() user: { sub: string; role: Role },
    @Param('patientId') patientId: string,
  ) {
    // Service expects { id, role }
    return this.mhService.getPatientHistory(
      { id: user.sub, role: user.role },
      patientId,
    );
  }

  /**
   * GET http://localhost:3000/medical-history/entry/:id
   * View a single history entry (that patient, any doctor, or admin).
   */
  @Get('entry/:id')
  getEntryById(
    @CurrentUser() user: { sub: string; role: Role },
    @Param('id') entryId: string,
  ) {
    // Service expects { id, role }
    return this.mhService.getHistoryEntryById(
      { id: user.sub, role: user.role },
      entryId,
    );
  }
}
