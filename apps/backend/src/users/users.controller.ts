import {
  Body,
  Controller,
  Get,
  Param,
  ParseUUIDPipe,
  Patch,
  Query,
  UseGuards,
} from '@nestjs/common';

import { AccessTokenGuard } from '../auth/access-token.guard';
import { CurrentAuth, type AuthContext } from '../auth/current-auth.decorator';
import { SearchUsersQueryDto } from './dto/search-users-query.dto';
import { UpdateProfileDto } from './dto/update-profile.dto';
import {
  type DiscoverableUser,
  type PublicUser,
  type UserSearchPage,
  UsersService,
} from './users.service';

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

  @Get()
  search(
    @CurrentAuth() auth: AuthContext,
    @Query() query: SearchUsersQueryDto,
  ): Promise<UserSearchPage> {
    return this.usersService.search(
      auth.userId,
      query.query,
      query.cursor,
      query.limit,
    );
  }

  @Get(':userId')
  getProfile(
    @Param('userId', new ParseUUIDPipe()) userId: string,
  ): Promise<DiscoverableUser> {
    return this.usersService.getPublicProfile(userId);
  }
}
