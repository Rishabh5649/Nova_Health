import { IsInt, IsNotEmpty, IsOptional, IsString, Max, Min } from 'class-validator';

export class CreateReviewDto {
    @IsNotEmpty()
    @IsString()
    appointmentId: string;

    @IsNotEmpty()
    @IsInt()
    @Min(1)
    @Max(5)
    rating: number;

    @IsOptional()
    @IsString()
    comment?: string;

    @IsOptional()
    @IsInt()
    @Min(1)
    @Max(5)
    organizationRating?: number;

    @IsOptional()
    @IsString()
    organizationComment?: string;
}
