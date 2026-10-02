#!/usr/bin/env node
// Dry-run by default. Never remove active avatars or live image messages.
import { createRequire } from "node:module";
import { loadEnvFile } from "node:process";
const require = createRequire(
  new URL("../apps/backend/package.json", import.meta.url),
);
const { Client } = require("pg");
const { S3Client, DeleteObjectCommand } = require("@aws-sdk/client-s3");
try {
  loadEnvFile(new URL("../apps/backend/.env", import.meta.url));
} catch {
  /* environment may be injected */
}
if (!process.env.MEDIA_BUCKET || !process.env.DATABASE_URL)
  throw new Error("Media/database configuration required.");
const db = new Client({ connectionString: process.env.DATABASE_URL });
const storage = new S3Client({
  endpoint: process.env.MEDIA_ENDPOINT || undefined,
  region: process.env.MEDIA_REGION ?? "us-east-1",
  forcePathStyle: process.env.MEDIA_PATH_STYLE === "true",
  credentials:
    process.env.MEDIA_ACCESS_KEY && process.env.MEDIA_SECRET_KEY
      ? {
          accessKeyId: process.env.MEDIA_ACCESS_KEY,
          secretAccessKey: process.env.MEDIA_SECRET_KEY,
        }
      : undefined,
});
const apply = process.argv.includes("--apply");
await db.connect();
try {
  await db.query("BEGIN");
  const { rows } =
    await db.query(`SELECT m.id,m.storage_key FROM media_uploads m
    WHERE NOT EXISTS (SELECT 1 FROM users u WHERE u.avatar_url = '/v1/media/' || m.id || '/content')
    AND ((m.claimed_message_id IS NULL AND m.expires_at < now())
      OR EXISTS (SELECT 1 FROM messages msg WHERE msg.id=m.claimed_message_id AND msg.deleted_at < now()-interval '7 days'))
    ORDER BY m.created_at LIMIT 100 FOR UPDATE OF m SKIP LOCKED`);
  if (apply)
    for (const row of rows) {
      if (row.storage_key)
        await storage.send(
          new DeleteObjectCommand({
            Bucket: process.env.MEDIA_BUCKET,
            Key: row.storage_key,
          }),
        );
      await db.query("DELETE FROM media_uploads WHERE id=$1", [row.id]);
    }
  await db.query(apply ? "COMMIT" : "ROLLBACK");
  console.log(
    `${apply ? "Removed" : "Eligible (dry run)"}: ${rows.length} expired/unreferenced or long-deleted images. Active references retained.`,
  );
} catch (error) {
  await db.query("ROLLBACK");
  throw error;
} finally {
  await db.end();
  storage.destroy();
}
