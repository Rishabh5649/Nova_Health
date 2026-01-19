import { IsString, IsNotEmpty, IsOptional, IsEmail, IsPhoneNumber } from 'class-validator';

export class CreateOrganizationDto {
    @IsString()
    @IsNotEmpty()
    name: string;

    @IsString()
    @IsNotEmpty()
    type: string; // Clinic, Hospital

    @IsString()
    @IsOptional()
    address?: string;

    @IsEmail()
    @IsOptional()
    contactEmail?: string;

    @IsPhoneNumber()
    @IsOptional()
    contactPhone?: string;

    @IsString()
    @IsOptional()
    feeControlMode?: string;

    @IsOptional()
    yearEstablished?: number;

    @IsOptional()
    latitude?: number;

    @IsOptional()
    longitude?: number;

    @IsOptional()
    branches?: string[];

    @IsOptional()
    adminUser?: {
        name: string;
        email: string;
        password: string;
        phone?: string;
    };
}
