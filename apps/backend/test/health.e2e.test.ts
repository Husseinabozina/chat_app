import 'reflect-metadata';

import assert from 'node:assert/strict';
import { after, before, test } from 'node:test';

import { type INestApplication } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';

import { AppModule } from '../dist/app.module.js';
import { configureApp } from '../dist/bootstrap/configure-app.js';

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
