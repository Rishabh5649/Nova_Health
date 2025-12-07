import { IsArray, IsInt, Max, Min, ValidateNested } from 'class-validator';
import { Type } from 'class-transformer';

class DayWindow {
  @IsInt() @Min(0) @Max(6)
  weekday!: number; // 0..6

  @IsInt() @Min(0) @Max(1440)
  startMin!: number;

  @IsInt() @Min(0) @Max(1440)
  endMin!: number;
}

export class UpsertAvailabilityDto {
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => DayWindow)
  windows!: DayWindow[];
}
