import { Inject, Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { InjectDataSource } from '@nestjs/typeorm';
import { isUUID } from 'class-validator';
import { DataSource } from 'typeorm';

import { ConversationMemberEntity } from '../database/entities';
import { RealtimeCommandError } from './realtime-command.error';
import { RealtimePublisher } from './realtime.publisher';

interface TypingEntry {
  socketId: string;
  conversationId: string;
  userId: string;
  recipientUserIds: string[];
  timer: NodeJS.Timeout;
}

@Injectable()
export class TypingStateService {
  private readonly entries = new Map<string, TypingEntry>();
  private readonly commandTimes = new Map<string, number[]>();
  private readonly ttlMs: number;

  constructor(
    @InjectDataSource()
    private readonly dataSource: DataSource,
    @Inject(RealtimePublisher)
    private readonly publisher: RealtimePublisher,
    @Inject(ConfigService)
    config: ConfigService,
  ) {
    this.ttlMs = this.readPositiveNumber(
      config,
      'REALTIME_TYPING_TTL_MS',
      7000,
    );
  }

  async start(
    socketId: string,
    userId: string,
    conversationId: string,
  ): Promise<void> {
    this.validateConversationId(conversationId);
    this.assertRateLimit(socketId);

    const recipientUserIds = await this.requireMembership(
      userId,
      conversationId,
    );
    const key = this.key(socketId, conversationId);
    const existing = this.entries.get(key);

    if (existing) {
      clearTimeout(existing.timer);
    }

    const expiresAt = new Date(Date.now() + this.ttlMs);
    const timer = setTimeout(() => {
      this.expire(key);
    }, this.ttlMs);

    this.entries.set(key, {
      socketId,
      conversationId,
      userId,
      recipientUserIds,
      timer,
    });

    this.publisher.publishTypingStarted(recipientUserIds, {
      conversationId,
      userId,
      expiresAt: expiresAt.toISOString(),
    });
  }

  async stop(
    socketId: string,
    userId: string,
    conversationId: string,
  ): Promise<void> {
    this.validateConversationId(conversationId);
    this.assertRateLimit(socketId);
    await this.requireMembership(userId, conversationId);

    const key = this.key(socketId, conversationId);
    const entry = this.entries.get(key);

    if (!entry) {
      return;
    }

    clearTimeout(entry.timer);
    this.entries.delete(key);

    this.publisher.publishTypingStopped(entry.recipientUserIds, {
      conversationId,
      userId,
    });
  }

  clearSocket(socketId: string): void {
    for (const [key, entry] of this.entries.entries()) {
      if (entry.socketId !== socketId) {
        continue;
      }

      clearTimeout(entry.timer);
      this.entries.delete(key);

      this.publisher.publishTypingStopped(entry.recipientUserIds, {
        conversationId: entry.conversationId,
        userId: entry.userId,
      });
    }

    this.commandTimes.delete(socketId);
  }

  private expire(key: string): void {
    const entry = this.entries.get(key);

    if (!entry) {
      return;
    }

    this.entries.delete(key);

    this.publisher.publishTypingStopped(entry.recipientUserIds, {
      conversationId: entry.conversationId,
      userId: entry.userId,
    });
  }

  private async requireMembership(
    userId: string,
    conversationId: string,
  ): Promise<string[]> {
    const members = await this.dataSource
      .getRepository(ConversationMemberEntity)
      .find({ where: { conversationId } });

    if (!members.some((member) => member.userId === userId)) {
      throw new RealtimeCommandError(
        'CONVERSATION_NOT_FOUND',
        'Conversation not found.',
      );
    }

    return members
      .filter((member) => member.userId !== userId)
      .map((member) => member.userId);
  }

  private validateConversationId(conversationId: string): void {
    if (!isUUID(conversationId)) {
      throw new RealtimeCommandError(
        'VALIDATION_ERROR',
        'conversationId must be a UUID.',
      );
    }
  }

  private assertRateLimit(socketId: string): void {
    const now = Date.now();
    const windowStart = now - 10_000;
    const recent = (this.commandTimes.get(socketId) ?? []).filter(
      (time) => time >= windowStart,
    );

    if (recent.length >= 10) {
      throw new RealtimeCommandError(
        'RATE_LIMITED',
        'Too many realtime commands.',
      );
    }

    recent.push(now);
    this.commandTimes.set(socketId, recent);
  }

  private key(socketId: string, conversationId: string): string {
    return `${socketId}:${conversationId}`;
  }

  private readPositiveNumber(
    config: ConfigService,
    key: string,
    fallback: number,
  ): number {
    const raw = config.get<string>(key);

    if (raw === undefined) {
      return fallback;
    }

    const value = Number(raw);

    if (!Number.isFinite(value) || value <= 0) {
      throw new Error(`${key} must be a positive number.`);
    }

    return value;
  }
}
