import { loadEnvFile } from 'node:process';

import { DataSource } from 'typeorm';

import { databaseEntities } from './entities';
import { InitialSchema2026093000000 } from './migrations/2026093000000-initial-schema';
import { AuthSessionIndexes2026093000100 } from './migrations/2026093000100-auth-session-indexes';
import { ConversationMessageIndexes2026093000200 } from './migrations/2026093000200-conversation-message-indexes';
import { UserDiscoveryIndexes2026093000300 } from './migrations/2026093000300-user-discovery-indexes';

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
  migrations: [
    InitialSchema2026093000000,
    AuthSessionIndexes2026093000100,
    ConversationMessageIndexes2026093000200,
    UserDiscoveryIndexes2026093000300,
  ],
  synchronize: false,
  logging: false,
});
