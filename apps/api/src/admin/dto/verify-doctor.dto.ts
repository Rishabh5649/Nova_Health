import { IsIn, IsOptional, IsString, MaxLength } from 'class-validator';

export class VerifyDoctorDto {
  @IsIn(['APPROVED', 'REJECTED'])
  status!: 'APPROVED' | 'REJECTED';

  @IsOptional() @IsString() @MaxLength(200)
  note?: string;
}
