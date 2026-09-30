import { HttpStatus, Inject, Injectable, Logger } from '@nestjs/common';
import { InjectDataSource } from '@nestjs/typeorm';
import { DataSource, QueryFailedError, type EntityManager } from 'typeorm';

import { ApiException } from '../common/http/api-exception';
import { ConversationsService } from '../conversations/conversations.service';
import {
  decodeOrderedCursor,
  encodeOrderedCursor,
} from '../common/pagination/ordered-cursor';
import {
  ConversationEntity,
  ConversationMemberEntity,
  MessageEntity,
} from '../database/entities';
import { RealtimePublisher } from '../realtime/realtime.publisher';
import { SendMessageDto } from './dto/send-message.dto';
import { UpdateMessageDto } from './dto/update-message.dto';

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
  private readonly logger = new Logger(MessagesService.name);

  constructor(
    @InjectDataSource()
    private readonly dataSource: DataSource,
    @Inject(ConversationsService)
    private readonly conversationsService: ConversationsService,
    @Inject(RealtimePublisher)
    private readonly realtimePublisher: RealtimePublisher,
  ) {}

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
      const result = await this.dataSource.transaction(async (manager) => {
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

          return {
            message: this.toResponse(existing),
            created: false,
          };
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

        return {
          message: this.toResponse(message),
          created: true,
        };
      });

      if (result.created) {
        await this.publishSafely(() =>
          this.publishMessageCreated(result.message),
        );
      }

      return result.message;
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
  async edit(
    userId: string,
    messageId: string,
    dto: UpdateMessageDto,
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

    const message = await this.dataSource.transaction(async (manager) => {
      const entity = await this.requireAccessibleMessage(
        manager,
        userId,
        messageId,
      );

      this.requireSender(entity, userId);

      if (entity.deletedAt) {
        throw this.messageNotFound();
      }

      entity.text = text;
      entity.editedAt = new Date();
      const saved = await manager.getRepository(MessageEntity).save(entity);

      return this.toResponse(saved);
    });

    await this.publishSafely(() => this.publishMessageUpdated(message));

    return message;
  }
  async delete(userId: string, messageId: string): Promise<void> {
    const deletedMessage = await this.dataSource.transaction(
      async (manager) => {
        const message = await this.requireAccessibleMessage(
          manager,
          userId,
          messageId,
        );

        this.requireSender(message, userId);

        if (message.deletedAt) {
          return null;
        }

        message.text = null;
        message.deletedAt = new Date();
        const saved = await manager.getRepository(MessageEntity).save(message);

        return this.toResponse(saved);
      },
    );

    if (deletedMessage) {
      await this.publishSafely(() =>
        this.publishMessageDeleted(deletedMessage),
      );
    }
  }
  private async publishMessageCreated(message: MessageResponse): Promise<void> {
    const participantUserIds =
      await this.conversationsService.getParticipantUserIds(
        message.conversationId,
      );

    this.realtimePublisher.publishMessageCreated(participantUserIds, message);

    await this.conversationsService.publishConversationSummaries(
      message.conversationId,
    );
  }

  private async publishMessageUpdated(message: MessageResponse): Promise<void> {
    const participantUserIds =
      await this.conversationsService.getParticipantUserIds(
        message.conversationId,
      );

    this.realtimePublisher.publishMessageUpdated(participantUserIds, message);

    await this.conversationsService.publishConversationSummaries(
      message.conversationId,
    );
  }

  private async publishMessageDeleted(message: MessageResponse): Promise<void> {
    const participantUserIds =
      await this.conversationsService.getParticipantUserIds(
        message.conversationId,
      );

    this.realtimePublisher.publishMessageDeleted(participantUserIds, message);

    await this.conversationsService.publishConversationSummaries(
      message.conversationId,
    );
  }

  private async publishSafely(publish: () => Promise<void>): Promise<void> {
    try {
      await publish();
    } catch (error) {
      this.logger.error(
        'Post-commit realtime publication failed.',
        error instanceof Error ? error.stack : undefined,
      );
    }
  }

  private async requireAccessibleMessage(
    manager: EntityManager,
    userId: string,
    messageId: string,
  ): Promise<MessageEntity> {
    const message = await manager
      .getRepository(MessageEntity)
      .createQueryBuilder('message')
      .where('message.id = :messageId', { messageId })
      .setLock('pessimistic_write')
      .getOne();

    if (!message) {
      throw this.messageNotFound();
    }

    const membership = await manager
      .getRepository(ConversationMemberEntity)
      .findOne({
        where: {
          conversationId: message.conversationId,
          userId,
        },
      });

    if (!membership) {
      throw this.messageNotFound();
    }

    return message;
  }

  private requireSender(message: MessageEntity, userId: string): void {
    if (message.senderId !== userId) {
      throw new ApiException(
        HttpStatus.FORBIDDEN,
        'FORBIDDEN',
        'Only the sender can modify this message.',
      );
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

  private messageNotFound(): ApiException {
    return new ApiException(
      HttpStatus.NOT_FOUND,
      'MESSAGE_NOT_FOUND',
      'Message not found.',
    );
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
