import { Module } from '@nestjs/common';

import { AuthModule } from '../auth/auth.module';
import { ConversationsModule } from '../conversations/conversations.module';
import { RealtimeEventsModule } from './realtime-events.module';
import { RealtimeGateway } from './realtime.gateway';

@Module({
  imports: [AuthModule, ConversationsModule, RealtimeEventsModule],
  providers: [RealtimeGateway],
})
export class RealtimeModule {}
