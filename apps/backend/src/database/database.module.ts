import { Module } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';
// TypeORM loads this driver dynamically; retain it in the serverless file trace.
import 'pg';

import { databaseEntities } from './entities';
import { databaseConnectionOptions } from './connection-options';

@Module({
  imports: [
    TypeOrmModule.forRootAsync({
      inject: [ConfigService],
      useFactory: (config: ConfigService) => ({
        type: 'postgres',
        url: config.getOrThrow<string>('DATABASE_URL'),
        ...databaseConnectionOptions(),
        retryAttempts: 3,
        retryDelay: 1000,
        entities: databaseEntities,
        synchronize: false,
        logging: false,
      }),
    }),
  ],
})
export class DatabaseModule {}
