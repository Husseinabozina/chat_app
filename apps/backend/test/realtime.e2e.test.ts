import 'reflect-metadata';

import assert from 'node:assert/strict';
import { randomUUID } from 'node:crypto';
import { after, before, test } from 'node:test';

import { type INestApplication } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import { io, type Socket } from 'socket.io-client';

import { AppModule } from '../dist/app.module.js';
import { configureApp } from '../dist/bootstrap/configure-app.js';
import { AppDataSource } from '../dist/database/data-source.js';

interface SessionResponse {
  accessToken: string;
  refreshToken: string;
  user: { id: string; email: string };
}

interface ConversationSummary {
  id: string;
}

interface MessageResponse {
  id: string;
  clientMessageId: string;
  conversationId: string;
  senderId: string;
  text: string | null;
  editedAt: string | null;
  deletedAt: string | null;
}

interface Envelope<T> {
  protocolVersion: 1;
  eventId: string;
  type: string;
  occurredAt: string;
  conversationId: string | null;
  data: T;
}

interface Ack {
  ok: boolean;
  error?: { code: string; message: string };
}

let app: INestApplication;
let baseUrl: string;
let realtimeUrl: string;
let alice: SessionResponse;
let bob: SessionResponse;
let eve: SessionResponse;
let conversationId: string;
let aliceSocket: Socket;
let bobSocket: Socket;
let eveSocket: Socket;

before(async () => {
  process.env.REALTIME_TYPING_TTL_MS = '250';

  await AppDataSource.initialize();
  await AppDataSource.runMigrations();
  await AppDataSource.query('TRUNCATE TABLE "users" CASCADE');
  await AppDataSource.destroy();

  app = await NestFactory.create(AppModule, { logger: false });
  configureApp(app);
  await app.listen(0, '127.0.0.1');

  const address = app.getHttpServer().address() as { port: number };
  baseUrl = `http://127.0.0.1:${address.port}/v1`;
  realtimeUrl = `http://127.0.0.1:${address.port}/realtime`;

  alice = await register('realtime-alice@example.com');
  bob = await register('realtime-bob@example.com');
  eve = await register('realtime-eve@example.com');

  const direct = await request<ConversationSummary>('/conversations/direct', {
    method: 'POST',
    accessToken: alice.accessToken,
    body: { userId: bob.user.id },
  });
  assert.equal(direct.status, 200);
  conversationId = direct.body.id;

  aliceSocket = await connectRealtime(alice.accessToken);
  bobSocket = await connectRealtime(bob.accessToken);
  eveSocket = await connectRealtime(eve.accessToken);
});

after(async () => {
  aliceSocket?.disconnect();
  bobSocket?.disconnect();
  eveSocket?.disconnect();
  await app.close();
});

test('realtime rejects invalid authentication and revoked sessions', async () => {
  const invalid = io(realtimeUrl, {
    autoConnect: false,
    transports: ['websocket'],
    auth: { accessToken: 'not-a-token' },
  });

  const invalidError = waitForConnectError(invalid);
  invalid.connect();
  const error = await invalidError;
  assert.equal(error.data?.code, 'UNAUTHORIZED');
  invalid.disconnect();

  const logout = await request<unknown>('/auth/logout', {
    method: 'POST',
    body: { refreshToken: eve.refreshToken },
  });
  assert.equal(logout.status, 204);

  const revoked = io(realtimeUrl, {
    autoConnect: false,
    transports: ['websocket'],
    auth: { accessToken: eve.accessToken },
  });
  const revokedError = waitForConnectError(revoked);
  revoked.connect();
  const revokedFailure = await revokedError;
  assert.equal(revokedFailure.data?.code, 'UNAUTHORIZED');
  revoked.disconnect();
});

