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
  refreshToken: string;
  user: {
    id: string;
    email: string;
  };
}

interface ConversationSummary {
  id: string;
  otherUser: {
    id: string;
  };
  lastMessage: {
    id: string;
    text: string | null;
  } | null;
  unreadCount: number;
  updatedAt: string;
}

interface ConversationPage {
  items: ConversationSummary[];
  nextCursor: string | null;
  hasMore: boolean;
}

interface MessageResponse {
  id: string;
  clientMessageId: string;
  conversationId: string;
  senderId: string;
  text: string | null;
  replyToMessageId: string | null;
  createdAt: string;
}

interface MessagePage {
  items: MessageResponse[];
  nextCursor: string | null;
  hasMore: boolean;
}

let app: INestApplication;
let baseUrl: string;
let alice: SessionResponse;
let bob: SessionResponse;
let eve: SessionResponse;
let conversationId: string;

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

  alice = await register('alice@example.com');
  bob = await register('bob@example.com');
  eve = await register('eve@example.com');

  const direct = await request<ConversationSummary>('/conversations/direct', {
    method: 'POST',
    accessToken: alice.accessToken,
    body: { userId: bob.user.id },
  });
  assert.equal(direct.status, 200);
  conversationId = direct.body.id;
});

after(async () => {
  await app.close();
});

test('direct conversations resolve idempotently and validate participants', async () => {
  const duplicate = await request<ConversationSummary>('/conversations/direct', {
    method: 'POST',
    accessToken: bob.accessToken,
    body: { userId: alice.user.id },
  });

  assert.equal(duplicate.status, 200);
  assert.equal(duplicate.body.id, conversationId);

  const self = await request<{ error: { code: string } }>(
    '/conversations/direct',
    {
      method: 'POST',
      accessToken: alice.accessToken,
      body: { userId: alice.user.id },
    },
  );
  assert.equal(self.status, 400);
  assert.equal(self.body.error.code, 'VALIDATION_ERROR');

  const missing = await request<{ error: { code: string } }>(
    '/conversations/direct',
    {
      method: 'POST',
      accessToken: alice.accessToken,
      body: { userId: randomUUID() },
    },
  );
  assert.equal(missing.status, 404);
  assert.equal(missing.body.error.code, 'USER_NOT_FOUND');

  const eveList = await request<ConversationPage>('/conversations', {
    method: 'GET',
    accessToken: eve.accessToken,
  });
  assert.equal(eveList.status, 200);
  assert.equal(eveList.body.items.length, 0);
});

test('messages are idempotent, authorized, and cursor paginated', async () => {
  const aliceClientId = randomUUID();
  const first = await sendMessage(
    alice.accessToken,
    conversationId,
    aliceClientId,
    'hello bob',
  );
  assert.equal(first.status, 201);

  const retry = await sendMessage(
    alice.accessToken,
    conversationId,
    aliceClientId,
    'hello bob',
  );
  assert.equal(retry.status, 201);
  assert.equal(retry.body.id, first.body.id);

  const second = await sendMessage(
    bob.accessToken,
    conversationId,
    randomUUID(),
    'message two',
  );
  const third = await sendMessage(
    bob.accessToken,
    conversationId,
    randomUUID(),
    'message three',
  );
  const fourth = await sendMessage(
    bob.accessToken,
    conversationId,
    randomUUID(),
    'message four',
  );
  assert.equal(second.status, 201);
  assert.equal(third.status, 201);
  assert.equal(fourth.status, 201);

  const firstPage = await request<MessagePage>(
    `/conversations/${conversationId}/messages?limit=2`,
    { method: 'GET', accessToken: alice.accessToken },
  );
  assert.equal(firstPage.status, 200);
  assert.equal(firstPage.body.items.length, 2);
  assert.equal(firstPage.body.hasMore, true);
  assert.ok(firstPage.body.nextCursor);

  const secondPage = await request<MessagePage>(
    `/conversations/${conversationId}/messages?limit=2&before=${encodeURIComponent(firstPage.body.nextCursor!)}`,
    { method: 'GET', accessToken: alice.accessToken },
  );
  assert.equal(secondPage.status, 200);
  assert.equal(secondPage.body.items.length, 2);
  assert.equal(secondPage.body.hasMore, false);

  const allIds = new Set([
    ...firstPage.body.items.map((message) => message.id),
    ...secondPage.body.items.map((message) => message.id),
  ]);
  assert.equal(allIds.size, 4);

  const unauthorized = await request<{ error: { code: string } }>(
    `/conversations/${conversationId}/messages`,
    { method: 'GET', accessToken: eve.accessToken },
  );
  assert.equal(unauthorized.status, 404);
  assert.equal(unauthorized.body.error.code, 'CONVERSATION_NOT_FOUND');

  const conversations = await request<ConversationPage>('/conversations', {
    method: 'GET',
    accessToken: alice.accessToken,
  });
  assert.equal(conversations.status, 200);
  assert.equal(conversations.body.items[0]?.id, conversationId);
  assert.equal(conversations.body.items[0]?.lastMessage?.text, 'message four');
  assert.equal(conversations.body.items[0]?.unreadCount, 3);

  const invalidCursor = await request<{ error: { code: string } }>(
    `/conversations/${conversationId}/messages?before=not-a-cursor`,
    { method: 'GET', accessToken: alice.accessToken },
  );
  assert.equal(invalidCursor.status, 400);
  assert.equal(invalidCursor.body.error.code, 'VALIDATION_ERROR');
});

test('reply targets and client message ids cannot cross conversations', async () => {
  const aliceEve = await request<ConversationSummary>('/conversations/direct', {
    method: 'POST',
    accessToken: alice.accessToken,
    body: { userId: eve.user.id },
  });
  assert.equal(aliceEve.status, 200);

  const otherMessage = await sendMessage(
    alice.accessToken,
    aliceEve.body.id,
    randomUUID(),
    'separate conversation',
  );
  assert.equal(otherMessage.status, 201);

  const invalidReply = await request<{ error: { code: string } }>(
    `/conversations/${conversationId}/messages`,
    {
      method: 'POST',
      accessToken: alice.accessToken,
      body: {
        clientMessageId: randomUUID(),
        type: 'text',
        text: 'bad reply',
        replyToMessageId: otherMessage.body.id,
        attachments: [],
      },
    },
  );
  assert.equal(invalidReply.status, 404);
  assert.equal(invalidReply.body.error.code, 'MESSAGE_NOT_FOUND');

  const reusedClientId = randomUUID();
  const accepted = await sendMessage(
    alice.accessToken,
    conversationId,
    reusedClientId,
    'first use',
  );
  assert.equal(accepted.status, 201);

  const conflict = await sendMessage(
    alice.accessToken,
    aliceEve.body.id,
    reusedClientId,
    'second use',
  );
  assert.equal(conflict.status, 409);
});

async function register(email: string): Promise<SessionResponse> {
  const response = await request<SessionResponse>('/auth/register', {
    method: 'POST',
    body: { email, password: 'password-12345' },
  });
  assert.equal(response.status, 201);
  return response.body;
}

function sendMessage(
  accessToken: string,
  targetConversationId: string,
  clientMessageId: string,
  text: string,
) {
  return request<MessageResponse>(
    `/conversations/${targetConversationId}/messages`,
    {
      method: 'POST',
      accessToken,
      body: {
        clientMessageId,
        type: 'text',
        text,
        replyToMessageId: null,
        attachments: [],
      },
    },
  );
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

  return { status: response.status, body: body as T };
}
