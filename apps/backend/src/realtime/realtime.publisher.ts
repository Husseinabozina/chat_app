import { randomUUID } from 'node:crypto';

import { Injectable, Logger } from '@nestjs/common';
import { type Server } from 'socket.io';

import { type ConversationSummary, type ReadStateResponse } from '../conversations/conversations.service';
import { type MessageResponse } from '../messages/messages.service';
import {
  REALTIME_PROTOCOL_VERSION,
  type RealtimeEnvelope,
  type RealtimeEventType,
} from './realtime.types';

@Injectable()
export class RealtimePublisher {
  private readonly logger = new Logger(RealtimePublisher.name);
  private server: Server | null = null;

  attachServer(server: Server): void {
    this.server = server;
  }

  publishConnectionReady(
    socketId: string,
    data: { userId: string; sessionId: string },
  ): void {
    this.emitToSocket(socketId, 'connection.ready', null, data);
  }

  publishMessageCreated(userIds: string[], message: MessageResponse): void {
    this.emitToUsers(userIds, 'message.created', message.conversationId, {
      message,
    });
  }

  publishMessageUpdated(userIds: string[], message: MessageResponse): void {
    this.emitToUsers(userIds, 'message.updated', message.conversationId, {
      message,
    });
  }

  publishMessageDeleted(
    userIds: string[],
    message: Pick<
      MessageResponse,
      'id' | 'conversationId' | 'senderId' | 'deletedAt'
    >,
  ): void {
    this.emitToUsers(userIds, 'message.deleted', message.conversationId, {
      messageId: message.id,
      conversationId: message.conversationId,
      senderId: message.senderId,
      deletedAt: message.deletedAt,
    });
  }

  publishConversationUpdated(
    userId: string,
    conversation: ConversationSummary,
  ): void {
    this.emitToUsers([userId], 'conversation.updated', conversation.id, {
      conversation,
    });
  }

  publishReadUpdated(
    userIds: string[],
    data: ReadStateResponse & { userId: string },
  ): void {
    this.emitToUsers(userIds, 'read.updated', data.conversationId, data);
  }

  publishTypingStarted(
    userIds: string[],
    data: {
      conversationId: string;
      userId: string;
      expiresAt: string;
    },
  ): void {
    this.emitToUsers(userIds, 'typing.started', data.conversationId, data);
  }

  publishTypingStopped(
    userIds: string[],
    data: { conversationId: string; userId: string },
  ): void {
    this.emitToUsers(userIds, 'typing.stopped', data.conversationId, data);
  }

  disconnectSession(sessionId: string): void {
    const server = this.server;

    if (!server) {
      return;
    }

    server.in(this.sessionRoom(sessionId)).disconnectSockets(true);
  }

  userRoom(userId: string): string {
    return `user:${userId}`;
  }

  sessionRoom(sessionId: string): string {
    return `session:${sessionId}`;
  }

  private emitToSocket<T>(
    socketId: string,
    type: RealtimeEventType,
    conversationId: string | null,
    data: T,
  ): void {
    const server = this.server;

    if (!server) {
      this.logger.warn(`Realtime server unavailable for event ${type}.`);
      return;
    }

    try {
      server
        .to(socketId)
        .emit(type, this.envelope(type, conversationId, data));
    } catch (error) {
      this.logPublicationError(type, error);
    }
  }

  private emitToUsers<T>(
    userIds: string[],
    type: RealtimeEventType,
    conversationId: string | null,
    data: T,
  ): void {
    const server = this.server;

    if (!server) {
      this.logger.warn(`Realtime server unavailable for event ${type}.`);
      return;
    }

    const envelope = this.envelope(type, conversationId, data);

    try {
      for (const userId of new Set(userIds)) {
        server.to(this.userRoom(userId)).emit(type, envelope);
      }
    } catch (error) {
      this.logPublicationError(type, error);
    }
  }

  private envelope<T>(
    type: RealtimeEventType,
    conversationId: string | null,
    data: T,
  ): RealtimeEnvelope<T> {
    return {
      protocolVersion: REALTIME_PROTOCOL_VERSION,
      eventId: randomUUID(),
      type,
      occurredAt: new Date().toISOString(),
      conversationId,
      data,
    };
  }

  private logPublicationError(type: RealtimeEventType, error: unknown): void {
    this.logger.error(
      `Realtime publication failed for event ${type}.`,
      error instanceof Error ? error.stack : undefined,
    );
  }
}
