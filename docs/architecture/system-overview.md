# System Architecture v1

## Purpose

This document defines the first implementation-ready architecture for the zero-to-hero messaging product.

The guiding principle is:

> The Flutter application must depend on product/domain contracts, not on Firebase, REST, Supabase, PostgreSQL, WebSockets, or any specific infrastructure provider.

The primary portfolio implementation will use a custom backend so the project demonstrates end-to-end product engineering, while preserving replaceable infrastructure boundaries.

---

## 1. System context

```text
Flutter mobile app
      │
      ├── REST/HTTPS ───────────────┐
      │                             │
      └── WebSocket ─────────────┐  │
                                ▼  ▼
                         Backend application
                                │
             ┌──────────────────┼───────────────────┐
             ▼                  ▼                   ▼
         PostgreSQL       Object storage          FCM
                                                notifications
```

Optional later infrastructure such as Redis may be introduced only if a measured need appears, for example cross-instance realtime fan-out or short-lived distributed state.

V1 does not require microservices.

---

## 2. Monorepo boundary

Target structure:

```text
apps/
  mobile/
  backend/

docs/
  product/
  design/
  architecture/
  api/

infra/
.github/
```

The mobile and backend applications remain independently testable, buildable, and deployable.

---

## 3. Mobile responsibilities

The Flutter app owns:

- Presentation and interaction.
- Local UI state.
- Domain/use-case orchestration where useful.
- Local cache/offline behavior.
- Mapping infrastructure failures into product-level failures.
- Push/deep-link navigation handling.
- Realtime subscription lifecycle.

It does not own server authority for:

- Authentication validity.
- Conversation membership authorization.
- Message persistence.
- Read-state authority.
- Media access authorization.

---

## 4. Backend responsibilities

The backend owns:

- Authentication/session authority.
- User/profile persistence.
- Direct-conversation uniqueness.
- Authorization.
- Message persistence and ordering.
- Read receipts.
- Media upload authorization/metadata.
- Push notification dispatch.
- Realtime event publication.
- Validation, rate limiting, and audit-relevant timestamps.

---

## 5. Primary backend style

Use a **modular monolith** for V1.

Why:

- Clear module boundaries.
- Easier deployment and debugging than microservices.
- Enough architectural depth for a portfolio project.
- Can later split hot modules if evidence justifies it.

Initial backend modules:

```text
auth
users
conversations
messages
media
notifications
realtime
common
```

---

## 6. Communication model

### REST

Use REST for durable commands and queries such as:

- Authentication.
- User search/profile.
- Conversation listing.
- Message history pagination.
- Creating/sending messages.
- Editing/deleting messages.
- Marking messages/conversations as read.
- Media-upload initiation.

### WebSocket

Use WebSocket for transient/realtime delivery such as:

- New persisted message event.
- Message update/delete event.
- Typing start/stop.
- Receipt/read-state updates.
- Conversation-summary updates.

Message creation remains a durable server command; WebSocket is used to broadcast the accepted result.

This makes retries and idempotency easier to reason about.

---

## 7. Reliability principles

- Client-generated idempotency key for message send.
- Server timestamps are authoritative.
- Cursor pagination rather than offset pagination for messages.
- Failed outgoing messages remain visible locally and can be retried.
- Reconnect triggers a REST resync rather than trusting missed WebSocket events.
- Backend operations that update multiple related records use transactions where needed.
- Media upload and message creation are modeled as separate states.

---

## 8. Replaceability

The mobile domain defines repository interfaces.

Possible adapters:

```text
ChatRepository
├── ApiChatRepository      // primary V1
├── FirebaseChatRepository // optional future adapter
└── SupabaseChatRepository // optional future adapter
```

A backend replacement may still require infrastructure-specific work, but it should not require rewriting presentation or core product logic.

---

## 9. Security baseline

- TLS in all non-local environments.
- Passwords hashed using a modern password-hashing algorithm.
- Short-lived access tokens and refresh-token/session strategy.
- Authorization checked server-side for every conversation/message resource.
- Upload type/size validation.
- Signed/presigned media access where appropriate.
- Rate limits on authentication, search, and message creation.
- Secrets never committed to the repository.
- Logs must avoid passwords, tokens, and sensitive message contents by default.

---

## 10. Observability baseline

Backend:

- Structured logs.
- Request correlation/request ID.
- Health endpoint.
- Error tracking.
- Basic latency/error-rate visibility.

Mobile:

- Crash/error reporting.
- Non-sensitive diagnostic logs.
- Network/realtime failure classification.

---

## 11. V1 architecture non-goals

Do not add by default:

- Microservices.
- Kafka.
- CQRS/event sourcing.
- Redis.
- Kubernetes.
- Complex service mesh.
- Multi-region architecture.

These are only justified by real requirements, not portfolio appearance.
