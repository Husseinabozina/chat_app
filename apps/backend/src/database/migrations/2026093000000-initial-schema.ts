import { MigrationInterface, QueryRunner } from 'typeorm';

export class InitialSchema2026093000000 implements MigrationInterface {
  name = 'InitialSchema2026093000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    const statements = [
      'CREATE EXTENSION IF NOT EXISTS "pgcrypto"',
      `CREATE TABLE "users" (
        "id" uuid PRIMARY KEY DEFAULT gen_random_uuid(),
        "email" varchar(320) NOT NULL,
        "username" varchar(40),
        "display_name" varchar(80),
        "bio" varchar(280),
        "avatar_url" text,
        "password_hash" text NOT NULL,
        "created_at" timestamptz NOT NULL DEFAULT now(),
        "updated_at" timestamptz NOT NULL DEFAULT now()
      )`,
      'CREATE UNIQUE INDEX "uq_users_email_ci" ON "users" (lower("email"))',
      'CREATE UNIQUE INDEX "uq_users_username_ci" ON "users" (lower("username")) WHERE "username" IS NOT NULL',
      `CREATE TABLE "refresh_sessions" (
        "id" uuid PRIMARY KEY DEFAULT gen_random_uuid(),
        "user_id" uuid NOT NULL REFERENCES "users"("id") ON DELETE CASCADE,
        "token_hash" text NOT NULL,
        "expires_at" timestamptz NOT NULL,
        "created_at" timestamptz NOT NULL DEFAULT now(),
        "revoked_at" timestamptz,
        "device_metadata" jsonb
      )`,
      'CREATE INDEX "idx_refresh_sessions_user_id" ON "refresh_sessions" ("user_id")',
      `CREATE TABLE "device_tokens" (
        "id" uuid PRIMARY KEY DEFAULT gen_random_uuid(),
        "user_id" uuid NOT NULL REFERENCES "users"("id") ON DELETE CASCADE,
        "token" text NOT NULL,
        "platform" varchar(20) NOT NULL,
        "device_id" varchar(160),
        "last_seen_at" timestamptz,
        "created_at" timestamptz NOT NULL DEFAULT now(),
        "revoked_at" timestamptz
      )`,
      'CREATE UNIQUE INDEX "uq_device_tokens_token" ON "device_tokens" ("token")',
      'CREATE INDEX "idx_device_tokens_user_id" ON "device_tokens" ("user_id")',
      `CREATE TABLE "conversations" (
        "id" uuid PRIMARY KEY DEFAULT gen_random_uuid(),
        "type" varchar(20) NOT NULL DEFAULT 'direct',
        "direct_key" varchar(80),
        "last_message_id" uuid,
        "created_at" timestamptz NOT NULL DEFAULT now(),
        "updated_at" timestamptz NOT NULL DEFAULT now(),
        CONSTRAINT "chk_conversations_type" CHECK ("type" IN ('direct', 'group'))
      )`,
      `CREATE UNIQUE INDEX "uq_conversations_direct_key"
        ON "conversations" ("direct_key")
        WHERE "type" = 'direct' AND "direct_key" IS NOT NULL`,
      `CREATE TABLE "conversation_members" (
        "conversation_id" uuid NOT NULL REFERENCES "conversations"("id") ON DELETE CASCADE,
        "user_id" uuid NOT NULL REFERENCES "users"("id") ON DELETE CASCADE,
        "joined_at" timestamptz NOT NULL DEFAULT now(),
        "last_read_message_id" uuid,
        "last_read_at" timestamptz,
        "muted_until" timestamptz,
        PRIMARY KEY ("conversation_id", "user_id")
      )`,
      'CREATE INDEX "idx_conversation_members_user_id" ON "conversation_members" ("user_id")',
      `CREATE TABLE "messages" (
        "id" uuid PRIMARY KEY DEFAULT gen_random_uuid(),
        "client_message_id" uuid NOT NULL,
        "conversation_id" uuid NOT NULL REFERENCES "conversations"("id") ON DELETE CASCADE,
        "sender_id" uuid NOT NULL REFERENCES "users"("id") ON DELETE RESTRICT,
        "type" varchar(20) NOT NULL,
        "text" text,
        "reply_to_message_id" uuid REFERENCES "messages"("id") ON DELETE SET NULL,
        "created_at" timestamptz NOT NULL DEFAULT now(),
        "edited_at" timestamptz,
        "deleted_at" timestamptz,
        CONSTRAINT "chk_messages_type" CHECK ("type" IN ('text', 'image'))
      )`,
      'CREATE UNIQUE INDEX "uq_messages_sender_client_id" ON "messages" ("sender_id", "client_message_id")',
      'CREATE INDEX "idx_messages_conversation_order" ON "messages" ("conversation_id", "created_at" DESC, "id" DESC)',
      'ALTER TABLE "conversations" ADD CONSTRAINT "fk_conversations_last_message" FOREIGN KEY ("last_message_id") REFERENCES "messages"("id") ON DELETE SET NULL',
      'ALTER TABLE "conversation_members" ADD CONSTRAINT "fk_conversation_members_last_read_message" FOREIGN KEY ("last_read_message_id") REFERENCES "messages"("id") ON DELETE SET NULL',
      `CREATE TABLE "attachments" (
        "id" uuid PRIMARY KEY DEFAULT gen_random_uuid(),
        "message_id" uuid NOT NULL REFERENCES "messages"("id") ON DELETE CASCADE,
        "kind" varchar(20) NOT NULL,
        "storage_key" text NOT NULL,
        "mime_type" varchar(120) NOT NULL,
        "size_bytes" bigint NOT NULL,
        "width" integer,
        "height" integer,
        "created_at" timestamptz NOT NULL DEFAULT now(),
        CONSTRAINT "chk_attachments_kind" CHECK ("kind" IN ('image'))
      )`,
      'CREATE UNIQUE INDEX "uq_attachments_storage_key" ON "attachments" ("storage_key")',
      'CREATE INDEX "idx_attachments_message_id" ON "attachments" ("message_id")',
    ];

    for (const statement of statements) {
      await queryRunner.query(statement);
    }
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    const statements = [
      'DROP TABLE IF EXISTS "attachments"',
      'ALTER TABLE "conversation_members" DROP CONSTRAINT IF EXISTS "fk_conversation_members_last_read_message"',
      'ALTER TABLE "conversations" DROP CONSTRAINT IF EXISTS "fk_conversations_last_message"',
      'DROP TABLE IF EXISTS "messages"',
      'DROP TABLE IF EXISTS "conversation_members"',
      'DROP TABLE IF EXISTS "conversations"',
      'DROP TABLE IF EXISTS "device_tokens"',
      'DROP TABLE IF EXISTS "refresh_sessions"',
      'DROP TABLE IF EXISTS "users"',
    ];

    for (const statement of statements) {
      await queryRunner.query(statement);
    }
  }
}
