# Mingle icons, motion and local demo checkpoint

Updated: 2026-10-02. Branch: `feat/mobile-motion-demo`, based on actual PR #19 HEAD `abe502695e6f32512800e30c7ab09b4ec7e0a41a`. Draft PR [#20](https://github.com/Husseinabozina/chat_app/pull/20). Implementation commit: `313b800f0dd90128b5d92a7725552d5e61266802`.

## User direction

The user accepted the native pastel direction, requested original friendly icons instead of Material icons, identified the duplicate bottom-navigation plus action, and requested more sample people/conversations. Motion should make Mingle distinctive while remaining calm and appropriate to a messenger. No dating/match/heart effects. On 2026-10-02 the user requested code/automated verification first, with visual simulator review consolidated instead of repeatedly interrupting implementation.

## Implementation

- `mingle_icons.dart`: 20 original rounded vector glyphs, with directional mirroring for RTL. Existing buttons retain their labels, tooltips and touch targets. Decorative glyphs are excluded from semantics. This is a user-authorized custom icon system, not copied Material glyphs.
- `mingle_motion.dart`: 110ms press feedback, 180ms tab/arrival transitions, 220ms selected-icon changes, 140ms actual sent/read transitions, real typing dots. iOS routes retain Cupertino transitions/back gesture; other platforms use a quiet fade. Controllers are disposed and inactive tab tickers are muted.
- Reduce Motion/accessibility navigation bypasses motion. These preferences are handled in code; native acceptance of every setting remains separate.
- Only genuinely newer messages after initial history loading opt into entrance motion. Historical pagination does not animate. Client IDs are scoped by sender, and pending/persisted acknowledgments avoid duplicate entrances. Newer messages recovered after reconnect can also enter; there is no fake incoming traffic.
- One 900ms paper-plane/chat-bubble scene is explicitly limited to empty, unfiltered Chats with no failure. It settles once per mount. Search/no-results and Retry panels remain static. This is not an animated chat wallpaper or a completed splash screen.
- Flutter-native motion; no Lottie dependency, asset download, generated image or pubspec/lockfile change.
- Three bottom tabs remain Chats/People/Profile. The duplicate central plus is removed. New conversation inside Chats opens a dedicated person chooser and starts/reuses the direct conversation. People remains discovery/public-profile navigation.
- Headerless screens and AppBars now specify matching light/dark status-bar foreground style. A low-contrast native status bar was observed before this fix; final native verification of the correction is pending.
- No backend/schema/command/repository changes. Durable REST authority, idempotency, read visibility and transient typing contracts remain unchanged.

## Explicit local fixture

`scripts/seed-mobile-demo.mjs` runs only when invoked manually against HTTP loopback. It rejects remote origins, URL credentials and redirects, requires an environment-supplied disposable password and reserved `@example.test` viewer email, and never runs in startup or CI.

With a running migrated backend:

```sh
export CHAT_API_BASE_URL=http://127.0.0.1:55418
export MINGLE_DEMO_EMAIL=iphone.demo@example.test
# Set MINGLE_DEMO_PASSWORD in your shell to the disposable local account password.
node scripts/seed-mobile-demo.mjs
```

Use Node 24. Existing matching accounts must use the same password; the script does not reset credentials. Credentials/tokens are never printed or committed. Sessions created by the fixture are logged out afterward; errors still fail the run.

The fixture creates/reuses 12 fictional Arabic/English profiles, eight direct conversations and 94 stable seed messages, including replies and real read pointers. Search People for `demo`. The first conversation contains enough history for pagination. Timestamps/receipts are actual API records, not backdated or fabricated presence. Stable message IDs/conversation identity make reruns reusable; existing monotonic read positions are preserved. User-added messages may increase database totals above 94.

## Verification boundary

- Existing suite: 46 passed, one intentional ordinary live skip. Separate real REST/Socket.IO two-account integration: one passed. No tests added or weakened.
- Read-only formatter and analyzer passed; seeder syntax/Prettier checks passed. Fixture rerun succeeded without recreating conversations or seed identities.
- Two earlier native builds/launches during this checkpoint succeeded (32.4s and 63.9s). A populated light Chats capture exists outside the repo at workspace `output/motion-ui/chats.png`. The screenshot precedes the final explicit empty-state/status-bar fixes.
- Latest hot-reload attempt reported a lost device connection. That does not validate the latest native rendering. Do not infer native acceptance from CI or old screenshots.
- Final full native motion/Reduce Motion/dark/keyboard review, physical-device and two-native-client checks remain pending. Keep this PR Draft while visual acceptance remains incomplete; `design-qa.md` records the boundary.
- Existing automatic iOS/macOS build migration changes and local Podfile.lock are preserved locally, excluded from this checkpoint.

## Next checkpoint

Finish one consolidated native acceptance pass for this checkpoint. Then design/implement branded logo/app icon, native splash and first-run onboarding above the verified stack. Email/password authentication and separate text profile setup already work. Password recovery/social authentication require explicit backend contracts and remain pending; do not add decorative buttons for unsupported providers.

Image/profile media, push delivery/routing, supported appearance settings and release readiness remain initial-release work. Voice notes/files/presence/reactions need scope/contract decisions; groups/calls/stories/matching remain outside initial scope.

## Published verification

[Mobile CI #24](https://github.com/Husseinabozina/chat_app/actions/runs/36984743287) passed on exact implementation commit `313b800f0dd90128b5d92a7725552d5e61266802`. Both quality job `110767080025` and real integration job `110767446164` completed/success; backend fixture format/lint/typecheck/build/migrations/tests and the final two-account mobile integration all passed. Subsequent documentation-only HEAD/checks are recorded in PR metadata.

No merge or force push. Proposed order remains #15 → #16 → #17 → #18 → #19 → #20 after review/authorization. PR #5/#8 were already closed as superseded by the other conversation; this checkpoint did not change them.
