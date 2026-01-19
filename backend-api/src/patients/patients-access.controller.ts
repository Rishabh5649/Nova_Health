import { Controller, Get, Param, UseGuards } from '@nestjs/common';
import { PatientsService } from './patients.service';
import { JwtAuthGuard } from '../auth/jwt.guard';
import { RolesGuard } from '../auth/roles.guard';
import { Roles } from '../auth/roles.decorator';
import { Role } from '@prisma/client';

@Controller('patients')
@UseGuards(JwtAuthGuard, RolesGuard)
export class PatientsAccessController {
    constructor(private readonly svc: PatientsService) { }

    @Get(':id/records')
    @Roles(Role.DOCTOR, Role.ADMIN)
    getPatientRecords(@Param('id') id: string) {
        return this.svc.listMyRecords(id);
    }

    @Get(':id')
    @Roles(Role.DOCTOR, Role.ADMIN)
    getPatientProfile(@Param('id') id: string) {
        return this.svc.getMe(id);
    }

    @Get(':id/summary')
    @Roles(Role.DOCTOR, Role.ADMIN)
    getPatientSummary(@Param('id') id: string) {
        return this.svc.getSummary(id);
    }
}
