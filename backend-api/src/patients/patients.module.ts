import { Module } from '@nestjs/common';
import { PatientsController } from './patients.controller';
import { PatientsService } from './patients.service';
import { PrismaModule } from '../prisma/prisma.module';

import { PatientsAccessController } from './patients-access.controller';

@Module({
  imports: [PrismaModule],
  controllers: [PatientsController, PatientsAccessController],
  providers: [PatientsService],
  exports: [PatientsService],
})
export class PatientsModule { }
