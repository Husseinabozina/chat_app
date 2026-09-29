import { createHash, randomBytes } from 'node:crypto';

import { HttpStatus, Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import * as argon2 from 'argon2';
import {
  DataSource,
  IsNull,
  QueryFailedError,
  Repository,
} from 'typeorm';

import { ApiException } from '../common/http/api-exception';
import {
  RefreshSessionEntity,
  UserEntity,
} from '../database/entities';
import { LoginDto } from './dto/login.dto';
import { RegisterDto } from './dto/register.dto';

export interface AuthUserResponse {
  id: string;
  email: string;
  username: string | null;
  displayName: string | null;
  bio: string | null;
  avatarUrl: string | null;
}

export interface AuthSessionResponse {
  accessToken: string;
  refreshToken: string;
  expiresIn: number;
  user: AuthUserResponse;
}

interface SessionMaterial {
  user: UserEntity;
  session: RefreshSessionEntity;
  refreshToken: string;
}

@Injectable()
export class AuthService {
  private readonly accessTokenTtlSeconds: number;
  private readonly refreshTokenTtlDays: number;

  constructor(
    private readonly dataSource: DataSource,
    private readonly jwtService: JwtService,
    private readonly config: ConfigService,
  ) {
    this.accessTokenTtlSeconds = this.readPositiveNumber(
      'ACCESS_TOKEN_TTL_SECONDS',
      900,
    );
    this.refreshTokenTtlDays = this.readPositiveNumber(
      'REFRESH_TOKEN_TTL_DAYS',
      30,
    );
  }

  async register(dto: RegisterDto): Promise<AuthSessionResponse> {
    const email = this.normalizeEmail(dto.email);
    const users = this.dataSource.getRepository(UserEntity);

    const existing = await users
      .createQueryBuilder('user')
      .where('LOWER(user.email) = :email', { email })
      .getOne();

    if (existing) {
      throw new ApiException(
        HttpStatus.CONFLICT,
        'EMAIL_TAKEN',
        'An account already exists for that email address.',
      );
    }

    const passwordHash = await argon2.hash(dto.password, {
      type: argon2.argon2id,
    });
    const refreshToken = this.createRefreshToken();
    const refreshTokenHash = this.hashRefreshToken(refreshToken);

    try {
      const material = await this.dataSource.transaction(async (manager) => {
        const transactionUsers = manager.getRepository(UserEntity);
        const sessions = manager.getRepository(RefreshSessionEntity);

        const user = await transactionUsers.save(
          transactionUsers.create({
            email,
            username: null,
            displayName: null,
            bio: null,
            avatarUrl: null,
            passwordHash,
          }),
        );

        const session = await sessions.save(
          sessions.create({
            userId: user.id,
            tokenHash: refreshTokenHash,
            expiresAt: this.refreshExpiry(),
            revokedAt: null,
            deviceMetadata: null,
          }),
        );

        return { user, session, refreshToken };
      });

      return this.toSessionResponse(material);
    } catch (error) {
      if (this.isUniqueViolation(error, 'uq_users_email_ci')) {
        throw new ApiException(
          HttpStatus.CONFLICT,
          'EMAIL_TAKEN',
          'An account already exists for that email address.',
        );
      }

      throw error;
    }
  }

  async login(dto: LoginDto): Promise<AuthSessionResponse> {
    const email = this.normalizeEmail(dto.email);

    const user = await this.dataSource
      .getRepository(UserEntity)
      .createQueryBuilder('user')
      .addSelect('user.passwordHash')
      .where('LOWER(user.email) = :email', { email })
      .getOne();

    if (!user || !(await argon2.verify(user.passwordHash, dto.password))) {
      throw new ApiException(
        HttpStatus.UNAUTHORIZED,
        'INVALID_CREDENTIALS',
        'Email or password is incorrect.',
      );
    }

    const refreshToken = this.createRefreshToken();
    const session = await this.createSession(
      this.dataSource.getRepository(RefreshSessionEntity),
      user.id,
      refreshToken,
    );

    return this.toSessionResponse({ user, session, refreshToken });
  }

  async refresh(refreshToken: string): Promise<AuthSessionResponse> {
    const tokenHash = this.hashRefreshToken(refreshToken);
    const nextRefreshToken = this.createRefreshToken();

    const material = await this.dataSource.transaction(async (manager) => {
      const sessions = manager.getRepository(RefreshSessionEntity);
      const users = manager.getRepository(UserEntity);

      const session = await sessions
        .createQueryBuilder('session')
        .where('session.tokenHash = :tokenHash', { tokenHash })
        .setLock('pessimistic_write')
        .getOne();

      const now = Date.now();

      if (
        !session ||
        session.revokedAt !== null ||
        session.expiresAt.getTime() <= now
      ) {
        throw new ApiException(
          HttpStatus.UNAUTHORIZED,
          'TOKEN_EXPIRED',
          'Refresh token is invalid or expired.',
        );
      }

      const user = await users.findOne({ where: { id: session.userId } });

      if (!user) {
        session.revokedAt = new Date();
        await sessions.save(session);

        throw new ApiException(
          HttpStatus.UNAUTHORIZED,
          'TOKEN_EXPIRED',
          'Refresh token is invalid or expired.',
        );
      }

      session.tokenHash = this.hashRefreshToken(nextRefreshToken);
      session.expiresAt = this.refreshExpiry();
      session.revokedAt = null;

      await sessions.save(session);

      return {
        user,
        session,
        refreshToken: nextRefreshToken,
      };
    });

    return this.toSessionResponse(material);
  }

  async logout(refreshToken: string): Promise<void> {
    const tokenHash = this.hashRefreshToken(refreshToken);

    await this.dataSource.getRepository(RefreshSessionEntity).update(
      {
        tokenHash,
        revokedAt: IsNull(),
      },
      {
        revokedAt: new Date(),
      },
    );
  }

  private async createSession(
    sessions: Repository<RefreshSessionEntity>,
    userId: string,
    refreshToken: string,
  ): Promise<RefreshSessionEntity> {
    return sessions.save(
      sessions.create({
        userId,
        tokenHash: this.hashRefreshToken(refreshToken),
        expiresAt: this.refreshExpiry(),
        revokedAt: null,
        deviceMetadata: null,
      }),
    );
  }

  private async toSessionResponse(
    material: SessionMaterial,
  ): Promise<AuthSessionResponse> {
    const accessToken = await this.jwtService.signAsync(
      {
        sub: material.user.id,
        sid: material.session.id,
        typ: 'access',
      },
      {
        expiresIn: this.accessTokenTtlSeconds,
      },
    );

    return {
      accessToken,
      refreshToken: material.refreshToken,
      expiresIn: this.accessTokenTtlSeconds,
      user: this.toAuthUser(material.user),
    };
  }

  private toAuthUser(user: UserEntity): AuthUserResponse {
    return {
      id: user.id,
      email: user.email,
      username: user.username,
      displayName: user.displayName,
      bio: user.bio,
      avatarUrl: user.avatarUrl,
    };
  }

  private normalizeEmail(email: string): string {
    return email.trim().toLowerCase();
  }

  private createRefreshToken(): string {
    return randomBytes(48).toString('base64url');
  }

  private hashRefreshToken(token: string): string {
    return createHash('sha256').update(token).digest('hex');
  }

  private refreshExpiry(): Date {
    const milliseconds = this.refreshTokenTtlDays * 24 * 60 * 60 * 1000;
    return new Date(Date.now() + milliseconds);
  }

  private readPositiveNumber(key: string, fallback: number): number {
    const raw = this.config.get<string>(key);

    if (raw === undefined) {
      return fallback;
    }

    const value = Number(raw);

    if (!Number.isFinite(value) || value <= 0) {
      throw new Error(`${key} must be a positive number.`);
    }

    return value;
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
