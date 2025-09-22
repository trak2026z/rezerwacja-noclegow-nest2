import {
  Injectable,
  NotFoundException,
  ForbiddenException,
} from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { Room, RoomDocument } from './schemas/room.schema';
import { CreateRoomDto } from './dto/create-room.dto';
import { RoomResponseDto } from './dto/room-response.dto';

import { UpdateRoomDto, PatchRoomDto } from './dto/update-room.dto';

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

  async updateRoom(
    id: string,
    dto: UpdateRoomDto,
    userId: string,
  ): Promise<RoomResponseDto> {
    const room = await this.roomModel.findById(id);
    if (!room) throw new NotFoundException('Room not found');
    if (room.createdBy.toString() !== userId)
      throw new ForbiddenException('You are not the owner of this room');

    // PUT – pełna aktualizacja
    room.title = dto.title;
    room.body = dto.body;
    room.city = dto.city;
    room.imgLink = dto.imgLink ?? room.imgLink;
    room.startAt = dto.startAt ? new Date(dto.startAt) : (undefined as any);
    room.endsAt = dto.endsAt ? new Date(dto.endsAt) : (undefined as any);

    const updated = await room.save();
    return this.toResponseDto(updated);
  }

  async patchRoom(
    id: string,
    dto: PatchRoomDto,
    userId: string,
  ): Promise<RoomResponseDto> {
    const room = await this.roomModel.findById(id);
    if (!room) throw new NotFoundException('Room not found');
    if (room.createdBy.toString() !== userId)
      throw new ForbiddenException('You are not the owner of this room');

    // PATCH – tylko pola, które przyszły
    if (dto.title) room.title = dto.title;
    if (dto.body) room.body = dto.body;
    if (dto.city) room.city = dto.city;
    if (dto.imgLink) room.imgLink = dto.imgLink;
    if (dto.startAt) room.startAt = new Date(dto.startAt);
    if (dto.endsAt) room.endsAt = new Date(dto.endsAt);

    const updated = await room.save();
    return this.toResponseDto(updated);
  }

  async deleteRoom(id: string, userId: string): Promise<void> {
    const room = await this.roomModel.findById(id);
    if (!room) {
      throw new NotFoundException('Room not found');
    }

    if (room.createdBy.toString() !== userId) {
      throw new ForbiddenException('You are not the owner of this room');
    }

    await this.roomModel.deleteOne({ _id: id });
  }

  private isOwner(room: RoomDocument, userId: string): boolean {
    const ownerId =
      room.createdBy instanceof Types.ObjectId
        ? room.createdBy.toString()
        : ((room.createdBy as any)._id as Types.ObjectId).toString();
    return ownerId === userId;
  }

  async likeRoom(roomId: string, userId: string): Promise<RoomResponseDto> {
    const room = await this.roomModel.findById(roomId);
    if (!room) throw new NotFoundException('Room not found');

    if (this.isOwner(room, userId)) {
      throw new ForbiddenException('Owner cannot react to own room');
    }

    const userObjectId = new Types.ObjectId(userId);

    // zabezpieczenie na wypadek undefined
    room.likedBy = room.likedBy ?? [];
    room.dislikedBy = room.dislikedBy ?? [];

    // usuń ewentualny dislike
    room.dislikedBy = room.dislikedBy.filter(
      (u) => u.toString() !== userObjectId.toString(),
    );

    // dodaj like tylko jeśli jeszcze nie ma
    if (!room.likedBy.some((u) => u.toString() === userObjectId.toString())) {
      room.likedBy.push(userObjectId);
    }

    room.likes = room.likedBy.length;
    room.dislikes = room.dislikedBy.length;

    const updated = await room.save();
    return this.toResponseDto(updated);
  }

  async dislikeRoom(roomId: string, userId: string): Promise<RoomResponseDto> {
    const room = await this.roomModel.findById(roomId);
    if (!room) throw new NotFoundException('Room not found');

    if (this.isOwner(room, userId)) {
      throw new ForbiddenException('Owner cannot react to own room');
    }

    const userObjectId = new Types.ObjectId(userId);

    // zabezpieczenie na wypadek undefined
    room.likedBy = room.likedBy ?? [];
    room.dislikedBy = room.dislikedBy ?? [];

    // usuń ewentualny like
    room.likedBy = room.likedBy.filter(
      (u) => u.toString() !== userObjectId.toString(),
    );

    // dodaj dislike tylko jeśli jeszcze nie ma
    if (!room.dislikedBy.some((u) => u.toString() === userObjectId.toString())) {
      room.dislikedBy.push(userObjectId);
    }

    room.likes = room.likedBy.length;
    room.dislikes = room.dislikedBy.length;

    const updated = await room.save();
    return this.toResponseDto(updated);
  }
}
