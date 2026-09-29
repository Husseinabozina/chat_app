import { RefreshSessionEntity } from '../auth/entities/refresh-session.entity';
import { UserEntity } from '../users/entities/user.entity';
import { CreateIdentitySchema1790630000000 } from './migrations/1790630000000-create-identity-schema';

export const databaseEntities = [UserEntity, RefreshSessionEntity];

export const databaseMigrations = [CreateIdentitySchema1790630000000];
