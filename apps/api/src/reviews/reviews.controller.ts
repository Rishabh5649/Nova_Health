import { Body, Controller, Get, Param, Post, UseGuards } from '@nestjs/common';
import { ReviewsService } from './reviews.service';
import { CreateReviewDto } from './dto/create-review.dto';
import { JwtAuthGuard } from '../auth/jwt.guard';
import { RolesGuard } from '../auth/roles.guard';
import { Roles } from '../auth/roles.decorator';
import { Role } from '@prisma/client';
import { CurrentUser } from '../auth/current-user.decorator';

@Controller('reviews')
export class ReviewsController {
    constructor(private readonly reviewsService: ReviewsService) { }

    @Post()
    @UseGuards(JwtAuthGuard, RolesGuard)
    @Roles(Role.PATIENT)
    create(@CurrentUser() user: { sub: string }, @Body() dto: CreateReviewDto) {
        return this.reviewsService.create(user.sub, dto);
    }

    @Get('doctor/:doctorId')
    getDoctorReviews(@Param('doctorId') doctorId: string) {
        return this.reviewsService.getDoctorReviews(doctorId);
    }

    @Get('organization/:orgId')
    getOrganizationReviews(@Param('orgId') orgId: string) {
        return this.reviewsService.getOrganizationReviews(orgId);
    }
}
