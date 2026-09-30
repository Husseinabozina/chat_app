import { HttpStatus, Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { QueryFailedError, Repository } from 'typeorm';

import { ApiException } from '../common/http/api-exception';
import { UserEntity } from '../database/entities';
import { UpdateProfileDto } from './dto/update-profile.dto';
import {
  decodeUserSearchCursor,
  encodeUserSearchCursor,
} from './user-search-cursor';

export interface PublicUser {
  id: string;
  email: string;
  username: string | null;
  displayName: string | null;
  bio: string | null;
  avatarUrl: string | null;
  createdAt: Date;
  updatedAt: Date;
}

export interface DiscoverableUser {
  id: string;
  username: string | null;
  displayName: string | null;
  bio: string | null;
  avatarUrl: string | null;
}

export interface UserSearchItem {
  id: string;
  username: string | null;
  displayName: string | null;
  avatarUrl: string | null;
}

export interface UserSearchPage {
  items: UserSearchItem[];
  nextCursor: string | null;
  hasMore: boolean;
}

interface UserSearchRow {
  id: string;
  username: string | null;
  display_name: string | null;
  avatar_url: string | null;
  search_rank: number | string;
  sort_text: string;
}

@Injectable()
export class UsersService {
  constructor(
    @InjectRepository(UserEntity)
    private readonly users: Repository<UserEntity>,
  ) {}

  async getById(userId: string): Promise<UserEntity> {
    const user = await this.users.findOne({ where: { id: userId } });

    if (!user) {
      throw new ApiException(
        HttpStatus.NOT_FOUND,
        'USER_NOT_FOUND',
        'User not found.',
      );
    }

    return user;
  }

  async getPublicProfile(userId: string): Promise<DiscoverableUser> {
    return this.toDiscoverableUser(await this.getById(userId));
  }

  async search(
    requesterId: string,
    queryValue: string,
    cursorValue: string | undefined,
    limit: number,
  ): Promise<UserSearchPage> {
    const normalizedQuery = queryValue.trim().toLowerCase();

    if (normalizedQuery.length === 0) {
      throw new ApiException(
        HttpStatus.BAD_REQUEST,
        'VALIDATION_ERROR',
        'Search query cannot be empty.',
        { field: 'query' },
      );
    }

    const escapedQuery = this.escapeLike(normalizedQuery);
    const prefixPattern = `${escapedQuery}%`;
    const containsPattern = `%${escapedQuery}%`;
    const cursor =
      cursorValue === undefined
        ? undefined
        : decodeUserSearchCursor(cursorValue);
    const parameters: unknown[] = [
      requesterId,
      normalizedQuery,
      prefixPattern,
      containsPattern,
    ];
    const addParameter = (value: unknown): string => {
      parameters.push(value);
      return String.fromCharCode(36) + parameters.length;
    };
    let cursorClause = '';

    if (cursor) {
      const rankParameter = addParameter(cursor.rank);
      const sortParameter = addParameter(cursor.sortText);
      const idParameter = addParameter(cursor.id);
      cursorClause = `
        WHERE (
          search_rank > ${rankParameter}
          OR (
            search_rank = ${rankParameter}
            AND sort_text > ${sortParameter}
          )
          OR (
            search_rank = ${rankParameter}
            AND sort_text = ${sortParameter}
            AND id > ${idParameter}
          )
        )
      `;
    }

    const limitParameter = addParameter(limit + 1);
    const rows = await this.users.manager.query<UserSearchRow[]>(
      `
        WITH ranked_users AS (
          SELECT
            "id",
            "username",
            "display_name",
            "avatar_url",
            CASE
              WHEN lower("username") = $2 THEN 0
              WHEN lower("username") LIKE $3 ESCAPE '!' THEN 1
              WHEN lower("display_name") LIKE $3 ESCAPE '!' THEN 2
              ELSE 3
            END AS search_rank,
            lower(COALESCE("username", "display_name", '')) AS sort_text
          FROM "users"
          WHERE "id" <> $1
            AND (
              lower("username") LIKE $4 ESCAPE '!'
              OR lower("display_name") LIKE $4 ESCAPE '!'
            )
        )
        SELECT
          "id",
          "username",
          "display_name",
          "avatar_url",
          search_rank,
          sort_text
        FROM ranked_users
        ${cursorClause}
        ORDER BY search_rank ASC, sort_text ASC, id ASC
        LIMIT ${limitParameter}
      `,
      parameters,
    );
    const hasMore = rows.length > limit;
    const visibleRows = hasMore ? rows.slice(0, limit) : rows;
    const items = visibleRows.map((row) => ({
      id: row.id,
      username: row.username,
      displayName: row.display_name,
      avatarUrl: row.avatar_url,
    }));
    const lastRow = visibleRows.at(-1);

    return {
      items,
      hasMore,
      nextCursor:
        hasMore && lastRow
          ? encodeUserSearchCursor({
              rank: Number(lastRow.search_rank),
              sortText: lastRow.sort_text,
              id: lastRow.id,
            })
          : null,
    };
  }

  async updateProfile(
    userId: string,
    dto: UpdateProfileDto,
  ): Promise<PublicUser> {
    const user = await this.getById(userId);

    if (dto.username !== undefined) {
      user.username = dto.username.trim();
    }

    if (dto.displayName !== undefined) {
      user.displayName = dto.displayName.trim();
    }

    if (dto.bio !== undefined) {
      user.bio = dto.bio.trim();
    }

    try {
      return this.toPublicUser(await this.users.save(user));
    } catch (error) {
      if (this.isUniqueViolation(error, 'uq_users_username_ci')) {
        throw new ApiException(
          HttpStatus.CONFLICT,
          'USERNAME_TAKEN',
          'Username is already in use.',
        );
      }

      throw error;
    }
  }

  toPublicUser(user: UserEntity): PublicUser {
    return {
      id: user.id,
      email: user.email,
      username: user.username,
      displayName: user.displayName,
      bio: user.bio,
      avatarUrl: user.avatarUrl,
      createdAt: user.createdAt,
      updatedAt: user.updatedAt,
    };
  }

  private toDiscoverableUser(user: UserEntity): DiscoverableUser {
    return {
      id: user.id,
      username: user.username,
      displayName: user.displayName,
      bio: user.bio,
      avatarUrl: user.avatarUrl,
    };
  }

  private escapeLike(value: string): string {
    return value.replace(/[!%_]/g, (match) => `!${match}`);
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
 + parameters.length;
    };
    let cursorClause = '';

    if (cursor) {
      const rankParameter = addParameter(cursor.rank);
      const sortParameter = addParameter(cursor.sortText);
      const idParameter = addParameter(cursor.id);
      cursorClause = `
        WHERE (
          search_rank > ${rankParameter}
          OR (
            search_rank = ${rankParameter}
            AND sort_text > ${sortParameter}
          )
          OR (
            search_rank = ${rankParameter}
            AND sort_text = ${sortParameter}
            AND id > ${idParameter}
          )
        )
      `;
    }

    const limitParameter = addParameter(limit + 1);
    const rows = await this.users.manager.query<UserSearchRow[]>(
      `
        WITH ranked_users AS (
          SELECT
            "id",
            "username",
            "display_name",
            "avatar_url",
            CASE
              WHEN lower("username") = $2 THEN 0
              WHEN lower("username") LIKE $3 ESCAPE '!' THEN 1
              WHEN lower("display_name") LIKE $3 ESCAPE '!' THEN 2
              ELSE 3
            END AS search_rank,
            lower(COALESCE("username", "display_name", '')) AS sort_text
          FROM "users"
          WHERE "id" <> $1
            AND (
              lower("username") LIKE $4 ESCAPE '!'
              OR lower("display_name") LIKE $4 ESCAPE '!'
            )
        )
        SELECT
          "id",
          "username",
          "display_name",
          "avatar_url",
          search_rank,
          sort_text
        FROM ranked_users
        ${cursorClause}
        ORDER BY search_rank ASC, sort_text ASC, id ASC
        LIMIT ${limitParameter}
      `,
      parameters,
    );
    const hasMore = rows.length > limit;
    const visibleRows = hasMore ? rows.slice(0, limit) : rows;
    const items = visibleRows.map((row) => ({
      id: row.id,
      username: row.username,
      displayName: row.display_name,
      avatarUrl: row.avatar_url,
    }));
    const lastRow = visibleRows.at(-1);

    return {
      items,
      hasMore,
      nextCursor:
        hasMore && lastRow
          ? encodeUserSearchCursor({
              rank: Number(lastRow.search_rank),
              sortText: lastRow.sort_text,
              id: lastRow.id,
            })
          : null,
    };
  }

  async updateProfile(
    userId: string,
    dto: UpdateProfileDto,
  ): Promise<PublicUser> {
    const user = await this.getById(userId);

    if (dto.username !== undefined) {
      user.username = dto.username.trim();
    }

    if (dto.displayName !== undefined) {
      user.displayName = dto.displayName.trim();
    }

    if (dto.bio !== undefined) {
      user.bio = dto.bio.trim();
    }

    try {
      return this.toPublicUser(await this.users.save(user));
    } catch (error) {
      if (this.isUniqueViolation(error, 'uq_users_username_ci')) {
        throw new ApiException(
          HttpStatus.CONFLICT,
          'USERNAME_TAKEN',
          'Username is already in use.',
        );
      }

      throw error;
    }
  }

  toPublicUser(user: UserEntity): PublicUser {
    return {
      id: user.id,
      email: user.email,
      username: user.username,
      displayName: user.displayName,
      bio: user.bio,
      avatarUrl: user.avatarUrl,
      createdAt: user.createdAt,
      updatedAt: user.updatedAt,
    };
  }

  private toDiscoverableUser(user: UserEntity): DiscoverableUser {
    return {
      id: user.id,
      username: user.username,
      displayName: user.displayName,
      bio: user.bio,
      avatarUrl: user.avatarUrl,
    };
  }

  private escapeLike(value: string): string {
    return value.replace(/[!%_]/g, (match) => `!${match}`);
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
