import { type MigrationInterface, type QueryRunner } from 'typeorm';
export class ImageMedia2026100200000 implements MigrationInterface {
  name = 'ImageMedia2026100200000';
  async up(runner: QueryRunner): Promise<void> {
    await runner.query(`CREATE TABLE "media_uploads" (
      "id" uuid PRIMARY KEY DEFAULT gen_random_uuid(),
      "owner_id" uuid NOT NULL REFERENCES "users"("id") ON DELETE CASCADE,
      "purpose" varchar(20) NOT NULL CHECK ("purpose" IN ('avatar', 'message')),
      "conversation_id" uuid REFERENCES "conversations"("id") ON DELETE CASCADE,
      "mime_type" varchar(120) NOT NULL, "size_bytes" integer NOT NULL CHECK ("size_bytes" BETWEEN 1 AND 6291456),
      "storage_key" text, "width" integer, "height" integer,
      "claimed_message_id" uuid UNIQUE REFERENCES "messages"("id") ON DELETE SET NULL,
      "expires_at" timestamptz NOT NULL, "created_at" timestamptz NOT NULL DEFAULT now(),
      CONSTRAINT "chk_media_purpose" CHECK (("purpose" = 'avatar' AND "conversation_id" IS NULL) OR ("purpose" = 'message' AND "conversation_id" IS NOT NULL))
    )`);
    await runner.query(
      'CREATE INDEX "idx_media_owner_created" ON "media_uploads"("owner_id", "created_at")',
    );
    await runner.query(
      'ALTER TABLE "messages" ADD COLUMN "image_media_id" uuid UNIQUE REFERENCES "media_uploads"("id") ON DELETE SET NULL',
    );
  }
  async down(runner: QueryRunner): Promise<void> {
    await runner.query('ALTER TABLE "messages" DROP COLUMN "image_media_id"');
    await runner.query('DROP TABLE "media_uploads"');
  }
}
