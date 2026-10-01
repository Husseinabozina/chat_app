# Realtime Contract v1

## Status

**Approved for implementation.**

This document is the implementation contract for the first realtime checkpoint.

The durable source of truth remains PostgreSQL through the REST/application services. Realtime delivery is an acceleration path, not a second database and not a permanent event log.

---

## 1. Transport decision

V1 uses **Socket.IO through NestJS** on a dedicated realtime namespace:

```text
/realtime
```

Socket.IO is chosen for connection middleware, acknowledgements, rooms, reconnect support, and a mature client/server protocol. Product/domain code must not depend directly on Socket.IO types.

The transport implementation sits behind a backend publication boundary and a mobile realtime datasource/client boundary.

Breaking transport changes must not leak into domain contracts.

---

## 2. Durable-command boundary

The following remain REST commands in V1:

- create/resolve conversation
- send message
- edit message
- delete message
- mark conversation read
- profile updates
- future media upload commands

The socket does **not** create, edit, or delete durable resources.

Realtime client-to-server commands are limited to transient behavior such as typing.

This preserves the existing retry/idempotency rules:

- message send succeeds when REST durably persists it
- `clientMessageId` reconciles retries
- read state succeeds when the database read pointer advances
- socket delivery is not required for the REST command to be successful

---

## 3. Authentication handshake

The client connects with the current short-lived access token in the Socket.IO handshake auth object:

```json
{
  "auth": {
    "accessToken": "<jwt>"
  }
}
```

Do not put access tokens in query strings or room names.

The server validates:

- signature
- issuer `chat-platform-api`
- audience `chat-mobile`
- `typ === "access"`
- `sub` user ID
- `sid` refresh-session ID
- JWT expiration
- the referenced refresh session exists
- the refresh session belongs to the same user
- the refresh session is not revoked or expired

Authentication failure rejects the connection with a stable `UNAUTHORIZED` code without exposing token details.

### Token expiry while connected

V1 does not support in-band token replacement.

The server must disconnect the socket no later than the authenticated access token expiry.

The client then:

1. refreshes the session through REST if necessary
2. reconnects with the new access token
3. performs the reconnect resynchronization flow

### Logout/session revocation

Sockets are associated with the authenticated session ID.

When the same refresh session is revoked/logout completes, realtime integration should disconnect sockets belonging to that session on a best-effort basis.

Even if that disconnect signal is missed, access-token expiry bounds the remaining socket lifetime.

---

## 4. Connection identity and multi-device semantics

Every accepted socket has server-owned context:

```text
socketId
userId
sessionId
accessTokenExpiresAt
```

Internal server rooms:

```text
user:{userId}
session:{sessionId}
```

Clients never request arbitrary room names.

### User room

All active sessions/devices for one account join `user:{userId}`.

Durable conversation/message/read events are delivered to the authorized participant user rooms.

### Session room

All sockets associated with one auth session join `session:{sessionId}`.

This supports session-scoped disconnect/revocation behavior.

### Conversation rooms

V1 does not require client-visible or client-controlled conversation subscriptions.

The server already knows direct-conversation membership from PostgreSQL and can route to participant user rooms.

Conversation rooms may be introduced later as an internal optimization without changing the public protocol.

### Multiple devices

A user may have multiple active refresh sessions/devices.

Read state is **user/conversation state**, not per-device state. If one device advances the read pointer, the user's other devices observe the same durable read state.

Multiple temporary sockets for the same session are tolerated.

---

## 5. Connection-ready event

After authentication and room attachment, the server emits:

```json
{
  "protocolVersion": 1,
  "eventId": "uuid",
  "type": "connection.ready",
  "occurredAt": "2026-09-30T13:00:00.000Z",
  "conversationId": null,
  "data": {
    "userId": "uuid",
    "sessionId": "uuid"
  }
}
```

Receiving `connection.ready` means the socket is authenticated and ready for transient commands/events.

It does **not** mean the client is synchronized with every durable change that happened while disconnected.

---

## 6. Event envelope

Every server-to-client application event uses the same envelope:

```json
{
  "protocolVersion": 1,
  "eventId": "uuid",
  "type": "message.created",
  "occurredAt": "2026-09-30T13:00:00.000Z",
  "conversationId": "uuid-or-null",
  "data": {}
}
```

Fields:

- `protocolVersion`: integer protocol version; V1 is `1`
- `eventId`: unique ID for this publication
- `type`: stable event name
- `occurredAt`: server timestamp for this publication
- `conversationId`: conversation scope when applicable
- `data`: event-specific payload

