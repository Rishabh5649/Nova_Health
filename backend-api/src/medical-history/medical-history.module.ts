import { Module } from '@nestjs/common';
import { MedicalHistoryService } from './medical-history.service';
import { MedicalHistoryController } from './medical-history.controller';
import { PrismaService } from '../prisma/prisma.service';

@Module({
  controllers: [MedicalHistoryController],
  providers: [MedicalHistoryService, PrismaService],
  exports: [MedicalHistoryService],
})
export class MedicalHistoryModule {}
