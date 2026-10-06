import { Module } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';

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
