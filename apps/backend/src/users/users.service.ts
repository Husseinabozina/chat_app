import { HttpStatus, Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { QueryFailedError, Repository } from 'typeorm';

import { ApiException } from '../common/http/api-exception';
import { UserEntity } from '../database/entities';
import { UpdateProfileDto } from './dto/update-profile.dto';

export interface PublicUser {
  id: string;
  email: string;
  username: string | null;
  displayName: string | null;
  bio: string | null;
  avatarUrl: string | null;
  createdAt: Date;
  updatedAt: Date;
}

@Injectable()
export class UsersService {
  constructor(
    @InjectRepository(UserEntity)
    private readonly users: Repository<UserEntity>,
  ) {}

  async getById(userId: string): Promise<UserEntity> {
    const user = await this.users.findOne({ where: { id: userId } });

    if (!user) {
      throw new ApiException(
        HttpStatus.NOT_FOUND,
        'USER_NOT_FOUND',
        'User not found.',
      );
    }

    return user;
  }

  async updateProfile(
    userId: string,
    dto: UpdateProfileDto,
  ): Promise<PublicUser> {
    const user = await this.getById(userId);

    if (dto.username !== undefined) {
      user.username = dto.username.trim();
    }

    if (dto.displayName !== undefined) {
      user.displayName = dto.displayName.trim();
    }

    if (dto.bio !== undefined) {
      user.bio = dto.bio.trim();
    }

    try {
      return this.toPublicUser(await this.users.save(user));
    } catch (error) {
      if (this.isUniqueViolation(error, 'uq_users_username_ci')) {
        throw new ApiException(
          HttpStatus.CONFLICT,
          'USERNAME_TAKEN',
          'Username is already in use.',
        );
      }

      throw error;
    }
  }

  toPublicUser(user: UserEntity): PublicUser {
    return {
      id: user.id,
      email: user.email,
      username: user.username,
      displayName: user.displayName,
      bio: user.bio,
      avatarUrl: user.avatarUrl,
      createdAt: user.createdAt,
      updatedAt: user.updatedAt,
    };
  }

  private isUniqueViolation(error: unknown, constraint: string): boolean {
    if (!(error instanceof QueryFailedError)) {
      return false;
    }

    const driverError = error.driverError;

    return (
      typeof driverError === 'object' &&
      driverError !== null &&
      'code' in driverError &&
      driverError.code === '23505' &&
      'constraint' in driverError &&
      driverError.constraint === constraint
    );
  }
}
