import { ApiProperty, PartialType } from '@nestjs/swagger';
import { CreateRoomDto } from './create-room.dto';
import { IsDateString, IsOptional } from 'class-validator';

export class UpdateRoomDto extends CreateRoomDto {}

export class PatchRoomDto extends PartialType(CreateRoomDto) {
  @ApiProperty({ example: '2025-09-25T12:00:00Z', required: false })
  @IsOptional()
  @IsDateString()
  startAt?: string;

  @ApiProperty({ example: '2025-09-28T10:00:00Z', required: false })
  @IsOptional()
  @IsDateString()
  endsAt?: string;
}
