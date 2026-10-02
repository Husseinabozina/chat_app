import { PushModule } from '../push/push.module';
import { MediaModule } from '../media/media.module';
import { Module } from '@nestjs/common';

import { AuthModule } from '../auth/auth.module';
import { ConversationsModule } from '../conversations/conversations.module';
import { RealtimeModule } from '../realtime/realtime.module';
import { MessageLifecycleController } from './message-lifecycle.controller';
import { MessagesController } from './messages.controller';
import { MessagesService } from './messages.service';

@Module({
  imports: [
    AuthModule,
    ConversationsModule,
    RealtimeModule,
    MediaModule,
    PushModule,
  ],
  controllers: [MessagesController, MessageLifecycleController],
  providers: [MessagesService],
})
export class MessagesModule {}
