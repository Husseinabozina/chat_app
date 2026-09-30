import { loadEnvFile } from 'node:process';

import { DataSource } from 'typeorm';

import { databaseEntities } from './entities';
import { InitialSchema2026093000000 } from './migrations/2026093000000-initial-schema';

try {
  loadEnvFile('.env');
} catch {
  // CI and production inject environment variables directly.
}

const databaseUrl = process.env.DATABASE_URL;

if (!databaseUrl) {
  throw new Error('DATABASE_URL is required.');
}

export const AppDataSource = new DataSource({
  type: 'postgres',
  url: databaseUrl,
  entities: databaseEntities,
  migrations: [InitialSchema2026093000000],
  synchronize: false,
  logging: false,
});
