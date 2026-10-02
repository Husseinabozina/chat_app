import { type MigrationInterface, type QueryRunner } from 'typeorm';

export class SessionPushDevices2026100200100 implements MigrationInterface {
  name = 'SessionPushDevices2026100200100';
  async up(runner: QueryRunner): Promise<void> {
    await runner.query(
      'ALTER TABLE "device_tokens" ADD COLUMN "installation_id" uuid UNIQUE, ADD COLUMN "session_id" uuid REFERENCES "refresh_sessions"("id") ON DELETE CASCADE',
    );
    await runner.query(
      'CREATE INDEX "idx_device_tokens_session" ON "device_tokens"("session_id")',
    );
  }
  async down(runner: QueryRunner): Promise<void> {
    await runner.query(
      'ALTER TABLE "device_tokens" DROP COLUMN "installation_id", DROP COLUMN "session_id"',
    );
  }
}
