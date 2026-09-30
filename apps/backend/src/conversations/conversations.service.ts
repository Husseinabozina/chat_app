import { HttpStatus, Injectable } from '@nestjs/common';
import { InjectDataSource } from '@nestjs/typeorm';
import { DataSource, QueryFailedError } from 'typeorm';

import { ApiException } from '../common/http/api-exception';
import {
  decodeOrderedCursor,
  encodeOrderedCursor,
  type OrderedCursor,
} from '../common/pagination/ordered-cursor';
import {
  ConversationEntity,
  ConversationMemberEntity,
  UserEntity,
} from '../database/entities';

export interface ConversationUserSummary {
  id: string;
  username: string | null;
  displayName: string | null;
  avatarUrl: string | null;
}

export interface ConversationLastMessageSummary {
  id: string;
  senderId: string;
  type: string;
  text: string | null;
  createdAt: Date;
  deletedAt: Date | null;
}

export interface ConversationSummary {
  id: string;
  type: 'direct';
  otherUser: ConversationUserSummary;
  lastMessage: ConversationLastMessageSummary | null;
  unreadCount: number;
  updatedAt: Date;
}

export interface ConversationPage {
  items: ConversationSummary[];
  nextCursor: string | null;
  hasMore: boolean;
}

interface ConversationSummaryRow {
  id: string;
  type: string;
  updated_at: Date | string;
  other_user_id: string;
  other_username: string | null;
  other_display_name: string | null;
  other_avatar_url: string | null;
  last_message_id: string | null;
  last_message_sender_id: string | null;
  last_message_type: string | null;
  last_message_text: string | null;
  last_message_created_at: Date | string | null;
  last_message_deleted_at: Date | string | null;
  unread_count: number | string;
}

@Injectable()
export class ConversationsService {
  constructor(@InjectDataSource() private readonly dataSource: DataSource) {}

  async createOrResolveDirect(
    userId: string,
    targetUserId: string,
  ): Promise<ConversationSummary> {
    if (userId === targetUserId) {
      throw new ApiException(
        HttpStatus.BAD_REQUEST,
        'VALIDATION_ERROR',
        'A direct conversation requires another user.',
        { field: 'userId' },
      );
    }

    const target = await this.dataSource.getRepository(UserEntity).findOne({
      where: { id: targetUserId },
    });

    if (!target) {
      throw new ApiException(
        HttpStatus.NOT_FOUND,
        'USER_NOT_FOUND',
        'User not found.',
      );
    }

    const directKey = this.directKey(userId, targetUserId);
    const existing = await this.dataSource
      .getRepository(ConversationEntity)
      .findOne({ where: { type: 'direct', directKey } });

    if (existing) {
      return this.getSummary(userId, existing.id);
    }

    try {
      const conversationId = await this.dataSource.transaction(
        async (manager) => {
          const conversations = manager.getRepository(ConversationEntity);
          const members = manager.getRepository(ConversationMemberEntity);
          const now = new Date();
          const conversation = await conversations.save(
            conversations.create({
              type: 'direct',
              directKey,
              lastMessageId: null,
            }),
          );

          await members.save([
            members.create({
              conversationId: conversation.id,
              userId,
              joinedAt: now,
              lastReadMessageId: null,
              lastReadAt: null,
              mutedUntil: null,
            }),
            members.create({
              conversationId: conversation.id,
              userId: targetUserId,
              joinedAt: now,
              lastReadMessageId: null,
              lastReadAt: null,
              mutedUntil: null,
            }),
          ]);

          return conversation.id;
        },
      );

      return this.getSummary(userId, conversationId);
    } catch (error) {
      if (!this.isUniqueViolation(error, 'uq_conversations_direct_key')) {
        throw error;
      }

      const racedConversation = await this.dataSource
        .getRepository(ConversationEntity)
        .findOne({ where: { type: 'direct', directKey } });

      if (!racedConversation) {
        throw error;
      }

      return this.getSummary(userId, racedConversation.id);
    }
  }

  async list(
    userId: string,
    cursorValue: string | undefined,
    limit: number,
  ): Promise<ConversationPage> {
    const cursor =
      cursorValue === undefined ? undefined : decodeOrderedCursor(cursorValue);
    const rows = await this.querySummaryRows(userId, {
      cursor,
      limit: limit + 1,
    });
    const hasMore = rows.length > limit;
    const visibleRows = hasMore ? rows.slice(0, limit) : rows;
    const items = visibleRows.map((row) => this.toSummary(row));
    const lastItem = items.at(-1);

    return {
      items,
      hasMore,
      nextCursor:
        hasMore && lastItem
          ? encodeOrderedCursor(lastItem.updatedAt, lastItem.id)
          : null,
    };
  }

