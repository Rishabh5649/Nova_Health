import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

export interface WorkHours {
    weekday: number; // 0=Sunday, 1=Monday, etc.
    startHour: number; // 0-23
    endHour: number; // 0-23
}

@Injectable()
export class DoctorAvailabilityService {
    constructor(private prisma: PrismaService) { }

    async setWorkHours(doctorId: string, workHours: WorkHours[]) {
        // Delete existing availability
        await this.prisma.doctorAvailability.deleteMany({
            where: { doctorId },
        });

        // Create new availability entries
        const entries = workHours.map(wh => ({
            doctorId,
            weekday: wh.weekday,
            startTime: new Date(2000, 0, 1, wh.startHour, 0, 0),
            endTime: new Date(2000, 0, 1, wh.endHour, 0, 0),
        }));

        return this.prisma.doctorAvailability.createMany({
            data: entries,
        });
    }

    async getWorkHours(doctorId: string) {
        const availability = await this.prisma.doctorAvailability.findMany({
            where: { doctorId },
            orderBy: { weekday: 'asc' },
        });

        return availability.map(a => ({
            weekday: a.weekday,
            startHour: a.startTime.getHours(),
            endHour: a.endTime.getHours(),
        }));
    }

    async addTimeOff(doctorId: string, startTime: Date, endTime: Date, reason?: string) {
        return this.prisma.doctorTimeOff.create({
            data: {
                doctorId,
                startTime,
                endTime,
                reason,
            },
        });
    }

    async getTimeOff(doctorId: string, fromDate?: Date, toDate?: Date) {
        return this.prisma.doctorTimeOff.findMany({
            where: {
                doctorId,
                ...(fromDate && {
                    startTime: {
                        gte: fromDate,
                    },
                }),
                ...(toDate && {
                    endTime: {
                        lte: toDate,
                    },
                }),
            },
            orderBy: { startTime: 'asc' },
        });
    }

    async removeTimeOff(timeOffId: string) {
        return this.prisma.doctorTimeOff.delete({
            where: { id: timeOffId },
        });
    }

    /**
     * Check if a doctor is available at a specific date/time
     */
    async isAvailable(doctorId: string, dateTime: Date): Promise<boolean> {
        const weekday = dateTime.getDay();
        const hour = dateTime.getHours();

        // Check work hours
        const workHours = await this.prisma.doctorAvailability.findFirst({
            where: {
                doctorId,
                weekday,
            },
        });

        if (!workHours) return false;

        const startHour = workHours.startTime.getHours();
        const endHour = workHours.endTime.getHours();

        if (hour < startHour || hour >= endHour) return false;

        // Check time off
        const timeOff = await this.prisma.doctorTimeOff.findFirst({
            where: {
                doctorId,
                startTime: {
                    lte: dateTime,
                },
                endTime: {
                    gte: dateTime,
                },
            },
        });

        return !timeOff;
    }
}
