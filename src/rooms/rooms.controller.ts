import {
  Body,
  Controller,
  Get,
  Param,
  Post,
  UseGuards,
  Req,
  Put,
  Patch,
  Delete,
} from '@nestjs/common';
import { RoomsService } from './rooms.service';
import { CreateRoomDto } from './dto/create-room.dto';
import { RoomResponseDto } from './dto/room-response.dto';
import {
  ApiTags,
  ApiCreatedResponse,
  ApiOkResponse,
  ApiBearerAuth,
  ApiNoContentResponse,
} from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import type { RequestWithUser } from '../common/interfaces/request-with-user.interface';

import { UpdateRoomDto, PatchRoomDto } from './dto/update-room.dto';

import { ReserveRoomDto } from './dto/reserve-room.dto';

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

  @Put(':id')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOkResponse({ type: RoomResponseDto })
  async updateRoom(
    @Param('id') id: string,
    @Body() dto: UpdateRoomDto,
    @Req() req: RequestWithUser,
  ): Promise<RoomResponseDto> {
    return this.roomsService.updateRoom(id, dto, req.user.userId);
  }

  @Patch(':id')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOkResponse({ type: RoomResponseDto })
  async patchRoom(
    @Param('id') id: string,
    @Body() dto: PatchRoomDto,
    @Req() req: RequestWithUser,
  ): Promise<RoomResponseDto> {
    return this.roomsService.patchRoom(id, dto, req.user.userId);
  }

  @Delete(':id')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiNoContentResponse()
  async deleteRoom(
    @Param('id') id: string,
    @Req() req: RequestWithUser,
  ): Promise<void> {
    return this.roomsService.deleteRoom(id, req.user.userId);
  }

  @Post(':id/like')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOkResponse({ type: RoomResponseDto })
  async likeRoom(
    @Param('id') id: string,
    @Req() req: RequestWithUser,
  ): Promise<RoomResponseDto> {
    return this.roomsService.likeRoom(id, req.user.userId);
  }

  @Post(':id/dislike')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOkResponse({ type: RoomResponseDto })
  async dislikeRoom(
    @Param('id') id: string,
    @Req() req: RequestWithUser,
  ): Promise<RoomResponseDto> {
    return this.roomsService.dislikeRoom(id, req.user.userId);
  }

  @Post(':id/reserve')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOkResponse({ type: RoomResponseDto })
  async reserveRoom(
    @Param('id') id: string,
    @Body() dto: ReserveRoomDto,
    @Req() req: RequestWithUser,
  ): Promise<RoomResponseDto> {
    return this.roomsService.reserveRoom(id, req.user.userId, dto);
  }
}
