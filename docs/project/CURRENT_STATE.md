# Current Project State

Update this file before closing each future project checkpoint. Verify branch heads and CI runs from GitHub before changing the status below.

**Updated:** 2026-09-30  
**Current phase:** Backend realtime foundation is verified on PR #15. Flutter backend data foundations are verified on stacked PR #16; repository reconciliation and the new conversation flow are next.

## Last verified integrated baseline

- Default branch: `master`
- Integrated master HEAD: `5f77dbd50efd9ae12f17d809a63c2746f35fc9ee` (PR #14 realtime contract merge).
- Last verified backend branch/PR/HEAD: `feat/backend-realtime-foundation` / [PR #15](https://github.com/Husseinabozina/chat_app/pull/15) / `456c842b157b30f4dd9728ba3869f7fa7b6a50d8`.
- Backend CI on that exact HEAD: [run #81](https://github.com/Husseinabozina/chat_app/actions/runs/36740459123), passed on Node 24 with PostgreSQL 17.
- Last verified mobile branch/PR/code commit: `feat/mobile-api-realtime-foundation` / [PR #16](https://github.com/Husseinabozina/chat_app/pull/16) / `dab2bd3a70f3518f08341eac859274f18744d9a2`.
- Mobile CI on that code commit: [run #13](https://github.com/Husseinabozina/chat_app/actions/runs/36753226755), passed on Flutter 3.47.5.
- Final documentation HEAD `42fe888387728447723b3d691719af1b99c50085` also passed Mobile CI [run #14](https://github.com/Husseinabozina/chat_app/actions/runs/36753687572). PR #16 is ready for review.
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

Open stack: PR #15 (`feat/backend-realtime-foundation` → `master`) → PR #16 (`feat/mobile-api-realtime-foundation` → `feat/backend-realtime-foundation`). Both are ready for review. Neither PR has been merged. Preserve ancestry with merge commits; after #15 merges, retarget #16 to `master` and recheck the diff/checks.

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
- On PR #16: secure backend session store; refresh-aware REST client; backend auth and direct-conversation REST datasources; typed Socket.IO V1 event datasource with bounded reconnect; central opt-in backend data composition.
- On PR #16: canonical Flutter 3.47.5 lockfile, read-only Mobile CI, and tests for backend session handling and realtime event mapping.

The running mobile product still uses legacy Firebase chat behavior. The new backend datasources are staged and are not wired into `main.dart` or the current single-room UI. Repository-level REST/realtime reconciliation and the approved multi-conversation UI are not implemented yet.

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

Backend CI [run #81](https://github.com/Husseinabozina/chat_app/actions/runs/36740459123) passed on PR #15 HEAD `456c842b157b30f4dd9728ba3869f7fa7b6a50d8`. The latest integrated backend code on `master` previously passed [run #73](https://github.com/Husseinabozina/chat_app/actions/runs/36724138035).

Pipeline:

`npm ci → format:check → lint → typecheck → build → migrations → E2E tests`

### Mobile

Mobile CI [run #13](https://github.com/Husseinabozina/chat_app/actions/runs/36753226755) passed on PR #16 code commit `dab2bd3a70f3518f08341eac859274f18744d9a2`. It uses `flutter pub get --enforce-lockfile`, a non-writing format check, analysis, and tests. The latest integrated mobile-changing `master` commit previously passed [run #12](https://github.com/Husseinabozina/chat_app/actions/runs/36723604090).

PR #14 was docs-only. PR #15 has green Backend CI and PR #16 has green Mobile CI; the active mobile entrypoint remains on the prior Firebase behavior.

## Deferred features

- Public presence/last-seen.
- Durable delivered-to-device receipts.
- Durable realtime event replay/transactional outbox.
- Redis/multi-instance realtime adapter.
- Push notifications/device-token runtime flow.
- Media uploads/storage and avatar storage-key policy.
- Flutter repository-level REST/realtime merge, event deduplication/ordering, and reconnect resynchronization.
- Multi-conversation Flutter product flow.
- Final high-fidelity UI implementation.
- Deployment/observability/production hardening beyond current CI.

## Known issues / technical debt

- Dedicated cascade-deletion regression coverage from superseded #8 has not been reproduced.
- Avatar storage-key design remains deferred to media storage.
- Product edit/delete time-window policy remains undecided.
- Mobile still runs legacy Firebase behavior.
- The current Firebase registration form requires a profile image, while backend registration accepts email/password; media/profile setup needs a separate product flow before entrypoint migration.
- PR #16 transport tests are local/fake-client tests; an on-device backend/socket integration flow has not been verified yet.
- Production allowed-origin/CORS policy and handshake attempt throttling still need implementation before public deployment. The current backend checkpoint is for local/single-instance integration.
- Realtime publication is best effort after commit; a crash between commit and emission can lose an event. REST resynchronization is the V1 recovery path.

## Exact next checkpoint

**Mobile repository reconciliation and auth lifecycle**, stacked after PR #16 until the two open PRs are reviewed/merged. Build the direct-conversation repository over the staged REST/realtime datasources; deduplicate events, preserve deleted/edited/read monotonic state, buffer events during REST resync after reconnect, and coordinate socket connect/disconnect with the backend session. Test these merge rules with fake datasources. The subsequent checkpoint can switch the single-room Firebase UI to the approved direct-conversation flow using the design assets.

Before any public backend deployment, complete the allowed-origin/CORS policy and handshake attempt throttling noted above.
