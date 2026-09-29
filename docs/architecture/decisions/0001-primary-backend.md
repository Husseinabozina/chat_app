# ADR 0001: Use a Custom Modular Backend as the Primary V1 Implementation

## Status

Accepted for V1 architecture planning.

## Context

The existing Flutter project directly uses Firebase services.

The new portfolio goal is broader: demonstrate an end-to-end product journey including backend, data modeling, realtime communication, API design, deployment, testing, and CI/CD.

At the same time, the Flutter client should not become permanently coupled to one backend vendor.

## Decision

Use a custom backend as the primary V1 reference implementation:

- NestJS
- PostgreSQL
- WebSocket
- S3-compatible object storage
- FCM for push notifications

Keep the Flutter client behind repository/domain abstractions so another backend implementation can replace the API adapter without rewriting presentation/domain code.

## Why

This option demonstrates:

- REST API design.
- Authentication/session design.
- Relational data modeling.
- Authorization.
- Realtime protocol design.
- Media upload architecture.
- Push integration.
- Backend testing.
- Deployment and observability.

It also gives the project a stronger zero-to-hero engineering story than keeping all server behavior inside client-side Firebase calls.

## Alternatives considered

### Firebase as the primary backend

Advantages:

- Fast implementation.
- Managed realtime/storage/auth.
- Low operational overhead.

Tradeoff for this project:

- Less backend/system-design exposure.

Firebase remains a valid possible adapter or future comparison implementation.

### Supabase

Advantages:

- PostgreSQL-based managed platform.
- Auth/storage/realtime available.

Tradeoff:

- Still abstracts part of the backend/application engineering experience the project is intentionally trying to demonstrate.

## Consequences

Positive:

- Richer full-stack portfolio.
- Explicit contracts.
- Stronger backend/security/testing experience.
- Infrastructure remains replaceable from the mobile side.

Negative:

- More implementation and deployment work.
- More security responsibility.
- More failure modes than using a fully managed backend.

## Guardrail

Do not use the custom backend decision as an excuse to over-engineer.

V1 remains a modular monolith, not a microservice platform.
