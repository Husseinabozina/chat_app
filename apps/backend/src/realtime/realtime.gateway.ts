import { Inject, Logger } from '@nestjs/common';
import {
  ConnectedSocket,
  MessageBody,
  OnGatewayConnection,
  OnGatewayDisconnect,
  OnGatewayInit,
  SubscribeMessage,
  WebSocketGateway,
} from '@nestjs/websockets';
import { type Server, type Socket } from 'socket.io';

import { RealtimeAuthService } from './realtime-auth.service';
import { RealtimeCommandError } from './realtime-command.error';
import { RealtimePublisher } from './realtime.publisher';
import {
  type RealtimeCommandAck,
  type RealtimeSocketAuth,
  type TypingCommandPayload,
} from './realtime.types';
import { TypingStateService } from './typing-state.service';

interface SocketData {
  auth?: RealtimeSocketAuth;
}

type AuthenticatedSocket = Socket<
  Record<string, never>,
  Record<string, never>,
  Record<string, never>,
  SocketData
>;

@WebSocketGateway({
  namespace: '/realtime',
  maxHttpBufferSize: 16 * 1024,
})
export class RealtimeGateway
  implements OnGatewayInit, OnGatewayConnection, OnGatewayDisconnect
{
  private readonly logger = new Logger(RealtimeGateway.name);
  private readonly expiryTimers = new Map<string, NodeJS.Timeout>();

  constructor(
    @Inject(RealtimeAuthService)
    private readonly authService: RealtimeAuthService,
    @Inject(RealtimePublisher)
    private readonly publisher: RealtimePublisher,
    @Inject(TypingStateService)
    private readonly typingState: TypingStateService,
  ) {}

  afterInit(server: Server): void {
    this.publisher.attachServer(server);

    server.use(async (socket, next) => {
      try {
        const auth = await this.authService.authenticate(socket);
        (socket.data as SocketData).auth = auth;
        next();
      } catch {
        const error = new Error(
          'Unauthorized realtime connection.',
        ) as Error & { data?: Record<string, unknown> };
        error.data = { code: 'UNAUTHORIZED' };
        next(error);
      }
    });
  }

  async handleConnection(client: AuthenticatedSocket): Promise<void> {
    const auth = client.data.auth;

    if (!auth) {
      client.disconnect(true);
      return;
    }

    await client.join([
      this.publisher.userRoom(auth.userId),
      this.publisher.sessionRoom(auth.sessionId),
    ]);

    const delay = Math.max(0, auth.connectionExpiresAt - Date.now());
    const timer = setTimeout(() => {
      client.disconnect(true);
    }, delay);

    this.expiryTimers.set(client.id, timer);

    this.publisher.publishConnectionReady(client.id, {
      userId: auth.userId,
      sessionId: auth.sessionId,
    });
  }

  handleDisconnect(client: AuthenticatedSocket): void {
    const timer = this.expiryTimers.get(client.id);

    if (timer) {
      clearTimeout(timer);
      this.expiryTimers.delete(client.id);
    }

    this.typingState.clearSocket(client.id);
  }

  @SubscribeMessage('typing.start')
  async startTyping(
    @ConnectedSocket() client: AuthenticatedSocket,
    @MessageBody() payload: TypingCommandPayload,
  ): Promise<RealtimeCommandAck> {
    return this.runCommand(client, payload, (auth, conversationId) =>
      this.typingState.start(client.id, auth.userId, conversationId),
    );
  }

  @SubscribeMessage('typing.stop')
  async stopTyping(
    @ConnectedSocket() client: AuthenticatedSocket,
    @MessageBody() payload: TypingCommandPayload,
  ): Promise<RealtimeCommandAck> {
    return this.runCommand(client, payload, (auth, conversationId) =>
      this.typingState.stop(client.id, auth.userId, conversationId),
    );
  }

  private async runCommand(
    client: AuthenticatedSocket,
    payload: TypingCommandPayload,
    command: (
      auth: RealtimeSocketAuth,
      conversationId: string,
    ) => Promise<void>,
  ): Promise<RealtimeCommandAck> {
    const auth = client.data.auth;

    if (!auth) {
      return {
        ok: false,
        error: {
          code: 'UNAUTHORIZED',
          message: 'Realtime connection is not authenticated.',
        },
      };
    }

    const conversationId =
      typeof payload?.conversationId === 'string'
        ? payload.conversationId
        : '';

    try {
      await command(auth, conversationId);
      return { ok: true };
    } catch (error) {
      if (error instanceof RealtimeCommandError) {
        return error.toAck();
      }

      this.logger.error(
        'Realtime command failed.',
        error instanceof Error ? error.stack : undefined,
      );

      return {
        ok: false,
        error: {
          code: 'VALIDATION_ERROR',
          message: 'Realtime command failed.',
        },
      };
    }
  }
}
