import { IsOptional, IsString, IsInt, Min } from 'class-validator';
import { Type } from 'class-transformer';

export class QueryDoctorsDto {
  /** Free text search across name / specialties / qualifications */
  @IsOptional()
  @IsString()
  q?: string;

  /** Filter by one specialty (matches entries inside specialties[]) */
  @IsOptional()
  @IsString()
  specialty?: string;

  /** 1-based page number */
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  page: number = 1;

  /** page size */
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  pageSize: number = 10;
}
