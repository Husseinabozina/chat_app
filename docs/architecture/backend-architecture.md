# Backend Architecture v1

## Reference implementation

Primary V1 backend:

- **NestJS**
- **PostgreSQL**
- WebSocket gateway
- S3-compatible object storage
- Firebase Cloud Messaging for push notifications

The API/realtime contracts remain more important than the framework choice; the mobile client must not depend on NestJS-specific concepts.

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
- Authenticated WebSocket handshake.

OAuth/social login can be added later if intentionally scoped.

---

## 4. Authorization

Every resource operation checks ownership/membership server-side.

Examples:

- User may read a direct conversation only if a member.
- User may edit/delete only their own message under allowed product rules.
- User may mark read only for their own membership.
- Media access must follow conversation/resource authorization.

Client-side hiding is not authorization.

---

## 5. Conversation service

Responsibilities:

- Create-or-return direct conversation.
- Prevent duplicate direct conversations.
- List a user's conversations.
- Maintain conversation summary metadata where useful.
- Validate participant membership.

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
- Publish realtime event only after durable persistence succeeds.

---

## 7. Realtime gateway

Responsibilities:

- Authenticate socket.
- Join user/conversation rooms.
- Publish message/receipt updates.
- Accept transient typing commands.
- Clean up presence/typing state on disconnect.

Durable message creation remains REST-based in V1.

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

Validation errors use a stable API error shape.

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
- Realtime integration tests for message broadcast and typing where valuable.

---

## 13. Deployment unit

V1 backend is one deployable application plus managed dependencies.

No service split unless profiling/scale requirements justify it.
