import { Body, Controller, Post } from '@nestjs/common';
import { UsersService } from './users.service';
import { RegisterUserDto } from './dto/register-user.dto';
import { UserProfileResponseDto } from './dto/user-profile-response.dto';
import { ApiTags, ApiCreatedResponse } from '@nestjs/swagger';

@ApiTags('users')
@Controller('users')
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  @Post('register')
  @ApiCreatedResponse({ type: UserProfileResponseDto })
  async register(@Body() dto: RegisterUserDto): Promise<UserProfileResponseDto> {
    return this.usersService.createUser(dto);
  }
}
