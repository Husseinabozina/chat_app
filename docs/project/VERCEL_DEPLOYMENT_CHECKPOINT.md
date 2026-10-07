# Vercel backend deployment checkpoint

Updated: 2026-10-07. Status: cloud resources and schema provisioned; deployed API acceptance/promotion pending.

## Live provisioning progress — 2026-10-07

- Verified local/PR #28 HEAD: `a06148ff3309d7956a95f7a0127d250b4a05aa3d`. Backend CI `37479702684` and Mobile CI `37479702698` both completed/success on this exact HEAD.
- Vercel CLI 62.7.0 authenticated to the intended Hobby team `abozina50-1441`. Created and linked only `chat-app-backend` (`prj_2cH9bcfiVAqWo9VHUaHUyoAfnJUY`); the existing unrelated project is untouched.
- Selected NestJS preset, Node 24, `npm ci --no-audit --no-fund` and `npm run build`. CLI deployment directory is `apps/backend`, so the linked project's relative root is `.`. No Git integration has been created yet.
- Created private Vercel Blob `chat-app-media` (`store_emnloA7kffpPunSE`), Frankfurt `fra1`, connected only to production. Blob integration into the existing S3 upload contract remains implementation/acceptance work; creation alone does not make media operational.
- User explicitly approved marketplace terms/account-data sharing. Neon `free_v3` `chat-app-postgres` (`store_JlQHAQ5ySeCzQjJM`, external `small-water-21829944`), Frankfurt, built-in Neon Auth disabled, production only; Upstash Redis `free` `chat-app-realtime` (`store_hyynRjD43XVLW7Im`), Frankfurt, automatic paid upgrades disabled, production only. Both resources are ready and connected.
- All six migrations succeeded using the direct cloud connection with certificate/hostname validation; initial public table count was zero. No production E2E truncation was run.
- `MEDIA_PROVIDER=vercel-blob` enables additive PUT tickets and private downloads using `@vercel/blob` 2.8.1. Each pending upload is scoped to its random path, MIME type, declared maximum size and five-minute lifetime. Completion checks exact bytes/format/pixel budget and creates a different immutable JPEG key; replaying the pending PUT cannot modify finalized media. Existing S3/local contract stays compatible.
- Actual provider acceptance passed: Redis TLS/PING; direct Blob PUT; bounded sanitized JPEG; signed GET; unsigned private GET denied. Only task-owned temporary provider fixtures were removed. Full deployed REST membership/owner isolation and native picker acceptance remain pending.
- Redis adapter promises register with `@vercel/functions` 3.9.11 `waitUntil`, retaining bounded error handling after a Fluid HTTP response. Push remains disabled until credential/native-delivery acceptance.
- `.vercel` and local environment files are ignored; no credentials are committed. Existing native mobile modifications remain unstaged. No deployment, promotion or mobile origin changes yet.

## Starting point