### Event ID semantics

`eventId` deduplicates repeated delivery of the same publication.

In the first implementation it is **not** a durable replay cursor and must not be treated as one.

A later transactional-outbox design may strengthen this guarantee without changing the envelope.

Clients should maintain a bounded recent-event-ID cache and must also merge by canonical resource IDs/state, because the same durable resource state can legitimately be observed from both REST and realtime.

---

## 7. Server-to-client durable-resource events

Durable events are emitted only **after the corresponding database transaction has committed successfully**.

If realtime publication fails after commit:

- the REST command remains successful
- the failure is logged/observed
- reconnect/resume REST resynchronization restores correctness

V1 does not promise lossless event replay.

### 7.1 message.created

Emitted after a message is durably created.

```json
{
  "protocolVersion": 1,
  "eventId": "uuid",
  "type": "message.created",
  "occurredAt": "2026-09-30T13:00:00.000Z",
  "conversationId": "conversation-uuid",
  "data": {
    "message": {
      "id": "message-uuid",
      "clientMessageId": "client-uuid",
      "conversationId": "conversation-uuid",
      "senderId": "user-uuid",
      "type": "text",
      "text": "Hello",
      "replyToMessageId": null,
      "createdAt": "2026-09-30T13:00:00.000Z",
      "editedAt": null,
      "deletedAt": null
    }
  }
}
```

The payload uses the same canonical message representation as REST.

### 7.2 message.updated

Emitted after an authorized edit commits.

Payload contains the full current canonical message.

Clients must not let an older `message.created` or older edit overwrite a newer `editedAt`/deleted state.

### 7.3 message.deleted

Emitted after an authorized soft delete commits.

Payload:

```json
{
  "messageId": "uuid",
  "conversationId": "uuid",
  "senderId": "uuid",
  "deletedAt": "2026-09-30T13:01:00.000Z"
}
```

The client renders a tombstone/deleted state and must not restore older message text if a delayed event arrives afterward.

### 7.4 conversation.updated

Emitted when the Chats-list representation for a user changes, for example:

- last message changes
- last-message text changes because that message was edited/deleted
- unread count changes
- a new direct conversation becomes visible

Payload contains the user-specific canonical conversation summary:

```json
{
  "conversation": {
    "id": "uuid",
    "type": "direct",
    "otherUser": {},
    "lastMessage": {},
    "unreadCount": 3,
    "updatedAt": "2026-09-30T13:00:00.000Z"
  }
}
```

Because `unreadCount` is user-specific, the server may publish different conversation summaries to each participant user room.

### 7.5 read.updated

Emitted after the durable read pointer advances.

```json
{
  "conversationId": "uuid",
  "userId": "uuid",
  "lastReadMessageId": "uuid",
  "lastReadAt": "2026-09-30T13:02:00.000Z"
}
```

The event is visible to both conversation participants so the other participant can render read state.

The client must never move a read pointer backward.

---

## 8. Sent/read semantics

V1 intentionally distinguishes only states that have a clear authority.

### Local outgoing states

The mobile client may show:

```text
pending
sending
sent
failed
read
```

### Sent

A message becomes **sent** when the REST create-message request returns the durably persisted canonical message.

Socket reception is not required.

### Read

A message is **read** when the other participant's durable conversation read pointer is at or after that message in canonical message ordering.

### No durable "delivered-to-device" receipt in V1

V1 does not claim that a recipient device received or rendered a message merely because a socket publication occurred.

A separate durable delivery-receipt model may be added later if the product requires it.

---

## 9. Client-to-server transient commands

V1 accepts only:

```text
typing.start
typing.stop
```

Payload:

```json
{
  "conversationId": "uuid"
}
```

The server validates conversation membership on every command.

Commands use an acknowledgement shape:

Success:

```json
{
  "ok": true
}
```

Failure:

```json
{
  "ok": false,
  "error": {
    "code": "RATE_LIMITED",
    "message": "Too many realtime commands."
  }
}
```

Do not include message text in typing payloads.

---

## 10. Typing lifecycle

Typing state is transient and is never persisted to message history.

### Client behavior

- send `typing.start` when meaningful non-empty input begins
- while typing continues, refresh `typing.start` no more frequently than every 3 seconds
- send `typing.stop` when input becomes empty
- send `typing.stop` after sending
- send `typing.stop` when leaving the conversation
- send `typing.stop` when the app backgrounds when practical

