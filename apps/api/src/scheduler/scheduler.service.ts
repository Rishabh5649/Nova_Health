import { Injectable, Logger } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import { PrismaService } from '../prisma/prisma.service';
import { NotificationsService } from '../notifications/notifications.service';

@Injectable()
export class SchedulerService {
    private readonly logger = new Logger(SchedulerService.name);

    constructor(
        private readonly prisma: PrismaService,
        private readonly notifications: NotificationsService,
    ) { }

    /**
     * Daily Medicine Reminder (at 8:00 AM)
     * Reminds patients with active prescriptions (created in last 7 days) to take meds.
     */
    @Cron(CronExpression.EVERY_DAY_AT_8AM)
    async handleMedicineReminders() {
        this.logger.log('Running Medicine Reminders...');

        // Find prescriptions issued in the last 7 days
        const sevenDaysAgo = new Date();
        sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);

        const activePrescriptions = await this.prisma.prescription.findMany({
            where: {
                createdAt: {
                    gte: sevenDaysAgo,
                },
                status: 'ISSUED',
            },
            select: {
                id: true,
                patientId: true,
                medications: {
                    select: { name: true, frequency: true },
                },
            },
        });

        const notifiedPatients = new Set<String>();

        for (const rx of activePrescriptions) {
            if (notifiedPatients.has(rx.patientId) || rx.medications.length === 0) continue;

            const medNames = rx.medications.map(m => m.name).join(', ');
            await this.notifications.create({
                userId: rx.patientId,
                title: 'Time for your medicines',
                message: `Reminder to take your medications: ${medNames}. Stay healthy!`,
                type: 'MEDICATION_REMINDER',
            });
            notifiedPatients.add(rx.patientId);
        }

        this.logger.log(`Sent medicine reminders to ${notifiedPatients.size} patients.`);
    }

    /**
     * Appointment Reminder (at 8:00 PM the night before)
     * Reminds patients of appointments scheduled for tomorrow.
     */
    @Cron(CronExpression.EVERY_DAY_AT_8PM)
    async handleAppointmentReminders() {
        this.logger.log('Running Appointment Reminders...');

        const tomorrowStart = new Date();
        tomorrowStart.setDate(tomorrowStart.getDate() + 1);
        tomorrowStart.setHours(0, 0, 0, 0);

        const tomorrowEnd = new Date(tomorrowStart);
        tomorrowEnd.setHours(23, 59, 59, 999);

        const appointments = await this.prisma.appointment.findMany({
            where: {
                scheduledAt: {
                    gte: tomorrowStart,
                    lte: tomorrowEnd,
                },
                status: 'CONFIRMED',
            },
            include: {
                doctor: {
                    include: { doctorProfile: true },
                },
            },
        });

        for (const appt of appointments) {
            const timeString = appt.scheduledAt.toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit' });
            await this.notifications.create({
                userId: appt.patientId,
                title: 'Upcoming Appointment',
                message: `You have an appointment with Dr. ${appt.doctor.doctorProfile?.name ?? 'Unknown'} tomorrow at ${timeString}.`,
                type: 'APPOINTMENT_REMINDER',
            });
        }

        this.logger.log(`Sent appointment reminders for ${appointments.length} appointments.`);
    }

    /**
     * Custom Medicine Reminders (Every Minute)
     * Checks for active patient reminders scheduled for the current time.
     */
    @Cron(CronExpression.EVERY_MINUTE)
    async handleCustomReminders() {
        // Get current time in HH:mm format
        const now = new Date();
        const hours = now.getHours().toString().padStart(2, '0');
        const minutes = now.getMinutes().toString().padStart(2, '0');
        const currentTime = `${hours}:${minutes}`;

        // Find active reminders within valid date range
        const activeReminders = await this.prisma.patientReminder.findMany({
            where: {
                isEnabled: true,
                startDate: {
                    lte: now,
                },
                endDate: {
                    gte: now,
                },
            },
        });

        // Filter for remunerations matching the current time slot
        const remindersToNotify = activeReminders.filter(reminder =>
            reminder.timeSlots.includes(currentTime)
        );

        if (remindersToNotify.length === 0) return;

        this.logger.log(`Found ${remindersToNotify.length} custom reminders for ${currentTime}`);

        for (const reminder of remindersToNotify) {
            await this.notifications.create({
                userId: reminder.patientId,
                title: `Medicine Reminder: ${reminder.medicineName}`,
                message: `It's time to take your medicine: ${reminder.medicineName}.`,
                type: 'CUSTOM_REMINDER',
            });
        }
    }

    /**
     * Follow-up Reminder (at 10:00 AM)
     * Reminds patients to book a follow-up if their last appointment was 5 days ago (assuming 7-day window).
     */
    @Cron(CronExpression.EVERY_DAY_AT_10AM)
    async handleFollowUpReminders() {
        this.logger.log('Running Follow-up Reminders...');

        const fiveDaysAgoStart = new Date();
        fiveDaysAgoStart.setDate(fiveDaysAgoStart.getDate() - 5);
        fiveDaysAgoStart.setHours(0, 0, 0, 0);

        const fiveDaysAgoEnd = new Date(fiveDaysAgoStart);
        fiveDaysAgoEnd.setHours(23, 59, 59, 999);

        // Find completed appointments from 5 days ago
        const completedAppts = await this.prisma.appointment.findMany({
            where: {
                status: 'COMPLETED',
                // Assuming updatedAt is close to completion time
                updatedAt: {
                    gte: fiveDaysAgoStart,
                    lte: fiveDaysAgoEnd,
                },
            },
            include: {
                doctor: {
                    include: { doctorProfile: true },
                }
            }
        });

        for (const appt of completedAppts) {
            // Check if follow-up days > 5 (default 7 usually)
            const followUpDays = appt.doctor.doctorProfile?.followUpDays ?? 7;
            if (followUpDays > 5) {
                await this.notifications.create({
                    userId: appt.patientId,
                    title: 'Free Follow-up Available',
                    message: `Your follow-up period with Dr. ${appt.doctor.doctorProfile?.name} is active for a few more days. Book now if you need to!`,
                    type: 'FOLLOW_UP_REMINDER',
                });
            }
        }
    }
}
