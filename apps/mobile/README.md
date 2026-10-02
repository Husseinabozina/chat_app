# Mobile App

Flutter client for the messaging platform.

## Baseline

- Flutter: 3.47+
- Dart: 3.13+
- Android minimum SDK: 24
- iOS minimum target: 15.0
- State management: repository streams and local widget state in current Mingle; Cubit via flutter_bloc in the archived Firebase prototype
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

Current Mingle presentation depends on backend repository contracts. `BackendDataDependencies` composes its REST, realtime and media adapters. The archived Firebase prototype keeps its Cubit/data adapters in `injection/app_dependencies.dart` and is selected explicitly through `main_legacy.dart`.

## Backend data foundation

`BackendDataDependencies` composes secure session storage, an authenticated REST client, direct-conversation REST datasources, and a Socket.IO realtime datasource. It reads the backend origin from `CHAT_API_BASE_URL` when instantiated (for example, `https://api.example.com`). The REST datasource uses `/v1`; the realtime datasource uses `/realtime`.

`main.dart` always opens the current Mingle backend product. Debug runs default to the local API on port 55418: iOS/macOS use 127.0.0.1, Android emulator uses 10.0.2.2. Override with `--dart-define=CHAT_API_BASE_URL=...` for physical devices or a different server. Release/profile builds require an explicit API origin. The archived Firebase prototype is available only through `-t lib/main_legacy.dart`. Email/password account creation is followed by name/username/bio setup; profile photos are staged and attached only on Save profile.

The realtime datasource emits typed domain events, refreshes the access token before connecting, and reconnects with bounded backoff. Repository reconciliation and backend auth lifecycle are implemented. The backend UI consumes domain ports via `BackendAppServices`: account restoration, chats, people search/public profiles, profile completion/editing, and direct text/image conversations. Device integration and final visual acceptance are separate from host integration tests.

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
flutter run --dart-define=CHAT_API_BASE_URL=http://127.0.0.1:55418
flutter test test/live/backend_flow_test.dart --dart-define=CHAT_INTEGRATION_URL=http://127.0.0.1:3000
```

For Android emulators use `http://10.0.2.2:3000`; public deployments use HTTPS. Do not point the live test at production: it creates disposable accounts/conversations/history. The test requires a migrated local/test backend and PostgreSQL. It models two independent clients and deliberately loses one send response after the database commit, verifying idempotent retry, receipts, message changes, pagination, reconnect recovery, refresh and logout. It uses memory session stores only in the test; production composition uses secure storage.

Mobile CI remains `contents: read`, uses locked dependencies, format/analyze/tests, and now runs this live test against a Node 24/PostgreSQL 17 fixture. Backend fixture gates are install/format/lint/typecheck/build/migrations/compiled-app E2E. Backend changes also trigger Mobile CI so the cross-stack contract remains checked. The live test is explicitly skipped in ordinary `flutter test` unless its URL is supplied.

The current native iOS project keeps its CocoaPods integration (`flutter.config.enable-swift-package-manager: false`) while platform migration is verified separately. REST requests have a 15-second deadline, mapped to retryable connection errors. Shared account/conversation state belongs to the domain repositories; backend presentation uses stream snapshots and local widget state for forms, pagination and navigation. Existing Firebase Cubits remain available in the legacy flow.

## Next checkpoints

1. Complete native device verification and visual acceptance of the backend UI.
2. Review the open PR stack and integrate only after merge authorization.
3. Public deployment hardening (allowed origins and socket handshake attempt throttling).
4. Push registration/delivery/routing and cloud deployment, then native release acceptance. Durable offline persistence remains deferred.

## Opening flow

The branded Flutter opening screen lasts at least 800 ms while device preferences and account restoration run concurrently. First-time onboarding appears when its completion flag is unset, even if a session is restored. Get started/Skip persists completion; subsequent launches and logout do not replay it. There is no onboarding toggle/replay entry in Settings. Native launcher/splash resources require a rebuild; no forced logout or full preference reset is performed.

The corrected entry flow uses onboarding revision 2. Earlier development preference records may have been marked complete automatically on account restore, so they show the introduction once after upgrading. Theme/motion and credentials are retained. Completing/Skipping revision 2 prevents subsequent replay; there is no product setting to turn it on/off.

## Profile and message photos

Profile → Edit profile → Change photo → Photos/Camera → Use photo → Save profile. In a conversation use the custom photo attachment button, choose a picture, preview/add an optional caption, then send. Tap the image to zoom; failed sends retain the client ID for retry. Upload requires configured private object storage, not just PostgreSQL/API. See `docs/project/MEDIA_CHECKPOINT.md` for setup, limits and verification boundaries.

## Message notifications

Profile → Settings → New messages requests OS permission only on explicit opt-in, then registers the current installation/session. Disable revokes the server installation first. Missing server/provider setup is shown as unavailable. Existing firebase_messaging is behind a push domain port; cold/background taps verify target account and membership before opening a conversation. Native entitlements/permissions require a new user-owned build and actual FCM/APNs credentials; host CI does not prove delivery. See `docs/project/PUSH_CHECKPOINT.md`.
