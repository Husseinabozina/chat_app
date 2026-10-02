# Current Project State

Update this file before closing each future project checkpoint. Verify actual branch heads and CI runs from GitHub before changing the state below. Record native acceptance separately from host/CI checks.

**Updated:** 2026-10-02
**Current phase:** Private profile/photo-message implementation on `feat/media-images`, based on PR #24 implementation `06689b770171a607c7279320994e43a587cd07ad` (Mobile CI #33 success). Actual uploads/validated private storage, message image persistence/retry/realtime, profile-photo save, picker/preview/viewer and one-time corrected onboarding revision2 are implemented. See `MEDIA_CHECKPOINT.md`; publication/current-head CI is recorded in PR metadata. No native build/visual acceptance claim.

**Current acceptance boundary:** The user explicitly deferred the previous native visual review and authorized this implementation without further questions. Historical native resource builds succeeded before this checkpoint; no new native build was started. Latest full visual/motion/keyboard/dark/physical/two-device acceptance is still pending. Android native build is unverified because no local Android SDK is installed. See `BRAND_ENTRY_SETTINGS_CHECKPOINT.md` and `design-qa.md`. This is not a released application; new photo features need native/provider acceptance, and push/supported notification settings/release readiness remain.

## Last verified branch / PR / commit

- Active media branch `feat/media-images`, based on PR #24 implementation `06689b770171a607c7279320994e43a587cd07ad`, [Mobile CI #33](https://github.com/Husseinabozina/chat_app/actions/runs/37025464141) success. New media publication/exact-head checks pending; older evidence below is historical.

- Active checkpoint: `fix/mobile-entry-visual-polish`, based on exact PR #22 final HEAD `d89dd9e869f180d42cd9fa60ddee19c194199b2d`, [Mobile CI #29](https://github.com/Husseinabozina/chat_app/actions/runs/37009976819) success. Draft [PR #23](https://github.com/Husseinabozina/chat_app/pull/23), verified implementation `776e9c1d88ad00c811e2f62a7fb224b87edfedb7`; [Mobile CI #30](https://github.com/Husseinabozina/chat_app/actions/runs/37020880336) completed/success. Final documentation HEAD/checks are recorded in PR metadata; older evidence below is historical.

