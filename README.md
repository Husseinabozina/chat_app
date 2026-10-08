# Mingle

A friendly messaging app built with **Flutter and our own NestJS backend**.
Mingle uses a pastel pink/cream identity, original icons and restrained motion.
This repository follows the journey from product/design decisions to working
accounts, messaging, private photos, automated checks and cloud deployment.

## What works today

- Persisted first-run onboarding, branded opening, login/registration and secure session restoration.
- People search, public profiles and profile editing with photos.
- Unique direct conversations, text/photo messages and paginated history.
- Replies, copy/edit/soft delete, stable-ID retries, unread counts and read state.
- Realtime message changes and typing, reconnect recovery and logout disconnect.
- System/light/dark appearance, reduced-motion and account settings.
- Private image uploads with server validation and membership-checked downloads.

The active app uses the backend in this repository. The former Firebase chat
prototype is archived behind `lib/main_legacy.dart`. Firebase Cloud Messaging
provides the notification integration; our auth, API and message database are
implemented by our own backend. Push registration/routing is implemented, but
production push remains disabled until server credentials and native delivery
are verified.

## Backend and hosting

| Component                                | Role                                                                 |
| ---------------------------------------- | -------------------------------------------------------------------- |
| Node 24 / NestJS 12 / TypeScript 6       | Our authentication, profiles, messaging, media and realtime code     |
| PostgreSQL / explicit TypeORM migrations | Durable accounts, sessions, conversations, messages and read state   |
| Socket.IO                                | Transient delivery and typing; REST remains the durable command path |
| Vercel Fluid                             | Hosts our backend                                                    |
| Neon PostgreSQL                          | Hosted database                                                      |
| Upstash Redis                            | Coordination between backend instances                               |
| Private Vercel Blob                      | Validated, private image storage                                     |

Verified public API: `https://chat-app-backend-two-tawny.vercel.app`.
Health: [`GET /v1/health`](https://chat-app-backend-two-tawny.vercel.app/v1/health).
Hosted REST, private photos and realtime flows were verified on 2026-10-07.
The cloud showcase contains fictional profiles and conversations. Local
accounts are a separate environment and have not been migrated.

**This is a working portfolio project, not a completed store release.** Native
cloud/photo/push acceptance, public abuse controls and media cleanup remain.
Groups, calls, voice notes, social login and password recovery are not implemented.
See [CURRENT_STATE](docs/project/CURRENT_STATE.md) for the exact verified HEAD,
PR dependencies, acceptance boundaries and next checkpoint. Update it before
closing each checkpoint.

## Repository

```text
apps/mobile/       Flutter client
apps/backend/      Custom NestJS API + realtime gateway
docs/product/      Scope and product decisions
docs/design/       UI direction and references
docs/architecture/ Contracts and architecture decisions
docs/project/      Verified state and checkpoint reports
infra/             Local development services
scripts/           Brand tooling and explicit showcase seeders
```

## Run the mobile app against the cloud

Use **Flutter 3.47.5+ / Dart 3.13+**. From `apps/mobile`:

```bash
flutter pub get --enforce-lockfile
flutter run --dart-define-from-file=config/cloud.json
```

Use the correct SDK executable if your global Flutter is older. The cloud
configuration contains only the public origin. Local servers are unnecessary
for cloud runs. Stop and restart a run when changing its API configuration;
hot reload does not update compile-time defines. Log in with a cloud account.
Showcase credentials are operator-local and never committed to Git.

## Local backend development

Use Node 24, Docker and a disposable development database:

```bash
docker compose -f infra/docker-compose.yml up -d
cd apps/backend
cp .env.example .env
npm ci --no-audit --no-fund
npm run db:migrate
npm run start:dev
```

Configure optional Redis/private storage through `.env` as described in the
[backend README](apps/backend/README.md). To connect Flutter to the local API:

```bash
flutter run --dart-define=CHAT_API_BASE_URL=http://127.0.0.1:3000
```

Android emulators use `10.0.2.2`; physical devices require a reachable host.
Secrets belong in ignored environment files or hosting secrets.

## Quality gates

Backend CI is read-only and uses:

```text
npm ci → format:check → lint → typecheck → build → migrations → npm test
```

The E2E runner tests the compiled Nest app, with database suites in separate
processes. **Backend E2E resets fixture data: use only a disposable test DB,
never the cloud database or a developer's saved accounts.** Mobile CI checks
locked dependencies, formatting, analysis and tests, then a two-account
REST/realtime integration against disposable backend services. These checks
do not prove native notification delivery or final device appearance.

## Project references

- [Mobile commands and behavior](apps/mobile/README.md)
- [Backend commands and API](apps/backend/README.md)
- [Cloud deployment checkpoint](docs/project/VERCEL_DEPLOYMENT_CHECKPOINT.md)
- [Cloud release readiness](docs/project/CLOUD_RELEASE_READINESS_CHECKPOINT.md)
- [Product/UI acceptance checklist](docs/project/UI_UX_ACCEPTANCE_CHECKLIST.md)

Work is published through stacked PRs. The default branch displays only merged
checkpoints; open PRs contain subsequent implementation. Review/merge requires
explicit authorization; this checkpoint does not merge the stack.
