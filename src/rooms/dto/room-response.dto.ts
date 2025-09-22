import { ApiProperty } from '@nestjs/swagger';

export class RoomResponseDto {
  @ApiProperty()
  id: string;

  @ApiProperty()
  title: string;

  @ApiProperty()
  body: string;

  @ApiProperty()
  city: string;

  @ApiProperty()
  imgLink: string;

  @ApiProperty()
  createdBy: string;

  @ApiProperty()
  createdAt: string;

  @ApiProperty()
  likes: number;

  @ApiProperty()
  dislikes: number;

  @ApiProperty()
  reserved: boolean;

  @ApiProperty({ required: false })
  startAt?: string;

  @ApiProperty({ required: false })
  endsAt?: string;
}
