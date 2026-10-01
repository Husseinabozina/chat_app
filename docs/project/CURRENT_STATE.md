# Current Project State

Update this file before closing each future project checkpoint. Verify branch heads and CI runs from GitHub before changing the status below.

**Updated:** 2026-10-01
**Current phase:** Backend account/direct-conversation UI implementation on `feat/mobile-backend-product-flow`, based on verified PR #17 HEAD `d1a1c683a63c9ace2b337d861bb83eef26e45763`. The backend app entrypoint is enabled by `CHAT_API_BASE_URL`; the legacy Firebase fallback remains when unset. Host/widget and live two-account checks have passed locally; final CI/native-device results are recorded at checkpoint closure.

## Last verified integrated baseline

- Default branch: `master`
- Integrated master HEAD: `5f77dbd50efd9ae12f17d809a63c2746f35fc9ee` (PR #14 realtime contract merge).
- Last verified backend branch/PR/HEAD: `feat/backend-realtime-foundation` / [PR #15](https://github.com/Husseinabozina/chat_app/pull/15) / `456c842b157b30f4dd9728ba3869f7fa7b6a50d8`.
- Backend CI on that exact HEAD: [run #81](https://github.com/Husseinabozina/chat_app/actions/runs/36740459123), passed on Node 24 with PostgreSQL 17.
- Last verified mobile branch/PR/code commit: `feat/mobile-api-realtime-foundation` / [PR #16](https://github.com/Husseinabozina/chat_app/pull/16) / `dab2bd3a70f3518f08341eac859274f18744d9a2`.
- Mobile CI on that code commit: [run #13](https://github.com/Husseinabozina/chat_app/actions/runs/36753226755), passed on Flutter 3.47.5.
- PR #16 final HEAD `b0a68f4908a60facea617655b358e478b22a7004` passed Mobile CI [run #15](https://github.com/Husseinabozina/chat_app/actions/runs/36755021551). PR #16 is ready for review.
- Backend CI: [run #73](https://github.com/Husseinabozina/chat_app/actions/runs/36724138035), passed on the integrated backend baseline `c84e4ff5294867de0d6da392dccc071ca076901b`.
- Latest mobile-changing master SHA: `e03d990fda545463ff259513fb668494dec8b1ec`
- Mobile CI: [run #12](https://github.com/Husseinabozina/chat_app/actions/runs/36723604090), passed on that exact mobile-changing master SHA.
- Later master merges after `e03d990...` affected backend/docs only, not `apps/mobile/**`.

## Last verified repository checkpoint (#17)

- Branch/PR: `feat/mobile-repository-reconciliation` / [PR #17](https://github.com/Husseinabozina/chat_app/pull/17), ready for review and unmerged.
- Verified implementation commit: `9c369dc661d4e59341318304c3b779eeb5425991`.
- Backend CI [run #82](https://github.com/Husseinabozina/chat_app/actions/runs/36798100758): success; 20 tests passed, zero failed (health 1, auth 3, discovery 3, messaging 7, realtime 4), Node 24/PostgreSQL 17.
- Mobile CI [run #16](https://github.com/Husseinabozina/chat_app/actions/runs/36798100980): success; format/analyze and 37 tests passed, Flutter 3.47.5.
- GitHub tested PR merge ref `0cc1d4ef5c288895bbfe877dc7cf264b7400c96e`; its tree `1bf5a174a0fef49585cb0ba0b69beeae6223c5af` exactly matches the implementation commit tree. No merge into a project branch was performed.
- Subsequent verification documentation changes do not change that code; PR metadata records the final documentation HEAD and final checks.
- Local locked mobile dependencies, format/analyze/37 tests and backend format/lint/typecheck/build/test-typecheck also passed. Backend database E2E verification is from CI; local Node was 22.

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

Open stack: PR #15 (`feat/backend-realtime-foundation` → `master`) → PR #16 (`feat/mobile-api-realtime-foundation` → `feat/backend-realtime-foundation`) → PR #17 (`feat/mobile-repository-reconciliation` → `feat/mobile-api-realtime-foundation`). All are ready for review and unmerged. Preserve ancestry with merge commits; after each merge, retarget the following PR to `master` and recheck its diff/checks. No merge or force push was performed in the #17 checkpoint.

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
- On PR #17: membership-authorized read-state recovery query and additive canonical read-position fields, allowing REST recovery of receipts missed offline.

### Mobile

- Flutter 3.47 / Dart 3.13 baseline.
- Mobile CI.
- Feature-first auth/chat structure.
- Cubit state management.
- Domain repository contracts.
- Firebase isolated behind data-layer adapters.
- On PR #16: secure backend session store; refresh-aware REST client; backend auth and direct-conversation REST datasources; typed Socket.IO V1 event datasource with bounded reconnect; central opt-in backend data composition.
- On PR #16: canonical Flutter 3.47.5 lockfile, read-only Mobile CI, and tests for backend session handling and realtime event mapping.
- On PR #17: domain conversation/account repositories, REST/event deduplication, edit/delete/read monotonic merging, buffered resync of loaded windows/read snapshots, outgoing retries, typing TTL/throttling, and account-scoped session/socket lifecycle.

The backend entrypoint now exposes account creation/login, profile completion/editing, Chats/People/Profile, search/public profiles/direct conversation creation, paginated text history, reply/copy/edit/delete, failed-send retry, read receipts and typing. Widgets use domain contracts and account-keyed routing; background/foreground hooks pause/resume the existing transport. No backend architecture/schema/durable socket command changes are introduced. The Firebase flow is still the default when the backend URL is unset. This is functional UI implementation based on the documented direction; final visual acceptance is pending.

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

Backend CI [run #82](https://github.com/Husseinabozina/chat_app/actions/runs/36798100758) passed for PR #17 implementation HEAD `9c369dc661d4e59341318304c3b779eeb5425991` (identical merge-ref tree as recorded above), including 20 compiled-app E2E tests. PR #15 previously passed [run #81](https://github.com/Husseinabozina/chat_app/actions/runs/36740459123); integrated backend `master` previously passed [run #73](https://github.com/Husseinabozina/chat_app/actions/runs/36724138035).

Pipeline (unchanged, `contents: read`):

`npm ci → format:check → lint → typecheck → build → migrations → E2E tests`

### Mobile

Mobile CI [run #16](https://github.com/Husseinabozina/chat_app/actions/runs/36798100980) passed for the same PR #17 implementation HEAD/tree: locked dependencies, a non-writing format check, analysis, and 37 tests. PR #16 previously passed [run #15](https://github.com/Husseinabozina/chat_app/actions/runs/36755021551). Integrated mobile-changing `master` previously passed [run #12](https://github.com/Husseinabozina/chat_app/actions/runs/36723604090).

Both workflows are unchanged and read-only, with no temporary diagnostics/artifacts. No dependency/lockfile/migration changed in #17. The active mobile entrypoint remains on the prior Firebase behavior. Final documentation HEAD checks are recorded in PR #17 metadata to avoid a self-referential commit hash in this file.

## Deferred features

- Public presence/last-seen.
- Durable delivered-to-device receipts.
- Durable realtime event replay/transactional outbox.
- Redis/multi-instance realtime adapter.
- Push notifications/device-token runtime flow.
- Media uploads/storage and avatar storage-key policy.
- Durable mobile offline cache/outbox beyond in-memory outgoing retries.
- Final high-fidelity UI implementation.
- Deployment/observability/production hardening beyond current CI.

## Known issues / technical debt

- Dedicated cascade-deletion regression coverage from superseded #8 has not been reproduced.
- Avatar storage-key design remains deferred to media storage.
- Product edit/delete time-window policy remains undecided.
- Backend mode requires an explicit `CHAT_API_BASE_URL`; the default remains the legacy Firebase flow.
- Backend onboarding separates email/password creation from supported text identity fields. Avatar/media upload remains deferred.
- Two real backend accounts are verified on the Flutter test host; this does not establish two-device UI behavior or native secure-storage persistence. Native iPhone simulator verification is tracked separately.
- Conversation summaries have no durable revision; mobile conservatively invalidates/refetches them, which may add REST traffic under heavy load.
- Message-edit timestamps can tie; conflicting equal-time content is resolved through REST refetch. An independent resource revision can reduce ambiguity/query traffic later.
- Offline logout clears local state immediately, while server revocation of pending rotated/auth tokens remains best effort.
- Production allowed-origin/CORS policy and handshake attempt throttling still need implementation before public deployment. The current backend checkpoint is for local/single-instance integration.
- Realtime publication is best effort after commit; a crash between commit and emission can lose an event. REST resynchronization is the V1 recovery path.

## Exact next checkpoint

**Native backend UI/device acceptance and reviewed stack integration.** Finish native simulator/device validation and visual acceptance (including two-device foreground/background/reconnect and secure storage restore), then review the open #15 → #16 → #17 → UI PR stack. Merge only after explicit authorization; use merge commits, retarget the following PR and verify integrated master. Before any public deployment, implement allowed-origin/CORS and handshake attempt throttling. Media/push/presence/outbox remain deferred.

## Backend UI checkpoint in progress

- Branch: `feat/mobile-backend-product-flow`; parent is PR #17 final HEAD above. PR/implementation/final-check identifiers will be recorded after publication.
- Local mobile: format/analysis at earlier revision and full current test suite passed (46 tests; live test skipped without URL). The live test separately passed with two accounts on PostgreSQL 17.11/Node 24.9.0.
- Backend existing 20 compiled-app E2E tests previously passed on the same unchanged backend tree.
- Mobile CI adds a reproducible Node 24/PostgreSQL 17 integration job and triggers for backend contract changes; it retains `contents: read`, locked dependencies, and no diagnostic artifact upload. Backend workflow remains unchanged.
- Native iOS build is still in dependency preparation at publication planning time; it is not counted as passed. Final native and CI results are documented in `MOBILE_BACKEND_UI_CHECKPOINT.md` and the PR.
- Typography/assets and final visual approval remain future acceptance work. No new generated images.

Reconciliation details and limitations: `docs/project/MOBILE_RECONCILIATION_CHECKPOINT.md`.

Before any public backend deployment, complete the allowed-origin/CORS policy and handshake attempt throttling noted above.