### Server behavior

- validate membership
- track typing by socket + conversation
- assign a 7-second expiry to typing state
- broadcast typing state only to the other participant's user room
- clear that socket's typing state on disconnect
- automatically expire stale state even if `typing.stop` is lost

### Server events

`typing.started`:

```json
{
  "conversationId": "uuid",
  "userId": "uuid",
  "expiresAt": "2026-09-30T13:00:07.000Z"
}
```

`typing.stopped`:

```json
{
  "conversationId": "uuid",
  "userId": "uuid"
}
```

The UI must also hide typing locally when `expiresAt` passes.

---

## 11. Presence and last-seen policy

Product presence/last-seen is **deferred from the first realtime implementation slice**.

The server may track connected sockets internally for operational purposes or future push optimization, but V1 does not expose:

- public `presence.updated`
- exact last-seen timestamps
- a persisted online/offline field

This avoids accidentally creating a privacy-sensitive product contract before the product policy is approved.

If presence is added later, it requires a separate policy covering privacy controls, multi-device semantics, and persistence.

---

## 12. Ordering guarantees

There is no global realtime event order.

The database remains authoritative.

### Messages

Canonical message order is:

```text
(createdAt, id)
```

### Conversation list

Canonical conversation order is:

```text
(updatedAt, id)
```

### Read pointers

Read state is monotonic and advances according to canonical message order.

### Socket ordering

A single connection may often observe emissions in order, but clients must not depend on this for correctness, especially after reconnects or future horizontal scaling.

Merge rules:

- identify messages by server message ID
- reconcile optimistic sends with `clientMessageId`
- never replace newer `editedAt`/deleted state with older state
- deletion/tombstone state wins over older non-deleted payloads
- never regress read pointers
- treat `conversation.updated` as a snapshot produced at the event's `occurredAt`
- if state ordering is ambiguous, refetch the affected resource through REST

---

## 13. Reconnect and missed-event recovery

V1 does **not** provide server-side event replay or a `lastEventId` resume stream.

After every successful reconnect following a lost connection, the mobile client performs REST resynchronization.

Recommended flow:

1. authenticate/reconnect socket
2. receive `connection.ready`
3. buffer realtime events arriving during resync
4. refetch the relevant conversation-list window
5. if a chat is open, refetch its newest message page
6. reconcile local pending/failed outgoing items by `clientMessageId`
7. apply buffered realtime events using normal merge rules
8. resume normal streaming

The app should also resync when returning to foreground if the realtime connection was lost or its freshness is uncertain.

### Backoff

Use bounded exponential reconnect backoff with jitter.

Reference client behavior:

```text
~1s → 2s → 4s → 8s → ... → max ~30s
```

with jitter to avoid synchronized reconnect storms.

---

## 14. Publication boundary in the backend

Conversation/message services must not import Socket.IO server/socket types.

Introduce an application-facing abstraction such as:

```text
RealtimePublisher
  publishMessageCreated(...)
  publishMessageUpdated(...)
  publishMessageDeleted(...)
  publishConversationUpdated(...)
  publishReadUpdated(...)
```

The Socket.IO gateway/adapter implements delivery.

Durable service flow:

```text
validate/authorize
→ database transaction
→ commit
→ build canonical response/snapshot
→ publish realtime event
→ return REST response
```

Realtime publication errors after commit do not roll back the durable command.

They must be logged/metriced without exposing message contents.

---

## 15. Horizontal scaling strategy

Initial deployment may run one backend instance.

Do not add Redis merely for portfolio appearance.

When multiple realtime backend instances are actually required:

- introduce the Socket.IO Redis adapter or equivalent transient pub/sub layer
- keep PostgreSQL as durable authority
- preserve the same public event contract
- keep user/session room semantics consistent across instances

If HTTP long-polling fallback is enabled in a multi-instance deployment, the deployment must account for its affinity/sticky-session requirements.

The pub/sub layer is not a durable event store.

### Transactional outbox

A transactional outbox is deferred from the first realtime slice.

It becomes justified if requirements demand stronger guarantees that every committed durable mutation is eventually published even when a process crashes between database commit and socket emit.

Until then, REST resync provides correctness recovery.

---

## 16. Payload, rate-limit, and abuse baseline

V1 realtime carries small JSON control/resource events only.

No media bytes or arbitrary files travel over the socket.

Implementation baseline:

