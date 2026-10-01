# Backend account and direct-conversation UI checkpoint

Updated: 2026-10-01. Branch: `feat/mobile-backend-product-flow`, based on PR #17 HEAD `d1a1c683a63c9ace2b337d861bb83eef26e45763`. Publication/final CI/native results are recorded in the PR and CURRENT_STATE at closure.

## Scope

The backend path is opt-in with `CHAT_API_BASE_URL`. It initializes secure backend sessions instead of Firebase, restores the account, routes on account changes and clears pushed routes on logout/expiry. Email/password creation precedes text profile completion; media remains deferred.

Implemented screens: sign in/create account; complete/edit own profile; Chats with loaded-window search and All/Unread filters; People with debounced, paginated user search; public profile; direct conversation with paginated history, optimistic outgoing state/stable-ID retry, reply/copy, sender edit/delete, typing and canonical receipts. Conversation search describes loaded chats and allows loading more even when the current filter has no matches.

Presentation consumes BackendAccountRepository, ConversationsRepository and UsersRepository through BackendAppServices. It stays within app/auth/users/conversations/core boundaries. Shared state stays in repositories; transient form/navigation/loading state stays in widgets. REST/PostgreSQL remain authoritative; existing Socket.IO adapters are reused. No backend endpoint/schema/dependency/migration or durable socket command is changed.

## Correctness choices

- Canonical repository history is ascending. The reversed scrolling view consumes descending items so the newest message is at the bottom and older pages extend the upper history.
- Read commands use only visible incoming message bounds while the route is current and the app is foregrounded. Receipt comparison uses canonical `(createdAt,id)`, not read-event publication time.
- Failed outgoing messages remain visible and retry with their existing client ID.
- Search generations reject stale responses. Account-keyed shells reject late profile work through widget disposal and the REST client rejects stale account revisions.
- REST requests have a 15-second deadline; a timeout is a retryable network failure and does not silently clear credentials.
- Arabic/English message paragraphs choose direction from their first supported strong character. Bubbles use directional alignment. This is not full Arabic UI localization.
- Chats/People use scrollable headers/content, allowing small landscape screens and larger text without a fixed header consuming the viewport.
- Typing expiry regression tests use an injected clock to avoid a 50ms wall-clock race on busy machines. Production uses DateTime.now.

## Verification

Local current suite: 46 mobile tests passed, one live test skipped when the integration URL is absent. The separate live test passed with two actual accounts against Node 24.9.0/PostgreSQL 17.11, real REST and Socket.IO. It covers response loss after commit/idempotent retry, discovery/public identity isolation, unique direct conversation, read/edit/delete, missed-event recovery, typing, 44-message cursor history, refresh and logout.

The eight new presentation/read tests cover account/profile onboarding and route removal, failed-send retry, latest-message placement/visible reads, stale search results, reply/edit/delete actions, covered/background read suppression, small scaled RTL layout, and read-position comparison. A new request deadline test preserves the session on timeout.

Mobile CI adds a separate live integration job with an ephemeral PostgreSQL service and compiled backend fixture. The fixture runs npm ci/format/lint/typecheck/build/migrations/tests; mobile dependencies are locked. The existing Backend CI workflow is unchanged. No diagnostic steps or uploaded temporary artifacts.

## Native iOS boundary

An initial automatic Swift Package Manager migration attempted a full Firebase source clone and failed after prolonged network transfer. The app currently retains its existing CocoaPods strategy through per-project Flutter config. Stale CocoaPods CDN version indices were refreshed locally from the upstream CDN, outside the repository. iPhone 16e exists; simulator availability was never the blocker. Native build completion and actual screen review must be recorded separately and must not be inferred from host tests.

## Remaining scope

- Final high-fidelity design/typography/asset acceptance.
- Two-device native UI integration and secure-storage restoration, unless separately evidenced at closure.
- Durable local cache/outbox, media/avatar upload, push, presence/last seen, durable delivery receipts, replay/outbox/Redis.
- Production allowed origins/CORS and handshake attempt throttling.

No merge or force push is included. Keep CURRENT_STATE updated before closing future checkpoints.
