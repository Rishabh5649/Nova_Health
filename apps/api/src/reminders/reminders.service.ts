import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateReminderDto } from './dto/create-reminder.dto';
import { UpdateReminderDto } from './dto/update-reminder.dto';

@Injectable()
export class RemindersService {
  constructor(private prisma: PrismaService) { }

  create(userId: string, dto: CreateReminderDto) {
    const startDate = new Date();
    const endDate = new Date();
    endDate.setDate(endDate.getDate() + dto.duration);

    return this.prisma.patientReminder.create({
      data: {
        patientId: userId,
        medicineName: dto.medicineName,
        frequency: dto.frequency,
        timeSlots: dto.timeSlots,
        duration: dto.duration,
        startDate: startDate,
        endDate: endDate,
      }
    });
  }

  findMyReminders(userId: string) {
    return this.prisma.patientReminder.findMany({
      where: { patientId: userId },
      orderBy: { createdAt: 'desc' }
    });
  }

  // Toggles or updates reminder
  update(id: string, userId: string, dto: UpdateReminderDto) {
    // If update involves duration/start, we might need recalc, but for now allow simple updates.
    // If user updates duration, we should ideally recalc endDate, but UpdateDto is Partial.
    // For simplicity, we assume simple toggles or straightforward updates.
    return this.prisma.patientReminder.updateMany({
      where: { id, patientId: userId },
      data: dto
    });
  }

  remove(id: string, userId: string) {
    return this.prisma.patientReminder.deleteMany({
      where: { id, patientId: userId }
    });
  }
}