- enforce a small maximum inbound Socket.IO payload; target approximately 16 KiB transport maximum
- typing commands should be far smaller than that
- reject malformed event payloads
- rate-limit handshake attempts
- rate-limit typing commands per socket/user
- reference typing ceiling: 10 commands per 10 seconds per socket
- repeated malformed/abusive commands may cause disconnect
- apply an explicit allowed-origin/CORS policy in non-local environments
- never log access tokens, refresh tokens, or message bodies by default

Server acknowledgements should return stable error codes such as:

- `UNAUTHORIZED`
- `CONVERSATION_NOT_FOUND`
- `VALIDATION_ERROR`
- `RATE_LIMITED`

---

## 17. Session revocation control

The server may emit a best-effort session-scoped control event before disconnect:

```text
session.revoked
```

The client response is:

1. stop using that realtime connection
2. clear/refresh auth state as appropriate
3. do not treat the event itself as durable proof; REST/auth state remains authoritative

---

## 18. Mobile architecture boundary

The Flutter domain/presentation layers do not import Socket.IO classes.

Target infrastructure composition:

```text
ApiChatRepository
├── RestChatDataSource
└── RealtimeChatDataSource
      └── RealtimeClient
```

The repository:

- performs durable commands/queries through REST
- exposes domain realtime events as streams
- maps socket DTOs into domain events/entities
- reconciles duplicate REST/realtime observations
- surfaces transport problems as product-level `RealtimeFailure`/connection state

Cubits subscribe to repository/domain streams, not raw sockets.

Auth/session coordination owns when the realtime client connects/disconnects.

---

## 19. Initial implementation event set

The first implementation checkpoint includes:

Server to client:

- `connection.ready`
- `message.created`
- `message.updated`
- `message.deleted`
- `conversation.updated`
- `read.updated`
- `typing.started`
- `typing.stopped`

Client to server:

- `typing.start`
- `typing.stop`

Optional control:

- `session.revoked`

Not included yet:

- presence/last-seen product events
- media transfer
- push transport
- durable delivered-to-device receipts
- durable event replay
- client-side room subscription commands

---

## 20. Realtime test contract

Backend realtime integration tests should use the compiled application and a real PostgreSQL test database, consistent with existing E2E policy.

Minimum scenarios:

1. unauthenticated socket is rejected
2. valid token receives `connection.ready`
3. expired/revoked session cannot establish a new socket
4. REST message creation publishes `message.created` to both participants
5. unrelated users receive no conversation/message event
6. REST edit publishes `message.updated`
7. REST delete publishes `message.deleted`
8. REST mark-read publishes monotonic `read.updated`
9. participant receives correct user-specific `conversation.updated`
10. typing requires membership
11. typing starts/stops and expires without persistence
12. disconnect clears transient typing state
13. duplicate/reordered event merge behavior is covered on the mobile side
14. reconnect correctness is validated through REST resynchronization, not assumed event replay

Realtime tests must not make the suite depend on timing-sensitive sleeps when deterministic signalling/acknowledgements can be used.

---

## 21. Observability baseline

Record non-sensitive metrics/logs for:

- active authenticated socket count
- connection/auth rejection count
- disconnect reason
- realtime publication failure count
- event counts by type
- typing rate-limit drops
- reconnect pressure where observable
- adapter/pub-sub errors when scaling is introduced

Do not log:

- access/refresh tokens
- passwords
- full message text by default

---

## 22. Versioning rules

`protocolVersion: 1` and event names/required payload fields are contractual.

Adding optional fields is non-breaking.

Breaking changes require a protocol-version strategy rather than silently changing V1 meaning.

The server should reject unsupported client protocol versions once client-version negotiation is introduced.

For the first implementation, both sides are shipped together and use protocol version 1.

---

## 23. Non-goals for the first realtime slice

Do not add by default:

- Kafka
- event sourcing
- CQRS
- durable socket event log
- Redis before multi-instance need exists
- microservices
- public presence/last-seen
- message creation over WebSocket
- media transfer over WebSocket

## Read recovery addition

`read.updated.data.lastReadMessageCreatedAt` is an optional additive V1 field
for the pointed-to message's canonical creation timestamp. Current backend
mark-read responses include it. Clients compare `(lastReadMessageCreatedAt,
lastReadMessageId)` rather than publication time. Older events lacking the field
can be resolved from loaded messages or the authenticated REST read-state query
in `api-contract-v1.md`. Reconnect resync fetches both members' durable pointers
for loaded chats, including updates missed while offline.
