import { Body, Controller, Post, Get, UseGuards, Req } from '@nestjs/common';
import { UsersService } from './users.service';
import { RegisterUserDto } from './dto/register-user.dto';
import { UserProfileResponseDto } from './dto/user-profile-response.dto';
import { ApiTags, ApiCreatedResponse, ApiBearerAuth, ApiOkResponse } from '@nestjs/swagger';

import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import type { RequestWithUser } from '../common/interfaces/request-with-user.interface';

@ApiTags('users')
@Controller('users')
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  @Post('register')
  @ApiCreatedResponse({ type: UserProfileResponseDto })
  async register(
    @Body() dto: RegisterUserDto,
  ): Promise<UserProfileResponseDto> {
    return this.usersService.createUser(dto);
  }

  @Get('profile')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOkResponse({ type: UserProfileResponseDto })
  async getProfile(@Req() req: RequestWithUser): Promise<UserProfileResponseDto> {
    return this.usersService.getUserProfile(req.user.userId);
  }

}
