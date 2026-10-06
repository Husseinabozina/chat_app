import { type INestApplicationContext, Logger } from '@nestjs/common';
import { IoAdapter } from '@nestjs/platform-socket.io';
import { createAdapter } from '@socket.io/redis-adapter';
import { Redis } from 'ioredis';

/** Shares delivery and session revocation across server instances, not durable data. */
export class RedisIoAdapter extends IoAdapter {
  private readonly log = new Logger(RedisIoAdapter.name);
  private readonly publisher: Redis;
  private readonly subscriber: Redis;
  private adapter?: ReturnType<typeof createAdapter>;

  constructor(
    app: INestApplicationContext,
    url: string,
    private readonly key: string,
  ) {
    super(app);
    this.publisher = new Redis(url, {
      lazyConnect: true,
      connectTimeout: 5000,
      commandTimeout: 5000,
      maxRetriesPerRequest: 1,
      enableOfflineQueue: false,
      retryStrategy: (attempt) => Math.min(attempt * 200, 3000),
    });
    this.subscriber = this.publisher.duplicate();
    // Do not include connection errors: provider URLs may contain credentials.
    for (const client of [this.publisher, this.subscriber]) {
      client.on('error', () =>
        this.log.warn('Realtime Redis connection failed.'),
      );
    }
  }

  async connect(): Promise<void> {
    try {
      await Promise.all([this.publisher.connect(), this.subscriber.connect()]);
      this.adapter = createAdapter(
        this.guardCommands(this.publisher),
        this.guardCommands(this.subscriber),
        {
          key: this.key,
          requestsTimeout: 5000,
          publishOnSpecificResponseChannel: true,
        },
      );
    } catch {
      this.publisher.disconnect();
      this.subscriber.disconnect();
      throw new Error('Could not initialize realtime Redis.');
    }
  }

  private guardCommands(client: Redis): Redis {
    // The Socket.IO adapter does not await these commands. Handle rejected
    // promises so a provider outage cannot crash an otherwise healthy REST API.
    const ignoredCommands = new Set([
      'publish',
      'subscribe',
      'psubscribe',
      'unsubscribe',
      'punsubscribe',
    ]);
    return new Proxy(client, {
      get: (target, property) => {
        const value = Reflect.get(target, property, target);
        if (typeof value !== 'function') return value;
        if (!ignoredCommands.has(String(property))) return value.bind(target);
        return (...args: unknown[]) => {
          const result = Reflect.apply(value, target, args) as Promise<unknown>;
          return result.catch(() =>
            this.log.warn(
              'Realtime Redis command failed; recover durable state through REST.',
            ),
          );
        };
      },
    });
  }

  override createIOServer(
    port: number,
    options?: Parameters<IoAdapter['createIOServer']>[1],
  ): ReturnType<IoAdapter['createIOServer']> {
    if (!this.adapter)
      throw new Error('Realtime Redis must connect before listen.');
    const server = super.createIOServer(port, options);
    server.adapter(this.adapter);
    return server;
  }

  override async dispose(): Promise<void> {
    this.publisher.disconnect();
    this.subscriber.disconnect();
    await super.dispose();
  }
}
