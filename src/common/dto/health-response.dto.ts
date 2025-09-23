import { ApiProperty } from '@nestjs/swagger';

export class HealthResponseDto {
  @ApiProperty({ example: 'ok', description: 'Aktualny status aplikacji' })
  status: string;

  @ApiProperty({
    example: '2025-09-21T16:10:00.000Z',
    description: 'Znacznik czasu w ISO8601',
  })
  timestamp: string;
}
