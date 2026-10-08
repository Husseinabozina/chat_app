import 'reflect-metadata';

import assert from 'node:assert/strict';
import { after, before, test } from 'node:test';

import { type INestApplication } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import { ConfigService } from '@nestjs/config';
import { type DataSource } from 'typeorm';

import { AppModule } from '../dist/app.module.js';
import { configureApp } from '../dist/bootstrap/configure-app.js';
import { FcmProviderService } from '../dist/push/fcm-provider.service.js';
import { PushService } from '../dist/push/push.service.js';

let app: INestApplication;
let baseUrl: string;

before(async () => {
  app = await NestFactory.create(AppModule, { logger: false });
  configureApp(app);
  await app.listen(0, '127.0.0.1');

  const address = app.getHttpServer().address() as { port: number };
  baseUrl = `http://127.0.0.1:${address.port}/v1`;
});

after(async () => {
  await app?.close();
});

test('health endpoint confirms API and PostgreSQL availability', async () => {
  const response = await fetch(`${baseUrl}/health`);
  assert.equal(response.status, 200);

  const body = (await response.json()) as {
    status: string;
    database: string;
    timestamp: string;
  };

  assert.equal(body.status, 'ok');
  assert.equal(body.database, 'up');
  assert.ok(Number.isFinite(Date.parse(body.timestamp)));
});

test('push rejects wrong-project and malformed cloud credentials without exposing their contents', () => {
  for (const raw of [
    '{PRIVATE-CREDENTIAL-CONTENTS',
    JSON.stringify({ type: 'service_account', project_id: 'wrong-project' }),
    JSON.stringify({ type: 'authorized_user', project_id: 'expected-project' }),
  ]) {
    assert.throws(
      () =>
        new FcmProviderService(
          new ConfigService({
            PUSH_ENABLED: 'true',
            FCM_PROJECT_ID: 'expected-project',
            FCM_SERVICE_ACCOUNT_JSON: raw,
          }),
        ),
      { message: 'Invalid FCM service account for the configured project.' },
    );
  }
  assert.throws(
    () => new FcmProviderService(new ConfigService({ PUSH_ENABLED: 'true' })),
    { message: 'FCM_PROJECT_ID is required when push is enabled.' },
  );
});

test('Fluid request continuation waits for push delivery after enqueue returns', async () => {
  const key = Symbol.for('@vercel/request-context');
  const context = globalThis as unknown as Record<symbol, unknown>;
  const previousContext = context[key];
  const previousVercel = process.env.VERCEL;
  const continuations: Promise<unknown>[] = [];
  let release!: () => void;
  let sent = false;
  const gate = new Promise<void>((resolve) => (release = resolve));
  context[key] = {
    get: () => ({ waitUntil: (p: Promise<unknown>) => continuations.push(p) }),
  };
  process.env.VERCEL = '1';
  const db = {
    query: async () => [
      {
        id: 'device',
        token: 'test-token',
        user_id: 'recipient',
        conversation_id: 'conversation',
      },
    ],
  } as unknown as DataSource;
  const provider = {
    configured: true,
    send: async () => {
      await gate;
      sent = true;
      return true;
    },
  } as unknown as FcmProviderService;
  const push = new PushService(db, provider);
  try {
    push.enqueue('message');
    push.enqueue('message-two');
    push.enqueue('message-three');
    assert.equal(sent, false);
    assert.equal(continuations.length, 3);
    release();
    await Promise.all(continuations);
    assert.equal(sent, true);
  } finally {
    release();
    await push.onModuleDestroy();
    if (previousContext === undefined) delete context[key];
    else context[key] = previousContext;
    if (previousVercel === undefined) delete process.env.VERCEL;
    else process.env.VERCEL = previousVercel;
  }
});
