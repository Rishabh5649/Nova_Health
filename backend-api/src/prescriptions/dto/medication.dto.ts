import { IsString, IsOptional } from 'class-validator';

export class MedicationDto {
    @IsString()
    name: string;

    @IsString()
    dosage: string;

    @IsString()
    frequency: string;

    @IsString()
    duration: string;

    @IsOptional()
    @IsString()
    instruction?: string;
}
