import { type MigrationInterface, type QueryRunner } from 'typeorm';

export class ConversationMessageIndexes2026093000200 implements MigrationInterface {
  name = 'ConversationMessageIndexes2026093000200';

  async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      'CREATE INDEX "idx_conversations_updated_order" ON "conversations" ("updated_at" DESC, "id" DESC)',
    );
  }

  async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      'DROP INDEX IF EXISTS "idx_conversations_updated_order"',
    );
  }
}
