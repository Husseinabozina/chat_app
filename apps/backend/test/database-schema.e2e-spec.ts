import 'reflect-metadata';

import type { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { DataSource } from 'typeorm';

import { AppModule } from '../src/app.module';
import { RefreshSessionEntity } from '../src/auth/entities/refresh-session.entity';
import { configureApp } from '../src/bootstrap/configure-app';
import { UserEntity } from '../src/users/entities/user.entity';

describe('Identity persistence schema', () => {
  let app: INestApplication;
  let dataSource: DataSource;

  beforeAll(async () => {
    const moduleRef = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleRef.createNestApplication();
    configureApp(app);
    await app.init();

    dataSource = app.get(DataSource);
    await dataSource.runMigrations();

    await dataSource.query(
      'DELETE FROM "users" WHERE "email_normalized" LIKE $1',
      ['schema-test-%'],
    );
  });

  afterAll(async () => {
    await app.close();
  });

  it('creates the users and refresh_sessions tables through migrations', async () => {
    const rows = (await dataSource.query(
      `
        SELECT table_name
        FROM information_schema.tables
        WHERE table_schema = 'public'
          AND table_name IN ('users', 'refresh_sessions')
        ORDER BY table_name
      `,
    )) as Array<{ table_name: string }>;

    expect(rows.map((row) => row.table_name)).toEqual([
      'refresh_sessions',
      'users',
    ]);
  });

  it('enforces normalized email uniqueness at the database level', async () => {
    const users = dataSource.getRepository(UserEntity);

    const firstUser = users.create({
      email: 'Schema-Test-One@example.com',
      emailNormalized: 'schema-test-one@example.com',
      passwordHash: 'test-password-hash',
      displayName: null,
      username: null,
      usernameNormalized: null,
      bio: null,
      avatarStorageKey: null,
    });

    await users.save(firstUser);

    const duplicate = users.create({
      email: 'schema-test-one@example.com',
      emailNormalized: 'schema-test-one@example.com',
      passwordHash: 'another-test-password-hash',
      displayName: null,
      username: null,
      usernameNormalized: null,
      bio: null,
      avatarStorageKey: null,
    });

    await expect(users.save(duplicate)).rejects.toThrow();
  });

  it('cascades refresh sessions when their user is deleted', async () => {
    const users = dataSource.getRepository(UserEntity);
    const sessions = dataSource.getRepository(RefreshSessionEntity);

    const user = await users.save(
      users.create({
        email: 'Schema-Test-Session@example.com',
        emailNormalized: 'schema-test-session@example.com',
        passwordHash: 'test-password-hash',
        displayName: null,
        username: null,
        usernameNormalized: null,
        bio: null,
        avatarStorageKey: null,
      }),
    );

    const session = await sessions.save(
      sessions.create({
        userId: user.id,
        user,
        tokenHash: 'a'.repeat(64),
        expiresAt: new Date(Date.now() + 86_400_000),
        revokedAt: null,
        deviceMetadata: {
          platform: 'test',
        },
      }),
    );

    await users.remove(user);

    expect(await sessions.countBy({ id: session.id })).toBe(0);
  });
});
