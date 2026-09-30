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
- Socket.IO/WebSocket clients.
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

The UI never calls Dio, FirebaseFirestore, or a Socket.IO client directly.

---

## 5. DTO/entity separation

Infrastructure responses map:

```text
JSON / realtime payload
→ DTO
→ mapper
→ domain entity/event
```

This prevents API/realtime schema changes from leaking directly into presentation.

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

Never display raw server/Firebase/Socket.IO exception text directly.

---

## 7. Offline/retry model

For outgoing messages, maintain a local client state such as:

```text
pending
sending
sent
failed
read
```

A client-generated message ID/idempotency key allows retry without accidental duplication.

`sent` means the REST command returned the durably persisted message.

`read` is derived from the other participant's durable read pointer.

V1 does not claim a durable delivered-to-device state.

Local persistence choice should be made during implementation after evaluating message-cache needs; the architecture must allow a local datasource without changing the domain API.

---

## 8. Realtime infrastructure boundary

Target composition:

```text
ApiChatRepository
├── RestChatDataSource
└── RealtimeChatDataSource
      └── RealtimeClient
```

The domain/presentation layers do not import Socket.IO types.

The repository merges durable REST results and realtime domain events.

Socket payloads map to typed DTOs and then domain events before they reach Cubits.

---

## 9. Realtime lifecycle

The mobile app should:

1. authenticate normally through REST
2. establish realtime after a valid access token exists
3. wait for `connection.ready`
4. consume domain realtime events from the repository
5. reconnect with bounded exponential backoff/jitter
6. refresh/reconnect when the access token expires
7. REST-resync after reconnect
8. reconcile pending outgoing messages by `clientMessageId`
9. disconnect realtime when auth is cleared

No client-controlled room subscription API is required in V1.

### Reconnect merge strategy

During reconnect resync:

- buffer incoming realtime events
- refresh the relevant conversation-list window
- refresh the active conversation's newest message page
- apply buffered events afterward
- never regress edited/deleted/read state

WebSocket/Socket.IO data is not assumed to be a permanent event log.

---

## 10. Typing state

Typing is transient presentation state sourced from realtime domain events.

The UI must expire stale typing locally even if a stop event is lost.

Typing state must not be written into durable message history or treated as conversation authority.

---

## 11. Dependency injection

Centralize object composition.

Repositories depend on datasources/clients.

Cubits/use cases depend on repository interfaces.

Auth/session coordination owns realtime connect/disconnect lifecycle.

Avoid service-locator calls scattered inside widgets.

---

## 12. Navigation

Navigation must support:

- Auth gate.
- Main shell.
- Direct opening of a conversation.
- Push-notification deep links.
- Restoration after authentication when a protected deep link is opened.

Routing should remain outside feature business logic.

---

## 13. Testing strategy

### Unit

- REST/realtime DTO mappers.
- Event deduplication/merge rules.
- Use cases where present.
- Cubit/state transitions.
- Repository behavior with fake REST/realtime datasources.

### Widget

- Forms.
- Conversation tiles.
- Message states.
- Composer states.
- Typing state.
- Empty/error/loading UI.

### Integration

Critical flows:

- Register/sign in.
- Find user.
- Start conversation.
- Send/retry message.
- Receive realtime message.
- Edit/delete propagation.
- Read-state propagation.
- Reconnect + REST resync.
- Open notification target.

Testing depth should follow risk, not arbitrary coverage numbers.
