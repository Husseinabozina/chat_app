# Product Vision

## Working definition

This project is a **zero-to-hero flagship portfolio product**: a modern one-to-one social messenger designed and engineered end to end, from product discovery and UX through backend, Flutter implementation, testing, CI/CD, deployment, monitoring, and production documentation.

The goal is not to rebuild WhatsApp, Telegram, or a dating app. The goal is to build a focused messaging product with a small-to-medium feature set implemented to a high engineering and UX standard.

## Product thesis

A user should be able to:

1. Create an account and complete a lightweight profile.
2. Find another user by name or username.
3. Open that user's profile.
4. Start or continue a one-to-one conversation.
5. Exchange realtime text and image messages.
6. Understand delivery, unread, typing, loading, offline, and failure states without technical friction.

The product should feel warm, friendly, modern, and memorable while remaining professional enough for a production-oriented engineering portfolio.

## Primary product areas

- Authentication
- User profiles
- People discovery/search
- Conversations
- Realtime messaging
- Settings and appearance

## Engineering goals

The project should demonstrate:

- Feature-first, modular architecture.
- Clear separation between presentation, domain/business rules, and infrastructure.
- Repository abstractions so Flutter is not coupled directly to Firebase, REST, Supabase, or another backend implementation.
- BLoC/Cubit-style explicit state management where appropriate.
- Realtime communication, pagination, media, notifications, offline-aware behavior, and failure recovery.
- Automated testing at unit, widget, integration, and backend levels where each provides value.
- CI/CD, deployment, monitoring, and production documentation.
- A clean Git history using logical branches, meaningful commits, and pull requests.

## Repository strategy

Use a **monorepo** for the product so mobile, backend, documentation, infrastructure, and CI/CD live together while remaining independently testable and deployable.

Planned high-level structure:

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

The existing Flutter app is a starting point only. It may be reorganized during implementation.

## Non-goals

For the initial portfolio release, this project is not intended to become:

- A dating product.
- A social feed.
- A Telegram-style platform with channels, bots, and communities.
- A WhatsApp-sized feature clone.
- A calling platform.
- A distributed messaging system at internet-scale.

Scope should remain intentionally controlled so depth and quality are prioritized over feature count.

## Product quality bar

A feature is not considered complete when only the happy path works. Relevant screens and actions should consider:

- Loading
- Content
- Empty
- Error
- Offline
- Partial/cached data
- Action in progress
- Action failure and retry
- Accessibility
- Responsive/adaptive behavior
- Performance at realistic data sizes

## Portfolio outcome

The final repository should make it possible to explain the complete journey:

```text
Idea
→ Product research
→ Competitor research
→ Feature prioritization
→ UX and information architecture
→ Visual system and high-fidelity UI
→ System architecture
→ Database and API design
→ Backend implementation
→ Flutter implementation
→ Realtime integration
→ Testing
→ Performance and accessibility
→ CI/CD
→ Deployment and monitoring
→ Production documentation
→ Portfolio/CV/interview case study
```
