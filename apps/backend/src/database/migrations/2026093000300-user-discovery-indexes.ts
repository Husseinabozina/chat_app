import { type MigrationInterface, type QueryRunner } from 'typeorm';

export class UserDiscoveryIndexes2026093000300 implements MigrationInterface {
  name = 'UserDiscoveryIndexes2026093000300';

  async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query('CREATE EXTENSION IF NOT EXISTS "pg_trgm"');
    await queryRunner.query(
      'CREATE INDEX "idx_users_username_trgm" ON "users" USING gin (lower("username") gin_trgm_ops) WHERE "username" IS NOT NULL',
    );
    await queryRunner.query(
      'CREATE INDEX "idx_users_display_name_trgm" ON "users" USING gin (lower("display_name") gin_trgm_ops) WHERE "display_name" IS NOT NULL',
    );
  }

  async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query('DROP INDEX IF EXISTS "idx_users_display_name_trgm"');
    await queryRunner.query('DROP INDEX IF EXISTS "idx_users_username_trgm"');
  }
}
