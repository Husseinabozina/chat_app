import type { MigrationInterface, QueryRunner } from 'typeorm';

export class AuthSessionIndexes2026093000100 implements MigrationInterface {
  name = 'AuthSessionIndexes2026093000100';

  async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      'CREATE UNIQUE INDEX "uq_refresh_sessions_token_hash" ON "refresh_sessions" ("token_hash")',
    );
    await queryRunner.query(
      'CREATE INDEX "idx_refresh_sessions_expires_at" ON "refresh_sessions" ("expires_at")',
    );
  }

  async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      'DROP INDEX IF EXISTS "idx_refresh_sessions_expires_at"',
    );
    await queryRunner.query(
      'DROP INDEX IF EXISTS "uq_refresh_sessions_token_hash"',
    );
  }
}
