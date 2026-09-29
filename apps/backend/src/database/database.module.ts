import { Module } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';

import { databaseEntities, databaseMigrations } from './database.registry';

@Module({
  imports: [
    TypeOrmModule.forRootAsync({
      inject: [ConfigService],
      useFactory: (config: ConfigService) => ({
        type: 'postgres',
        url: config.getOrThrow<string>('DATABASE_URL'),
        entities: databaseEntities,
        migrations: databaseMigrations,
        synchronize: false,
        migrationsRun: false,
        logging: false,
      }),
    }),
  ],
})
export class DatabaseModule {}
