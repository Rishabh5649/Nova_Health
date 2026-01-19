import { Module } from '@nestjs/common';
import { AppointmentsController } from './appointments.controller';
import { AppointmentsService } from './appointments.service';
import { RescheduleService } from './reschedule.service';
import { CancellationService } from './cancellation.service';
import { PrismaModule } from '../prisma/prisma.module';

@Module({
  imports: [PrismaModule],
  controllers: [AppointmentsController],
  providers: [AppointmentsService, RescheduleService, CancellationService],
  exports: [AppointmentsService, RescheduleService, CancellationService],
})
export class AppointmentsModule { }
