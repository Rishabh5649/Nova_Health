import { Transform } from 'class-transformer';
import { IsISO8601, IsInt, IsOptional, Min } from 'class-validator';

export class QueryFreeSlotsDto {
  @IsISO8601()
  from!: string; // inclusive

  @IsISO8601()
  to!: string;   // exclusive

  @IsOptional()
  @IsInt() @Min(5)
  @Transform(({ value }) => (value ? Number(value) : 30))
  slotMinutes: number = 30;
}
