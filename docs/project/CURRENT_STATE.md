# Current Project State

Update this file before closing each future project checkpoint. Verify branch heads and CI runs from GitHub before changing the status below.

**Updated:** 2026-09-30  
**Current phase:** Backend/mobile integration complete on `master`. Realtime/WebSocket implementation has **not** started. The next checkpoint is the realtime architecture contract review.

## Last verified integrated baseline

- Default branch: `master`
- Integrated application baseline SHA: `c84e4ff5294867de0d6da392dccc071ca076901b`
- Backend CI: [run #73](https://github.com/Husseinabozina/chat_app/actions/runs/36724138035), passed on that exact master SHA.
- Latest mobile-changing master SHA: `e03d990fda545463ff259513fb668494dec8b1ec`
- Mobile CI: [run #12](https://github.com/Husseinabozina/chat_app/actions/runs/36723604090), passed on that exact mobile-changing master SHA.
- Later master merges after `e03d990...` affected backend/docs only, not `apps/mobile/**`.

## Integrated PR history

The active stack has been merged to `master` with merge commits, preserving stacked ancestry:

1. [#1 Product/design/architecture docs](https://github.com/Husseinabozina/chat_app/pull/1)  
   Merge commit: `3bb14efd7c1fc28208534a5e3687e8e0e52628cf`
2. [#2 Monorepo/backend foundation](https://github.com/Husseinabozina/chat_app/pull/2)  
   Merge commit: `6961c3b36459a96819e08c7c579ec08e86964946`
3. [#3 Mobile modernization](https://github.com/Husseinabozina/chat_app/pull/3)  
   Merge commit: `bd822d3796acec1a36a393a8a9a74a18b1823553`
4. [#4 Mobile feature-first architecture](https://github.com/Husseinabozina/chat_app/pull/4)  
   Merge commit: `e03d990fda545463ff259513fb668494dec8b1ec`
5. [#6 Database foundation](https://github.com/Husseinabozina/chat_app/pull/6)  
   Merge commit: `62c3e521188f68ab7cb277db73badcb601d9357c`
6. [#7 Auth/users](https://github.com/Husseinabozina/chat_app/pull/7)  
   Merge commit: `9c0506e372eb3caeab643d7a2adc91ced3c4edf1`
7. [#9 Conversations/messages](https://github.com/Husseinabozina/chat_app/pull/9)  
   Merge commit: `9d6dfecc3f3fec557c9fceabbc93fd969792414c`
8. [#10 User discovery/public profiles](https://github.com/Husseinabozina/chat_app/pull/10)  
   Merge commit: `bd0670026d88eae6f9ff9277a3d21143f33601f6`
9. [#11 Read + message lifecycle](https://github.com/Husseinabozina/chat_app/pull/11)  
   Merge commit: `f16d521d560e9353fbdad97f22bff4cd584c43b3`
10. [#12 Backend quality reconciliation](https://github.com/Husseinabozina/chat_app/pull/12)  
    Merge commit: `c84e4ff5294867de0d6da392dccc071ca076901b`

All active-stack PRs above are now merged.

## Superseded branches / PRs

- [#5 Backend quality foundation](https://github.com/Husseinabozina/chat_app/pull/5) is closed as superseded. Useful quality work was reconciled into #12; the older Jest/ts-jest and TypeScript 5.9 direction is intentionally not part of the current stack.
- [#8 Identity persistence](https://github.com/Husseinabozina/chat_app/pull/8) is closed as superseded. Its schema conflicts with the active #6/#7 implementation and must not be merged.
- The branches for #5 and #8 are preserved for history/reference.

## Completed checkpoints

### Product and design

- Product vision, V1 scope, user flows, initial REST and realtime contracts, system/data architecture, ADR 0001, and approved visual direction are documented under `docs/`.
- High-fidelity screen planning and approved UI direction are documented.
- Final production UI implementation and prototype validation are not complete.

### Backend

- NestJS modular backend with PostgreSQL 17.
- TypeORM entities and explicit migrations; `synchronize` remains disabled.
- Users, refresh sessions, device-token groundwork, conversations, membership, messages, and attachments schema.
- Email/password authentication with Argon2id.
- Short-lived JWT access tokens and rotating/revocable refresh sessions.
- Current-user profile endpoints.
- Direct conversation creation and canonical participant-pair identity.
- Durable text messages, reply isolation, sender/client-message idempotency, and deterministic cursor pagination.
- User discovery and public profiles.
- Monotonic read pointers and unread counts.
- Sender-owned message edit and idempotent soft delete.
- ESLint, Prettier, typecheck, compiled-app E2E tests, migrations, and reproducible `npm ci` CI.
- Live PostgreSQL health E2E coverage.

### Mobile

- Flutter 3.47 / Dart 3.13 baseline.
- Mobile CI with dependency resolution, formatting, analysis, and tests.
- Feature-first auth/chat structure.
- Cubit state management.
- Domain repository contracts.
- Firebase implementation isolated behind data-layer repository adapters.

The running mobile product still uses the legacy Firebase chat behavior. Custom REST/realtime backend adapters and the approved multi-conversation UI flow are not implemented yet.

## Locked architecture decisions

- Custom modular NestJS + PostgreSQL is the primary V1 backend.
- Durable state and authorization are committed through REST/database operations before realtime delivery.
- Realtime transport must not become the source of truth for durable state.
- Mobile presentation/domain layers depend on repository contracts rather than Firebase/backend SDK types.
- Direct conversation identity is the canonical participant pair.
- Message retries are keyed by sender + `clientMessageId`.
- Message/conversation pagination uses stable timestamp-plus-ID ordering.
- Read pointers are monotonic.
- Only the message sender may edit or soft-delete that message.
- E2E suites exercise the compiled Nest application so runtime decorator metadata matches production.
- Database-using E2E suites run in separate Node processes.

## Current CI state

### Backend

Master Backend CI [run #73](https://github.com/Husseinabozina/chat_app/actions/runs/36724138035) passed on `c84e4ff5294867de0d6da392dccc071ca076901b`.

Pipeline:

`npm ci → format:check → lint → typecheck → build → migrations → E2E tests`

The workflow uses read-only repository permissions and contains no temporary diagnostic/writeback steps.

### Mobile

Master Mobile CI [run #12](https://github.com/Husseinabozina/chat_app/actions/runs/36723604090) passed on `e03d990fda545463ff259513fb668494dec8b1ec`, the latest commit in the integrated chain that changed mobile code.

Subsequent integrated PRs changed backend/docs only.

## Deferred features

- Realtime/WebSocket delivery.
- Realtime read/delivery events.
- Typing indicators and presence/last-seen policy.
- Push notifications and device-token runtime flow.
- Media upload/storage flows and avatar storage-key policy.
- Flutter REST/realtime adapters.
- Multi-conversation Flutter product flow.
- Final high-fidelity UI implementation.
- Offline queue/retry semantics beyond current server idempotency groundwork.
- Deployment, observability, monitoring, and production hardening.

## Known issues / technical debt

- A dedicated cascade-deletion database regression test from the superseded #8 exploration has not been reproduced in the active test suite.
- Avatar storage-key design remains deferred to the media-storage checkpoint.
- Product policy for an edit/delete time window has not been selected.
- The mobile app still uses the legacy Firebase behavior despite having backend-agnostic repository contracts.
- Realtime reconnect/resume, event ordering, event IDs, delivery acknowledgement, typing, and presence semantics are not locked yet.

## Exact next checkpoint

**Realtime Architecture Contract Review — no implementation before the contract is approved.**

The review must define at minimum:

1. WebSocket authentication and token refresh/re-auth behavior.
2. Connection identity, device/session semantics, and multi-device behavior.
3. Event envelope/versioning and stable event IDs.
4. Server ordering guarantees and duplicate-event handling.
5. Reconnect/resume strategy and missed-event recovery through REST/database state.
6. Message-created/edited/deleted events.
7. Read-pointer/read-receipt events and their durable source of truth.
8. Typing event semantics, throttling, TTL, and non-durable behavior.
9. Presence/last-seen privacy and durability policy.
10. Backpressure, rate limiting, payload limits, and abuse controls.
11. Horizontal scaling/pub-sub strategy without making the socket layer authoritative.
12. Flutter repository/transport boundaries for REST + realtime coexistence.

Only after that contract is reviewed should the Realtime/WebSocket implementation branch begin.
