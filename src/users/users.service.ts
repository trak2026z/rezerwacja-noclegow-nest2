import { Injectable, ConflictException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import * as bcrypt from 'bcrypt';
import { User, UserDocument } from './schemas/user.schema';
import { RegisterUserDto } from './dto/register-user.dto';
import { UserProfileResponseDto } from './dto/user-profile-response.dto';

import { Types } from 'mongoose';

import { NotFoundException } from '@nestjs/common';
import { PublicUserProfileDto } from './dto/public-user-profile.dto';

@Injectable()
export class UsersService {
  constructor(@InjectModel(User.name) private userModel: Model<UserDocument>) {}

  async createUser(dto: RegisterUserDto): Promise<UserProfileResponseDto> {
    const existingEmail = await this.userModel.findOne({ email: dto.email });
    if (existingEmail) {
      throw new ConflictException('Email already in use');
    }

    const existingUsername = await this.userModel.findOne({
      username: dto.username,
    });
    if (existingUsername) {
      throw new ConflictException('Username already in use');
    }

    const saltRounds = 10;
    const passwordHash = await bcrypt.hash(dto.password, saltRounds);

    const createdUser = new this.userModel({
      email: dto.email,
      username: dto.username,
      passwordHash,
    });

    const user = await createdUser.save();

    return {
      id: (user._id as Types.ObjectId).toString(),
      email: user.email,
      username: user.username,
      createdAt: user.createdAt.toISOString(),
    };
  }

  async findByEmailOrUsername(
    emailOrUsername: string,
  ): Promise<UserDocument | null> {
    return this.userModel.findOne({
      $or: [
        { email: emailOrUsername.toLowerCase() },
        { username: emailOrUsername.toLowerCase() },
      ],
    });
  }

  async getUserProfile(userId: string): Promise<UserProfileResponseDto> {
    const user = await this.userModel.findById(userId);
    if (!user) {
      throw new Error('User not found');
    }
    return {
      id: (user._id as Types.ObjectId).toString(),
      email: user.email,
      username: user.username,
      createdAt: user.createdAt.toISOString(),
    };
  }

  async getPublicProfile(username: string): Promise<PublicUserProfileDto> {
    const user = await this.userModel.findOne({
      username: username.toLowerCase(),
    });
    if (!user) {
      throw new NotFoundException('User not found');
    }
    return {
      username: user.username,
      createdAt: user.createdAt.toISOString(),
    };
  }

  async isEmailAvailable(email: string): Promise<{ available: boolean }> {
    const exists = await this.userModel.exists({ email: email.toLowerCase() });
    return { available: !exists };
  }

  async isUsernameAvailable(username: string): Promise<{ available: boolean }> {
    const exists = await this.userModel.exists({
      username: username.toLowerCase(),
    });
    return { available: !exists };
  }
}
