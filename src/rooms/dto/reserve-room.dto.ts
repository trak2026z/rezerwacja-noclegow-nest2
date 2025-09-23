import { ApiProperty } from '@nestjs/swagger';
import { IsDateString, IsNotEmpty } from 'class-validator';

export class ReserveRoomDto {
  @ApiProperty({
    example: '2025-10-01T12:00:00Z',
    description: 'Data rozpoczęcia rezerwacji w ISO 8601',
  })
  @IsNotEmpty()
  @IsDateString()
  startAt: string;

  @ApiProperty({
    example: '2025-10-05T10:00:00Z',
    description: 'Data zakończenia rezerwacji w ISO 8601',
  })
  @IsNotEmpty()
  @IsDateString()
  endsAt: string;
}
