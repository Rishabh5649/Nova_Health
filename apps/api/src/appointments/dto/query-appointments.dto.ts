import { Transform } from 'class-transformer';
import { IsISO8601, IsOptional, IsString, IsInt, Min, Max, Length } from 'class-validator';

export class QueryAppointmentsDto {
  @IsOptional() @IsString() @Length(10, 50)
  doctorId?: string;

  @IsOptional() @IsString() @Length(10, 50)
  patientId?: string;

  @IsOptional() @IsISO8601()
  from?: string;

  @IsOptional() @IsISO8601()
  to?: string;

  @IsOptional() @Transform(({ value }) => parseInt(value, 10))
  @IsInt() @Min(1) @Max(100)
  pageSize: number = 10;

  @IsOptional() @Transform(({ value }) => parseInt(value, 10))
  @IsInt() @Min(1)
  page: number = 1;
}
