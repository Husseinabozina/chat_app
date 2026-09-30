# Backend

NestJS API for the messaging platform. The current backend provides authentication, user discovery, direct conversations, and durable text-message and read-state REST endpoints. Realtime transport is a later checkpoint.

## Stack

- Node.js 24 (`.nvmrc` at the repository root)
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

`npm test` typechecks the E2E files, then runs the health, auth, user discovery, and messaging suites sequentially in separate Node processes. The tests load the compiled `dist/` application, so build before testing. The auth and messaging suites reset test data; use a dedicated test database.

Backend CI performs the same ordered checks with `npm ci`, Node 24, and PostgreSQL 17. The workflow has read-only repository permissions.

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
  users/
```

The current REST endpoints and response contracts are documented in `docs/api/api-contract-v1.md`. Media uploads, push notifications, and WebSocket delivery remain separate checkpoints.
