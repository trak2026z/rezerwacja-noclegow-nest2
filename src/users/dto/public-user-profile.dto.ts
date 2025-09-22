import { ApiProperty } from '@nestjs/swagger';

export class PublicUserProfileDto {
  @ApiProperty()
  username: string;

  @ApiProperty()
  createdAt: string;
}
