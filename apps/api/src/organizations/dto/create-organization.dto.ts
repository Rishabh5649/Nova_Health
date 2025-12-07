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
}
