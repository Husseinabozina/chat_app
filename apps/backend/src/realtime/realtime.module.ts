import { Module } from '@nestjs/common';

import { AuthModule } from '../auth/auth.module';
import { RealtimeAuthService } from './realtime-auth.service';
import { RealtimeGateway } from './realtime.gateway';
import { RealtimePublisher } from './realtime.publisher';
import { TypingStateService } from './typing-state.service';

@Module({
  imports: [AuthModule],
  providers: [
    RealtimePublisher,
    RealtimeAuthService,
    TypingStateService,
    RealtimeGateway,
  ],
  exports: [RealtimePublisher],
})
export class RealtimeModule {}
