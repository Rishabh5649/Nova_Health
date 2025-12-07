import { IsString, IsUUID, IsOptional } from 'class-validator';

export class CreateMedicalHistoryDto {
  @IsUUID()
  patientId: string; // which patient this note is about

  @IsString()
  diagnosis: string; // e.g. "Type 2 Diabetes - uncontrolled"

  @IsOptional()
  @IsString()
  details?: string; // notes, plan, follow-up
}
