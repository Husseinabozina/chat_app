import { HttpStatus, Injectable } from '@nestjs/common';
import { InjectDataSource } from '@nestjs/typeorm';
import { DataSource, QueryFailedError, type EntityManager } from 'typeorm';

import { ApiException } from '../common/http/api-exception';
import {
  decodeOrderedCursor,
  encodeOrderedCursor,
} from '../common/pagination/ordered-cursor';
import {
  ConversationEntity,
  ConversationMemberEntity,
  MessageEntity,
} from '../database/entities';
import { SendMessageDto } from './dto/send-message.dto';

export interface MessageResponse {
  id: string;
  clientMessageId: string;
  conversationId: string;
  senderId: string;
  type: string;
  text: string | null;
  replyToMessageId: string | null;
  createdAt: Date;
  editedAt: Date | null;
  deletedAt: Date | null;
}

export interface MessagePage {
  items: MessageResponse[];
  nextCursor: string | null;
  hasMore: boolean;
}

@Injectable()
export class MessagesService {
  constructor(@InjectDataSource() private readonly dataSource: DataSource) {}

  async list(
    userId: string,
    conversationId: string,
    beforeValue: string | undefined,
    limit: number,
  ): Promise<MessagePage> {
    await this.requireMembership(
      this.dataSource.manager,
      userId,
      conversationId,
    );

    const before =
      beforeValue === undefined ? undefined : decodeOrderedCursor(beforeValue);
    const query = this.dataSource
      .getRepository(MessageEntity)
      .createQueryBuilder('message')
      .where('message.conversation_id = :conversationId', { conversationId })
      .orderBy('message.created_at', 'DESC')
      .addOrderBy('message.id', 'DESC')
      .take(limit + 1);

    if (before) {
      query.andWhere(
        '(message.created_at < :beforeTimestamp OR ' +
          '(message.created_at = :beforeTimestamp AND message.id < :beforeId))',
        {
          beforeTimestamp: before.timestamp,
          beforeId: before.id,
        },
      );
    }

    const rows = await query.getMany();
    const hasMore = rows.length > limit;
    const visibleRows = hasMore ? rows.slice(0, limit) : rows;
    const items = visibleRows.map((message) => this.toResponse(message));
    const lastItem = items.at(-1);

    return {
      items,
      hasMore,
      nextCursor:
        hasMore && lastItem
          ? encodeOrderedCursor(lastItem.createdAt, lastItem.id)
          : null,
    };
  }

  async send(
    userId: string,
    conversationId: string,
    dto: SendMessageDto,
  ): Promise<MessageResponse> {
    const text = dto.text.trim();

    if (text.length === 0) {
      throw new ApiException(
        HttpStatus.BAD_REQUEST,
        'VALIDATION_ERROR',
        'Message text cannot be empty.',
        { field: 'text' },
      );
    }

    try {
      return await this.dataSource.transaction(async (manager) => {
        await this.requireMembership(manager, userId, conversationId);

        const conversations = manager.getRepository(ConversationEntity);
        const messages = manager.getRepository(MessageEntity);
        const conversation = await conversations
          .createQueryBuilder('conversation')
          .where('conversation.id = :conversationId', { conversationId })
          .setLock('pessimistic_write')
          .getOne();

        if (!conversation) {
          throw this.conversationNotFound();
        }

        const existing = await messages.findOne({
          where: {
            senderId: userId,
            clientMessageId: dto.clientMessageId,
          },
        });

        if (existing) {
          if (existing.conversationId !== conversationId) {
            throw this.clientMessageIdConflict();
          }

          return this.toResponse(existing);
        }

        if (dto.replyToMessageId) {
          const replyTarget = await messages.findOne({
            where: {
              id: dto.replyToMessageId,
              conversationId,
            },
          });

          if (!replyTarget || replyTarget.deletedAt) {
            throw new ApiException(
              HttpStatus.NOT_FOUND,
              'MESSAGE_NOT_FOUND',
              'Reply target was not found.',
            );
          }
        }

        const message = await messages.save(
          messages.create({
            clientMessageId: dto.clientMessageId,
            conversationId,
            senderId: userId,
            type: 'text',
            text,
            replyToMessageId: dto.replyToMessageId ?? null,
            editedAt: null,
            deletedAt: null,
          }),
        );

        conversation.lastMessageId = message.id;
        conversation.updatedAt = message.createdAt;
        await conversations.save(conversation);

        return this.toResponse(message);
      });
    } catch (error) {
      if (!this.isUniqueViolation(error, 'uq_messages_sender_client_id')) {
        throw error;
      }

      const existing = await this.dataSource
        .getRepository(MessageEntity)
        .findOne({
          where: {
            senderId: userId,
            clientMessageId: dto.clientMessageId,
          },
        });

      if (existing?.conversationId === conversationId) {
        return this.toResponse(existing);
      }

      throw this.clientMessageIdConflict();
    }
  }

  private async requireMembership(
    manager: EntityManager,
    userId: string,
    conversationId: string,
  ): Promise<ConversationMemberEntity> {
    const membership = await manager
      .getRepository(ConversationMemberEntity)
      .findOne({
        where: {
          conversationId,
          userId,
        },
      });

    if (!membership) {
      throw this.conversationNotFound();
    }

    return membership;
  }

  private toResponse(message: MessageEntity): MessageResponse {
    return {
      id: message.id,
      clientMessageId: message.clientMessageId,
      conversationId: message.conversationId,
      senderId: message.senderId,
      type: message.type,
      text: message.text,
      replyToMessageId: message.replyToMessageId,
      createdAt: message.createdAt,
      editedAt: message.editedAt,
      deletedAt: message.deletedAt,
    };
  }

  private conversationNotFound(): ApiException {
    return new ApiException(
      HttpStatus.NOT_FOUND,
      'CONVERSATION_NOT_FOUND',
      'Conversation not found.',
    );
  }

  private clientMessageIdConflict(): ApiException {
    return new ApiException(
      HttpStatus.CONFLICT,
      'VALIDATION_ERROR',
      'clientMessageId has already been used for another message.',
      { field: 'clientMessageId' },
    );
  }

  private isUniqueViolation(error: unknown, constraint: string): boolean {
    if (!(error instanceof QueryFailedError)) {
      return false;
    }

    const driverError = error.driverError;

    return (
      typeof driverError === 'object' &&
      driverError !== null &&
      'code' in driverError &&
      driverError.code === '23505' &&
      'constraint' in driverError &&
      driverError.constraint === constraint
    );
  }
}
