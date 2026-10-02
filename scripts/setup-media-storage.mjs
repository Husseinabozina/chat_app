#!/usr/bin/env node
// Explicit storage setup. Creates a private bucket and pending-only expiry.
import { createRequire } from "node:module";
import { loadEnvFile } from "node:process";
const require = createRequire(
  new URL("../apps/backend/package.json", import.meta.url),
);
const {
  S3Client,
  HeadBucketCommand,
  GetBucketLifecycleConfigurationCommand,
  CreateBucketCommand,
  PutBucketLifecycleConfigurationCommand,
} = require("@aws-sdk/client-s3");
try {
  loadEnvFile(new URL("../apps/backend/.env", import.meta.url));
} catch {
  /* caller may inject env */
}
if (!process.env.MEDIA_BUCKET)
  throw new Error("Configure MEDIA_BUCKET and S3 access before setup.");
const client = new S3Client({
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
try {
  try {
    await client.send(
      new HeadBucketCommand({ Bucket: process.env.MEDIA_BUCKET }),
    );
  } catch (error) {
    if (error.$metadata?.httpStatusCode !== 404) throw error;
    await client.send(
      new CreateBucketCommand({
        Bucket: process.env.MEDIA_BUCKET,
        ...(process.env.MEDIA_REGION && process.env.MEDIA_REGION !== "us-east-1"
          ? {
              CreateBucketConfiguration: {
                LocationConstraint: process.env.MEDIA_REGION,
              },
            }
          : {}),
      }),
    );
  }
  let existingRules = [];
  try {
    const existing = await client.send(
      new GetBucketLifecycleConfigurationCommand({
        Bucket: process.env.MEDIA_BUCKET,
      }),
    );
    existingRules = existing.Rules ?? [];
  } catch (error) {
    if (
      error.name !== "NoSuchLifecycleConfiguration" &&
      error.$metadata?.httpStatusCode !== 404
    )
      throw error;
  }
  await client.send(
    new PutBucketLifecycleConfigurationCommand({
      Bucket: process.env.MEDIA_BUCKET,
      LifecycleConfiguration: {
        Rules: [
          ...existingRules.filter(
            (rule) => rule.ID !== "expire-pending-uploads",
          ),
          {
            ID: "expire-pending-uploads",
            Status: "Enabled",
            Filter: { Prefix: "pending/" },
            Expiration: { Days: 1 },
          },
        ],
      },
    }),
  );
  console.log(
    "Private bucket ready; pending originals expire after one day. Other lifecycle rules are preserved.",
  );
} finally {
  client.destroy();
}
