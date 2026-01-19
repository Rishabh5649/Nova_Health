import { IsISO8601, IsOptional, IsString, Length } from 'class-validator';

export class RescheduleAppointmentDto {
  @IsISO8601() startTime!: string;
  @IsISO8601() endTime!: string;

  @IsOptional() @IsString() @Length(0, 300)
  reason?: string;
}