test('REST message lifecycle publishes durable realtime events', async () => {
  const clientMessageId = randomUUID();
  const aliceCreated = waitForEvent<
    { message: MessageResponse }
  >(aliceSocket, 'message.created');
  const bobCreated = waitForEvent<
    { message: MessageResponse }
  >(bobSocket, 'message.created');

  const sent = await request<MessageResponse>(
    `/conversations/${conversationId}/messages`,
    {
      method: 'POST',
      accessToken: alice.accessToken,
      body: {
        clientMessageId,
        type: 'text',
        text: 'hello realtime',
        replyToMessageId: null,
        attachments: [],
      },
    },
  );
  assert.equal(sent.status, 201);

  const [aliceEvent, bobEvent] = await Promise.all([aliceCreated, bobCreated]);
  assert.equal(aliceEvent.data.message.id, sent.body.id);
  assert.equal(bobEvent.data.message.id, sent.body.id);
  assert.equal(bobEvent.protocolVersion, 1);
  assert.equal(bobEvent.conversationId, conversationId);

  const updatedEvent = waitForEvent<{ message: MessageResponse }>(
    bobSocket,
    'message.updated',
  );
  const edited = await request<MessageResponse>(`/messages/${sent.body.id}`, {
    method: 'PATCH',
    accessToken: alice.accessToken,
    body: { text: 'hello edited realtime' },
  });
  assert.equal(edited.status, 200);
  const updated = await updatedEvent;
  assert.equal(updated.data.message.text, 'hello edited realtime');
  assert.ok(updated.data.message.editedAt);

  const readEvent = waitForEvent<
    {
      conversationId: string;
      userId: string;
      lastReadMessageId: string;
      lastReadAt: string;
    }
  >(aliceSocket, 'read.updated');
  const read = await request<unknown>(`/conversations/${conversationId}/read`, {
    method: 'POST',
    accessToken: bob.accessToken,
    body: { upToMessageId: sent.body.id },
  });
  assert.equal(read.status, 200);
  const readUpdate = await readEvent;
  assert.equal(readUpdate.data.userId, bob.user.id);
  assert.equal(readUpdate.data.lastReadMessageId, sent.body.id);

  const deletedEvent = waitForEvent<
    { messageId: string; deletedAt: string }
  >(bobSocket, 'message.deleted');
  const deleted = await request<unknown>(`/messages/${sent.body.id}`, {
    method: 'DELETE',
    accessToken: alice.accessToken,
  });
  assert.equal(deleted.status, 204);
  const deletedUpdate = await deletedEvent;
  assert.equal(deletedUpdate.data.messageId, sent.body.id);
  assert.ok(deletedUpdate.data.deletedAt);
});

test('typing is membership scoped and transient', async () => {
  const started = waitForEvent<
    { conversationId: string; userId: string; expiresAt: string }
  >(bobSocket, 'typing.started');

  const startAck = await emitWithAck(aliceSocket, 'typing.start', {
    conversationId,
  });
  assert.equal(startAck.ok, true);
  const startedEvent = await started;
  assert.equal(startedEvent.data.userId, alice.user.id);

  const stopped = waitForEvent<
    { conversationId: string; userId: string }
  >(bobSocket, 'typing.stopped');
  const stopAck = await emitWithAck(aliceSocket, 'typing.stop', {
    conversationId,
  });
  assert.equal(stopAck.ok, true);
  const stoppedEvent = await stopped;
  assert.equal(stoppedEvent.data.userId, alice.user.id);

  const unauthorizedAck = await emitWithAck(eveSocket, 'typing.start', {
    conversationId,
  });
  assert.equal(unauthorizedAck.ok, false);
  assert.equal(unauthorizedAck.error?.code, 'CONVERSATION_NOT_FOUND');
});

async function register(email: string): Promise<SessionResponse> {
  const response = await request<SessionResponse>('/auth/register', {
    method: 'POST',
    body: { email, password: 'password-12345' },
  });
  assert.equal(response.status, 201);
  return response.body;
}

async function connectRealtime(accessToken: string): Promise<Socket> {
  const socket = io(realtimeUrl, {
    autoConnect: false,
    transports: ['websocket'],
    auth: { accessToken },
  });
  const ready = waitForEvent<{ userId: string; sessionId: string }>(
    socket,
    'connection.ready',
  );
  socket.connect();
  await ready;
  return socket;
}

function waitForEvent<T>(
  socket: Socket,
  eventName: string,
  timeoutMs = 3000,
): Promise<Envelope<T>> {
  return new Promise((resolve, reject) => {
    const timer = setTimeout(() => {
      socket.off(eventName, onEvent);
      reject(new Error(`Timed out waiting for ${eventName}.`));
    }, timeoutMs);

    const onEvent = (event: Envelope<T>) => {
      clearTimeout(timer);
      resolve(event);
    };

    socket.once(eventName, onEvent);
  });
}

function waitForConnectError(
  socket: Socket,
  timeoutMs = 3000,
): Promise<Error & { data?: { code?: string } }> {
  return new Promise((resolve, reject) => {
    const timer = setTimeout(() => {
      socket.off('connect_error', onError);
      reject(new Error('Timed out waiting for connect_error.'));
    }, timeoutMs);

    const onError = (error: Error & { data?: { code?: string } }) => {
      clearTimeout(timer);
      resolve(error);
    };

    socket.once('connect_error', onError);
  });
}

function emitWithAck(
  socket: Socket,
  eventName: string,
  payload: Record<string, unknown>,
): Promise<Ack> {
  return new Promise((resolve, reject) => {
    const timer = setTimeout(() => {
      reject(new Error(`Timed out waiting for ${eventName} ack.`));
    }, 3000);

    socket.emit(eventName, payload, (ack: Ack) => {
      clearTimeout(timer);
      resolve(ack);
    });
  });
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
