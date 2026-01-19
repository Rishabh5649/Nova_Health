import { Injectable, ForbiddenException, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { isSameWeek } from 'date-fns';

@Injectable()
export class CancellationService {
    constructor(private prisma: PrismaService) { }

    /** Patient cancels appointment (no refund) */
    async cancelAsPatient(appointmentId: string, patientId: string, reason: string) {
        const appointment = await this.prisma.appointment.findUnique({
            where: { id: appointmentId },
            include: { patient: true },
        });
        if (!appointment) {
            throw new NotFoundException('Appointment not found');
        }
        if (appointment.patientId !== patientId) {
            throw new ForbiddenException('You can only cancel your own appointments');
        }
        // Update status
        await this.prisma.appointment.update({
            where: { id: appointmentId },
            data: { status: 'CANCELLED' },
        });
        // Record cancellation
        await this.prisma.appointmentCancellation.create({
            data: {
                appointmentId,
                cancelledById: patientId,
                reason,
                refundStatus: 'non_refundable',
                refundAmount: 0,
            },
        });
        return { message: 'Appointment cancelled (no refund)' };
    }

    /** Admin or receptionist cancels appointment (refund) */
    async cancelAsAdmin(appointmentId: string, adminId: string, reason: string) {
        if (!reason || reason.trim().length < 10) {
            throw new ForbiddenException('Cancellation reason must be at least 10 characters');
        }
        const appointment = await this.prisma.appointment.findUnique({
            where: { id: appointmentId },
            include: { patient: true },
        });
        if (!appointment) {
            throw new NotFoundException('Appointment not found');
        }
        // For simplicity, assume full fee refund (could be derived from appointment data)
        const refundAmount = appointment.chargedFee || 0;
        await this.prisma.appointment.update({
            where: { id: appointmentId },
            data: { status: 'CANCELLED' },
        });
        await this.prisma.appointmentCancellation.create({
            data: {
                appointmentId,
                cancelledById: adminId,
                reason,
                refundStatus: 'refunded',
                refundAmount,
            },
        });
        // TODO: integrate payment gateway for actual refund
        return { message: 'Appointment cancelled and refund processed', refundAmount };
    }

    /** Doctor attempts to cancel – forbidden */
    async cancelAsDoctor() {
        throw new ForbiddenException('Doctors cannot cancel appointments. Use reschedule instead.');
    }
}
