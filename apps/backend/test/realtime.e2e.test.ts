import 'reflect-metadata';

import assert from 'node:assert/strict';
import { randomUUID } from 'node:crypto';
import { after, before, test } from 'node:test';

import { type INestApplication } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import { JwtService } from '@nestjs/jwt';
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
let mallory: SessionResponse;
let conversationId: string;
let firstMessageId: string;
let aliceSocket: Socket;
let bobSocket: Socket;
let eveSocket: Socket;
let mallorySocket: Socket;

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
  mallory = await register('realtime-mallory@example.com');

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
  mallorySocket = await connectRealtime(mallory.accessToken);
});

after(async () => {
  aliceSocket?.disconnect();
  bobSocket?.disconnect();
  eveSocket?.disconnect();
  mallorySocket?.disconnect();
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

  const expiredToken = await app
    .get(JwtService)
    .signAsync(
      { sub: alice.user.id, sid: randomUUID(), typ: 'access' },
      { expiresIn: -1 },
    );
  const expired = io(realtimeUrl, {
    autoConnect: false,
    transports: ['websocket'],
    auth: { accessToken: expiredToken },
  });
  const expiredError = waitForConnectError(expired);
  expired.connect();
  assert.equal((await expiredError).data?.code, 'UNAUTHORIZED');
  expired.disconnect();

  const disconnected = waitForDisconnect(eveSocket);
  const logout = await request<unknown>('/auth/logout', {
    method: 'POST',
    body: { refreshToken: eve.refreshToken },
  });
  assert.equal(logout.status, 204);
  await disconnected;
  assert.equal(eveSocket.connected, false);

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
  const unrelatedEvents: string[] = [];
  const onUnrelatedEvent = (eventName: string) => {
    if (
      eventName.startsWith('message.') ||
      eventName === 'conversation.updated' ||
      eventName === 'read.updated'
    ) {
      unrelatedEvents.push(eventName);
    }
  };
  mallorySocket.onAny(onUnrelatedEvent);
  const aliceCreated = waitForEvent<{ message: MessageResponse }>(
    aliceSocket,
    'message.created',
  );
  const bobCreated = waitForEvent<{ message: MessageResponse }>(
    bobSocket,
    'message.created',
  );
  const bobConversation = waitForEvent<{
    conversation: {
      id: string;
      unreadCount: number;
      lastMessage: { id: string };
    };
  }>(bobSocket, 'conversation.updated');

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
  firstMessageId = sent.body.id;

  const [aliceEvent, bobEvent] = await Promise.all([aliceCreated, bobCreated]);
  assert.equal(aliceEvent.data.message.id, sent.body.id);
  assert.equal(bobEvent.data.message.id, sent.body.id);
  assert.equal(bobEvent.protocolVersion, 1);
  assert.equal(bobEvent.conversationId, conversationId);
  const summary = await bobConversation;
  assert.equal(summary.data.conversation.id, conversationId);
  assert.equal(summary.data.conversation.lastMessage.id, sent.body.id);
  assert.equal(summary.data.conversation.unreadCount, 1);

  const updatedEvent = waitForEvent<{ message: MessageResponse }>(
    bobSocket,
    'message.updated',
  );
  const editSummary = waitForEvent<{
    conversation: { lastMessage: { id: string; text: string } };
  }>(bobSocket, 'conversation.updated');
  const edited = await request<MessageResponse>(`/messages/${sent.body.id}`, {
    method: 'PATCH',
    accessToken: alice.accessToken,
    body: { text: 'hello edited realtime' },
  });
  assert.equal(edited.status, 200);
  const updated = await updatedEvent;
  assert.equal(updated.data.message.text, 'hello edited realtime');
  assert.ok(updated.data.message.editedAt);
  assert.equal(
    (await editSummary).data.conversation.lastMessage.text,
    'hello edited realtime',
  );

  const readEvent = waitForEvent<{
    conversationId: string;
    userId: string;
    lastReadMessageId: string;
    lastReadAt: string;
  }>(aliceSocket, 'read.updated');
  const bobReadSummary = waitForEvent<{
    conversation: { unreadCount: number };
  }>(bobSocket, 'conversation.updated');
  const read = await request<unknown>(`/conversations/${conversationId}/read`, {
    method: 'POST',
    accessToken: bob.accessToken,
    body: { upToMessageId: sent.body.id },
  });
  assert.equal(read.status, 200);
  const readUpdate = await readEvent;
  assert.equal(readUpdate.data.userId, bob.user.id);
  assert.equal(readUpdate.data.lastReadMessageId, sent.body.id);
  assert.equal((await bobReadSummary).data.conversation.unreadCount, 0);

  const deletedEvent = waitForEvent<{ messageId: string; deletedAt: string }>(
    bobSocket,
    'message.deleted',
  );
  const deleted = await request<unknown>(`/messages/${sent.body.id}`, {
    method: 'DELETE',
    accessToken: alice.accessToken,
  });
  assert.equal(deleted.status, 204);
  const deletedUpdate = await deletedEvent;
  assert.equal(deletedUpdate.data.messageId, sent.body.id);
  assert.ok(deletedUpdate.data.deletedAt);

  // An acknowledgement on the unrelated socket follows any earlier packets
  // on that connection, so this checks isolation without a timing delay.
  await emitWithAck(mallorySocket, 'typing.stop', { conversationId });
  assert.deepEqual(unrelatedEvents, []);
  mallorySocket.offAny(onUnrelatedEvent);

  bobSocket.disconnect();
  bobSocket = await connectRealtime(bob.accessToken);
  const resynced = await request<{ items: MessageResponse[] }>(
    `/conversations/${conversationId}/messages`,
    { method: 'GET', accessToken: bob.accessToken },
  );
  assert.equal(resynced.status, 200);
  assert.equal(resynced.body.items[0]?.id, sent.body.id);
  assert.equal(resynced.body.items[0]?.text, null);
  assert.ok(resynced.body.items[0]?.deletedAt);
});

