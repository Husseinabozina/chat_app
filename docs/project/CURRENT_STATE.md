# Current Project State

Update this file before closing each future project checkpoint. Verify branch heads and CI runs from GitHub before changing the status below.

**Updated:** 2026-09-30
**Current phase:** Backend stack reconciliation and quality checkpoint. Realtime/WebSocket implementation is deferred.

## Last verified baseline

- Branch: `feat/backend-message-lifecycle`
- Pull request: [#11 — read and message lifecycle](https://github.com/Husseinabozina/chat_app/pull/11)
- Commit: `a2568595f42088193b3c15423e0cdca220891044`
- Backend CI: [run #65](https://github.com/Husseinabozina/chat_app/actions/runs/36653806395), passed on that commit
- Quality reconciliation branch: `chore/backend-quality-reconcile`, based directly on PR #11; verification is in progress.

## PR stack and dependencies

The active dependency chain is:

`master` → [#1 product/architecture docs](https://github.com/Husseinabozina/chat_app/pull/1) → [#2 monorepo](https://github.com/Husseinabozina/chat_app/pull/2) → [#3 mobile modernization](https://github.com/Husseinabozina/chat_app/pull/3) → [#4 mobile feature architecture](https://github.com/Husseinabozina/chat_app/pull/4) → [#6 database foundation](https://github.com/Husseinabozina/chat_app/pull/6) → [#7 auth/users](https://github.com/Husseinabozina/chat_app/pull/7) → [#9 conversations/messages](https://github.com/Husseinabozina/chat_app/pull/9) → [#10 user discovery](https://github.com/Husseinabozina/chat_app/pull/10) → [#11 read/message lifecycle](https://github.com/Husseinabozina/chat_app/pull/11) → this quality checkpoint.

[#5 backend quality foundation](https://github.com/Husseinabozina/chat_app/pull/5) and #6 both branch from #4. [#8 identity persistence](https://github.com/Husseinabozina/chat_app/pull/8) branches from #5. Neither #5 nor #8 is part of the active backend chain; leave both open while reviewing what has been superseded. Do not merge them into the chain without reconciling their changes.

## Completed checkpoints

### Product and design

- Product vision, V1 scope, user flows, initial REST and realtime contracts, system/data architecture, ADR 0001, and approved visual direction are documented under `docs/`.
- High-fidelity screen planning is documented; final screens and prototype validation are not implemented.

### Backend

- NestJS modular backend and PostgreSQL 17 local/CI infrastructure.
- TypeORM entities and explicit migrations for users, refresh sessions, device tokens, conversations, membership, messages, and attachments.
- Email/password auth, Argon2id hashing, access tokens, refresh rotation/revocation, and current-user profile endpoints.
- Direct conversation creation, durable text messages, cursor pagination, idempotent sends, reply isolation, and membership authorization.
- User discovery and public profiles with ranked, paginated search.
- Monotonic read pointers, unread counts, sender-owned edits, and idempotent soft deletion through REST.

### Mobile

- Flutter 3.47 / Dart 3.13 baseline and Mobile CI.
- Feature-first auth/chat structure with Cubit, domain repository contracts, and Firebase confined to data adapters.
- The running mobile behavior still uses the legacy Firebase chat model; the custom backend adapters and multi-conversation product flow are not implemented.

## Locked architecture decisions

- A custom modular NestJS backend with PostgreSQL is the primary V1 backend. TypeORM schema changes use migrations; `synchronize` stays disabled.
- Durable state and authorization are established through REST/database operations before realtime event delivery.
- Mobile presentation/domain code depends on repository contracts, not Firebase or backend SDK types.
- Direct conversation identity is the canonical participant pair. Message retries are keyed by sender and `clientMessageId`; message and conversation pages use stable timestamp-plus-ID ordering.
- Read pointers are monotonic. Only a message's sender may edit or soft-delete it. No edit/delete time window has been selected yet.
- E2E tests exercise the compiled Nest application, preserving production decorator metadata. Database-using suites run in separate Node processes.

## Current CI state

The last verified backend baseline is PR #11 run #65. The quality branch is adding ESLint, a live PostgreSQL health E2E test, E2E typechecking, and updated development documentation. Its target sequence is `npm ci` → `format:check` → `lint` → `typecheck` → `build` → migrations → tests. The workflow keeps `contents: read` and no diagnostic artifact steps. Record the quality PR's final run and commit here when CI succeeds.

## Deferred features

- Realtime/WebSocket delivery and read events, push notifications, and media upload/storage flows.
- Flutter adapters for the custom REST backend and the approved multi-conversation flow.
- Final high-fidelity UI implementation, offline/retry behavior, deployment, and monitoring.

## Divergent PR reconciliation

- #5's locked install, npm cache, formatting, shared app configuration, and live health behavior already exist in the active chain. This checkpoint restores its missing static lint gate, health E2E coverage, test typechecking, and useful development guidance. It does not import the older Jest/ts-jest runner, TypeScript 5.9 pin, or a type-import rule that conflicts with Nest runtime injection metadata.
- #8's alternate users/refresh-sessions implementation is superseded by #6/#7. The active schema has case-insensitive unique indexes and refresh-session cascade deletion through its own migration. #8's separate normalized columns and avatar storage key are not part of the active schema. Its schema-specific cascade test remains an unported test idea, so the PR should not be merged or closed as part of this checkpoint.

## Known issues and technical debt

- The PR stack is still open; #5 and #8 are divergent alternatives to the active chain.
- #8's identity entities/migration cannot be merged over #6/#7. Its database-specific regression ideas (especially cascade behavior) are not yet reproduced as a dedicated test in the active chain.
- The root README now points here; keep detailed checkpoint status in this file to avoid competing summaries.
- Product policy for an edit/delete time window has not been decided.

## Exact next checkpoint

Finish this quality PR with green CI and make it ready for review. Then review and integrate the active PR dependency chain in order, without merging #5 or #8. Defer any realtime implementation until that integration checkpoint is complete and separately authorized.
