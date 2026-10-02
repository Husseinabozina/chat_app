import { MediaModule } from './media/media.module';
import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';

import { AuthModule } from './auth/auth.module';
import { ConversationsModule } from './conversations/conversations.module';
import { DatabaseModule } from './database/database.module';
import { HealthModule } from './health/health.module';
import { MessagesModule } from './messages/messages.module';
import { RealtimeModule } from './realtime/realtime.module';
import { UsersModule } from './users/users.module';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
    }),
    DatabaseModule,
    AuthModule,
    UsersModule,
    ConversationsModule,
    MessagesModule,
    MediaModule,
    RealtimeModule,
    HealthModule,
  ],
})
export class AppModule {}
