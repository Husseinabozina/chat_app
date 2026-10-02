# Private profile and message images

2026-10-02. Branch `feat/media-images`, based on PR #24 implementation `06689b770171a607c7279320994e43a587cd07ad`. PR #24 Mobile CI #33 run37025464141 success; base PR #23 exact HEAD1dd304b with CI #32 success.

## Implemented

- Authenticated media upload authorization (avatar or a membership-checked conversation), signed direct POST to private S3-compatible storage, exact declared byte length capped at 6 MB, 5-minute upload capability and 20-minute completion window.
- Server verifies/decodes JPEG/PNG/WebP, rejects animated/oversized-pixel input, applies orientation, strips original metadata and re-encodes JPEG (avatar max768, message max2048). Two concurrent decoders per app instance; ready media IDs remain claimable for 7 days.
- SQL migration adds media_uploads and unique messages.image_media_id. Uploads are bound to actor/purpose/conversation. Same sender/client-message idempotency and post-commit realtime remain; images are claimed under a transaction/row lock and cannot be reused in another message or conversation.
- GET /media/:id/content authorizes active avatar or conversation membership/live message and returns a short-lived signed URL. Soft deletion hides references and refuses new grants; previously granted URLs expire within 5 minutes. Only resource IDs/API references persist, not signed URLs.
- Mobile media port encapsulates picker/HTTP. Photos/Camera selection, preview, optional caption, bounded upload, retry retaining ticket/ready ID, failed-send retries preserving client message ID, photo bubbles and zoomable viewer. Profile photo is attached on Save profile, not merely on choosing a preview. Real avatars replace illustrated fallback where present.
- New custom photo/camera glyphs; no mobile dependency/lockfile change. Backend pins AWS SDK3.1145.0 and sharp0.35.5 with updated lockfile.
- Corrected first-run onboarding revision2: old development flags could have been set automatically without viewing onboarding. Show the introduction once for those records; preserve credentials/theme/motion. Explicit completion/Skip prevents later replay; Settings replay remains removed.

## Local runtime and data

Private MinIO fixture is running on loopback55419 (console55420); data `/Volumes/Hussein/DevStorage/Runtime/chat_app/minio`. Task-owned binary is the checksum-verified Homebrew bottle RELEASE.2025-10-15T17-29-55Z; this archived release is a local fixture, not the production deployment choice. Credentials are outside Git in mode600 runtime config. Current API55418 uses the same database/signing secret after restart; no database reset. New migration applied. Actual local demo profile photo and one image message were uploaded/sanitized/persisted through the API and private store by the explicit loopback-only seeder. No image/media bytes travel over Socket.IO.

## Setup / cleanup

Configure MEDIA_BUCKET, MEDIA_REGION, optional MEDIA_ENDPOINT/MEDIA_PUBLIC_ENDPOINT/path style, and scoped credentials or AWS default credential provider. MEDIA_PUBLIC_ENDPOINT supports a client-reachable signing endpoint distinct from the server endpoint. Storage must support signed POST; MinIO is exercised, public provider deployment remains unverified (do not assume every S3-compatible provider supports POST).

From repository root run `node scripts/setup-media-storage.mjs` explicitly; it preserves other lifecycle rules and expires pending originals after one day. Optional Compose media profile uses a private loopback fixture. `node scripts/cleanup-media.mjs` is a dry run; `--apply` explicitly purges at most100 expired unused/long-deleted rows and their objects, preserving active avatars/live messages. Cleanup is not scheduled or executed destructively in this checkpoint. Objects orphaned by storage success followed by database rollback still need a bucket reconciliation pass before production.

## Verification boundary

Host format/analyzer, backend lint/typecheck/build and migration succeeded. Implementation `5baf62fe7941496b361f1477c378e1fe69136243` in Draft PR #25 passed Backend CI #84 (run37029887146) and Mobile CI #34 (run37029887362), including the established two-account REST/realtime integration; no additional test suite was added (existing fake port signature updated for optional media parameter). New native picker/camera/image rendering is not visually accepted: user owns build/run; no simulator or iOS build initiated. Existing CI does not exercise the full media authorization matrix or device picker. Record final exact-head checks in PR metadata/CURRENT_STATE.

## Next

Push device-token lifecycle, FCM credentials/configuration, conversation routing and supported Settings. Cloud deployment hardening, native/iOS/Android/physical/two-device acceptance and release signing remain. Do not claim the app is ready for release. No merge/force push.
