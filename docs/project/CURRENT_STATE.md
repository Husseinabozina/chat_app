# Current Project State

Update this file before closing each future project checkpoint. Verify actual branch heads and CI runs from GitHub before changing the state below. Record native acceptance separately from host/CI checks.

**Updated:** 2026-10-01
**Current phase:** Pastel Mingle presentation implemented above PR #18 and verified by Mobile CI #22. The user approved the complete Chats concept and authorized continuation. Xcode build/launch succeeded on iPhone 16e/iOS 26.2; comparison of the revised native screens is blocked because the Mac is locked and computer-use automatic unlock failed. This is not final visual acceptance. PR #19 remains Draft.

## Last verified branch / PR / commit

- Branch: `feat/mobile-pastel-visual-identity`.
- PR: [#19](https://github.com/Husseinabozina/chat_app/pull/19), open/Draft, based on PR #18 branch `feat/mobile-backend-product-flow` at actual HEAD `01f5220bb8f80736749200331536ed7f4bcdee28`.
- Verified implementation commit: `9dbf88c359d446d8b9853573cedc478243e3006c`.
- [Mobile CI #22](https://github.com/Husseinabozina/chat_app/actions/runs/36909761654): completed/success on that exact implementation HEAD; quality and real two-account integration both succeeded.
- Implementation tree: `dc521cc56f8e864944fa809b5580b59c516efa8d`. It exactly matches the original local implementation commit `0dca83a3ee51ec44e3a8819ba896e9eb0fe64c14`, preserved in local branch `feat/mobile-pastel-visual-identity-local0d`. Publication used the GitHub connector after the native credential helper failed; remote metadata produced a different commit SHA with identical files and the same PR #18 parent. The remote branch was advanced with force=false.
- Local verification: read-only format check (57 files unchanged), clean analysis, 46 existing mobile tests passed + one ordinary live skip, one separately invoked real backend integration passed. No tests were added or weakened.
- Native execution: Flutter 3.47.5/Dart 3.13.4 build completed in 749.7s and launched on iPhone 16e/iOS 26.2. This establishes build/launch, not a review of the revised appearance.
- Final documentation HEAD/checks are recorded in PR metadata and handoff after publication to avoid a self-referential file hash.
- Historical baseline: PR #18 code `b4a31c6c7c17e7f12062c83261d700d94d8cc60d` / documentation HEAD `01f5220bb8f80736749200331536ed7f4bcdee28`, Mobile CI #21 success, targeted native account/message/session smoke passed.
- Automatic native build migrations remain local/unpublished, outside this PR. Do not stage the entire workspace.

## Integrated baseline and PR stack

Integrated `master` HEAD: `5f77dbd50efd9ae12f17d809a63c2746f35fc9ee` (PR #14 realtime contract merge). Latest checked active stack:

| PR | Branch | Base | Verified HEAD | State |
|---|---|---|---|---|
| #15 | `feat/backend-realtime-foundation` | `master` | `456c842b157b30f4dd9728ba3869f7fa7b6a50d8` | Ready, unmerged |
| #16 | `feat/mobile-api-realtime-foundation` | #15 branch | `b0a68f4908a60facea617655b358e478b22a7004` | Ready, unmerged |
| #17 | `feat/mobile-repository-reconciliation` | #16 branch | `d1a1c683a63c9ace2b337d861bb83eef26e45763` | Ready, unmerged |
| #18 | `feat/mobile-backend-product-flow` | #17 branch | `01f5220bb8f80736749200331536ed7f4bcdee28` (docs; code `b4a31c6`) | Draft, functional native acceptance incomplete |
| #19 | `feat/mobile-pastel-visual-identity` | #18 branch | `9dbf88c359d446d8b9853573cedc478243e3006c` (implementation) | Draft, CI green; native visual comparison blocked |

Proposed merge order: **#15 → #16 → #17 → #18 → #19**, after review and explicit merge authorization. Use merge commits to preserve ancestry; after each merge retarget the next PR to `master` and verify its diff/checks. No merge or force push is included in this checkpoint.

Integrated earlier history:

1. #1 Product/design/architecture docs
2. #2 Monorepo/backend foundation
3. #3 Mobile modernization
4. #4 Mobile feature-first architecture
5. #6 Database foundation
6. #7 Auth/users
7. #9 Conversations/messages
8. #10 User discovery/public profiles
9. #11 Read + message lifecycle
10. #12 Backend quality reconciliation
11. #13 Integrated-state documentation
12. #14 Realtime V1 architecture contract

PR #5 and PR #8 were closed as superseded by the main project conversation; their branches remain available. #12 rescued lint, health E2E, E2E typechecking and updated development commands from #5 without copying obsolete Jest/TypeScript configuration. Dedicated cascade regression coverage and avatar storage-key design from #8 remain debt, not rescued implementation.

## Completed checkpoints

### Product/design

- Product vision, initial scope, user flows, REST/realtime contracts, system/data architecture and ADRs are documented.
- Approved identity: soft pastel pink/cream, warm rounded surfaces, friendly rounded typography, object/environment decoration, abstract/initial avatars; no dating motifs or detailed decorative faces.
- Navigation: Chats/People/Profile; initial conversation filters All/Unread.
- Screen structure and loading/empty/error/offline/action states are planned.
- Rounded fonts and production raster artwork are now implemented in #19; the user approved the Chats concept at `docs/design/references/approved-chats-preview.png`. Native pixel-level acceptance remains pending. Cairo was requested for Arabic reports, not automatically for the app.
- The generated Chats preview is simplified and does not replace `docs/design/approved-ui-direction.md` or constitute approval of the final app appearance.
- Implementation/acceptance gaps are tracked in `docs/project/UI_UX_ACCEPTANCE_CHECKLIST.md`.

### Backend

- NestJS 12/TypeScript 6/Node 24 modular backend with PostgreSQL 17.
- Explicit TypeORM migrations; `synchronize` disabled.
- Email/password auth, Argon2id, JWT access tokens and rotating refresh sessions.
- Own/public profiles and user search; public identity excludes private email.
- Unique direct conversations and membership authorization.
- Durable text/replies, sender/client-message idempotency and stable cursor pagination.
- Monotonic read pointers/unread counts; sender-owned edit/soft delete.
- Health/PostgreSQL and compiled-app auth/users/messaging E2E coverage.
- PR #15: authenticated Socket.IO `/realtime`, server-controlled user/session rooms, post-commit message/conversation/read events, transient typing and logout disconnect.
- PR #17: membership-authorized REST read-state recovery plus additive canonical read positions, recovering receipts missed offline.
- PR #18 introduces no backend source/API/schema/migration change.

### Mobile

- Flutter 3.47.5/Dart 3.13.4 baseline, locked dependencies and Mobile CI.
- Feature-first presentation/domain/data boundaries; Firebase behind legacy data adapters.
- PR #16: secure backend session store, refresh-aware REST client, REST/realtime adapters and opt-in composition.
- PR #17: account/conversation repository contracts, deduplication, monotonic edit/delete/read merging, buffered REST recovery, stable-ID outgoing retries and typing TTL/throttling.
- PR #18: account restore/login/register, separate profile completion/edit, Chats/People/Profile, public profiles/search, unique direct conversation creation, paginated history, reply/copy/edit/delete, failed-send retry, read and typing display.
- PR #18: account-keyed navigation clears pushed routes on logout/replacement; foreground/background hooks control the existing transport.
- REST requests have a 15-second deadline and preserve credentials on network timeout.
- Reversed history shows newest messages at the bottom; read commands use visible incoming bounds on a current foreground route; canonical receipt order is `(createdAt,id)`.
- Chats/People have scrollable headers; Arabic/Latin message direction and scaled/landscape widget behavior are covered. Full Arabic UI localization is not implemented.
- Backend mode is enabled with `CHAT_API_BASE_URL`; when unset the existing Firebase entrypoint remains available.
- New UI is functional; environment artwork, final rounded font and custom navigation styling remain visual work.

## Locked architecture decisions

- Modular NestJS/PostgreSQL is the primary backend.
- REST/PostgreSQL are durable authority; durable send/edit/delete/read commands remain REST-only. Realtime publication follows commit.
- Socket.IO is behind replaceable adapters; it is not a durable message store.
- Socket access-token authentication validates the backing session; user/session rooms are server-controlled.
- V1 uses stable versioned event envelopes and IDs. No event replay log; REST resync provides reconnect recovery.
- Mobile domain/presentation depends on repository contracts, not SDK/HTTP/socket types. Shared backend state belongs to repositories; forms/loading/navigation use local widget state. Legacy Firebase Cubits remain available.
- Direct identity is the canonical participant pair. Retry uses sender + `clientMessageId`.
- Cursors/read pointers use stable timestamp-plus-ID order; read advances monotonically.
- Only the sender may edit/soft-delete their message.
- `sent` means REST persisted; `read` means durable recipient read pointer. No durable delivered-to-device receipt in V1.
- Typing is transient with TTL; no public presence/last-seen contract yet.
- E2E runs the compiled Nest app; database suites run in separate Node processes.
- No architecture/product scope change is justified by visual cleanup alone.

## Current CI and verification

### PR #18

[Mobile CI #19](https://github.com/Husseinabozina/chat_app/actions/runs/36857361322) succeeded on code HEAD `b4a31c6c7c17e7f12062c83261d700d94d8cc60d`:

- Quality job: locked dependency resolution → non-writing format check → analyze → tests.
- Integration job: Node 24/PostgreSQL 17 fixture; `npm ci → format:check → lint → typecheck → build → migrations → npm test`, followed by the separate Flutter two-account REST/Socket.IO test.
- Latest job IDs: `110352952396` (quality), `110353283333` (integration); both completed/success.
- Previous [CI #18](https://github.com/Husseinabozina/chat_app/actions/runs/36856224394) also succeeded on the initial UI commit; its inspected logs recorded 46 mobile tests passed + one live test skipped in the ordinary suite, 20 backend E2E passed, and one separately invoked live integration test passed. Those counts are from #18/local evidence, not a new download of #19 logs.
- Local full mobile suite: 46 passed + one live skip; separate live test: one passed against Node 24.9.0/PostgreSQL 17.11. Production composition uses secure storage; live test clients use memory stores.
- Live coverage: discovery/privacy, direct uniqueness, response loss after database commit and idempotent retry, read/edit/delete, missed-event REST recovery, typing, 44-message pagination, access-token refresh and logout.
- This is host/widget/backend integration evidence, not two-device native acceptance.

Workflows retain `contents: read`; mobile integration uses an ephemeral database and bounded backend health wait. No diagnostic steps or artifact upload. Backend workflow is unchanged. No backend dependencies, lockfiles or migrations changed in #18. Mobile CI also triggers on backend changes to check the cross-stack contract.

### Earlier verified checkpoints

- PR #17 final HEAD: [Backend CI #83](https://github.com/Husseinabozina/chat_app/actions/runs/36798410587), [Mobile CI #17](https://github.com/Husseinabozina/chat_app/actions/runs/36798410622), success. Implementation `9c369dc661d4e59341318304c3b779eeb5425991`: Backend #82/Mobile #16, 20/37 tests passed.
- PR #15: [Backend CI #81](https://github.com/Husseinabozina/chat_app/actions/runs/36740459123), success.
- PR #16 final HEAD: [Mobile CI #15](https://github.com/Husseinabozina/chat_app/actions/runs/36755021551), success.
- Integrated backend: [CI #73](https://github.com/Husseinabozina/chat_app/actions/runs/36724138035) on `c84e4ff5294867de0d6da392dccc071ca076901b`, success.
- Last mobile-changing master `e03d990fda545463ff259513fb668494dec8b1ec`: [Mobile CI #12](https://github.com/Husseinabozina/chat_app/actions/runs/36723604090), success; later integrated changes were backend/docs.

## Native iPhone acceptance boundary

- iPhone 16e simulator is available; absence of a simulator was not the blocker.
- Initial automatic SPM migration downloaded Firebase source and failed during network transfer. The project retains existing CocoaPods integration through `flutter.config.enable-swift-package-manager: false`.
- Stale local CocoaPods CDN indices were refreshed outside the repository. First native dependency/build preparation was prolonged; low disk space was reported and the user freed space.
- The user took over the simulator build. At the latest read-only check an executable `build/ios/iphonesimulator/Runner.app/Runner` existed and no matching `xcodebuild` process was running. This establishes artifact presence only; terminal success, launch and screen/device acceptance are not yet recorded.
- Flutter-generated iOS/macOS project changes and a local `ios/Podfile.lock` remain uncommitted, separate from verified PR #18. Review these with native build evidence before inclusion in any checkpoint.
- Reviewed automatic platform diff: Flutter UIScene/implicit-engine migration, CocoaPods workspace/framework/scripts/config wiring and platform includes; iOS target remains 15.0. This follow-up does not publish or manually edit these changes. No concurrent Flutter build/test or user-file cleanup was performed.
- The temporary Node binary/database disappeared between sessions. A new task-owned Node 24.9.0 runtime and PostgreSQL 17.11 cluster were created under the workspace `work/runtime` outside the repository; migrations applied and loopback API port 55418 health succeeded. These are disposable local demo data, not restored prior test accounts.
- Native automation paste/Unicode injection was unreliable; direct individual key presses worked. An iOS Save Password suggestion was not accepted. Software keyboard layout, native Arabic typing, full edit/delete/reply UI, dark/large-text native and two-device coverage remain pending.

## Pending initial-release work and later features

Pending initial-release scope includes final UI polish/acceptance, profile images/image messages, push notification delivery/routing, supported appearance settings and deployment. Media/push require explicit contracts before implementation; they are not removed from V1 merely because they are deferred from this checkpoint.

Later/deferred work:

- Public presence/last-seen, voice notes, reactions and conversation pinning require separate scope decisions.
- Durable delivered-to-device receipts.
- Durable mobile offline cache/outbox beyond in-memory retries.
- Durable realtime event replay/transactional outbox and Redis/multi-instance adapter.
- Groups, calls, stories and other excluded features remain outside the initial product scope.

## Known issues / technical debt

- Native account restoration across process termination/relaunch passed on iPhone 16e using production secure-storage composition. Two-device foreground/background/reconnect behavior and physical-device storage remain unverified.
- Decorative artwork, final font, custom navigation and final visual acceptance remain pending; current UI must not be described as the fully approved final design.
- Full Arabic UI localization is pending; current message direction handling is not equivalent to it.
- Dedicated cascade-deletion regression coverage from #8 has not been reproduced; avatar storage-key policy is deferred to media design.
- Edit/delete product time-window policy is undecided.
- Conversation summaries have no durable revision; conservative invalidation/refetch may add REST traffic.
- Equal edit timestamps are resolved by REST refetch; independent revisions could reduce ambiguity.
- Offline logout clears local state immediately; remote revocation remains best effort.
- Production allowed-origin/CORS policy and socket handshake attempt throttling must be implemented before public deployment.
- Publication is best effort after commit; a crash before emission can lose an event. REST resync is the V1 recovery path.

## Exact next checkpoint

**Unlock the Mac and complete native visual comparison against the approved Chats concept, then finish native acceptance.** One-simulator smoke/session restoration is recorded; finish software-keyboard/native Arabic input/text scaling/dark mode and two-native-client lifecycle coverage, then decide how to publish the reviewed automatic native changes; implement missing approved visual details screen by screen against `UI_UX_ACCEPTANCE_CHECKLIST.md`. Complete targeted checks before marking that acceptance passed. Do not silently treat host CI as device/visual approval.

Then review #15 → #16 → #17 → #18 → #19 integration; merge only after explicit authorization. Implement production origin/CORS and handshake throttling before any public deployment. Scope media/avatar and push contracts for the remaining initial-release work. Keep this file updated at every checkpoint closure.

## Active visual checkpoint — 2026-10-01

- User supplied the original pastel showcase, then requested a complete screen preview after seeing a large isolated avatar asset. The isolated landscape was intended only as a small circular fallback; it was not a background/product direction. The complete Chats concept was shown, the user approved it, and continuation was authorized. Both original and approved concept are saved under `docs/design/references`.
- Existing screens now use a cream/blush/navy theme; bundled Quicksand display, Nunito body/UI and Tajawal Arabic fallback; transparent clouds/paper plane/leaves; illustrated avatar fallback plus initial badge; integrated Chats/People/new-chat/Profile navigation; rounded lists/forms/bubbles/composer.
- Existing repositories, REST/realtime contracts, credential/profile separation, retry IDs and read rules remain unchanged. No unsupported social sign-in, voice, groups, calls, pinning or fake settings.
- Workflows and pubspec lockfile are unchanged and reproducible. Backend verification in Mobile CI still runs npm ci → format:check → lint → typecheck → build → migrations → npm test; no diagnostic steps or artifact uploads were added.
- Native build succeeded. Computer use reported a locked Mac and failed automatic unlock; the user was asked to unlock it manually. No alternate screen-capture route was used to bypass the block. See `design-qa.md` (final result: blocked) and `docs/project/PASTEL_UI_CHECKPOINT.md`.
- Exact next action: after manual unlock, inspect/capture the revised native Chats, Conversation, auth and profile screens; compare normalized views against the supplied/approved references; correct P0/P1/P2 differences; update the QA evidence, CI and PR description. Do not claim a generated preview is a native screenshot.
