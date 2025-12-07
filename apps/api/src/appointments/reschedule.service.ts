import { Injectable, NotFoundException, ForbiddenException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class RescheduleService {
    constructor(private prisma: PrismaService) { }

    /**
     * Patient or Doctor requests to reschedule an appointment
     */
    async requestReschedule(
        appointmentId: string,
        requestedById: string,
        requestedDateTime: Date,
        reason?: string
    ) {
        // Verify appointment exists
        const appointment = await this.prisma.appointment.findUnique({
            where: { id: appointmentId },
            include: { patient: true, doctor: true }
        });

        if (!appointment) {
            throw new NotFoundException('Appointment not found');
        }

        // Verify requester is either patient or doctor
        if (appointment.patientId !== requestedById && appointment.doctorId !== requestedById) {
            throw new ForbiddenException('You can only request reschedule for your own appointments');
        }

        // Create reschedule request
        return this.prisma.rescheduleRequest.create({
            data: {
                appointmentId,
                requestedById,
                requestedDateTime,
                reason,
                status: 'PENDING'
            },
            include: {
                appointment: {
                    include: {
                        patient: { select: { id: true, name: true, email: true } },
                        doctor: { select: { id: true, name: true } }
                    }
                },
                requestedBy: { select: { id: true, name: true, email: true } }
            }
        });
    }

    /**
     * Get all reschedule requests (optionally filtered by appointment or status)
     */
    async getRescheduleRequests(
        appointmentId?: string,
        status?: 'PENDING' | 'APPROVED' | 'REJECTED',
        organizationId?: string
    ) {
        return this.prisma.rescheduleRequest.findMany({
            where: {
                ...(appointmentId && { appointmentId }),
                ...(status && { status }),
                ...(organizationId && {
                    appointment: { organizationId }
                })
            },
            include: {
                appointment: {
                    include: {
                        patient: { select: { id: true, name: true, email: true } },
                        doctor: { select: { id: true, name: true } }
                    }
                },
                requestedBy: { select: { id: true, name: true, email: true, role: true } }
            },
            orderBy: { createdAt: 'desc' }
        });
    }

    /**
     * Get a single reschedule request
     */
    async getRescheduleRequest(id: string) {
        const request = await this.prisma.rescheduleRequest.findUnique({
            where: { id },
            include: {
                appointment: {
                    include: {
                        patient: { select: { id: true, name: true, email: true } },
                        doctor: { select: { id: true, name: true } }
                    }
                },
                requestedBy: { select: { id: true, name: true, email: true, role: true } }
            }
        });

        if (!request) {
            throw new NotFoundException('Reschedule request not found');
        }

        return request;
    }

    /**
     * Admin approves a reschedule request and updates the appointment
     */
    async approveReschedule(requestId: string) {
        const request = await this.getRescheduleRequest(requestId);

        if (request.status !== 'PENDING') {
            throw new ForbiddenException('This request has already been processed');
        }

        // Update the appointment's scheduled time
        await this.prisma.appointment.update({
            where: { id: request.appointmentId },
            data: { scheduledAt: request.requestedDateTime }
        });

        // Mark request as approved
        return this.prisma.rescheduleRequest.update({
            where: { id: requestId },
            data: { status: 'APPROVED', updatedAt: new Date() }
        });
    }

    /**
     * Admin rejects a reschedule request
     */
    async rejectReschedule(requestId: string) {
        const request = await this.getRescheduleRequest(requestId);

        if (request.status !== 'PENDING') {
            throw new ForbiddenException('This request has already been processed');
        }

        return this.prisma.rescheduleRequest.update({
            where: { id: requestId },
            data: { status: 'REJECTED', updatedAt: new Date() }
        });
    }

    /**
     * Admin directly reschedules an appointment (bypassing request flow)
     */
    async directReschedule(appointmentId: string, newDateTime: Date) {
        const appointment = await this.prisma.appointment.findUnique({
            where: { id: appointmentId }
        });

        if (!appointment) {
            throw new NotFoundException('Appointment not found');
        }

        return this.prisma.appointment.update({
            where: { id: appointmentId },
            data: { scheduledAt: newDateTime }
        });
    }

    /**
     * Delete a reschedule request (before it's processed)
     */
    async cancelRescheduleRequest(requestId: string, userId: string) {
        const request = await this.getRescheduleRequest(requestId);

        // Only the requester can cancel their own request
        if (request.requestedById !== userId) {
            throw new ForbiddenException('You can only cancel your own reschedule requests');
        }

        if (request.status !== 'PENDING') {
            throw new ForbiddenException('Cannot cancel a processed request');
        }

        return this.prisma.rescheduleRequest.delete({
            where: { id: requestId }
        });
    }
}
