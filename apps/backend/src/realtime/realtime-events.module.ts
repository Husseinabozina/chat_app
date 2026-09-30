import { Module } from '@nestjs/common';

import { RealtimeEventBus } from './realtime-event-bus';

@Module({
  providers: [RealtimeEventBus],
  exports: [RealtimeEventBus],
})
export class RealtimeEventsModule {}
