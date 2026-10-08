import { Inject, Injectable } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { InjectDataSource } from '@nestjs/typeorm';
import { type Socket } from 'socket.io';
import { DataSource } from 'typeorm';

import { RefreshSessionEntity } from '../database/entities';
import { type RealtimeSocketAuth } from './realtime.types';

interface AccessTokenPayload {
  sub: string;
  sid: string;
  typ: 'access';
  exp: number;
}

@Injectable()
export class RealtimeAuthService {
  constructor(
    @Inject(JwtService)
    private readonly jwtService: JwtService,
    @InjectDataSource()
    private readonly dataSource: DataSource,
  ) {}

  async authenticate(socket: Socket): Promise<RealtimeSocketAuth> {
    const token = this.readAccessToken(socket);
    const payload = await this.jwtService.verifyAsync<AccessTokenPayload>(
      token,
      {
        issuer: 'chat-platform-api',
        audience: 'chat-mobile',
      },
    );

    if (
      payload.typ !== 'access' ||
      typeof payload.sub !== 'string' ||
      typeof payload.sid !== 'string' ||
      typeof payload.exp !== 'number'
    ) {
      throw new Error('Invalid access token payload.');
    }

    const session = await this.dataSource
      .getRepository(RefreshSessionEntity)
      .findOne({
        where: {
          id: payload.sid,
          userId: payload.sub,
        },
      });

    const now = Date.now();

    if (
      !session ||
      session.revokedAt !== null ||
      session.expiresAt.getTime() <= now
    ) {
      throw new Error('Session is inactive.');
    }

    return {
      userId: payload.sub,
      sessionId: payload.sid,
      connectionExpiresAt: Math.min(
        payload.exp * 1000,
        session.expiresAt.getTime(),
      ),
    };
  }

  private readAccessToken(socket: Socket): string {
    const raw = socket.handshake.auth?.accessToken;

    if (typeof raw !== 'string' || raw.trim().length === 0) {
      throw new Error('Missing access token.');
    }

    return raw.trim();
  }
}
