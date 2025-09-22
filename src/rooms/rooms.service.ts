import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { Room, RoomDocument } from './schemas/room.schema';
import { CreateRoomDto } from './dto/create-room.dto';
import { RoomResponseDto } from './dto/room-response.dto';

@Injectable()
export class RoomsService {
  constructor(@InjectModel(Room.name) private roomModel: Model<RoomDocument>) {}

  async createRoom(
    dto: CreateRoomDto,
    userId: string,
  ): Promise<RoomResponseDto> {
    const created = new this.roomModel({
      ...dto,
      createdBy: new Types.ObjectId(userId),
      startAt: dto.startAt ? new Date(dto.startAt) : undefined,
      endsAt: dto.endsAt ? new Date(dto.endsAt) : undefined,
    });
    const room = await created.save();

    return this.toResponseDto(room);
  }

  async getAllRooms(): Promise<RoomResponseDto[]> {
    const rooms = await this.roomModel.find().populate('createdBy', 'username');
    return rooms.map((room) => this.toResponseDto(room));
  }

  async getRoomById(id: string): Promise<RoomResponseDto> {
    const room = await this.roomModel
      .findById(id)
      .populate('createdBy', 'username');
    if (!room) {
      throw new NotFoundException('Room not found');
    }
    return this.toResponseDto(room);
  }

  private toResponseDto(room: RoomDocument): RoomResponseDto {
    return {
      id: (room._id as Types.ObjectId).toString(),
      title: room.title,
      body: room.body,
      city: room.city,
      imgLink: room.imgLink,
      createdBy:
        room.createdBy instanceof Types.ObjectId
          ? room.createdBy.toString()
          : (room.createdBy as any).username,
      createdAt: room.createdAt.toISOString(),
      likes: room.likes,
      dislikes: room.dislikes,
      reserved: room.reserved,
      startAt: room.startAt ? room.startAt.toISOString() : undefined,
      endsAt: room.endsAt ? room.endsAt.toISOString() : undefined,
    };
  }
}
