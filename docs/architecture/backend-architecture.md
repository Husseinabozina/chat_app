# Backend Architecture v1

## Reference implementation

Primary V1 backend:

- **NestJS**
- **PostgreSQL**
- Socket.IO realtime gateway
- S3-compatible object storage
- Firebase Cloud Messaging for push notifications

The API/realtime contracts remain more important than the framework choice; the mobile client must not depend on NestJS- or Socket.IO-specific concepts.

---

## 1. Architecture style

Use a modular monolith.

```text
src/
  auth/
  users/
  conversations/
  messages/
  media/
  notifications/
  realtime/
  common/
```

Each module should expose a clear application/service boundary and own its persistence logic.

---

## 2. Request path

Typical REST request:

```text
Controller
→ validation/auth guards
→ application/service
→ repository/persistence
→ database
→ response DTO
```

Controllers should remain thin.

Do not place substantial business rules directly in controllers.

---

## 3. Authentication

V1 direction:

- Email/password account.
- Secure password hash.
- Access token.
- Refresh token/session rotation strategy.
- Logout/revocation support.
- Authenticated Socket.IO handshake.

OAuth/social login can be added later if intentionally scoped.

---

## 4. Authorization

Every resource operation checks ownership/membership server-side.

Examples:

- User may read a direct conversation only if a member.
- User may edit/delete only their own message under allowed product rules.
- User may mark read only for their own membership.
- Media access must follow conversation/resource authorization.
- Typing commands validate conversation membership server-side.

Client-side hiding is not authorization.

---

## 5. Conversation service

Responsibilities:

- Create-or-return direct conversation.
- Prevent duplicate direct conversations.
- List a user's conversations.
- Maintain conversation summary metadata where useful.
- Validate participant membership.
- Advance monotonic read state.

Use a canonical direct-conversation key or equivalent unique constraint for duplicate prevention.

---

## 6. Message service

Responsibilities:

- Validate membership.
- Enforce idempotent create using client message ID/key.
- Persist message.
- Support reply relation.
- Support edit/delete rules.
- Return canonical server timestamps.
- Publish realtime events only after durable persistence succeeds.

---

## 7. Realtime module

The implementation contract is `docs/api/realtime-contract-v1.md`.

Responsibilities:

- Authenticate Socket.IO connections.
- Bind sockets to server-owned user/session identity.
- Join internal user/session rooms.
- Publish post-commit message/conversation/read events.
- Accept only transient typing commands in the first slice.
- Clean up typing state on disconnect/expiry.
- Expose no client-controlled arbitrary room subscription.
- Remain replaceable behind a `RealtimePublisher` boundary.

Durable message creation/edit/delete/read commands remain REST-based.

Post-commit publication is best effort in the first slice. REST resynchronization restores correctness after missed events.

---

## 8. Media service

Preferred flow:

```text
client requests upload authorization
→ backend validates type/size/context
→ backend returns signed upload target
→ client uploads directly to object storage
→ client sends message referencing uploaded media metadata
```

This avoids proxying large media bytes through the application server.

V1 may simplify implementation if deployment constraints require it, while preserving the same abstraction.

---

## 9. Notifications

On persisted incoming message:

1. Determine recipient(s).
2. Check active-session/realtime state if optimization is available.
3. Resolve registered device tokens.
4. Send FCM notification when appropriate.
5. Include a safe conversation identifier/deep-link payload.

Push is not the source of truth; opening the app resyncs from the backend.

---

## 10. Validation

Validate at boundaries:

- Email/username format.
- Message length.
- Upload MIME type and size.
- Pagination limits.
- UUID/identifier formats.
- Edit/delete permissions.
- Realtime handshake and transient command payloads.

Validation errors use stable error codes/envelopes.

---

## 11. Database access

Use transactions where correctness spans multiple writes.

Indexes are defined from real query patterns, especially:

- Username lookup/search strategy.
- Conversation membership.
- Conversation list ordering.
- Message pagination.
- Receipt lookup.

Avoid N+1 query patterns in conversation lists.

---

## 12. Testing

Backend test layers:

- Unit tests for important domain/service logic.
- Integration tests against a real test database for persistence-heavy behavior.
- API/e2e tests for critical auth/conversation/message flows.
- Realtime integration tests using the compiled app and real test database.

Realtime E2E must verify authorization, publication after REST mutations, typing membership/expiry, and reconnect correctness through REST resync.

---

## 13. Deployment unit

V1 backend is one deployable application plus managed dependencies.

No service split unless profiling/scale requirements justify it.

Redis is not required for single-instance V1. A transient Socket.IO adapter/pub-sub layer may be introduced only when multiple realtime instances are required.
