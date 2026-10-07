# Vercel backend deployment checkpoint

Updated: 2026-10-07. Status: production REST, realtime and private media accepted; native cloud acceptance and push delivery remain separate.

## Verified production

- Branch `feat/backend-vercel-deployment`, [PR #28](https://github.com/Husseinabozina/chat_app/pull/28), directly above PR #27 (`feat/mobile-showcase-polish`, verified base `3fffa67aa3c0b4b00dcb8e90d8cf94019b459c29`). No merge or force push.
- Deployed implementation: `345f26af3a31cae9805196682f627560b97341a2`.
- [Backend CI](https://github.com/Husseinabozina/chat_app/actions/runs/37568824601) and [Mobile CI](https://github.com/Husseinabozina/chat_app/actions/runs/37568824641) completed/success on that exact implementation, including two-account REST/realtime integration. Final documentation/configuration HEAD and checks are recorded in PR metadata to avoid self-referential hashes.
- Vercel project `chat-app-backend` (`prj_2cH9bcfiVAqWo9VHUaHUyoAfnJUY`), intended Hobby team `abozina50-1441`, Node 24 / NestJS preset / Fluid compute, runtime Frankfurt `fra1`.
- Promoted deployment `dpl_DVAei46DKqeTReg4Wfdrsmr6RTY8`: `https://chat-app-backend-qrg2tgvz0-abozina50-1441.vercel.app`.
- Stable public project domain: **https://chat-app-backend-two-tawny.vercel.app**. Unauthenticated `GET /v1/health` returned 200 with database up. The generated team/deployment aliases remain behind Vercel Authentication; deployment protection was not disabled. The verified public project domain was assigned to the same promoted artifact.
- CLI deployment root is `apps/backend` (linked relative root `.`). No Git integration created yet; future monorepo Git integration must use `apps/backend`. The unrelated existing Vercel project is untouched.

## Cloud persistence and configuration

| Resource                             | Selection                                                                                  | Scope           |
| ------------------------------------ | ------------------------------------------------------------------------------------------ | --------------- |
| Neon PostgreSQL `chat-app-postgres`  | `free_v3`, Frankfurt, built-in Neon Auth disabled; `store_JlQHAQ5ySeCzQjJM`                | Production only |
| Upstash Redis `chat-app-realtime`    | Free, Frankfurt; automatic paid upgrade/production pack disabled; `store_hyynRjD43XVLW7Im` | Production only |
| Private Vercel Blob `chat-app-media` | Frankfurt; `store_emnloA7kffpPunSE`                                                        | Production only |

Marketplace terms/account-data sharing were accepted after explicit user approval. No paid plan or automatic paid upgrade was enabled. These services remain subject to provider quotas; no unlimited-capacity claim.

All six migrations were applied once using Neon’s direct connection with certificate/hostname validation. The database was initially empty. Application startup never runs migrations, and no destructive E2E suite targeted the cloud or local demo database.

Secrets are stored in Vercel production configuration and private operator files, never Git. `DATABASE_URL` uses the runtime pooler, `DATABASE_POOL_MAX=3`, `REALTIME_REDIS_URL` is an authenticated TLS TCP URL, and `REALTIME_REDIS_PREFIX=chat-app:production:v1`. The access-token secret is newly generated for production. `MEDIA_PROVIDER=vercel-blob` selects private Blob; `PUSH_ENABLED=false` remains explicit.

## Runtime problems and fixes

1. The initial build succeeded, but hosted execution raised `ERR_REQUIRE_ESM` for NestJS 12. Lambda disabled CommonJS `require(esm)`. Production `NODE_OPTIONS=--experimental-require-module` restores the support recommended by Nest’s migration guide. No framework downgrade or application-wide module conversion.
2. TypeORM’s dynamic driver loading omitted `pg` from the serverless trace. Explicitly importing the existing dependency in `DatabaseModule` retains it. Database health and actual migrations/auth/message queries then passed.
3. Public Socket.IO requests returned 404 while REST worked. Nest dynamically loads its optional `@nestjs/websockets/socket-module` and silently proceeds without it when loading fails. An explicit import in `configure-realtime.ts` retains that module in tracing; actual cloud WebSocket delivery/reconnect/logout then passed. No alternate realtime protocol or product behavior was introduced.
4. The first acceptance helper incorrectly expected an already issued REST access JWT to be immediately invalid after logout. Existing REST authentication is stateless: access JWTs expire on their configured TTL (15 minutes); logout revokes refresh sessions and connected sockets, while new socket handshakes check the database session. Corrected the verification assertion to the existing refresh-revocation contract. No authentication architecture was changed.

## Private media and distributed publication

- Pinned `@vercel/blob` 2.8.1 and `@vercel/functions` 3.9.11 with a normal lockfile update. No force/legacy-peer-deps workaround.
- Blob upload grants authorize direct PUT to one random pending path, declared MIME/maximum size and a five-minute lifetime. Retrying can overwrite that pending object only. Completion still checks ownership/membership, exact bytes, image format/pixel budget, then writes a different immutable sanitized JPEG key.
- Private five-minute GET URLs are issued only after the existing API authorization. Direct uploads avoid relaying image bodies through the Function. Flutter understands PUT tickets while retaining local/S3 multipart POST support.
- Redis Pub/Sub coordinates user/session rooms across instances; PostgreSQL remains the durable source of truth. Ignored Redis adapter commands register their bounded promises with Vercel `waitUntil` so publication can finish after an HTTP response. This is not a durable event outbox.
- WebSocket connections can expire with Function duration. The existing reconnect and REST recovery path remains required; Pub/Sub offers no durable replay.

## Actual acceptance

Verified against the promoted public HTTPS origin, with disposable fictional accounts:

- Health/database, native Argon2 registration/login, DTO validation, profile writes.
- Direct-conversation uniqueness, persisted text messages, same-client-ID idempotent retry, cursor pagination, read state, edit and outsider isolation.
- Real direct Blob PUT, native Sharp sanitization, completion-owner isolation, private image messages, member download and outsider/unsigned denial.
- Authenticated WebSocket connection/event delivery, reconnect plus REST recovery, logout socket disconnect and revoked refresh denial.
- Provider checks also verified Redis TLS/PING and private storage behavior.

Removed only the task-created verification fixtures: 12 accounts, four conversations and six private objects. Identity and conversation membership checks preceded cleanup; no unrelated local/cloud data was removed. Existing local `@attest` and showcase accounts/history remain intact and have **not** been copied to cloud. Account/data transfer choice is still pending user response.

Host backend format/lint/typecheck/build and Flutter analyzer passed. CI remains read-only and reproducible: `npm ci → format:check → lint → typecheck → build → migrations → npm test`, using disposable PostgreSQL 17/Redis 7. No diagnostic workflow steps or temporary artifact uploads.

## Run mobile on cloud

`apps/mobile/config/cloud.json` contains the verified public origin only. From `apps/mobile`, using Flutter 3.47.5 / Dart 3.13 or newer:

```bash
flutter run --dart-define-from-file=config/cloud.json
```

Use the same define file for native builds. Restart the Flutter run to change compile-time configuration; hot reload alone does not switch origins. Cloud runs need no local API/PostgreSQL/MinIO. Debug’s ordinary local default remains available. Sign in again when changing environments; old local accounts are absent from the new database until explicitly transferred.

## Remaining checkpoint boundaries

- No Simulator access or iOS/native build in this checkpoint, as requested. Private picker/viewer, physical/two-device, background and release acceptance remain separate. Pre-existing iOS/macOS migrations and `Podfile.lock` remain local/unpublished.
- Push server credentials, APNs/signing and actual notification/account-routing acceptance remain incomplete; push is disabled honestly.
- Local-account/showcase transfer is awaiting the user’s selection. Cloud deployment does not imply that local accounts/history were copied.
- Scheduled media cleanup/orphan reconciliation, public abuse controls (including handshake attempt limits), future browser-origin policy, durable notification/event outboxes and offline persistence remain debt/release work. Current scope is the native messaging client.
- The earlier local hot CPU/unresponsive event recovered on restart; its root cause remains unproven. Cloud acceptance does not establish long-term reliability or resolve that local investigation.
- Future deploys: inspect actual HEAD/CI, stage production, verify the exact artifact, promote and verify the stable project domain, then update this checkpoint and `CURRENT_STATE.md`. Never run destructive test suites against cloud/demo data.

Sources checked 2026-10-07: [NestJS migration guide](https://docs.nestjs.com/migration-guide), [Vercel NestJS](https://vercel.com/docs/frameworks/backend/nestjs), [Vercel WebSockets](https://vercel.com/docs/functions/websockets), [signed Blob URLs](https://vercel.com/docs/vercel-blob/vercel-signed-urls), [Functions waitUntil](https://vercel.com/docs/functions/functions-api-reference/vercel-functions-package).
