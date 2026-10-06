# Vercel backend deployment checkpoint

Updated: 2026-10-06. Status: preparation; no public deployment exists yet.

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

- Vercel login/account access, organization/database choice and provider credentials are pending user input.
- No cloud database, Redis or object store has been created here; no cloud migrations have run.
- No preview/production URL exists and mobile continues using its existing local configuration.
- The local backend's earlier hot CPU/unresponsive event was recovered by restarting. Its root cause was not established; local Node 24.9 was below current dependency engine requirements. Task runtime 24.21.0 was downloaded from nodejs.org and checksum verified. This does not prove the hang's root cause or cloud reliability.
- Native Simulator is not opened for this checkpoint, per the user's request.
- Actual CI outcome is recorded in the PR/checkpoint update after publication; do not infer success from prior PR #27.

Sources checked on 2026-10-06: [Vercel NestJS](https://vercel.com/docs/frameworks/backend/nestjs), [Vercel WebSockets](https://vercel.com/docs/functions/websockets), [Socket.IO Redis adapter](https://socket.io/docs/v4/redis-adapter/), [Supabase S3 compatibility](https://supabase.com/docs/guides/storage/s3/compatibility).
