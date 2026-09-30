# Realtime Contract v1

## Purpose

WebSocket handles low-latency updates.

REST remains the source for durable commands/queries and reconnect resynchronization.

---

## 1. Connection

Client connects with an authenticated session/token.

Server validates the session before subscribing the socket to user/conversation channels.

On authentication failure:

- connection is rejected/closed with a stable reason
- mobile refreshes/re-authenticates as appropriate

---

## 2. Server-to-client events

### message.created

Emitted after a message is durably persisted.

Payload concept:

```json
{
  "event": "message.created",
  "conversationId": "...",
  "message": {}
}
```

### message.updated

Used for edits.

### message.deleted

Used after authorized delete.

### conversation.updated

Used when conversation-list summary/unread metadata changes.

### receipt.updated

Concept:

```json
{
  "event": "receipt.updated",
  "conversationId": "...",
  "userId": "...",
  "lastReadMessageId": "...",
  "readAt": "..."
}
```

### typing.started

Transient.

### typing.stopped

Transient.

Typing events are not persisted as message history.

---

## 3. Client-to-server realtime commands

V1 realtime commands are deliberately small:

- typing.start
- typing.stop

Durable message creation/edit/delete remain REST commands.

This keeps retry/idempotency semantics straightforward.

---

## 4. Rooms/subscriptions

Conceptual channels:

```text
user:{userId}
conversation:{conversationId}
```

A socket may join only channels the authenticated user is authorized to access.

---

## 5. Reconnect behavior

On disconnect:

1. Mobile reconnects with bounded exponential backoff/jitter.
2. Re-authenticate socket.
3. Rejoin required channels.
4. Refetch critical current state via REST.
5. Merge server state with local pending outgoing messages.

Do not assume all missed events will be replayed.

---

## 6. Ordering and duplicates

Clients must tolerate:

- Duplicate event delivery.
- REST response arriving near the same realtime event.
- Slightly delayed events.

Domain entities are keyed by stable IDs.

Message creation uses `clientMessageId`/server message ID to reconcile optimistic local state.

---

## 7. Typing lifecycle

Client sends typing.start after actual user input begins, with throttling/debouncing.

Client sends typing.stop when:

- input becomes empty
- message is sent
- user leaves chat
- inactivity timeout occurs

Server should expire stale typing state automatically.

---

## 8. Push vs realtime

- WebSocket serves active/connected sessions.
- Push helps notify background/offline devices.
- Neither push nor realtime replaces database state.

On app resume/open, authoritative data is fetched as required.

---

## 9. Versioning

Event names and required fields form a contract.

Breaking changes require protocol/API version strategy rather than silently changing payload meaning.