  private async getSummary(
    userId: string,
    conversationId: string,
  ): Promise<ConversationSummary> {
    const rows = await this.querySummaryRows(userId, {
      conversationId,
      limit: 1,
    });
    const row = rows[0];

    if (!row) {
      throw new ApiException(
        HttpStatus.NOT_FOUND,
        'CONVERSATION_NOT_FOUND',
        'Conversation not found.',
      );
    }

    return this.toSummary(row);
  }

  private async querySummaryRows(
    userId: string,
    options: {
      conversationId?: string;
      cursor?: OrderedCursor;
      limit: number;
    },
  ): Promise<ConversationSummaryRow[]> {
    const parameters: unknown[] = [userId];
    const conditions = [
      'self_member.user_id = $1',
      "conversation.type = 'direct'",
    ];
    const addParameter = (value: unknown): string => {
      parameters.push(value);
      return `$${parameters.length}`;
    };

    if (options.conversationId) {
      const parameter = addParameter(options.conversationId);
      conditions.push(`conversation.id = ${parameter}`);
    }

    if (options.cursor) {
      const timestampParameter = addParameter(options.cursor.timestamp);
      const idParameter = addParameter(options.cursor.id);
      conditions.push(
        `(conversation.updated_at < ${timestampParameter} OR ` +
          `(conversation.updated_at = ${timestampParameter} AND ` +
          `conversation.id < ${idParameter}))`,
      );
    }

    const limitParameter = addParameter(options.limit);

    return this.dataSource.query<ConversationSummaryRow[]>(
      `
        SELECT
          conversation.id,
          conversation.type,
          conversation.updated_at,
          other_user.id AS other_user_id,
          other_user.username AS other_username,
          other_user.display_name AS other_display_name,
          other_user.avatar_url AS other_avatar_url,
          last_message.id AS last_message_id,
          last_message.sender_id AS last_message_sender_id,
          last_message.type AS last_message_type,
          last_message.text AS last_message_text,
          last_message.created_at AS last_message_created_at,
          last_message.deleted_at AS last_message_deleted_at,
          COALESCE(unread_stats.unread_count, 0) AS unread_count
        FROM conversation_members self_member
        JOIN conversations conversation
          ON conversation.id = self_member.conversation_id
        JOIN conversation_members other_member
          ON other_member.conversation_id = conversation.id
          AND other_member.user_id <> $1
        JOIN users other_user
          ON other_user.id = other_member.user_id
        LEFT JOIN messages last_message
          ON last_message.id = conversation.last_message_id
        LEFT JOIN messages read_message
          ON read_message.id = self_member.last_read_message_id
        LEFT JOIN LATERAL (
          SELECT COUNT(*)::int AS unread_count
          FROM messages unread_message
          WHERE unread_message.conversation_id = conversation.id
            AND unread_message.sender_id <> $1
            AND unread_message.deleted_at IS NULL
            AND (
              read_message.id IS NULL
              OR unread_message.created_at > read_message.created_at
              OR (
                unread_message.created_at = read_message.created_at
                AND unread_message.id > read_message.id
              )
            )
        ) unread_stats ON TRUE
        WHERE ${conditions.join('\n          AND ')}
        ORDER BY conversation.updated_at DESC, conversation.id DESC
        LIMIT ${limitParameter}
      `,
      parameters,
    );
  }

  private toSummary(row: ConversationSummaryRow): ConversationSummary {
    let lastMessage: ConversationLastMessageSummary | null = null;

    if (
      row.last_message_id &&
      row.last_message_sender_id &&
      row.last_message_type &&
      row.last_message_created_at
    ) {
      lastMessage = {
        id: row.last_message_id,
        senderId: row.last_message_sender_id,
        type: row.last_message_type,
        text: row.last_message_text,
        createdAt: new Date(row.last_message_created_at),
        deletedAt: row.last_message_deleted_at
          ? new Date(row.last_message_deleted_at)
          : null,
      };
    }

    return {
      id: row.id,
      type: 'direct',
      otherUser: {
        id: row.other_user_id,
        username: row.other_username,
        displayName: row.other_display_name,
        avatarUrl: row.other_avatar_url,
      },
      lastMessage,
      unreadCount: Number(row.unread_count),
      updatedAt: new Date(row.updated_at),
    };
  }

  private directKey(firstUserId: string, secondUserId: string): string {
    return [firstUserId, secondUserId].sort().join(':');
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
