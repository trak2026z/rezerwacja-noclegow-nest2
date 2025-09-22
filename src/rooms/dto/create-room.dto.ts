import { ApiProperty } from '@nestjs/swagger';
import { IsNotEmpty, IsString, Length, IsDateString, IsOptional } from 'class-validator';

export class CreateRoomDto {
  @ApiProperty({ example: 'Pokój z widokiem na morze' })
  @IsString()
  @Length(5, 50)
  title: string;

  @ApiProperty({ example: 'Nowoczesny pokój w centrum Gdańska, blisko plaży.' })
  @IsString()
  @Length(5, 500)
  body: string;

  @ApiProperty({ example: 'Gdańsk' })
  @IsString()
  @IsNotEmpty()
  city: string;

  @ApiProperty({ example: 'https://picsum.photos/800/600', required: false })
  @IsOptional()
  @IsString()
  imgLink?: string;

  @ApiProperty({ example: '2025-09-25T12:00:00Z', required: false, description: 'Data rozpoczęcia w ISO 8601' })
  @IsOptional()
  @IsDateString()
  startAt?: string;

  @ApiProperty({ example: '2025-09-28T10:00:00Z', required: false, description: 'Data zakończenia w ISO 8601' })
  @IsOptional()
  @IsDateString()
  endsAt?: string;
}
