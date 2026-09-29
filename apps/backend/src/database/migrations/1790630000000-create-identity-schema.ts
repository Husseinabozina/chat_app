import type { MigrationInterface, QueryRunner } from 'typeorm';

export class CreateIdentitySchema1790630000000 implements MigrationInterface {
  name = 'CreateIdentitySchema1790630000000';

  async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      CREATE TABLE "users" (
        "id" uuid NOT NULL DEFAULT gen_random_uuid(),
        "email" varchar(320) NOT NULL,
        "email_normalized" varchar(320) NOT NULL,
        "password_hash" text NOT NULL,
        "display_name" varchar(120),
        "username" varchar(32),
        "username_normalized" varchar(32),
        "bio" varchar(280),
        "avatar_storage_key" text,
        "created_at" timestamptz NOT NULL DEFAULT now(),
        "updated_at" timestamptz NOT NULL DEFAULT now(),
        CONSTRAINT "pk_users" PRIMARY KEY ("id"),
        CONSTRAINT "ck_users_email_normalized_lowercase"
          CHECK ("email_normalized" = lower("email_normalized")),
        CONSTRAINT "ck_users_username_normalized_lowercase"
          CHECK (
            "username_normalized" IS NULL
            OR "username_normalized" = lower("username_normalized")
          )
      )
    `);

    await queryRunner.query(`
      CREATE UNIQUE INDEX "uq_users_email_normalized"
      ON "users" ("email_normalized")
    `);

    await queryRunner.query(`
      CREATE UNIQUE INDEX "uq_users_username_normalized"
      ON "users" ("username_normalized")
      WHERE "username_normalized" IS NOT NULL
    `);

    await queryRunner.query(`
      CREATE TABLE "refresh_sessions" (
        "id" uuid NOT NULL DEFAULT gen_random_uuid(),
        "user_id" uuid NOT NULL,
        "token_hash" char(64) NOT NULL,
        "expires_at" timestamptz NOT NULL,
        "created_at" timestamptz NOT NULL DEFAULT now(),
        "revoked_at" timestamptz,
        "device_metadata" jsonb,
        CONSTRAINT "pk_refresh_sessions" PRIMARY KEY ("id"),
        CONSTRAINT "fk_refresh_sessions_user"
          FOREIGN KEY ("user_id")
          REFERENCES "users"("id")
          ON DELETE CASCADE
      )
    `);

    await queryRunner.query(`
      CREATE INDEX "idx_refresh_sessions_user_id"
      ON "refresh_sessions" ("user_id")
    `);

    await queryRunner.query(`
      CREATE INDEX "idx_refresh_sessions_expires_at"
      ON "refresh_sessions" ("expires_at")
    `);
  }

  async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query('DROP TABLE IF EXISTS "refresh_sessions"');
    await queryRunner.query('DROP TABLE IF EXISTS "users"');
  }
}
