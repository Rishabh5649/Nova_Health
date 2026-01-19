import { IsString, IsNotEmpty } from 'class-validator';

export class CreateAppointmentDto {
  @IsString()
  @IsNotEmpty()
  doctorId: string;

  @IsString()
  reason: string;
}
