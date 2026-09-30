# ADR 0002: Use Socket.IO as the V1 Realtime Transport

## Status

Accepted.

## Context

The product already has durable REST/database behavior for:

- authentication
- direct conversations
- messages
- edit/delete lifecycle
- read pointers

The next checkpoint needs low-latency delivery and transient typing without creating a second source of truth.

The backend is NestJS and the Flutter client is intentionally isolated behind repository/infrastructure boundaries.

## Decision

Use **Socket.IO through NestJS** for the V1 realtime transport.

The public realtime namespace is:

```text
/realtime
```

Durable commands remain REST-based.

Socket.IO is hidden behind:

- a backend `RealtimePublisher` application boundary
- a mobile `RealtimeClient` / realtime datasource boundary

Domain and presentation code must not import Socket.IO types.

## Why

Socket.IO provides useful V1 transport primitives without requiring custom protocol plumbing for:

- authenticated connection middleware
- rooms
- acknowledgements
- disconnect lifecycle
- reconnect handling
- heartbeats
- client/server interoperability

These features are useful for a messaging application, while the project still retains explicit domain, persistence, authorization, and protocol design.

## Important limitation

Socket.IO is a protocol above the raw WebSocket transport and is not wire-compatible with a generic raw-WebSocket client.

That tradeoff is accepted for V1 because the transport is isolated behind adapters.

The product contract depends on the event envelope and semantics in `docs/api/realtime-contract-v1.md`, not on Socket.IO-specific classes.

## Durable source of truth

PostgreSQL remains authoritative.

Socket.IO does not become:

- a message store
- a read-state store
- an event-sourcing log
- a guaranteed replay stream

Committed durable mutations are published after commit.

If a publication is missed, REST resynchronization restores correctness.

## Alternatives considered

### Raw WebSocket / ws

Advantages:

- minimal wire protocol
- full control
- broad interoperability

Tradeoff:

- more custom work for authentication middleware, rooms, acknowledgements, reconnect conventions, and lifecycle handling
- little product value from rebuilding those primitives in V1

### Server-Sent Events

Advantages:

- simple server-to-client streaming

Tradeoff:

- typing/client transient commands require a separate channel
- less natural fit for bidirectional realtime interaction

### Firebase realtime transport

Advantages:

- managed realtime infrastructure

Tradeoff:

- conflicts with the accepted custom-backend portfolio direction
- would reintroduce infrastructure coupling the current architecture intentionally removed

## Scaling consequence

Initial deployment may use one backend instance.

If multiple realtime instances become necessary, use the Socket.IO Redis adapter or equivalent transient pub/sub mechanism.

Redis is not required for the first implementation and must not become durable authority.

## Reliability consequence

The first implementation is post-commit best-effort publication plus REST resynchronization.

A transactional outbox is deferred until stronger publish-after-commit guarantees are justified by requirements.

## Security consequence

Socket authentication uses the same short-lived JWT/session model as REST.

Access tokens are supplied through the handshake auth object, never URL query parameters.

The connection is bounded by token expiry and session revocation semantics.

## Guardrail

Do not move durable message/read/profile commands into Socket.IO merely because the gateway exists.

Realtime remains a delivery/transient-interaction layer.
