import 'reflect-metadata';

import assert from 'node:assert/strict';
import { randomUUID } from 'node:crypto';
import { after, before, test } from 'node:test';

import { type INestApplication } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';

import { AppModule } from '../dist/app.module.js';
import { configureApp } from '../dist/bootstrap/configure-app.js';
import { AppDataSource } from '../dist/database/data-source.js';

interface SessionResponse {
  accessToken: string;
  user: {
    id: string;
    email: string;
  };
}

interface SearchItem {
  id: string;
  username: string | null;
  displayName: string | null;
  avatarUrl: string | null;
}

interface SearchPage {
  items: SearchItem[];
  nextCursor: string | null;
  hasMore: boolean;
}

interface PublicProfile {
  id: string;
  username: string | null;
  displayName: string | null;
  bio: string | null;
  avatarUrl: string | null;
}

let app: INestApplication;
let baseUrl: string;
let seeker: SessionResponse;
let hussam: SessionResponse;
let hussein: SessionResponse;
let bob: SessionResponse;

before(async () => {
  await AppDataSource.initialize();
  await AppDataSource.runMigrations();
  await AppDataSource.query('TRUNCATE TABLE "users" CASCADE');
  await AppDataSource.destroy();

  app = await NestFactory.create(AppModule, { logger: false });
  configureApp(app);
  await app.listen(0, '127.0.0.1');

  const address = app.getHttpServer().address() as { port: number };
  baseUrl = `http://127.0.0.1:${address.port}/v1`;

  seeker = await register('seeker@example.com');
  hussam = await register('hussam@example.com');
  hussein = await register('hussein@example.com');
  bob = await register('bob@example.com');

  await updateProfile(seeker, {
    username: 'seeker',
    displayName: 'Search Owner',
  });
  await updateProfile(hussam, {
    username: 'hussam',
    displayName: 'Hussam',
  });
  await updateProfile(hussein, {
    username: 'hussein_dev',
    displayName: 'Hussein Abozina',
    bio: 'Flutter developer',
  });
  await updateProfile(bob, {
    username: 'bob_dev',
    displayName: 'Hussein Fan',
  });
});

after(async () => {
  await app.close();
});

test('user search is relevant, paginated, and excludes the requester', async () => {
  const firstPage = await request<SearchPage>('/users?query=huss&limit=2', {
    method: 'GET',
    accessToken: seeker.accessToken,
  });

  assert.equal(firstPage.status, 200);
  assert.equal(firstPage.body.items.length, 2);
  assert.equal(firstPage.body.hasMore, true);
  assert.ok(firstPage.body.nextCursor);
  assert.deepEqual(
    firstPage.body.items.map((item) => item.id),
    [hussam.user.id, hussein.user.id],
  );

  const secondPage = await request<SearchPage>(
    `/users?query=huss&limit=2&cursor=${encodeURIComponent(firstPage.body.nextCursor!)}`,
    {
      method: 'GET',
      accessToken: seeker.accessToken,
    },
  );

  assert.equal(secondPage.status, 200);
  assert.equal(secondPage.body.hasMore, false);
  assert.deepEqual(
    secondPage.body.items.map((item) => item.id),
    [bob.user.id],
  );

  const selfSearch = await request<SearchPage>('/users?query=seeker', {
    method: 'GET',
    accessToken: seeker.accessToken,
  });
  assert.equal(selfSearch.status, 200);
  assert.equal(selfSearch.body.items.length, 0);
});

test('public profiles expose messaging identity without private email', async () => {
  const profile = await request<PublicProfile>(`/users/${hussein.user.id}`, {
    method: 'GET',
    accessToken: seeker.accessToken,
  });

  assert.equal(profile.status, 200);
  assert.equal(profile.body.username, 'hussein_dev');
  assert.equal(profile.body.displayName, 'Hussein Abozina');
  assert.equal(profile.body.bio, 'Flutter developer');
  assert.equal('email' in (profile.body as object), false);

  const missing = await request<{ error: { code: string } }>(
    `/users/${randomUUID()}`,
    {
      method: 'GET',
      accessToken: seeker.accessToken,
    },
  );
  assert.equal(missing.status, 404);
  assert.equal(missing.body.error.code, 'USER_NOT_FOUND');
});

test('search treats wildcard characters literally and validates cursors', async () => {
  const wildcard = await request<SearchPage>('/users?query=%25', {
    method: 'GET',
    accessToken: seeker.accessToken,
  });
  assert.equal(wildcard.status, 200);
  assert.equal(wildcard.body.items.length, 0);

  const invalidCursor = await request<{ error: { code: string } }>(
    '/users?query=huss&cursor=not-a-cursor',
    {
      method: 'GET',
      accessToken: seeker.accessToken,
    },
  );
  assert.equal(invalidCursor.status, 400);
  assert.equal(invalidCursor.body.error.code, 'VALIDATION_ERROR');
});

async function register(email: string): Promise<SessionResponse> {
  const response = await request<SessionResponse>('/auth/register', {
    method: 'POST',
    body: {
      email,
      password: 'password-12345',
    },
  });

  assert.equal(response.status, 201);
  return response.body;
}

async function updateProfile(
  session: SessionResponse,
  body: Record<string, unknown>,
): Promise<void> {
  const response = await request<unknown>('/users/me', {
    method: 'PATCH',
    accessToken: session.accessToken,
    body,
  });

  assert.equal(response.status, 200);
}

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
    body: options.body === undefined ? undefined : JSON.stringify(options.body),
  });
  const text = await response.text();
  const body = text.length === 0 ? undefined : JSON.parse(text);

  return {
    status: response.status,
    body: body as T,
  };
}
