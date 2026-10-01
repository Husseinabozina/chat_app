# Backend account and direct-conversation UI checkpoint

Updated: 2026-10-01. Branch: `feat/mobile-backend-product-flow`, based on PR #17 HEAD `d1a1c683a63c9ace2b337d861bb83eef26e45763`. PR #18 is open/Draft. Verified code HEAD: `b4a31c6c7c17e7f12062c83261d700d94d8cc60d`; final host CI succeeded. Native and final visual acceptance remain pending.

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

## Published commits and verification

- Initial UI: `17de93fefd755de7a6cbe39799ebb14f18fd2918`.
- Unicode message length fix: `b4a31c6c7c17e7f12062c83261d700d94d8cc60d`; aligns mobile validation with backend surrogate-pair/variation-selector handling instead of rejecting valid long emoji messages.
- [Mobile CI #19](https://github.com/Husseinabozina/chat_app/actions/runs/36857361322) completed/success on that code HEAD; quality and two-account integration jobs both passed.
- Merge-ref tree `dffbf6da3b97b326d12e6c65758c3033249b4f79` matches the code HEAD tree; no project merge.
- Previous [CI #18](https://github.com/Husseinabozina/chat_app/actions/runs/36856224394) passed on the initial UI commit; inspected logs recorded 46 mobile tests passed + one live skip in the ordinary suite, 20 backend E2E passed, and one separate live test passed. Latest #19 status/jobs were freshly checked; its log counts were not independently downloaded in the documentation follow-up.


Local current suite: 46 mobile tests passed, one live test skipped when the integration URL is absent. The separate live test passed with two actual accounts against Node 24.9.0/PostgreSQL 17.11, real REST and Socket.IO. It covers response loss after commit/idempotent retry, discovery/public identity isolation, unique direct conversation, read/edit/delete, missed-event recovery, typing, 44-message cursor history, refresh and logout.

The eight new presentation/read tests cover account/profile onboarding and route removal, failed-send retry, latest-message placement/visible reads, stale search results, reply/edit/delete actions, covered/background read suppression, small scaled RTL layout, and read-position comparison. A new request deadline test preserves the session on timeout.

Mobile CI adds a separate live integration job with an ephemeral PostgreSQL service and compiled backend fixture. The fixture runs npm ci/format/lint/typecheck/build/migrations/tests; mobile dependencies are locked. The existing Backend CI workflow is unchanged. No diagnostic steps or uploaded temporary artifacts.

## Native iOS boundary

An initial automatic Swift Package Manager migration attempted a full Firebase source clone and failed after prolonged network transfer. The app currently retains its existing CocoaPods strategy through per-project Flutter config. Stale CocoaPods CDN version indices were refreshed locally from the upstream CDN, outside the repository. iPhone 16e exists; simulator availability was never the blocker. The user took over the build after freeing space. At the latest read-only check a Runner.app executable existed and no matching xcodebuild remained; terminal outcome/launch were not yet confirmed. Flutter-generated iOS/macOS project changes plus ios/Podfile.lock remain local and uncommitted, separate from verified PR #18. Native build completion and actual screen review must be recorded separately and must not be inferred from host tests or artifact presence.

## Remaining scope

- Final high-fidelity design/typography/asset acceptance.
- Two-device native UI integration and secure-storage restoration, unless separately evidenced at closure.
- Durable local cache/outbox, media/avatar upload, push, presence/last seen, durable delivery receipts, replay/outbox/Redis.
- Production allowed origins/CORS and handshake attempt throttling.

No merge or force push is included. Keep CURRENT_STATE updated before closing future checkpoints.

## Approved visual direction remains authoritative

The user reaffirmed the approved UI/UX decisions on 2026-10-01. The latest generated Chats preview was a simplified concept, not an app screenshot or replacement specification. Preserve environmental/object decoration, rounded friendly typography and integrated custom navigation from approved-ui-direction.md. Exact font is unapproved; Cairo was requested for the Arabic report. Track current visual/native gaps in UI_UX_ACCEPTANCE_CHECKLIST.md. This documentation follow-up changes no mobile source, dependency, lockfile or platform file. PR #18 stays Draft pending acceptance; #15/#16/#17 remain Ready and unmerged.

## Targeted native smoke follow-up — 2026-10-01

Installed/launched the user's existing Runner.app on iPhone 16e/iOS 26.2; no repeated Flutter build or new local test suite. Restarted task-owned backend dependencies in persistent workspace work/runtime because the earlier temporary Node binary and PostgreSQL cluster had disappeared. New disposable local database: PostgreSQL 17.11 on loopback 55417, migrations applied; Node 24.9.0 API on 55418; health confirmed. No public deployment.

Native UI passed fixture login, profile completion, empty Chats → People, username search, Arabic public profile → Message, reception of an Arabic/emoji message over realtime, native English outgoing send, and Sent → Read after the peer fixture advanced its durable read pointer. REST confirmed exactly two persisted messages. Terminating/relaunching the app restored the account without login and recovered the list/history/read state through production secure-storage composition. The peer is a REST fixture, not a second native client; this is a targeted one-simulator smoke check.

CUA paste/Unicode injection dropped characters; individual physical key presses worked. This is an automation limitation, not an established product defect. A system Save Password suggestion was not accepted. Software keyboard/native Arabic input, full native contextual actions, dark/large-text and two-device foreground/background/reconnect acceptance remain pending. Screenshots of actual Sign In and Conversation surfaces were reviewed through the simulator tool; they establish current functional layout, not final visual approval.

Automatic platform diff was read: Flutter UIScene/implicit-engine migration and CocoaPods wiring; minimum iOS target remains 15.0. All 11 generated platform modifications plus ios/Podfile.lock remain local/unpublished; no manual pbxproj edit, source/dependency/lockfile change or merge/force push. PR #18 remains Draft for full native and visual acceptance.
