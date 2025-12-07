import {
  IsArray,
  IsOptional,
  IsString,
  IsInt,
  Min,
  MaxLength,
  IsTimeZone,
} from 'class-validator';
import { Type } from 'class-transformer';

export class UpdateDoctorDto {
  @IsOptional()
  @IsString()
  @MaxLength(80)
  name?: string; // <-- lives on User table typically

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  age?: number;

  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  qualifications?: string[];

  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  specialties?: string[]; // array per your design

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(0)
  yearsExperience?: number;

  @IsOptional()
  @IsString()
  @MaxLength(500)
  bio?: string;

  @IsOptional()
  @IsString()
  @IsTimeZone()
  timezone?: string;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(0)
  baseFee?: number;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(0)
  followUpDays?: number;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(0)
  followUpFee?: number;
}
