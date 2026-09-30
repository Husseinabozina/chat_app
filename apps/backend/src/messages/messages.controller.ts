import {
  Body,
  Controller,
  Get,
  Inject,
  Param,
  ParseUUIDPipe,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';

import { AccessTokenGuard } from '../auth/access-token.guard';
import { CurrentAuth, type AuthContext } from '../auth/current-auth.decorator';
import { ListMessagesQueryDto } from './dto/list-messages-query.dto';
import { SendMessageDto } from './dto/send-message.dto';
import { MessagesService } from './messages.service';

@Controller('conversations/:conversationId/messages')
@UseGuards(AccessTokenGuard)
export class MessagesController {
  constructor(
    @Inject(MessagesService)
    private readonly messagesService: MessagesService,
  ) {}

  @Get()
  list(
    @CurrentAuth() auth: AuthContext,
    @Param('conversationId', new ParseUUIDPipe()) conversationId: string,
    @Query() query: ListMessagesQueryDto,
  ) {
    return this.messagesService.list(
      auth.userId,
      conversationId,
      query.before,
      query.limit,
    );
  }

  @Post()
  send(
    @CurrentAuth() auth: AuthContext,
    @Param('conversationId', new ParseUUIDPipe()) conversationId: string,
    @Body() dto: SendMessageDto,
  ) {
    return this.messagesService.send(auth.userId, conversationId, dto);
  }
}
