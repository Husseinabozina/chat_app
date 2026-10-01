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

The backend product is opt-in: run with `--dart-define=CHAT_API_BASE_URL=http://127.0.0.1:3000` (iOS simulator) or your HTTPS API origin. When configured, `main.dart` skips Firebase initialization and opens the backend account/direct-conversation flow. Without the define, the legacy Firebase entrypoint remains available. Email/password account creation is followed by name/username/bio setup; photo upload remains deferred.

The realtime datasource emits typed domain events, refreshes the access token before connecting, and reconnects with bounded backoff. Repository reconciliation and backend auth lifecycle are implemented. The backend UI consumes domain ports via `BackendAppServices`: account restoration, chats, people search/public profiles, profile completion/editing, and direct text conversations. Device integration and final visual acceptance are separate from host integration tests.

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
  `resumeRealtime()` reconnects and resyncs. The backend app activates these lifecycle hooks; the legacy entrypoint keeps its existing behavior. Typing indicators expire locally and start
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
The backend path has fake-datasource/widget coverage plus a real two-account REST/Socket.IO/PostgreSQL test. The latter runs on the Flutter test host, not on two devices. The new screens are a functional implementation of the documented visual direction; final high-fidelity visual acceptance is still pending.

## Development

```bash
flutter pub get --enforce-lockfile
dart format lib test
flutter analyze
flutter test
flutter run
```

## Backend UI and integration checks

```bash
flutter run --dart-define=CHAT_API_BASE_URL=http://127.0.0.1:3000
flutter test test/live/backend_flow_test.dart --dart-define=CHAT_INTEGRATION_URL=http://127.0.0.1:3000
```

For Android emulators use `http://10.0.2.2:3000`; public deployments use HTTPS. Do not point the live test at production: it creates disposable accounts/conversations/history. The test requires a migrated local/test backend and PostgreSQL. It models two independent clients and deliberately loses one send response after the database commit, verifying idempotent retry, receipts, message changes, pagination, reconnect recovery, refresh and logout. It uses memory session stores only in the test; production composition uses secure storage.

Mobile CI remains `contents: read`, uses locked dependencies, format/analyze/tests, and now runs this live test against a Node 24/PostgreSQL 17 fixture. Backend fixture gates are install/format/lint/typecheck/build/migrations/compiled-app E2E. Backend changes also trigger Mobile CI so the cross-stack contract remains checked. The live test is explicitly skipped in ordinary `flutter test` unless its URL is supplied.

The current native iOS project keeps its CocoaPods integration (`flutter.config.enable-swift-package-manager: false`) while platform migration is verified separately. REST requests have a 15-second deadline, mapped to retryable connection errors. Shared account/conversation state belongs to the domain repositories; backend presentation uses stream snapshots and local widget state for forms, pagination and navigation. Existing Firebase Cubits remain available in the legacy flow.

## Next checkpoints

1. Complete native device verification and visual acceptance of the backend UI.
2. Review the open PR stack and integrate only after merge authorization.
3. Public deployment hardening (allowed origins and socket handshake attempt throttling).
4. Media/push/offline persistence only after their contracts are scoped.