- Active logo repair branch: `fix/mobile-logo-fidelity`, based on actual remote PR #21 HEAD `49cd87c75a666f6bc174794a4a27a36474f44705` (verified before branching). Draft [PR #22](https://github.com/Husseinabozina/chat_app/pull/22); verified implementation `34f8fb0bec966395512a0fc1378c89190acffd64`, [Mobile CI #28](https://github.com/Husseinabozina/chat_app/actions/runs/37009580140) completed/success. See `LOGO_FIDELITY_CHECKPOINT.md`. Final documentation HEAD/checks are recorded in PR metadata to avoid self-referential hashes.
- Latest verified baseline: [PR #21](https://github.com/Husseinabozina/chat_app/pull/21), [Mobile CI #27](https://github.com/Husseinabozina/chat_app/actions/runs/36994964281), completed/success on that exact HEAD. Older implementation evidence below remains historical.

- Historical verified branch: `feat/mobile-brand-entry-settings`, Draft PR [#21](https://github.com/Husseinabozina/chat_app/pull/21), based on actual PR #20 HEAD `a757c75da81c550b09e377af69f86a33a6e0556d`.
- Latest verified implementation: `45d227930809c876c85d810e0b5070ca225bd562`, [Mobile CI #26](https://github.com/Husseinabozina/chat_app/actions/runs/36994453820) completed/success. Subsequent documentation HEAD/checks are recorded in PR metadata, avoiding a self-referential file hash.
- Latest implementation compiled/installed/launched on iPhone 16e/iOS 26.2 (23.2s native build). This is build/launch evidence, not visual acceptance.
- Baseline [Mobile CI #25](https://github.com/Husseinabozina/chat_app/actions/runs/36985197274): completed/success on that exact PR #20 HEAD.
- Previous verified branch: `feat/mobile-motion-demo`; Draft PR [#20](https://github.com/Husseinabozina/chat_app/pull/20), based on PR #19 branch at `abe502695e6f32512800e30c7ab09b4ec7e0a41a`.
- Previous verified implementation commit: `313b800f0dd90128b5d92a7725552d5e61266802`. [Mobile CI #24](https://github.com/Husseinabozina/chat_app/actions/runs/36984743287): completed/success, both quality and two-account integration jobs passed. Subsequent documentation HEAD/check results are recorded in PR metadata to avoid a self-referential file hash.
- Baseline PR: [#19](https://github.com/Husseinabozina/chat_app/pull/19), open/Draft, final published HEAD `abe502695e6f32512800e30c7ab09b4ec7e0a41a`, based on PR #18 branch `feat/mobile-backend-product-flow` at actual HEAD `01f5220bb8f80736749200331536ed7f4bcdee28`.
- Baseline latest [Mobile CI #23](https://github.com/Husseinabozina/chat_app/actions/runs/36911086830): completed/success on exact PR #19 documentation HEAD `abe502695e6f32512800e30c7ab09b4ec7e0a41a`, freshly checked 2026-10-02. The following #22 evidence is historical implementation verification.
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
| #19 | `feat/mobile-pastel-visual-identity` | #18 branch | `abe502695e6f32512800e30c7ab09b4ec7e0a41a` | Draft; Mobile CI #23 success; pastel direction accepted by user |
| #20 | `feat/mobile-motion-demo` | #19 branch | `313b800f0dd90128b5d92a7725552d5e61266802` (implementation) | Draft; CI #24 success; consolidated native acceptance pending |
| #21 | `feat/mobile-brand-entry-settings` | #20 branch | `49cd87c75a666f6bc174794a4a27a36474f44705` | Draft; CI #27 success; native visual review explicitly deferred |
| #22 | `fix/mobile-logo-fidelity` | #21 branch | `d89dd9e869f180d42cd9fa60ddee19c194199b2d` | Draft; CI #29 success; geometry superseded by #23 |
| #23 | `fix/mobile-entry-visual-polish` | #22 branch | `1dd304b054e53b382fa98317a858ccbd8b66e60e` | Draft; CI #32 success; native acceptance pending |
| #24 | `fix/mobile-product-entry` | #23 branch | `06689b770171a607c7279320994e43a587cd07ad` | Draft; CI #33 success; native acceptance pending |
| next | `feat/media-images` | #24 branch | Publication pending | Private media implementation; CI pending |

Proposed merge order: **#15 → #16 → #17 → #18 → #19 → #20 → #21 → #22 → #23 → #24 → media PR**, after review and explicit merge authorization. Use merge commits to preserve ancestry; after each merge retarget the next PR to `master` and verify its diff/checks. No merge or force push is included in this checkpoint.

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
- Rounded fonts and production raster artwork are implemented in #19; the user approved the Chats concept at `docs/design/references/approved-chats-preview.png` and subsequently accepted the native direction. Complete native fidelity/motion acceptance remains pending. Cairo was requested for Arabic reports, not automatically for the app.
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
- Current Mingle is the main entry; debug API defaults to local port 55418. Release/profile requires CHAT_API_BASE_URL. The Firebase prototype is explicit-only through main_legacy.dart.
- PR #19 implements bundled Quicksand/Nunito/Tajawal, pastel raster artwork and navigation. The current motion checkpoint adds 20 original icons, restrained motion with reduced-motion handling, three distinct bottom tabs, dedicated conversation chooser and explicit local demo fixture.
- New entry/settings checkpoint: editable/tintable logo, native launcher/splash resources, branded initialization, persisted first-run onboarding/skip/replay, System/Light/Dark and reduced-motion Settings, profile edit/about/confirmed logout. Authentication remains actual email/password with session restoration; social login and password recovery are not implemented.

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

### PR #23

[Mobile CI #30](https://github.com/Husseinabozina/chat_app/actions/runs/37020880336) completed/success on implementation `776e9c1d88ad00c811e2f62a7fb224b87edfedb7`. Quality job `110883333272`: 65 files format clean, analyzer clean, 46 tests passed + one intentional ordinary live skip. Integration job `110883826398`: complete backend gate and separate real two-account REST/realtime test passed. No new suite, native run, backend/workflow/dependency/lockfile change. Final documentation HEAD/checks are recorded in PR metadata.

### PR #22

[Mobile CI #28](https://github.com/Husseinabozina/chat_app/actions/runs/37009580140) completed/success on implementation `34f8fb0bec966395512a0fc1378c89190acffd64`. Quality job `110845826824`: 65 Dart files unchanged by format check, analyzer clean, 46 mobile tests passed + one intentional ordinary live skip. Integration job `110846145202`: complete Node 24/PostgreSQL 17 backend gate plus the separate two-account REST/realtime mobile test passed. No backend/workflow/dependency/lockfile changes. New logo native build/rendered acceptance is not claimed. Final documentation HEAD/checks are recorded in PR metadata.

### PR #21

[Mobile CI #26](https://github.com/Husseinabozina/chat_app/actions/runs/36994453820) completed/success on `45d227930809c876c85d810e0b5070ca225bd562`. Quality and the complete backend/two-account integration passed. No backend/workflow/dependency/lockfile changes. Native iOS implementation build/launch succeeded (23.2s); Android runtime/build and final rendered acceptance remain separate.

### PR #20

[Mobile CI #24](https://github.com/Husseinabozina/chat_app/actions/runs/36984743287) completed/success on exact implementation HEAD `313b800f0dd90128b5d92a7725552d5e61266802`:

- Quality job `110767080025`: locked dependencies, read-only formatting, analysis and existing tests passed.
- Integration job `110767446164`: Node 24/PostgreSQL 17 backend npm ci, format, lint, typecheck, build, migrations and tests passed, followed by the real two-account REST/Socket.IO mobile test.
- Native rendered acceptance is still separate; PR #20 remains Draft.

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
- Native terminal build/launch success is now recorded: PR #19 build 749.7s; motion checkpoint builds 32.4s and 63.9s on iPhone 16e/iOS 26.2. Populated Chats was captured. These earlier builds precede final source corrections. Latest hot reload lost the device connection; final native appearance is not established.
- Flutter-generated iOS/macOS project changes and a local `ios/Podfile.lock` remain uncommitted, separate from verified PR #18. Review these with native build evidence before inclusion in any checkpoint.
- Reviewed automatic platform diff: Flutter UIScene/implicit-engine migration, CocoaPods workspace/framework/scripts/config wiring and platform includes; iOS target remains 15.0. This follow-up does not publish or manually edit these changes. No concurrent Flutter build/test or user-file cleanup was performed.
- The temporary Node binary/database disappeared between sessions. A new task-owned Node 24.9.0 runtime and PostgreSQL 17.11 cluster were created under the workspace `work/runtime` outside the repository; migrations applied and loopback API port 55418 health succeeded. These are disposable local demo data, not restored prior test accounts.
- Native automation paste/Unicode injection was unreliable; direct individual key presses worked. An iOS Save Password suggestion was not accepted. Software keyboard layout, native Arabic typing, full edit/delete/reply UI, dark/large-text native and two-device coverage remain pending.

## Pending initial-release work and later features

Pending initial-release scope includes final UI/native acceptance (including newly implemented photos), push notification delivery/routing, supported notification settings and deployment. System/Light/Dark appearance selection and basic account Settings are now implemented with device persistence. Media/push require explicit contracts before implementation; they are not removed from V1 merely because they are deferred from this checkpoint.

Later/deferred work:

- Public presence/last-seen, voice notes, reactions and conversation pinning require separate scope decisions.
- Durable delivered-to-device receipts.
- Durable mobile offline cache/outbox beyond in-memory retries.
- Durable realtime event replay/transactional outbox and Redis/multi-instance adapter.
- Groups, calls, stories and other excluded features remain outside the initial product scope.

## Known issues / technical debt

- Native account restoration across process termination/relaunch passed on iPhone 16e using production secure-storage composition. Two-device foreground/background/reconnect behavior and physical-device storage remain unverified.
- Artwork, rounded fonts and custom navigation/icons are implemented; full visual/motion acceptance remains pending. Current UI must not be described as a finished application.
- Full Arabic UI localization is pending; current message direction handling is not equivalent to it.
- Dedicated cascade-deletion regression coverage from #8 has not been reproduced; avatar storage-key policy is deferred to media design.
- Edit/delete product time-window policy is undecided.
- Conversation summaries have no durable revision; conservative invalidation/refetch may add REST traffic.
- Equal edit timestamps are resolved by REST refetch; independent revisions could reduce ambiguity.
- Offline logout clears local state immediately; remote revocation remains best effort.
- Production allowed-origin/CORS policy and socket handshake attempt throttling must be implemented before public deployment.
- Publication is best effort after commit; a crash before emission can lose an event. REST resync is the V1 recovery path.

## Exact next checkpoint

1. Manual Flutter hot restart (`R`) previews current product entry. Introduction appears only with an unset completion flag, then sign-in/restored account; no Settings replay. Native launcher/splash require rebuilding. No reset of saved onboarding/session data is performed. Consolidated native acceptance remains separate.
2. Push device-token lifecycle, FCM credential configuration, conversation notification routing and supported Settings. Validate private photo storage/picker/viewer on native devices; avatars now use uploaded media when present.
3. Consolidated native acceptance remains explicitly deferred by the user; collect the missing evidence when resumed, including Android once its SDK is available.
4. Password recovery/social auth, localization, files/voice/presence/reactions require scope/contracts. No merges or force pushes without authorization.

## Current local quality evidence (2026-10-02)

- Current entry/settings host checks: 64 Dart files; analyzer clean; existing mobile suite 46 passed + one intentional live skip. Existing account-flow coverage extended for actual onboarding/settings/persistence; separate live REST/Socket.IO integration also passed on this checkpoint; full CI #26 backend fixture/two-account gate passed.
- Native iOS resources built successfully (42.8s) with existing local automatic migrations; asset sizes/alpha/XML/plist valid. Final central recoloring API is included in the subsequent 23.2s iPhone 16e build/launch on implementation HEAD; rendered acceptance remains deferred. No current Android native build claim.
- Seeder syntax/Prettier passed; rerun reused 12 demo profiles/eight directs/94 stable seed messages. Local database also contains user-added messages, so total message count can exceed fixture count.
- User requested code/automated checks first. Final rendered QA remains a separate gate, recorded in `design-qa.md`; no Lottie dependency was added.
- Workflows unchanged: read-only permissions, locked mobile resolution, backend npm ci → format:check → lint → typecheck → build → migrations → tests; no diagnostic steps/artifact uploads.
- Automatic native platform migrations and Podfile.lock remain local/unpublished.

## Local recovery and logo repair (2026-10-02)

- Canonical checkout: `/Volumes/Hussein/DevStorage/Projects/chat_app`; the former workspace checkout path is a symlink. Flutter/Node/PostgreSQL runtime remains outside Git in the task workspace. Local machine SDK paths are excluded from Git.
- User's manual iOS run exposed missing Flutter linker symbols. Local Debug/Release configurations now explicitly link Flutter and search built products; the Runner scheme invokes Flutter framework preparation. A subsequent iPhone 16e build/launch succeeded in 32.9s before the logo repair. These local native configuration fixes, automatic platform migrations and Podfile.lock remain unpublished and must be reviewed together before a native-platform checkpoint.
- The old local API process listened on port 55418 but timed out and consumed high CPU. Restarting only that API process restored `/v1/health` with database up and fast validation responses from login/register. No database reset or backend code change. The precise cause of the hang is unresolved; this is not evidence of a successful credential login.
- Original logo is preserved at `docs/design/references/original-mingle-logo.png`; four paths follow its silhouette, with smooth gradients replacing raster grain. Runtime recoloring preserves separate plane folds. No new app dependency, workflow or lockfile change.
- Host formatting/analyzer and developer export checks passed; Mobile CI #28 quality/backend/two-account integration passed. New-logo native build/rendered acceptance is not claimed. The user requested manual build ownership; no new simulator run was started for this logo repair.

## Latest entry polish implementation (2026-10-02)

- The ZCode trace lessons are incorporated into a reference-specific development script: complementary dark/light regions and cubic fitting, with a separately colored clipped lower fold. Earlier PR #22 silhouette-only evidence did not detect the identified internal artifacts; this checkpoint supersedes its geometry.
- Onboarding now explains People and messaging with decorative preview cards, Previous navigation, guarded page transitions and reduced-motion progress. Auth errors announce through a live region; Settings replay remains available.
- No new native build/simulator launch, backend/schema/dependency/lockfile/workflow change or extra test suite. Local automatic native migration/linker modifications and Podfile.lock remain unpublished.
- General PNG-to-SVG plugin work is explicitly deferred. Next product checkpoint remains profile/image media contracts and implementation, then push and release work.

## Product entry correction (2026-10-02)

- Supersedes earlier opt-in backend and Settings onboarding replay behavior: normal main.dart is now Mingle, branding is shown during startup, first-run onboarding requires explicit completion/Skip, and Settings no longer offers replay. Saved completion remains saved across logout/relaunch.
- Adjacent same-sender messages group visually without changing durable/read/retry behavior. Existing local platform modifications remain excluded.

## Current media checkpoint (2026-10-02)

- PR #24 product entry `06689b770171a607c7279320994e43a587cd07ad`: Mobile CI #33 run37025464141 success. Mingle is default; no Settings onboarding replay; startup branding and grouped messages implemented.
- `feat/media-images` starts from that verified code. Private signed upload/validation, atomic image-message claim, membership-checked download grants, photo picking/preview/avatar save/viewer and stable-ID retry now implemented; Mobile/Backend CI publication pending. Existing fake source accepts the new optional image parameter; no new suite.
- Legacy development onboarding flags are migrated through revision2 because earlier account restore could auto-complete them. Users see introduction once, then the persisted session/sign-in; credentials/theme are retained.
- Private local object storage is real, data on external disk; API/database healthy after preserving signing secret and restarting. Actual local demo photo/image message added. No cloud deployment or new native build.
- Remaining: push/FCM configuration and routing, production storage/provider verification, cleanup scheduling/orphan reconciliation, deployment hardening and consolidated native acceptance.
