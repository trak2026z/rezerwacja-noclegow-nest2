import { Body, Controller, Get, Param, Post, UseGuards, Req } from '@nestjs/common';
import { RoomsService } from './rooms.service';
import { CreateRoomDto } from './dto/create-room.dto';
import { RoomResponseDto } from './dto/room-response.dto';
import { ApiTags, ApiCreatedResponse, ApiOkResponse, ApiBearerAuth } from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import type { RequestWithUser } from '../common/interfaces/request-with-user.interface';

@ApiTags('rooms')
@Controller('rooms')
export class RoomsController {
  constructor(private readonly roomsService: RoomsService) {}

  @Post()
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiCreatedResponse({ type: RoomResponseDto })
  async createRoom(
    @Body() dto: CreateRoomDto,
    @Req() req: RequestWithUser,
  ): Promise<RoomResponseDto> {
    return this.roomsService.createRoom(dto, req.user.userId);
  }

  @Get()
  @ApiOkResponse({ type: [RoomResponseDto] })
  async getAllRooms(): Promise<RoomResponseDto[]> {
    return this.roomsService.getAllRooms();
  }

  @Get(':id')
  @ApiOkResponse({ type: RoomResponseDto })
  async getRoomById(@Param('id') id: string): Promise<RoomResponseDto> {
    return this.roomsService.getRoomById(id);
  }
}
