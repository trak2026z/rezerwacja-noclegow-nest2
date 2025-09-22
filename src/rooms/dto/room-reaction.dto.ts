import { ApiProperty } from '@nestjs/swagger';

export class RoomReactionResponseDto {
  @ApiProperty()
  id: string;

  @ApiProperty()
  likes: number;

  @ApiProperty()
  dislikes: number;
}
