import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateNotificationDto } from './dto/create-notification.dto';

@Injectable()
export class NotificationsService {
  private readonly logger = new Logger(NotificationsService.name);

  constructor(private prisma: PrismaService) { }

  async create(dto: CreateNotificationDto) {
    // 1. Save to DB
    const notif = await this.prisma.notification.create({
      data: {
        userId: dto.userId,
        title: dto.title,
        message: dto.message,
        type: dto.type,
      },
    });

    // 2. Mock Real-time / SMS / Email sending
    this.sendRealTimeUpdate(dto);

    return notif;
  }

  async findAll(userId: string) {
    return this.prisma.notification.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
    });
  }

  async markAsRead(id: string) {
    return this.prisma.notification.update({
      where: { id },
      data: { read: true },
    });
  }

  // Helper to simulate external comms
  private sendRealTimeUpdate(dto: CreateNotificationDto) {
    // In a real app, this would use Twilio / SendGrid / Socket.io
    this.logger.log(`[SMS] Sending to User ${dto.userId}: ${dto.title} - ${dto.message}`);
    this.logger.log(`[EMAIL] Sending to User ${dto.userId}: ${dto.title} - ${dto.message}`);
    this.logger.log(`[PUSH] Sending real-time push to User ${dto.userId}`);
  }
}