test('read pointer and read events never move backward', async () => {
  const sent = await request<MessageResponse>(
    `/conversations/${conversationId}/messages`,
    {
      method: 'POST',
      accessToken: alice.accessToken,
      body: {
        clientMessageId: randomUUID(),
        type: 'text',
        text: 'newer message',
        replyToMessageId: null,
        attachments: [],
      },
    },
  );
  assert.equal(sent.status, 201);

  const advancedEvent = waitForEvent<{ lastReadMessageId: string }>(
    aliceSocket,
    'read.updated',
  );
  const advanced = await request<{
    lastReadMessageId: string;
    lastReadAt: string;
  }>(`/conversations/${conversationId}/read`, {
    method: 'POST',
    accessToken: bob.accessToken,
    body: { upToMessageId: sent.body.id },
  });
  assert.equal(advanced.status, 200);
  assert.equal((await advancedEvent).data.lastReadMessageId, sent.body.id);

  let staleReadEvents = 0;
  const onStaleReadEvent = () => {
    staleReadEvents += 1;
  };
  aliceSocket.on('read.updated', onStaleReadEvent);
  const stale = await request<{
    lastReadMessageId: string;
    lastReadAt: string;
  }>(`/conversations/${conversationId}/read`, {
    method: 'POST',
    accessToken: bob.accessToken,
    body: { upToMessageId: firstMessageId },
  });
  assert.equal(stale.status, 200);
  assert.equal(stale.body.lastReadMessageId, sent.body.id);
  assert.equal(stale.body.lastReadAt, advanced.body.lastReadAt);
  await emitWithAck(aliceSocket, 'typing.stop', { conversationId });
  assert.equal(staleReadEvents, 0);
  aliceSocket.off('read.updated', onStaleReadEvent);
});

test('typing is membership scoped and transient', async () => {
  const started = waitForEvent<{
    conversationId: string;
    userId: string;
    expiresAt: string;
  }>(bobSocket, 'typing.started');

  const startAck = await emitWithAck(aliceSocket, 'typing.start', {
    conversationId,
  });
  assert.equal(startAck.ok, true);
  const startedEvent = await started;
  assert.equal(startedEvent.data.userId, alice.user.id);

  const stopped = waitForEvent<{ conversationId: string; userId: string }>(
    bobSocket,
    'typing.stopped',
  );
  const stopAck = await emitWithAck(aliceSocket, 'typing.stop', {
    conversationId,
  });
  assert.equal(stopAck.ok, true);
  const stoppedEvent = await stopped;
  assert.equal(stoppedEvent.data.userId, alice.user.id);

  const unauthorizedAck = await emitWithAck(mallorySocket, 'typing.start', {
    conversationId,
  });
  assert.equal(unauthorizedAck.ok, false);
  assert.equal(unauthorizedAck.error?.code, 'CONVERSATION_NOT_FOUND');

  const expired = waitForEvent<{ conversationId: string; userId: string }>(
    bobSocket,
    'typing.stopped',
  );
  assert.equal(
    (await emitWithAck(aliceSocket, 'typing.start', { conversationId })).ok,
    true,
  );
  assert.equal((await expired).data.userId, alice.user.id);

  const disconnected = waitForEvent<{
    conversationId: string;
    userId: string;
  }>(bobSocket, 'typing.stopped');
  assert.equal(
    (await emitWithAck(aliceSocket, 'typing.start', { conversationId })).ok,
    true,
  );
  aliceSocket.disconnect();
  assert.equal((await disconnected).data.userId, alice.user.id);
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

function waitForDisconnect(socket: Socket, timeoutMs = 3000): Promise<void> {
  return new Promise((resolve, reject) => {
    const timer = setTimeout(() => {
      socket.off('disconnect', onDisconnect);
      reject(new Error('Timed out waiting for socket disconnect.'));
    }, timeoutMs);

    const onDisconnect = () => {
      clearTimeout(timer);
      resolve();
    };

    socket.once('disconnect', onDisconnect);
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
