import { Transform } from 'class-transformer';
import { IsInt, IsOptional, IsString, Max, Min } from 'class-validator';

export class PaginatedQueryDto {
  @IsOptional() @IsString()
  q?: string;

  @IsOptional() @IsInt() @Min(1)
  @Transform(({ value }) => (value ? Number(value) : 1))
  page: number = 1;

  @IsOptional() @IsInt() @Min(1) @Max(100)
  @Transform(({ value }) => (value ? Number(value) : 20))
  pageSize: number = 20;
}
