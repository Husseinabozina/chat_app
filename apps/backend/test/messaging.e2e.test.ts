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
    deletedAt: string | null;
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
  editedAt: string | null;
  deletedAt: string | null;
}

interface MessagePage {
  items: MessageResponse[];
  nextCursor: string | null;
  hasMore: boolean;
}

interface ReadStateResponse {
  conversationId: string;
  lastReadMessageId: string;
  lastReadAt: string;
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
  const duplicate = await request<ConversationSummary>(
    '/conversations/direct',
    {
      method: 'POST',
      accessToken: bob.accessToken,
      body: { userId: alice.user.id },
    },
  );

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
    `/conversations/${conversationId}/messages?limit=2&before=${encodeURIComponent(
      firstPage.body.nextCursor!,
    )}`,
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

test('read state advances monotonically and drives unread counts', async () => {
  const baseline = await request<MessagePage>(
    `/conversations/${conversationId}/messages?limit=1`,
    {
      method: 'GET',
      accessToken: alice.accessToken,
    },
  );
  assert.equal(baseline.status, 200);

  const baselineMessage = baseline.body.items[0];
  if (baselineMessage) {
    const baselineRead = await request<ReadStateResponse>(
      `/conversations/${conversationId}/read`,
      {
        method: 'POST',
        accessToken: alice.accessToken,
        body: { upToMessageId: baselineMessage.id },
      },
    );
    assert.equal(baselineRead.status, 200);
  }

  const first = await sendMessage(
    bob.accessToken,
    conversationId,
    randomUUID(),
    'read-state one',
  );
  const second = await sendMessage(
    bob.accessToken,
    conversationId,
    randomUUID(),
    'read-state two',
  );
  const third = await sendMessage(
    bob.accessToken,
    conversationId,
    randomUUID(),
    'read-state three',
  );
  assert.equal(first.status, 201);
  assert.equal(second.status, 201);
  assert.equal(third.status, 201);

  const beforeRead = await request<ConversationPage>('/conversations', {
    method: 'GET',
    accessToken: alice.accessToken,
  });
  assert.equal(beforeRead.status, 200);
  assert.equal(beforeRead.body.items[0]?.unreadCount, 3);

  const readSecond = await request<ReadStateResponse>(
    `/conversations/${conversationId}/read`,
    {
      method: 'POST',
      accessToken: alice.accessToken,
      body: { upToMessageId: second.body.id },
    },
  );
  assert.equal(readSecond.status, 200);
  assert.equal(readSecond.body.lastReadMessageId, second.body.id);

  const afterRead = await request<ConversationPage>('/conversations', {
    method: 'GET',
    accessToken: alice.accessToken,
  });
  assert.equal(afterRead.status, 200);
  assert.equal(afterRead.body.items[0]?.unreadCount, 1);

  const backwards = await request<ReadStateResponse>(
    `/conversations/${conversationId}/read`,
    {
      method: 'POST',
      accessToken: alice.accessToken,
      body: { upToMessageId: first.body.id },
    },
  );
  assert.equal(backwards.status, 200);
  assert.equal(backwards.body.lastReadMessageId, second.body.id);

  const outsider = await request<{ error: { code: string } }>(
    `/conversations/${conversationId}/read`,
    {
      method: 'POST',
      accessToken: eve.accessToken,
      body: { upToMessageId: third.body.id },
    },
  );
  assert.equal(outsider.status, 404);
  assert.equal(outsider.body.error.code, 'CONVERSATION_NOT_FOUND');
});

test('only senders can edit or soft-delete their messages', async () => {
  const created = await sendMessage(
    alice.accessToken,
    conversationId,
    randomUUID(),
    'editable message',
  );
  assert.equal(created.status, 201);

  const forbiddenEdit = await request<{ error: { code: string } }>(
    `/messages/${created.body.id}`,
    {
      method: 'PATCH',
      accessToken: bob.accessToken,
      body: { text: 'not mine' },
    },
  );
  assert.equal(forbiddenEdit.status, 403);
  assert.equal(forbiddenEdit.body.error.code, 'FORBIDDEN');

  const edited = await request<MessageResponse>(
    `/messages/${created.body.id}`,
    {
      method: 'PATCH',
      accessToken: alice.accessToken,
      body: { text: 'edited message' },
    },
  );
  assert.equal(edited.status, 200);
  assert.equal(edited.body.text, 'edited message');
  assert.ok(edited.body.editedAt);

  const forbiddenDelete = await request<{ error: { code: string } }>(
    `/messages/${created.body.id}`,
    {
      method: 'DELETE',
      accessToken: bob.accessToken,
    },
  );
  assert.equal(forbiddenDelete.status, 403);
  assert.equal(forbiddenDelete.body.error.code, 'FORBIDDEN');

  const deleted = await request<unknown>(`/messages/${created.body.id}`, {
    method: 'DELETE',
    accessToken: alice.accessToken,
  });
  assert.equal(deleted.status, 204);

  const deletedAgain = await request<unknown>(`/messages/${created.body.id}`, {
    method: 'DELETE',
    accessToken: alice.accessToken,
  });
  assert.equal(deletedAgain.status, 204);

  const history = await request<MessagePage>(
    `/conversations/${conversationId}/messages?limit=100`,
    {
      method: 'GET',
      accessToken: alice.accessToken,
    },
  );
  assert.equal(history.status, 200);
  const tombstone = history.body.items.find(
    (message) => message.id === created.body.id,
  );
  assert.ok(tombstone);
  assert.equal(tombstone.text, null);
  assert.ok(tombstone.deletedAt);

  const conversations = await request<ConversationPage>('/conversations', {
    method: 'GET',
    accessToken: alice.accessToken,
  });
  assert.equal(conversations.status, 200);
  assert.equal(conversations.body.items[0]?.lastMessage?.id, created.body.id);
  assert.equal(conversations.body.items[0]?.lastMessage?.text, null);
  assert.ok(conversations.body.items[0]?.lastMessage?.deletedAt);
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
    method: 'GET' | 'POST' | 'PATCH' | 'DELETE';
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
