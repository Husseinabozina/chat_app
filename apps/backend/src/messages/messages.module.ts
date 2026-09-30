import { Module } from '@nestjs/common';

import { AuthModule } from '../auth/auth.module';
import { MessageLifecycleController } from './message-lifecycle.controller';
import { MessagesController } from './messages.controller';
import { MessagesService } from './messages.service';

@Module({
  imports: [AuthModule],
  controllers: [MessagesController, MessageLifecycleController],
  providers: [MessagesService],
})
export class MessagesModule {}
