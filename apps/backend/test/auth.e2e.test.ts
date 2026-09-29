import 'reflect-metadata';

import assert from 'node:assert/strict';
import { after, before, test } from 'node:test';

import { type INestApplication } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';

import { AppModule } from '../dist/app.module.js';
import { configureApp } from '../dist/bootstrap/configure-app.js';
import { AppDataSource } from '../dist/database/data-source.js';

interface SessionResponse {
  accessToken: string;
  refreshToken: string;
  expiresIn: number;
  user: {
    id: string;
    email: string;
    username: string | null;
  };
}

let app: INestApplication;
let baseUrl: string;

before(async () => {
  await AppDataSource.initialize();
  await AppDataSource.runMigrations();
  await AppDataSource.query('TRUNCATE TABLE "users" CASCADE');
  await AppDataSource.destroy();

  app = await NestFactory.create(AppModule, { logger: false });
  configureApp(app);
  await app.listen(0, '127.0.0.1');

  const address = app.getHttpServer().address() as {
    port: number;
  };

  baseUrl = `http://127.0.0.1:${address.port}/v1`;
});

after(async () => {
  await app.close();
});

test('auth lifecycle rotates refresh tokens and protects profile routes', async () => {
  const unauthenticated = await request<unknown>('/users/me', {
    method: 'GET',
  });
  assert.equal(unauthenticated.status, 401);

  const register = await request<SessionResponse>('/auth/register', {
    method: 'POST',
    body: {
      email: 'User@Example.com',
      password: 'correct-horse-battery-staple',
    },
  });

  assert.equal(register.status, 201);
  assert.equal(register.body.user.email, 'user@example.com');
  assert.equal(register.body.user.username, null);
  assert.ok(register.body.accessToken);
  assert.ok(register.body.refreshToken);

  const profile = await request<{ username: string | null }>('/users/me', {
    method: 'PATCH',
    accessToken: register.body.accessToken,
    body: {
      username: 'hussein_dev',
      displayName: 'Hussein',
      bio: 'Flutter developer',
    },
  });

  assert.equal(profile.status, 200);
  assert.equal(profile.body.username, 'hussein_dev');

  const refresh = await request<SessionResponse>('/auth/refresh', {
    method: 'POST',
    body: {
      refreshToken: register.body.refreshToken,
    },
  });

  assert.equal(refresh.status, 200);
  assert.notEqual(refresh.body.refreshToken, register.body.refreshToken);

  const reusedOldToken = await request<unknown>('/auth/refresh', {
    method: 'POST',
    body: {
      refreshToken: register.body.refreshToken,
    },
  });
  assert.equal(reusedOldToken.status, 401);

  const me = await request<{ username: string | null }>('/users/me', {
    method: 'GET',
    accessToken: refresh.body.accessToken,
  });
  assert.equal(me.status, 200);
  assert.equal(me.body.username, 'hussein_dev');

  const logout = await request<unknown>('/auth/logout', {
    method: 'POST',
    body: {
      refreshToken: refresh.body.refreshToken,
    },
  });
  assert.equal(logout.status, 204);

  const afterLogout = await request<unknown>('/auth/refresh', {
    method: 'POST',
    body: {
      refreshToken: refresh.body.refreshToken,
    },
  });
  assert.equal(afterLogout.status, 401);
});

test('registration and profile uniqueness return stable error codes', async () => {
  const first = await request<SessionResponse>('/auth/register', {
    method: 'POST',
    body: {
      email: 'duplicate@example.com',
      password: 'password-12345',
    },
  });
  assert.equal(first.status, 201);

  const duplicate = await request<{
    error: {
      code: string;
    };
  }>('/auth/register', {
    method: 'POST',
    body: {
      email: 'DUPLICATE@example.com',
      password: 'password-12345',
    },
  });

  assert.equal(duplicate.status, 409);
  assert.equal(duplicate.body.error.code, 'EMAIL_TAKEN');

  const second = await request<SessionResponse>('/auth/register', {
    method: 'POST',
    body: {
      email: 'second@example.com',
      password: 'password-12345',
    },
  });

  const firstProfile = await request<unknown>('/users/me', {
    method: 'PATCH',
    accessToken: first.body.accessToken,
    body: {
      username: 'Unique_Name',
    },
  });
  assert.equal(firstProfile.status, 200);

  const duplicateUsername = await request<{
    error: {
      code: string;
    };
  }>('/users/me', {
    method: 'PATCH',
    accessToken: second.body.accessToken,
    body: {
      username: 'unique_name',
    },
  });

  assert.equal(duplicateUsername.status, 409);
  assert.equal(duplicateUsername.body.error.code, 'USERNAME_TAKEN');
});

test('validation errors use the stable API error envelope', async () => {
  const invalid = await request<{
    error: {
      code: string;
    };
  }>('/auth/register', {
    method: 'POST',
    body: {
      email: 'not-an-email',
      password: 'short',
    },
  });

  assert.equal(invalid.status, 400);
  assert.equal(invalid.body.error.code, 'VALIDATION_ERROR');
});

async function request<T>(
  path: string,
  options: {
    method: 'GET' | 'POST' | 'PATCH';
    accessToken?: string;
    body?: Record<string, unknown>;
  },
): Promise<{ status: number; body: T }> {
  const headers: Record<string, string> = {};

  if (options.body !== undefined) {
    headers['content-type'] = 'application/json';
  }

  if (options.accessToken) {
    headers.authorization = `Bearer ${options.accessToken}`;
  }

  const response = await fetch(`${baseUrl}${path}`, {
    method: options.method,
    headers,
    body:
      options.body === undefined ? undefined : JSON.stringify(options.body),
  });

  const text = await response.text();
  const body = text.length === 0 ? undefined : JSON.parse(text);

  return {
    status: response.status,
    body: body as T,
  };
}
