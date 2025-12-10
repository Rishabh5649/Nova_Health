import { IsArray, IsInt, IsNotEmpty, IsString, Matches, Min } from 'class-validator';

export class CreateReminderDto {
    @IsNotEmpty()
    @IsString()
    medicineName: string;

    @IsInt()
    @Min(1)
    frequency: number;

    @IsArray()
    @IsString({ each: true })
    @Matches(/^([0-1]?[0-9]|2[0-3]):[0-5][0-9]$/, { each: true, message: 'Time must be in HH:mm format' })
    timeSlots: string[];

    @IsInt()
    @Min(1)
    duration: number;
}
