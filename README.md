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

The project is currently in the foundation phase.

- Product scope: documented
- UI direction: documented
- System architecture: documented
- REST/realtime contracts: documented
- Monorepo: initialized
- Backend: bootstrapped
- Flutter client: moved under `apps/mobile` without feature refactoring yet

## Development

### PostgreSQL

```bash
docker compose -f infra/docker-compose.yml up -d
```

### Backend

```bash
cd apps/backend
cp .env.example .env
npm install
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

The mobile application is still the legacy Flutter implementation at this checkpoint. Modernization and feature-first restructuring happen in subsequent commits.

## Engineering workflow

- One logical verified change per meaningful commit.
- One coherent feature/foundation unit per branch/PR.
- No direct feature development on `master`.
- Product and architecture contracts are updated when implementation decisions materially change them.