- Verified PR #27 HEAD: `3fffa67aa3c0b4b00dcb8e90d8cf94019b459c29`, branch `feat/mobile-showcase-polish`.
- Preparation branch: `feat/backend-vercel-deployment`, [Draft PR #28](https://github.com/Husseinabozina/chat_app/pull/28), directly above #27. Implementation `302f58e8f0faf9726c0b208de7d4e3125bad0361`; no merge or force push.
- Native platform migrations already present in the local checkout are excluded.

## Deployment design

- NestJS 12 / TypeScript 6 / Node 24, existing REST contracts and PostgreSQL authorization remain authoritative.
- Vercel project root: `apps/backend`. Existing `src/main.ts` uses native NestJS detection; no legacy catch-all handler or request-time migrations.
- `npm ci --no-audit --no-fund` then `npm run build`. Frankfurt (`fra1`) is the proposed region, near the existing Supabase organization projects' region.
- Current Vercel documentation supports WebSockets in public beta on all plans with Fluid compute. Existing mobile Socket.IO client already uses only the WebSocket transport. Function duration still causes disconnects; existing reconnect and REST recovery remain required.
- Redis Pub/Sub adapter shares user/session-room publication and session disconnect across instances. Redis stores no durable message data. TLS and an explicit application/environment channel prefix are required on Vercel. Keep production and preview credentials isolated; a prefix alone is not a security boundary.
- Ioredis 5.11.1 is pinned: current Ioredis 6 conflicts with TypeORM's optional peer range. No force/legacy-peer-deps workaround. Socket.IO's official documentation also recommends Ioredis over node-redis where subscription recovery is a concern.
- Redis connection setup is bounded; shutdown closes connections. Unawaited adapter commands have rejection handling so Redis outages do not crash REST. Redis Pub/Sub has no durable replay: recover messages through REST. Immediate remote logout disconnect depends on Redis availability; existing JWT expiry and database session checks remain the authorization boundary.
- PostgreSQL pools default to five connections per function instance, bounded connection/idle/query timeouts, and limited startup retries. Provider TLS must validate certificates; no `rejectUnauthorized: false` bypass.
- `DATABASE_URL` is the runtime pooler connection. Optional `DATABASE_MIGRATION_URL` is a direct/session connection for one-off migrations. Run migrations once before promotion; never run destructive E2E suites against a deployed/demo database.

## Required cloud configuration

Provide secrets through Vercel environment settings, never Git:

| Variable | Purpose |
|---|---|
| `DATABASE_URL` | Managed PostgreSQL URL with provider TLS settings |
| `DATABASE_POOL_MAX` | Per-instance pool; default 5, permitted 1–20 |
| `DATABASE_MIGRATION_URL` | Optional migration connection; supply to migration operator only |
| `ACCESS_TOKEN_SECRET` | New random production secret, at least 32 characters |
| `REALTIME_REDIS_URL` | Authenticated `rediss://` TCP Redis endpoint; a REST-only token is insufficient |
| `REALTIME_REDIS_PREFIX` | Stable production channel prefix shared across production instances |
| `MEDIA_*` | Private compatible object store credentials and reachable signing endpoint |
| `PUSH_ENABLED` | Keep false until cloud credentials and delivery acceptance exist |

Runtime filesystem and local MinIO/PostgreSQL cannot serve as cloud persistence. Database/provider selection is pending. An inactive Supabase project named `chat-app`, created in 2024, was discovered read-only; it has not been restored, modified or assumed to belong to this application. Other projects have not been changed.

Current image tickets use S3 presigned POST. Supabase's published S3 compatibility list documents PUT but does not establish presigned POST compatibility. Verify the chosen storage provider or implement/verify an additive upload transport before claiming photo deployment works. No provider migration or upload-contract change has been made here.

## Verification and publication order

1. Read actual base/head and preserve the user's native changes.
2. Run read-only format/lint/typecheck/build checks. CI remains `npm ci → format:check → lint → typecheck → build → migrations → npm test` with disposable PostgreSQL 17 and Redis 7 services.
3. Sign into Vercel, select the account/project and provision approved isolated cloud dependencies; confirm any provider cost before provisioning.
4. Run migrations on the selected cloud database. Deploy a preview and check actual Vercel bundling/decorator metadata, native Argon2/Sharp dependencies and function size.
5. Verify public health, register/login/refresh/logout, two-account durable messages, realtime/reconnect and remote session revocation. Verify private image upload/download authorization and account isolation with the real storage provider.
6. Promote the verified deployment and configure mobile `CHAT_API_BASE_URL` to its stable HTTPS origin. Do not commit secrets or silently switch the app to an unverified URL.
7. Record exact deployment URL, commit and CI runs in `CURRENT_STATE.md` and PR metadata.

## Verified preparation

- Node 24.21.0 local read-only format, lint, typecheck and Nest build passed.
- [Backend CI](https://github.com/Husseinabozina/chat_app/actions/runs/37479424513) completed/success on exact implementation `302f58e8f0faf9726c0b208de7d4e3125bad0361`: npm ci, format, lint, typecheck, build, migrations and all five suites, with realtime clients on two Nest instances connected through Redis.
- [Mobile CI](https://github.com/Husseinabozina/chat_app/actions/runs/37479424101) quality passed; its integration and documentation follow-up results are recorded in PR #28 after completion.
- Task-owned local API restarted on Node 24.21.0. Real health/database, temporary registration/login and existing showcase-account login passed; temporary account/session verification cleaned up by the helper. Demo accounts/messages remain intact.
- Final documentation HEAD is recorded in PR metadata to avoid embedding the file's own commit hash. No cloud acceptance is inferred from local/CI verification.

## Outstanding acceptance

- First Vercel runtime attempt failed with `ERR_REQUIRE_ESM`: the hosted Lambda runtime disabled CommonJS `require(esm)` for Nest 12. Configured production `NODE_OPTIONS=--experimental-require-module`, as documented by Nest for Lambda; the next invocation passed this boundary. It then exposed omitted `pg` in the serverless file trace because TypeORM loads drivers dynamically. An explicit `pg` import retains that existing dependency in the deployment. No framework downgrade or application-wide module conversion.
- Vercel account access and approved Neon/Upstash/private Blob provisioning are complete.
- The cloud database schema and direct-provider checks are complete. Actual deployed API/realtime/media verification and promotion remain pending.
- No preview/production URL exists and mobile continues using its existing local configuration.
- The local backend's earlier hot CPU/unresponsive event was recovered by restarting. Its root cause was not established; local Node 24.9 was below current dependency engine requirements. Task runtime 24.21.0 was downloaded from nodejs.org and checksum verified. This does not prove the hang's root cause or cloud reliability.
- Native Simulator is not opened for this checkpoint, per the user's request.
- Actual CI outcome is recorded in the PR/checkpoint update after publication; do not infer success from prior PR #27.

Sources checked on 2026-10-06: [Vercel NestJS](https://vercel.com/docs/frameworks/backend/nestjs), [Vercel WebSockets](https://vercel.com/docs/functions/websockets), [Socket.IO Redis adapter](https://socket.io/docs/v4/redis-adapter/), [Supabase S3 compatibility](https://supabase.com/docs/guides/storage/s3/compatibility).
