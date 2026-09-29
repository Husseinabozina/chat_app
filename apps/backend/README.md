# Backend

NestJS modular-monolith backend for the messaging platform.

## Stack

- Node.js 24 LTS baseline
- NestJS 12
- PostgreSQL 17
- TypeORM
- Jest + ts-jest for backend tests
- ESLint + Prettier for static quality gates
- WebSocket support will be introduced with the realtime module
- S3-compatible object storage and FCM will be added at the relevant feature checkpoints

## TypeScript baseline

The backend deliberately uses the supported TypeScript 5.9 line rather than TypeScript 7 for now.

The current TypeScript ESLint and ts-jest ecosystem does not yet support TypeScript 7 reliably. Keeping the compiler on a supported version gives us deterministic linting and test transforms while preserving strict TypeScript settings. This can be revisited when the ecosystem declares TypeScript 7 support.

## Setup

```bash
cp .env.example .env
npm install
npm run start:dev
```

Start PostgreSQL from the repository root:

```bash
docker compose -f infra/docker-compose.yml up -d
```

## Quality commands

```bash
npm run format:check
npm run lint
npm run typecheck
npm test
npm run build
```

## Database migrations

Schema changes are migration-driven. Runtime synchronization stays disabled.

```bash
npm run migration:run
npm run migration:revert
```

The first identity migration creates `users` and `refresh_sessions`, including database-level uniqueness and foreign-key constraints.

## Health

```http
GET /v1/health
```

The endpoint verifies that the API can query PostgreSQL.

## Current module baseline

```text
src/
  bootstrap/
  database/
  health/
```

Future modules are added only when implementation reaches their feature slice:

```text
auth/
users/
conversations/
messages/
media/
notifications/
realtime/
common/
```

This avoids creating empty architecture folders only for appearance.
