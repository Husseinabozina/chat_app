import { type INestApplication } from '@nestjs/common';

import { RedisIoAdapter } from '../realtime/redis-io.adapter';

export async function configureRealtime(app: INestApplication): Promise<void> {
  const url = process.env.REALTIME_REDIS_URL;
  const prefix = process.env.REALTIME_REDIS_PREFIX;
  if (!url) {
    if (process.env.VERCEL) {
      throw new Error('REALTIME_REDIS_URL is required on Vercel.');
    }
    return;
  }
  if (process.env.VERCEL && (!url.startsWith('rediss://') || !prefix)) {
    throw new Error(
      'Vercel requires Redis TLS and an isolated REALTIME_REDIS_PREFIX.',
    );
  }
  const adapter = new RedisIoAdapter(app, url, prefix || 'mingle-local');
  await adapter.connect();
  app.useWebSocketAdapter(adapter);
}
