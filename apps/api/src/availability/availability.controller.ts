import { Body, Controller, Get, Param, Post, Query, UseGuards } from '@nestjs/common';
import { AvailabilityService } from './availability.service';
import { JwtAuthGuard } from '../auth/jwt.guard';
import { Roles } from '../auth/roles.decorator';
import { RolesGuard } from '../auth/roles.guard';
import { CurrentUser } from '../auth/current-user.decorator';
import type { JwtUser } from '../auth/current-user.decorator';
import { UpsertAvailabilityDto } from './dto/upsert-availability.dto';
import { AddTimeOffDto } from './dto/add-timeoff.dto';
import { QueryFreeSlotsDto } from './dto/query-free-slots.dto';

@Controller()
export class AvailabilityController {
  constructor(private readonly svc: AvailabilityService) {}

  // Doctor sets weekly windows (replace all)
  @Post('doctors/me/availability')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('DOCTOR')
  upsertWeekly(@CurrentUser() user: JwtUser, @Body() dto: UpsertAvailabilityDto) {
    return this.svc.upsertWeekly(user!.sub, dto.windows);
  }

  // Doctor adds time off
  @Post('doctors/me/timeoff')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('DOCTOR')
  addTimeOff(@CurrentUser() user: JwtUser, @Body() dto: AddTimeOffDto) {
    return this.svc.addTimeOff(user!.sub, new Date(dto.startTime), new Date(dto.endTime), dto.reason);
  }

  // Public: free slots for a doctor in a range
  @Get('doctors/:doctorId/free-slots')
  free(@Param('doctorId') doctorId: string, @Query() q: QueryFreeSlotsDto) {
    return this.svc.freeSlots(doctorId, new Date(q.from), new Date(q.to), q.slotMinutes);
  }
}
