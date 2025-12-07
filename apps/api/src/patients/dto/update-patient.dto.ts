import { Transform } from 'class-transformer';
import { IsArray, IsDate, IsOptional, IsString, MaxLength } from 'class-validator';

export class UpdatePatientDto {
  @IsOptional() @IsString() @MaxLength(80)
  name?: string;

  @IsOptional()
  @Transform(({ value }) => (value ? new Date(value) : undefined))
  @IsDate()
  dob?: Date;

  @IsOptional()
  @IsString()
  bloodGroup?: string;

  @IsOptional() @IsString()
  gender?: string;

  @IsOptional() @IsArray()
  @Transform(({ value }) => (Array.isArray(value) ? value : undefined))
  allergies?: string[];

  @IsOptional() @IsArray()
  @Transform(({ value }) => (Array.isArray(value) ? value : undefined))
  chronicConditions?: string[];
}
