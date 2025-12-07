import {
  Controller,
  Get,
  Patch,
  Post,
  Delete,
  Param,
  Query,
  Body,
  UseGuards,
} from '@nestjs/common';
import { DoctorsService } from './doctors.service';
import { DoctorAvailabilityService } from './doctor-availability.service';
import { QueryDoctorsDto } from './dto/query-doctors.dto';
import { JwtAuthGuard } from '../auth/jwt.guard';
import { Roles } from '../auth/roles.decorator';
import { RolesGuard } from '../auth/roles.guard';
import { CurrentUser } from '../auth/current-user.decorator';
import type { JwtUser } from '../auth/current-user.decorator';
import { UpdateDoctorDto } from './dto/update-doctor.dto';

@Controller('doctors')
export class DoctorsController {
  constructor(
    private readonly svc: DoctorsService,
    private readonly availabilityService: DoctorAvailabilityService
  ) { }

  /**
   * GET /doctors/ping
   * Simple health check/debug
   */
  @Get('ping')
  ping() {
    return { ok: true };
  }

  /**
   * GET /doctors
   * Public search / listing of doctors (no auth required)
   * Supports filtering/pagination via QueryDoctorsDto
   */
  @Get()
  list(@Query() q: QueryDoctorsDto) {
    return this.svc.list(q);
  }

  /**
   * GET /doctors/:userId
   * Public doctor profile (lookup by userId)
   * This lets a patient view a doctor's profile before booking.
   */
  @Get(':userId')
  getOne(@Param('userId') userId: string) {
    return this.svc.getProfile(userId);
  }

  /**
   * PATCH /doctors/me
   * Doctor updates their own profile.
   * Protected: must be logged in and role DOCTOR.
   */
  @Patch('me')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('DOCTOR')
  updateMe(
    @CurrentUser() user: JwtUser,
    @Body() dto: UpdateDoctorDto,
  ) {
    // Your JWT payload uses `sub` as the user id
    return this.svc.updateSelf(user!.sub, dto);
  }

  /**
   * GET /doctors/me/patients
   * List patients treated by the logged-in doctor.
   */
  @Get('me/patients')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('DOCTOR')
  getMyPatients(@CurrentUser() user: JwtUser) {
    return this.svc.getMyPatients(user!.sub);
  }

  /**
   * PATCH /doctors/:userId
   * Admin updates a doctor's profile (including fees).
   */
  @Patch(':userId')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('ADMIN')
  updateDoctor(
    @Param('userId') userId: string,
    @Body() dto: UpdateDoctorDto,
  ) {
    return this.svc.updateDoctor(userId, dto);
  }

  /**
   * GET /doctors/:userId/availability
   * Get doctor's work hours
   */
  @Get(':userId/availability')
  getAvailability(@Param('userId') userId: string) {
    return this.availabilityService.getWorkHours(userId);
  }

  /**
   * POST /doctors/:userId/availability
   * Set doctor's work hours (doctor or admin only)
   */
  @Post(':userId/availability')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('DOCTOR', 'ADMIN')
  setAvailability(
    @Param('userId') userId: string,
    @Body() body: { workHours: any[] },
    @CurrentUser() user: JwtUser,
  ) {
    // Verify doctor is updating their own profile or is admin
    if (user.role !== 'ADMIN' && user.sub !== userId) {
      throw new Error('Unauthorized');
    }
    return this.availabilityService.setWorkHours(userId, body.workHours);
  }

  /**
   * GET /doctors/:userId/timeoff
   * Get doctor's time off
   */
  @Get(':userId/timeoff')
  getTimeOff(
    @Param('userId') userId: string,
    @Query('from') from?: string,
    @Query('to') to?: string,
  ) {
    const fromDate = from ? new Date(from) : undefined;
    const toDate = to ? new Date(to) : undefined;
    return this.availabilityService.getTimeOff(userId, fromDate, toDate);
  }

  /**
   * POST /doctors/:userId/timeoff
   * Add time off (doctor or admin only)
   */
  @Post(':userId/timeoff')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('DOCTOR', 'ADMIN')
  addTimeOff(
    @Param('userId') userId: string,
    @Body() body: { startTime: string; endTime: string; reason?: string },
    @CurrentUser() user: JwtUser,
  ) {
    if (user.role !== 'ADMIN' && user.sub !== userId) {
      throw new Error('Unauthorized');
    }
    return this.availabilityService.addTimeOff(
      userId,
      new Date(body.startTime),
      new Date(body.endTime),
      body.reason,
    );
  }

  /**
   * DELETE /doctors/timeoff/:id
   * Remove time off
   */
  @Delete('timeoff/:id')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('DOCTOR', 'ADMIN')
  removeTimeOff(@Param('id') id: string) {
    return this.availabilityService.removeTimeOff(id);
  }
}
