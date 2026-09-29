import {
  Body,
  Controller,
  Get,
  Patch,
  UseGuards,
} from '@nestjs/common';

import { AccessTokenGuard } from '../auth/access-token.guard';
import {
  CurrentAuth,
  type AuthContext,
} from '../auth/current-auth.decorator';
import { UpdateProfileDto } from './dto/update-profile.dto';
import { type PublicUser, UsersService } from './users.service';

@Controller('users')
@UseGuards(AccessTokenGuard)
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  @Get('me')
  async getMe(@CurrentAuth() auth: AuthContext): Promise<PublicUser> {
    return this.usersService.toPublicUser(
      await this.usersService.getById(auth.userId),
    );
  }

  @Patch('me')
  updateMe(
    @CurrentAuth() auth: AuthContext,
    @Body() dto: UpdateProfileDto,
  ): Promise<PublicUser> {
    return this.usersService.updateProfile(auth.userId, dto);
  }
}
