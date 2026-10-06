import 'reflect-metadata';

import { NestFactory } from '@nestjs/core';

import { AppModule } from './app.module';
import { configureApp } from './bootstrap/configure-app';
import { configureRealtime } from './bootstrap/configure-realtime';

async function bootstrap(): Promise<void> {
  const app = await NestFactory.create(AppModule);
  configureApp(app);
  try {
    await configureRealtime(app);
    const port = Number(process.env.PORT ?? 3000);
    await app.listen(port);
  } catch (error) {
    await app.close();
    throw error;
  }
}

void bootstrap();
