import { IsEnum, IsNotEmpty, IsOptional, IsString } from 'class-validator';
import { OrgRole } from '@prisma/client';

export class InviteStaffDto {
    @IsNotEmpty()
    @IsString()
    email: string;

    @IsNotEmpty()
    @IsString()
    name: string;

    @IsEnum(OrgRole)
    role: OrgRole;

    @IsOptional()
    @IsString()
    phone?: string;
}

export class ApproveStaffDto {
    @IsEnum(['APPROVED', 'REJECTED'])
    status: 'APPROVED' | 'REJECTED';
}

export class UpdateOrganizationSettingsDto {
    @IsOptional()
    enableReceptionists?: boolean;

    @IsOptional()
    allowPatientBooking?: boolean;

    @IsOptional()
    requireApprovalForDoctors?: boolean;

    @IsOptional()
    requireApprovalForReceptionists?: boolean;

    @IsOptional()
    autoApproveFollowUps?: boolean;
}
