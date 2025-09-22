// src/rooms/schemas/room.schema.ts
import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Schema as MongooseSchema } from 'mongoose';
import { User } from '../../users/schemas/user.schema';

import { Types } from 'mongoose';

export type RoomDocument = Room &
  Document & {
    likedBy: Types.ObjectId[];
    dislikedBy: Types.ObjectId[];
    reservedBy?: Types.ObjectId;
  };

@Schema({ timestamps: true })
export class Room {
  @Prop({
    required: true,
    minlength: 5,
    maxlength: 50,
  })
  title: string;

  @Prop({
    required: true,
    minlength: 5,
    maxlength: 500,
  })
  body: string;

  @Prop({ required: true })
  city: string;

  @Prop({ default: 'https://picsum.photos/800/600' })
  imgLink: string;

  @Prop({ type: MongooseSchema.Types.ObjectId, ref: 'User', required: true })
  createdBy: User;

  @Prop({ default: Date.now })
  createdAt: Date;

  @Prop({ default: 0 })
  likes: number;

  @Prop({ type: [{ type: MongooseSchema.Types.ObjectId, ref: 'User' }] })
  likedBy: Types.ObjectId[];

  @Prop({ default: 0 })
  dislikes: number;

  @Prop({ type: [{ type: MongooseSchema.Types.ObjectId, ref: 'User' }] })
  dislikedBy: Types.ObjectId[];

  @Prop({ default: false })
  reserved: boolean;

  @Prop({ type: MongooseSchema.Types.ObjectId, ref: 'User' })
  reservedBy?: User | Types.ObjectId;

  @Prop()
  startAt: Date;

  @Prop()
  endsAt: Date;
}

export const RoomSchema = SchemaFactory.createForClass(Room);
