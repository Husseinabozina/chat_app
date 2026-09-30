import { Inject, OnModuleDestroy } from '@nestjs/common';
import {
  ConnectedSocket,
  MessageBody,
  OnGatewayConnection,
  OnGatewayInit,
  SubscribeMessage,
  WebSocketGateway,
  WebSocketServer,
} from '@nestjs/websockets';
import { isUUID } from 'class-validator';
import { Subscription } from 'rxjs';
import { Server, Socket } from 'socket.io';

import { AccessTokenVerifier } from '../auth/access-token.verifier';
import { type AuthContext } from '../auth/current-auth.decorator';
import { ApiException } from '../common/http/api-exception';
import { ConversationsService } from '../conversations/conversations.service';
import {
  RealtimeDomainEvent,
  RealtimeEventBus,
} from './realtime-event-bus';

interface RealtimeAckSuccess {
  ok: true;
}

interface RealtimeAckFailure {
  ok: false;
  error: {
    code: string;
    message: string;
  };
}

type RealtimeAck = RealtimeAckSuccess | RealtimeAckFailure;

interface ConversationPayload {
  conversationId?: unknown;
}

@WebSocketGateway({
  namespace: '/realtime',
  transports: ['websocket'],
})
export class RealtimeGateway
  implements OnGatewayInit, OnGatewayConnection, OnModuleDestroy
{
  @WebSocketServer()
  private server!: Server;

  private eventSubscription?: Subscription;

  constructor(
    @Inject(AccessTokenVerifier)
    private readonly accessTokenVerifier: AccessTokenVerifier,
    @Inject(ConversationsService)
    private readonly conversationsService: ConversationsService,
    @Inject(RealtimeEventBus)
    private readonly eventBus: RealtimeEventBus,
  ) {}

  afterInit(server: Server): void {
    server.use((client, next) => {
      void this.authenticate(client)
        .then(() => next())
        .catch(() => {
          const error = new Error('UNAUTHORIZED') as Error & {
            data?: { code: string };
          };
          error.data = { code: 'UNAUTHORIZED' };
          next(error);
        });
    });

    this.eventSubscription = this.eventBus.events$.subscribe((event) => {
      this.emitDomainEvent(event);
    });
  }

  async handleConnection(client: Socket): Promise<void> {
    const auth = this.getAuth(client);

    if (!auth) {
      client.disconnect(true);
      return;
    }

    await client.join(this.userRoom(auth.userId));
  }

  onModuleDestroy(): void {
    this.eventSubscription?.unsubscribe();
  }

  @SubscribeMessage('conversation:join')
  async joinConversation(
    @ConnectedSocket() client: Socket,
    @MessageBody() payload: ConversationPayload,
  ): Promise<RealtimeAck> {
    const conversationId = this.parseConversationId(payload);

    if (!conversationId) {
      return this.validationFailure();
    }

    const auth = this.getAuth(client);

    if (!auth) {
      return this.unauthorizedFailure();
    }

    try {
      await this.conversationsService.assertMember(
        auth.userId,
        conversationId,
      );
      await client.join(this.conversationRoom(conversationId));
      return { ok: true };
    } catch (error) {
      return this.toFailure(error);
    }
  }

  @SubscribeMessage('conversation:leave')
  async leaveConversation(
    @ConnectedSocket() client: Socket,
    @MessageBody() payload: ConversationPayload,
  ): Promise<RealtimeAck> {
    const conversationId = this.parseConversationId(payload);

    if (!conversationId) {
      return this.validationFailure();
    }

    await client.leave(this.conversationRoom(conversationId));
    return { ok: true };
  }

  @SubscribeMessage('typing:start')
  typingStart(
    @ConnectedSocket() client: Socket,
    @MessageBody() payload: ConversationPayload,
  ): Promise<RealtimeAck> {
    return this.emitTyping(client, payload, true);
  }

  @SubscribeMessage('typing:stop')
  typingStop(
    @ConnectedSocket() client: Socket,
    @MessageBody() payload: ConversationPayload,
  ): Promise<RealtimeAck> {
    return this.emitTyping(client, payload, false);
  }

  private async emitTyping(
    client: Socket,
    payload: ConversationPayload,
    isTyping: boolean,
  ): Promise<RealtimeAck> {
    const conversationId = this.parseConversationId(payload);

    if (!conversationId) {
      return this.validationFailure();
    }

    const auth = this.getAuth(client);

    if (!auth) {
      return this.unauthorizedFailure();
    }

    try {
      await this.conversationsService.assertMember(
        auth.userId,
        conversationId,
      );

      client
        .to(this.conversationRoom(conversationId))
        .emit(isTyping ? 'typing:started' : 'typing:stopped', {
          conversationId,
          userId: auth.userId,
        });

      return { ok: true };
    } catch (error) {
      return this.toFailure(error);
    }
  }

  private async authenticate(client: Socket): Promise<void> {
    const token = this.extractAccessToken(client);
    const auth = await this.accessTokenVerifier.verify(token);
    client.data.auth = auth;
  }

  private extractAccessToken(client: Socket): string {
    const authToken = client.handshake.auth?.token;

    if (typeof authToken === 'string' && authToken.length > 0) {
      return authToken;
    }

    const authorization = client.handshake.headers.authorization;

    if (
      typeof authorization === 'string' &&
      authorization.startsWith('Bearer ')
    ) {
      return authorization.slice('Bearer '.length).trim();
    }

    return '';
  }

  private getAuth(client: Socket): AuthContext | undefined {
    const auth = client.data.auth as AuthContext | undefined;
    return auth;
  }

  private parseConversationId(payload: ConversationPayload): string | null {
    const value = payload?.conversationId;

    return typeof value === 'string' && isUUID(value) ? value : null;
  }

  private emitDomainEvent(event: RealtimeDomainEvent): void {
    const rooms = [
      this.conversationRoom(event.conversationId),
      ...event.participantUserIds.map((userId) => this.userRoom(userId)),
    ];
    const target = this.server.to(rooms);

    switch (event.kind) {
      case 'message.created':
        target.emit('message:created', event.message);
        break;
      case 'message.updated':
        target.emit('message:updated', event.message);
        break;
      case 'message.deleted':
        target.emit('message:deleted', {
          conversationId: event.conversationId,
          messageId: event.messageId,
          deletedAt: event.deletedAt,
        });
        break;
      case 'conversation.read':
        target.emit('conversation:read', {
          conversationId: event.conversationId,
          userId: event.readerUserId,
          lastReadMessageId: event.lastReadMessageId,
          lastReadAt: event.lastReadAt,
        });
        break;
    }
  }

  private toFailure(error: unknown): RealtimeAckFailure {
    if (error instanceof ApiException) {
      return {
        ok: false,
        error: {
          code: error.code,
          message: error.message,
        },
      };
    }

    return {
      ok: false,
      error: {
        code: 'INTERNAL_ERROR',
        message: 'An unexpected error occurred.',
      },
    };
  }

  private validationFailure(): RealtimeAckFailure {
    return {
      ok: false,
      error: {
        code: 'VALIDATION_ERROR',
        message: 'conversationId must be a valid UUID.',
      },
    };
  }

  private unauthorizedFailure(): RealtimeAckFailure {
    return {
      ok: false,
      error: {
        code: 'UNAUTHORIZED',
        message: 'Access token is missing, invalid, or expired.',
      },
    };
  }

  private userRoom(userId: string): string {
    return `user:${userId}`;
  }

  private conversationRoom(conversationId: string): string {
    return `conversation:${conversationId}`;
  }
}
