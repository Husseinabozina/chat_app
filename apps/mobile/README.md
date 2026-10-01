# Mobile App

Flutter client for the messaging platform.

## Baseline

- Flutter: 3.47+
- Dart: 3.13+
- Android minimum SDK: 24
- iOS minimum target: 15.0
- State management: Cubit via flutter_bloc
- Architecture: feature-first Clean Architecture principles

## Structure

```text
lib/
  app/
  core/
    failures/
  features/
    auth/
      data/
      domain/
      presentation/
    chat/
      data/
      domain/
      presentation/
  injection/
```

The UI now depends on domain repository contracts instead of Firebase SDK classes. Firebase is isolated behind data-layer repository implementations and composed centrally in `injection/app_dependencies.dart`.

Cubit is used for asynchronous auth and chat state. The current visual design and legacy Firebase-backed behavior are intentionally preserved while architecture boundaries are introduced.

## Backend data foundation

`BackendDataDependencies` composes secure session storage, an authenticated REST client, direct-conversation REST datasources, and a Socket.IO realtime datasource. It reads the backend origin from `CHAT_API_BASE_URL` when instantiated (for example, `https://api.example.com`). The REST datasource uses `/v1`; the realtime datasource uses `/realtime`.

The active `main.dart` composition still uses Firebase and the legacy single-room screen. The backend repository and session controller are staged for the direct-conversation UI rollout. The backend register endpoint currently accepts email/password; profile-image upload is outside that contract, so the legacy registration form is not routed to it.

The realtime datasource emits typed domain events, refreshes the access token before connecting, and reconnects with bounded backoff. Repository reconciliation and backend auth lifecycle are implemented. Direct-conversation screens and real-device integration are the next checkpoint before switching the app entrypoint.

## Backend repository and session lifecycle

- `BackendDataDependencies.session` implements the email/password-only
  `BackendAccountRepository`; call `initialize()` to restore/validate storage,
  `login()`/`register()` for accounts, and `logout()` to stop account resources.
- `BackendDataDependencies.repository` implements `ConversationsRepository`.
  Subscribe to `watchState()` for immutable list/history/outgoing/read/typing
  snapshots. `prepareMessage()` allocates one client ID and `sendOutgoing()`
  keeps that ID and original payload on retries. Canonical messages replace the
  corresponding outgoing item whether REST or realtime arrives first.
- Message IDs deduplicate resources; a bounded 512-event cache deduplicates
  publications. Newer edits and terminal tombstones win over stale observations.
- Resync buffers up to 1024 events and refetches loaded conversation/history
  windows plus REST read snapshots. Overflow invalidates the snapshot and
  refetches. Ambiguous summary events trigger REST refetch, because summaries
  have no durable revision. Read positions use canonical timestamp-plus-ID order.
- `pauseRealtime()` retains REST state while disconnecting for background use;
  `resumeRealtime()` reconnects and resyncs. UI lifecycle hooks are staged, not
  active in the legacy entrypoint. Typing indicators expire locally and start
  commands are throttled to one every three seconds.
- Session revisions reject late protected/auth/refresh responses after logout
  or account replacement. Storage writes are serialized; concurrent refreshes
  share a request. Cancelled successful auth responses revoke their returned
  refresh token on a best-effort basis. Offline logout always clears local state;
  remote revocation can fail when the network is unavailable.
- The backend read-state recovery query is required by this repository. No new
  database migration, dependency, or durable socket command is introduced.

Limitations: outgoing/cache state is in memory, not a durable offline outbox.
Only loaded windows are resynchronized. Summary invalidations can cause extra
REST queries under heavy event load; versioned summary snapshots can optimize
this later. Equal message-edit timestamps have no independent server revision.
The new backend path has fake-datasource coverage and still needs a two-account
on-device/backend integration pass with the new UI.

## Development

```bash
flutter pub get --enforce-lockfile
dart format lib test
flutter analyze
flutter test
flutter run
```

## Next checkpoints

1. Replace the legacy single-room Firebase behavior with the approved conversation model.
2. Add use cases only where they carry real orchestration/business value.
3. Wire the prepared backend account/conversation repositories into the new UI.
4. Implement the approved design system and high-fidelity screens.
