# Current Project State

Update this file before closing each future project checkpoint. Verify branch heads and CI runs from GitHub before changing the status below.

**Updated:** 2026-09-30  
**Current phase:** Realtime Backend Foundation implemented on PR #15 and verified; awaiting review/merge. Flutter REST/realtime integration is the next product checkpoint.

## Last verified integrated baseline

- Default branch: `master`
- Integrated master HEAD: `5f77dbd50efd9ae12f17d809a63c2746f35fc9ee` (PR #14 realtime contract merge).
- Last verified feature branch/PR/commit: `feat/backend-realtime-foundation` / [PR #15](https://github.com/Husseinabozina/chat_app/pull/15) / `4f96acd914c8ef0038aa3d6ee88781fad53ade03`.
- Backend CI on that feature commit: [run #80](https://github.com/Husseinabozina/chat_app/actions/runs/36740011258), passed on Node 24 with PostgreSQL 17.
- Backend CI: [run #73](https://github.com/Husseinabozina/chat_app/actions/runs/36724138035), passed on the integrated backend baseline `c84e4ff5294867de0d6da392dccc071ca076901b`.
- Latest mobile-changing master SHA: `e03d990fda545463ff259513fb668494dec8b1ec`
- Mobile CI: [run #12](https://github.com/Husseinabozina/chat_app/actions/runs/36723604090), passed on that exact mobile-changing master SHA.
- Later master merges after `e03d990...` affected backend/docs only, not `apps/mobile/**`.

## Integrated PR history

The active pre-realtime stack is integrated on `master` with merge commits:

1. #1 Product/design/architecture docs
2. #2 Monorepo/backend foundation
3. #3 Mobile modernization
4. #4 Mobile feature-first architecture
5. #6 Database foundation
6. #7 Auth/users
7. #9 Conversations/messages
8. #10 User discovery/public profiles
9. #11 Read + message lifecycle
10. #12 Backend quality reconciliation
11. #13 Integrated-state documentation
12. #14 Realtime V1 architecture contract

PR #5 and PR #8 are closed as superseded and their branches remain available for reference.

PR #15 is open on `feat/backend-realtime-foundation` against `master`; it has not been merged.

## Completed checkpoints

### Product and design

- Product vision, V1 scope, user flows, REST contract, system/data architecture, ADRs, and approved visual direction are documented.
- High-fidelity screen planning and approved UI direction are documented.
- Final production UI implementation and prototype validation are not complete.

### Backend

- NestJS modular backend with PostgreSQL 17.
- Explicit TypeORM migrations with `synchronize` disabled.
- Email/password auth, Argon2id, JWT access tokens, rotating refresh sessions.
- Users/current profile/public profile/search.
- Direct conversation uniqueness and membership authorization.
- Durable text messages, reply isolation, sender/client-message idempotency, cursor pagination.
- Monotonic read pointers/unread counts.
- Sender-owned edit and soft delete.
- Reproducible Backend CI with Prettier, ESLint, typecheck, build, migrations, and compiled-app E2E tests.
- Health/PostgreSQL E2E coverage.
- On PR #15: authenticated Socket.IO `/realtime` gateway, user/session rooms, post-commit message/conversation/read events, transient typing, and session-scoped disconnect after logout.
- On PR #15: compiled-app realtime E2E coverage for auth, revocation, event delivery, isolation, summaries, read monotonicity, typing expiry/disconnect, and REST resync after reconnect.

### Mobile

- Flutter 3.47 / Dart 3.13 baseline.
- Mobile CI.
- Feature-first auth/chat structure.
- Cubit state management.
- Domain repository contracts.
- Firebase isolated behind data-layer adapters.

The running mobile product still uses legacy Firebase chat behavior. Custom REST/realtime adapters and the approved multi-conversation UI are not implemented yet.

### Realtime architecture

The V1 realtime contract is locked in `docs/api/realtime-contract-v1.md`. PR #15 implements the first backend slice without changing the durable REST/PostgreSQL source of truth.

Key decisions:

- Socket.IO through NestJS under `/realtime`.
- REST/PostgreSQL remain the durable source of truth.
- Durable message/edit/delete/read commands remain REST-only.
- Socket handshake uses the existing short-lived access token and validates the backing session.
- User/session rooms are server-controlled; no arbitrary client room subscriptions.
- Stable versioned event envelope and event IDs.
- No event replay log in the first slice; reconnect correctness comes from REST resynchronization.
- Message events, user-specific conversation summaries, and read updates are published after commit.
- Typing is transient with TTL; presence/last-seen is deferred.
- No durable delivered-to-device receipt in V1.
- Backend uses a `RealtimePublisher` boundary; mobile uses REST + realtime datasources behind repositories.
- Redis/outbox are deferred until requirements justify them.

ADR 0002 records the Socket.IO transport choice.

## Locked architecture decisions

- Custom modular NestJS + PostgreSQL is the primary backend.
- Durable state/authorization commit through REST/database before realtime publication.
- Realtime transport is not the durable source of truth.
- Mobile presentation/domain layers depend on repository contracts, not infrastructure SDK types.
- Direct conversation identity is the canonical participant pair.
- Message retries use sender + `clientMessageId`.
- Message/conversation pagination uses stable timestamp-plus-ID ordering.
- Read pointers are monotonic.
- Only the sender may edit/soft-delete a message.
- E2E suites exercise the compiled Nest application.
- Database-using E2E suites run in separate Node processes.
- V1 realtime transport is Socket.IO behind replaceable adapters.
- `sent` means REST-persisted; `read` means durable recipient read pointer.
- No durable delivered-to-device state in the first V1 slice.
- No public presence/last-seen contract yet.

## Current CI state

### Backend

Backend CI [run #80](https://github.com/Husseinabozina/chat_app/actions/runs/36740011258) passed on PR #15 commit `4f96acd914c8ef0038aa3d6ee88781fad53ade03`. The latest integrated backend code on `master` previously passed [run #73](https://github.com/Husseinabozina/chat_app/actions/runs/36724138035).

Pipeline:

`npm ci → format:check → lint → typecheck → build → migrations → E2E tests`

### Mobile

Mobile CI [run #12](https://github.com/Husseinabozina/chat_app/actions/runs/36723604090) passed on the latest integrated mobile-changing commit.

PR #14 was docs-only; PR #15 changes backend runtime code and has its own green Backend CI. Mobile runtime remains at the prior verified baseline.

## Deferred features

- Public presence/last-seen.
- Durable delivered-to-device receipts.
- Durable realtime event replay/transactional outbox.
- Redis/multi-instance realtime adapter.
- Push notifications/device-token runtime flow.
- Media uploads/storage and avatar storage-key policy.
- Flutter REST/realtime adapters.
- Multi-conversation Flutter product flow.
- Final high-fidelity UI implementation.
- Deployment/observability/production hardening beyond current CI.

## Known issues / technical debt

- Dedicated cascade-deletion regression coverage from superseded #8 has not been reproduced.
- Avatar storage-key design remains deferred to media storage.
- Product edit/delete time-window policy remains undecided.
- Mobile still runs legacy Firebase behavior.
- Production allowed-origin/CORS policy and handshake attempt throttling still need implementation before public deployment. The current backend checkpoint is for local/single-instance integration.
- Realtime publication is best effort after commit; a crash between commit and emission can lose an event. REST resynchronization is the V1 recovery path.

## Exact next checkpoint

**Flutter REST/realtime data integration**, after PR #15 review/merge. Replace the legacy Firebase chat data path behind the existing mobile repository contracts with authenticated REST and Socket.IO datasources. Preserve REST as the durable authority, implement reconnect resynchronization and event deduplication, and keep presentation/domain layers free of transport types. Decide the screen-level rollout separately; do not combine it with presence, push, media, Redis, or durable event replay.

Before any public backend deployment, complete the allowed-origin/CORS policy and handshake attempt throttling noted above.
