# UI/UX Acceptance Checklist

Updated: 2026-10-02. This checklist reconciles approved design decisions with the functional backend UI in PR #18. It does not expand product scope, choose a final font, or approve a generated preview.

## Authority and review method

Read in this order:

1. `docs/design/approved-ui-direction.md` — approved identity, content constraints, typography character and screen direction.
2. `docs/product/feature-scope.md` / `user-flows.md` — initial-release behavior and scope.
3. `docs/design/high-fidelity-screen-plan.md` — screen composition, states and interactions.
4. `docs/design/design-system-v1.md` — provisional tokens and component rules, adjustable after readability/accessibility review.

Where documents contain different font suggestions, the approved direction takes precedence: rounded, friendly, geometric, readable; exact family remains unapproved. Cairo is the Arabic report font, not automatically the app font. Earlier screen-plan examples of registration fields or presence do not override current account/profile separation or the deferred presence contract.

An unchecked item is not accepted. A host/widget pass is not native evidence. A generated concept is not an app screenshot. Work one screen/related flow at a time, record review evidence and decisions, and update CURRENT_STATE before closing the checkpoint. Do not generate new mockups/assets without a specific user request.

## Functional baseline already verified on host

- Account creation/login/restore/logout, separate text profile completion/edit, account-keyed route cleanup.
- Chats/People/Profile; loaded-chat search/All/Unread and paginated user search/public profiles.
- Unique direct creation, paginated text history, reply/copy/sender edit/delete, retry preserving client ID.
- Visible foreground read handling, canonical read status, typing and transport lifecycle hooks.
- Friendly errors, bounded REST requests, scrollable headers, message direction and scaled/landscape widget checks.
- Real two-client REST/Socket.IO recovery, privacy/idempotency, pagination, refresh/logout integration.

PR #18 code HEAD `b4a31c6c7c17e7f12062c83261d700d94d8cc60d` passed Mobile CI #19. These checks do not establish completion of the visual/native checklist below.

## Global identity

- [ ] Preserve warm off-white/cream, blush surfaces, charcoal text and pink accents; recheck actual contrast.
- [ ] Keep surfaces/buttons/inputs/bubbles softly rounded, with restrained shadows and coherent spacing.
- [ ] Integrate selective object/environment artwork: clouds, paper planes, windows, plants, books, landscapes or abstract architecture.
- [ ] Avoid detailed decorative human faces, romantic imagery, matches/swipes/hearts as product language.
- [ ] Keep artwork separate from functional controls/content; it must not obscure text or intercept taps.
- [ ] Choose and validate the final rounded friendly font on English, Arabic, mixed text and long history. PR #19 bundles Quicksand/Nunito/Tajawal; full native typography acceptance remains pending.
- [ ] Review light/dark as separate designs and avoid color-only status communication.
- [ ] Replace remaining default navigation treatment with the approved integrated rounded treatment, retaining Chats/People/Profile and platform usability.
- [ ] Preserve real behavior while polishing; no fake presence, media, settings, pinned section or unsupported controls.

## Screen reviews

### Chats

- [ ] Soft decorative header reflects approved identity while leaving room for the list.
- [ ] Search and All/Unread controls have consistent rounded styling and clear selected state.
- [ ] Conversation rows clearly prioritize avatar/name, one-line preview, quiet time and unread count.
- [ ] New-chat action leads to People; no extra Files/Groups tabs or pinning without scope approval.
- [ ] Content/empty/no-results/loading/error/offline states reviewed on device, including loaded-window search wording and load-more when filtered empty.
- [ ] Final rounded bottom navigation and preserved tab/scroll behavior reviewed.

Current implementation: PR #19 adds bundled rounded fonts, separate cloud/plane/leaf artwork, illustrated fallback plus initial badge, native rounded rows/forms/bubbles and custom navigation. The user approved the complete Chats concept; the user subsequently accepted the native pastel direction. Custom glyphs/motion and a dedicated New conversation chooser are now implemented; comprehensive native acceptance remains pending. Implementation alone does not tick visual acceptance boxes.

### Conversation and composer

- [ ] Header back/avatar/name/profile navigation and one clear typing representation reviewed.
- [ ] Quiet warm history backdrop, distinct rounded own/received surfaces and readable message widths.
- [ ] Consecutive-message grouping, date separators and an unread boundary where useful; date separators exist, grouping/unread treatment still require review.
- [ ] Sending/sent/read/failed/retry/edited/deleted states remain legible in both themes and at larger text sizes.
- [ ] Reply preview is subordinate to new content; cancel/reply to deleted/unloaded messages behave clearly.
- [ ] Edit mode is explicitly labelled; cancel/save and deletion while editing remain clear.
- [ ] Consistent contextual actions for reply/copy/own edit/delete; destructive confirmation styling reviewed.
- [ ] Composer multiline limit, send enablement, draft context and keyboard/safe areas verified on iPhone.
- [ ] Latest messages remain at bottom; older pages preserve a usable reading position on native scrolling.
- [ ] Read state advances only for relevant visible incoming content on a current foreground route.
- [ ] No durable delivered-to-device or public online/last-seen status is implied.

