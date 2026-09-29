import 'reflect-metadata';

import { DataSource } from 'typeorm';

import { databaseEntities, databaseMigrations } from './database.registry';

const databaseUrl = process.env.DATABASE_URL;

if (!databaseUrl) {
  throw new Error('DATABASE_URL is required to configure TypeORM.');
}

export default new DataSource({
  type: 'postgres',
  url: databaseUrl,
  entities: databaseEntities,
  migrations: databaseMigrations,
  synchronize: false,
  logging: false,
});
