import { IsString, IsOptional, IsArray, ValidateNested } from 'class-validator';
import { Type } from 'class-transformer';
import { MedicationDto } from './medication.dto';

export class CreatePrescriptionDto {
  @IsString()
  appointmentId: string;

  @IsString()
  patientId: string;

  @IsString()
  diagnosis: string;

  @IsOptional()
  @IsString()
  notes?: string;

  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => MedicationDto)
  medications: MedicationDto[];
}