### People and public profile

- [ ] Search by name/username, useful no-results/loading/error states and stale-query handling reviewed.
- [ ] Avatar/name/username/bio/Message hierarchy matches the design language.
- [ ] Existing direct conversation reopens naturally; Message loading/failure is clear.
- [ ] Private email is absent from public identity.

### Auth and profile completion/edit

- [ ] Warm decorative first impression, readable headline/form and one clear primary action.
- [ ] Email/password autofill, visibility, keyboard traversal and inline errors reviewed on device.
- [ ] Loading preserves layout; errors preserve entered values.
- [ ] Credentials and profile completion stay separate; display name/username/bio validation is clear.
- [ ] Final avatar/photo area is added only with the scoped media implementation; initials remain valid fallback.
- [ ] Own profile/Edit/Sign out reviewed; logout removes prior-account routes and data.
- [ ] Only working appearance/notification/account settings appear. Appearance System/Light/Dark choice is planned; a full settings screen is not implemented in this slice.

## Native accessibility and behavior

- [ ] Record terminal build success, app launch, simulator model/OS and verified commit/local platform diff.
- [ ] Small/common/large phone layouts and landscape; tablet review follows the stable phone composition.
- [ ] Large text, readable metadata, contrast, approximately 48dp touch targets and semantic labels.
- [ ] Arabic/English/mixed messages and emoji; distinguish message-direction support from full Arabic UI localization.
- [ ] Keyboard appearance, return actions, composer expansion and bottom safe area.
- [x] Account persistence across process termination/relaunch using production secure-storage composition on iPhone 16e/iOS 26.2 (2026-10-01); physical-device acceptance remains pending.
- [ ] Two-account native flow: discover → profile → Message → send/reply/edit/delete/read/typing.
- [ ] Foreground/background, disconnect/reconnect and refresh expiry recover through the existing repositories.
- [ ] Short purposeful motion respects reduced-motion preferences where supported.

## Pending initial-release surfaces (separate implementation checkpoints)

- [ ] Profile photo and image message contracts/storage, camera/library selection, preview/caption, upload feedback/failure/retry and larger image viewer.
- [ ] Push notification delivery, real supported settings and correct conversation routing after app/session restore.
- [ ] Supported appearance settings and final production navigation/release flow.

Voice notes/reactions/presence/pinning need a later scope decision. Groups/calls/stories remain outside the initial release. Durable offline cache/outbox and distributed realtime features are deferred architecture work.

## Evidence log

| Area | Current evidence | Acceptance |
|---|---|---|
| Functional host/widget/backend integration | PR #18 code HEAD; CI #19 quality + two-account integration success | Host verified |
| Exact log counts | CI #18 inspected logs/local suite: 46 mobile passed + one ordinary live skip; 20 backend passed; one separate live integration passed | Counts scoped to recorded runs |
| Native artifact/runtime | User-built Runner.app installed/launched successfully on iPhone 16e/iOS 26.2; existing platform diff remains uncommitted | Artifact launch passed; final terminal build summary not captured |
| Native secure storage / two-device flow | One-simulator login/profile/search/direct send, Arabic realtime reception/read display and account/history restoration after process restart passed; peer was REST fixture | Targeted one-device smoke passed; two-native-client flow pending |
| Final artwork/font/navigation | PR #19 implementation/CI #22; user-approved complete Chats concept saved under docs/design/references | Native visual comparison blocked by locked Mac; not accepted as finished |

Record dated device screenshots/review decisions and targeted verification as they occur. Do not tick boxes based on expectations or build-artifact presence alone.

### PR #19 evidence update — 2026-10-01

Code `9dbf88c359d446d8b9853573cedc478243e3006c` passed Mobile CI #22 (quality + real two-account integration). Native build/launch succeeded on iPhone 16e/iOS 26.2 in 749.7s. New native screenshots/visual comparison are unavailable because the Mac is locked; the user was asked to unlock it. `design-qa.md` is explicitly blocked. Earlier native smoke remains historical PR #18 evidence, not automatic acceptance of the new appearance.

### Icons/motion checkpoint — 2026-10-02

The user requested automated verification first and consolidated simulator review. See `MOTION_DEMO_CHECKPOINT.md` for the exact implementation and evidence. Existing checks pass; no extra tests added. Twenty original glyphs, short purposeful motion, reduced-motion handling, distinct New conversation action and explicit loopback fixture are implemented. The latest status-bar correction still needs native confirmation. The final native motion/keyboard/dark/two-device boxes stay unchecked. Mac lock is a historical blocker, not the current blocker.

Additional entry-experience backlog, explicitly clarified with the user:

- [ ] Final branded logo and launcher icon.
- [ ] Native Mingle splash with no arbitrary startup delay.
- [ ] First-run onboarding/skip and persisted completion, followed by existing authentication and profile setup.
- [ ] Password recovery requires backend contract; Google/Apple providers are not currently implemented or silently added to scope.
