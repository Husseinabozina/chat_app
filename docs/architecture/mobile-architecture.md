# Mobile Architecture v1

## Goal

The Flutter client should remain testable, feature-oriented, and replaceable at infrastructure boundaries.

---

## 1. Architecture style

Use **feature-first Clean Architecture principles** pragmatically.

Target shape:

```text
apps/mobile/lib/
  app/
  core/
  features/
    auth/
    profile/
    people/
    conversations/
    chat/
    settings/
  injection/
```

Within a sufficiently complex feature:

```text
feature/
  data/
    datasources/
    models/
    repositories/
  domain/
    entities/
    repositories/
    usecases/
  presentation/
    cubit/
    pages/
    widgets/
```

Do not create empty layers or one-use-case-per-file boilerplate when it adds no value.

---

## 2. Dependency direction

```text
Presentation
    ↓
Domain
    ↑
Data implementation
```

The domain layer must not import:

- Firebase SDK classes.
- HTTP clients.
- WebSocket clients.
- DTOs.
- Flutter widgets or BuildContext.

---

## 3. State management

Use BLoC/Cubit where a feature has meaningful asynchronous or multi-state behavior.

Examples:

- AuthCubit
- ConversationListCubit
- PeopleSearchCubit
- ChatCubit
- ProfileCubit

Avoid one global mega-Cubit.

UI responsibilities:

- Render state.
- Dispatch user intent.
- Handle purely local visual state when appropriate.

Business/network orchestration belongs outside widgets.

---

## 4. Repository contracts

Example concept:

```dart
abstract interface class ChatRepository {
  Future<Message> sendMessage(SendMessageInput input);
  Stream<ChatEvent> watchConversation(String conversationId);
  Future<MessagePage> getMessages({
    required String conversationId,
    String? beforeCursor,
  });
  Future<void> markRead({
    required String conversationId,
    required String upToMessageId,
  });
}
```

The UI never calls Dio, FirebaseFirestore, or a WebSocket directly.

---

## 5. DTO/entity separation

Infrastructure responses map:

```text
JSON / socket payload
→ DTO
→ mapper
→ domain entity
```

This prevents API schema changes from leaking directly into presentation.

---

## 6. Error model

Infrastructure exceptions should become typed product failures, for example:

- NetworkFailure
- UnauthorizedFailure
- ValidationFailure
- NotFoundFailure
- ConflictFailure
- RateLimitFailure
- MediaUploadFailure
- RealtimeFailure
- UnknownFailure

UI copy is chosen at the presentation layer from these product-level failures.

Never display raw server/Firebase exception text directly.

---

## 7. Offline/retry model

For outgoing messages, maintain a local client state such as:

```text
pending
sending
sent
failed
```

A client-generated message ID/idempotency key allows retry without accidental duplication.

V1 local persistence choice should be made during implementation after evaluating message-cache needs; the architecture must allow a local datasource without changing the domain API.

---

## 8. Realtime lifecycle

The mobile app should:

1. Authenticate normally.
2. Establish realtime connection after a valid session exists.
3. Subscribe to relevant conversation/user channels.
4. Merge realtime events into current state.
5. Reconnect with backoff.
6. Resync via REST after reconnect/app resume when correctness requires it.

WebSocket data is not assumed to be a perfect permanent event log.

---

## 9. Dependency injection

Centralize object composition.

Repositories depend on datasources/clients.

Cubits/use cases depend on repository interfaces.

Avoid service-locator calls scattered inside widgets.

---

## 10. Navigation

Navigation must support:

- Auth gate.
- Main shell.
- Direct opening of a conversation.
- Push-notification deep links.
- Restoration after authentication when a protected deep link is opened.

Routing should remain outside feature business logic.

---

## 11. Testing strategy

### Unit

- Mappers.
- Use cases where present.
- Cubit/state transitions.
- Repository behavior with mocked/fake datasources.

### Widget

- Forms.
- Conversation tiles.
- Message states.
- Composer states.
- Empty/error/loading UI.

### Integration

Critical flows:

- Register/sign in.
- Find user.
- Start conversation.
- Send/retry message.
- Receive realtime message.
- Open notification target.

Testing depth should follow risk, not arbitrary coverage numbers.
