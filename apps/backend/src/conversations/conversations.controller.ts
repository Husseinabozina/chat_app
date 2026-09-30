import {
  Body,
  Controller,
  Get,
  HttpCode,
  HttpStatus,
  Inject,
  Param,
  ParseUUIDPipe,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';

import { AccessTokenGuard } from '../auth/access-token.guard';
import { CurrentAuth, type AuthContext } from '../auth/current-auth.decorator';
import { ConversationsService } from './conversations.service';
import { CreateDirectConversationDto } from './dto/create-direct-conversation.dto';
import { ListConversationsQueryDto } from './dto/list-conversations-query.dto';
import { MarkConversationReadDto } from './dto/mark-conversation-read.dto';

@Controller('conversations')
@UseGuards(AccessTokenGuard)
export class ConversationsController {
  constructor(
    @Inject(ConversationsService)
    private readonly conversationsService: ConversationsService,
  ) {}

  @Get()
  list(
    @CurrentAuth() auth: AuthContext,
    @Query() query: ListConversationsQueryDto,
  ) {
    return this.conversationsService.list(
      auth.userId,
      query.cursor,
      query.limit,
    );
  }

  @Post('direct')
  @HttpCode(HttpStatus.OK)
  createDirect(
    @CurrentAuth() auth: AuthContext,
    @Body() dto: CreateDirectConversationDto,
  ) {
    return this.conversationsService.createOrResolveDirect(
      auth.userId,
      dto.userId,
    );
  }

  @Post(':conversationId/read')
  @HttpCode(HttpStatus.OK)
  markRead(
    @CurrentAuth() auth: AuthContext,
    @Param('conversationId', new ParseUUIDPipe()) conversationId: string,
    @Body() dto: MarkConversationReadDto,
  ) {
    return this.conversationsService.markRead(
      auth.userId,
      conversationId,
      dto.upToMessageId,
    );
  }
}
