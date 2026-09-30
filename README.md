# Realtime Messaging Platform

A zero-to-hero portfolio product that documents and implements the complete journey from product research and UX through backend, Flutter, testing, CI/CD, deployment, monitoring, and production documentation.

> The product name is not final yet. The repository name remains `chat_app` during the foundation phase.

## Monorepo

```text
apps/
  mobile/      Flutter client
  backend/     NestJS API + realtime backend

docs/
  product/
  design/
  architecture/
  api/

infra/
  docker-compose.yml
```

## Current status

[Current project state](docs/project/CURRENT_STATE.md) records the verified branch, PR stack, completed checkpoints, CI, deferred work, and exact next checkpoint. Keep that file updated before closing each checkpoint.

The backend now has auth, user discovery, direct conversations, durable text messages, read pointers, and message lifecycle REST behavior. The Flutter client has a feature-first structure and still runs its legacy Firebase-backed chat behavior. Realtime/WebSocket transport has not been integrated into the active backend chain.

## Development

### PostgreSQL

```bash
docker compose -f infra/docker-compose.yml up -d
```

### Backend

```bash
cd apps/backend
cp .env.example .env
npm ci
npm run db:migrate
npm run start:dev
```

Health endpoint:

```text
GET http://localhost:3000/v1/health
```

### Flutter

```bash
cd apps/mobile
flutter pub get
flutter run
```

See the backend and mobile READMEs for current development and quality commands.

## Engineering workflow

- One logical verified change per meaningful commit.
- One coherent feature/foundation unit per branch/PR.
- No direct feature development on `master`.
- Product and architecture contracts are updated when implementation decisions materially change them.
