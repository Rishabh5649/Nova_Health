import { IsISO8601, IsNotEmpty } from 'class-validator';

export class AcceptAppointmentDto {
  @IsISO8601()
  @IsNotEmpty()
  startTime: string;

  @IsISO8601()
  @IsNotEmpty()
  endTime: string;
}
