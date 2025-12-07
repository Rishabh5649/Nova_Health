import { Module } from '@nestjs/common';
import { DoctorsController } from './doctors.controller';
import { DoctorsService } from './doctors.service';
import { DoctorAvailabilityService } from './doctor-availability.service';
import { PrismaModule } from '../prisma/prisma.module';

@Module({
  imports: [PrismaModule],
  controllers: [DoctorsController],
  providers: [DoctorsService, DoctorAvailabilityService],
  exports: [DoctorsService, DoctorAvailabilityService],
})
export class DoctorsModule { }
