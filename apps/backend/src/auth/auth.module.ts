import { Module } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtModule } from '@nestjs/jwt';
import { TypeOrmModule } from '@nestjs/typeorm';

import { RefreshSessionEntity, UserEntity } from '../database/entities';
import { AccessTokenGuard } from './access-token.guard';
import { AuthController } from './auth.controller';
import { AuthService } from './auth.service';
import { SessionRevocationService } from './session-revocation.service';

@Module({
  imports: [
    TypeOrmModule.forFeature([UserEntity, RefreshSessionEntity]),
    JwtModule.registerAsync({
      inject: [ConfigService],
      useFactory: (config: ConfigService) => {
        const secret = config.getOrThrow<string>('ACCESS_TOKEN_SECRET');

        if (Buffer.byteLength(secret, 'utf8') < 32) {
          throw new Error(
            'ACCESS_TOKEN_SECRET must be at least 32 bytes long.',
          );
        }

        return {
          secret,
          signOptions: {
            issuer: 'chat-platform-api',
            audience: 'chat-mobile',
          },
        };
      },
    }),
  ],
  controllers: [AuthController],
  providers: [AuthService, AccessTokenGuard, SessionRevocationService],
  exports: [AccessTokenGuard, JwtModule, SessionRevocationService],
})
export class AuthModule {}
