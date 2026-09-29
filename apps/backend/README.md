# Backend

NestJS modular-monolith backend for the messaging platform.

## Stack

- Node.js 24 LTS baseline
- NestJS 12
- PostgreSQL
- TypeORM
- WebSocket support will be introduced with the realtime module
- S3-compatible object storage and FCM will be added at the relevant feature checkpoints

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

## Health

```http
GET /v1/health
```

The endpoint verifies that the API can query PostgreSQL.

## Current module baseline

```text
src/
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
