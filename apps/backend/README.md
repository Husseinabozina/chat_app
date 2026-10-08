# Backend

NestJS API for the messaging platform. The current backend provides authentication, user discovery, direct conversations, and durable text/image-message and read-state REST endpoints, authenticated Socket.IO publication, and private photo storage authorization.

## Stack

- Node.js 24 LTS, at least 24.15 (`.nvmrc` at the repository root)
- NestJS 12 and TypeScript 6
- PostgreSQL 17 and TypeORM with explicit migrations (`synchronize: false`)
- Node's test runner against the compiled Nest application
- ESLint and Prettier quality gates

## Local development

From the repository root, start PostgreSQL:

```bash
docker compose -f infra/docker-compose.yml up -d
```

Then, from `apps/backend`:

```bash
cp .env.example .env
npm ci
npm run db:migrate
npm run start:dev
```

Set a local `ACCESS_TOKEN_SECRET` of at least 32 characters in `.env`. `db:migrate` builds the application and applies pending migrations. The API listens on port 3000 by default. `GET /v1/health` checks the API's PostgreSQL connection.

## Quality checks

Run these from `apps/backend` with PostgreSQL available:

```bash
npm run format:check
npm run lint
npm run typecheck
npm run build
node dist/database/migrate.js
npm test
```

`npm test` typechecks the E2E files, then runs health, auth, user discovery, messaging and realtime suites sequentially in separate Node processes. The tests load the compiled `dist/` application, so build before testing. The suites reset test data; use a dedicated test database. With `REALTIME_REDIS_URL`, realtime coverage connects clients to two different Nest instances and checks cross-instance delivery, typing, authorization, reconnect recovery and session revocation.

Backend CI performs the same ordered checks with `npm ci`, Node 24, and PostgreSQL 17. The workflow has read-only repository permissions.

## Vercel deployment

Public origin: `https://chat-app-backend-two-tawny.vercel.app`. Actual health/database, auth, direct messages, realtime delivery/recovery/session disconnect and private media acceptance passed on 2026-10-07.

Use `apps/backend` as the Vercel project root, Node 24 and native NestJS detection (`src/main.ts`). `vercel.json` locks the install/build commands and Frankfurt region. Fluid compute is required for WebSockets. Set production `NODE_OPTIONS=--experimental-require-module` for NestJS 12 in the hosted Lambda runtime. Explicit imports retain the dynamically loaded PostgreSQL driver and optional WebSocket module in serverless tracing. See [`VERCEL_DEPLOYMENT_CHECKPOINT.md`](../../docs/project/VERCEL_DEPLOYMENT_CHECKPOINT.md) for the exact deployment, cloud dependencies and remaining acceptance.

Private Vercel Blob: set `MEDIA_PROVIDER=vercel-blob` and a production-only `BLOB_READ_WRITE_TOKEN`. Upload tickets use direct `PUT` with returned headers; S3 tickets retain multipart `POST`. Upload/download grants expire after five minutes. The API still verifies ownership, conversation membership, exact size and decoded image limits before storing a separate immutable sanitized JPEG. Cloud migrations use the direct database connection once, never application startup; Redis uses a TLS TCP URL, not its REST token.

## Modules

```text
src/
  auth/
  bootstrap/
  common/
  conversations/
  database/
  health/
  messages/
  media/
  push/
  realtime/
  users/
```

The current REST endpoints and response contracts are documented in `docs/api/api-contract-v1.md`. Private media is implemented in PR #25 and verified against private Vercel Blob in PR #28. See `docs/project/MEDIA_CHECKPOINT.md`. Push registration/FCM adapter is implemented but requires explicit credentials/configuration and actual delivery acceptance; see `docs/project/PUSH_CHECKPOINT.md`. Production `PUSH_ENABLED` remains false.

For a non-Google server such as Vercel, configure `FCM_PROJECT_ID` and the
encrypted server-only `FCM_SERVICE_ACCOUNT_JSON` secret for that exact project.
The existing local `GOOGLE_APPLICATION_CREDENTIALS`/ADC path remains supported.
Never commit a service-account key or include it in Flutter configuration.
Enable push only after provider authorization and native delivery acceptance.
Bounded best-effort jobs use Vercel request continuations; this is not a durable
notification outbox.
