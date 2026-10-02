import {
  Body,
  Controller,
  Get,
  Param,
  ParseUUIDPipe,
  Patch,
  Post,
  UseGuards,
} from '@nestjs/common';
import { AccessTokenGuard } from '../auth/access-token.guard';
import { CurrentAuth, type AuthContext } from '../auth/current-auth.decorator';
import { CreateUploadDto } from './dto/create-upload.dto';
import { MediaService } from './media.service';
@Controller('media')
@UseGuards(AccessTokenGuard)
export class MediaController {
  constructor(private readonly media: MediaService) {}
  @Post('uploads') authorize(
    @CurrentAuth() auth: AuthContext,
    @Body() dto: CreateUploadDto,
  ) {
    return this.media.authorize(auth.userId, dto);
  }
  @Post(':id/complete') complete(
    @CurrentAuth() auth: AuthContext,
    @Param('id', new ParseUUIDPipe()) id: string,
  ) {
    return this.media.complete(auth.userId, id);
  }
  @Patch(':id/avatar') avatar(
    @CurrentAuth() auth: AuthContext,
    @Param('id', new ParseUUIDPipe()) id: string,
  ) {
    return this.media.setAvatar(auth.userId, id);
  }
  @Get(':id/content') content(
    @CurrentAuth() auth: AuthContext,
    @Param('id', new ParseUUIDPipe()) id: string,
  ) {
    return this.media.download(auth.userId, id);
  }
}
