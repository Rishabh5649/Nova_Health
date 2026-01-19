import {
    BadRequestException,
    ForbiddenException,
    Injectable,
    NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateReviewDto } from './dto/create-review.dto';

@Injectable()
export class ReviewsService {
    constructor(private prisma: PrismaService) { }

    async create(patientId: string, dto: CreateReviewDto) {
        // 1. Verify appointment
        const appointment = await this.prisma.appointment.findUnique({
            where: { id: dto.appointmentId },
            include: { review: true },
        });

        if (!appointment) {
            throw new NotFoundException('Appointment not found');
        }

        if (appointment.patientId !== patientId) {
            throw new ForbiddenException('You can only review your own appointments');
        }

        if (appointment.status !== 'COMPLETED') {
            throw new BadRequestException('You can only review completed appointments');
        }

        if (appointment.review) {
            throw new BadRequestException('You have already reviewed this appointment');
        }

        // 2. Create review
        const review = await this.prisma.review.create({
            data: {
                appointmentId: dto.appointmentId,
                patientId: patientId,
                doctorId: appointment.doctorId,
                rating: dto.rating,
                comment: dto.comment,
                organizationId: appointment.organizationId,
                organizationRating: dto.organizationRating,
                organizationComment: dto.organizationComment,
            },
        });

        // 3. Update doctor stats
        await this.updateDoctorRating(appointment.doctorId);

        // 4. Update organization stats
        if (appointment.organizationId && dto.organizationRating) {
            await this.updateOrganizationRating(appointment.organizationId);
        }

        return review;
    }

    async getDoctorReviews(doctorId: string) {
        return this.prisma.review.findMany({
            where: { doctorId },
            orderBy: { createdAt: 'desc' },
            include: {
                patient: {
                    select: { name: true },
                },
            },
        });
    }

    async getOrganizationReviews(organizationId: string) {
        return this.prisma.review.findMany({
            where: { organizationId, organizationRating: { not: null } },
            orderBy: { createdAt: 'desc' },
            include: {
                patient: {
                    select: { name: true },
                },
            },
        });
    }

    private async updateDoctorRating(doctorId: string) {
        const agg = await this.prisma.review.aggregate({
            where: { doctorId },
            _avg: { rating: true },
            _count: { rating: true },
        });

        await this.prisma.doctor.update({
            where: { userId: doctorId },
            data: {
                ratingAvg: agg._avg.rating || 0,
                ratingCount: agg._count.rating || 0,
            },
        });
    }

    private async updateOrganizationRating(organizationId: string) {
        const agg = await this.prisma.review.aggregate({
            where: { organizationId, organizationRating: { not: null } },
            _avg: { organizationRating: true },
            _count: { organizationRating: true },
        });

        await this.prisma.organization.update({
            where: { id: organizationId },
            data: {
                ratingAvg: agg._avg.organizationRating || 0,
                ratingCount: agg._count.organizationRating || 0,
            },
        });
    }
}
