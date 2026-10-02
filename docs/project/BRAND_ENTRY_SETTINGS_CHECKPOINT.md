# Mingle brand, entry experience and settings

Date: 2026-10-02. Branch: `feat/mobile-brand-entry-settings`, based on actual PR #20 HEAD `a757c75da81c550b09e377af69f86a33a6e0556d`. The user explicitly deferred the previous consolidated native visual review and authorized completing logo/splash/onboarding/settings without further questions.

## Implemented

- Original monochrome paper-plane/chat-bubble vector master: `apps/mobile/assets/brand/mingle-mark.svg`. It extends the current rounded icon vocabulary. No romantic motifs. No completed image-generation result was available after the permissions interruption; the final implementation is an editable vector, as required by the subsequent recoloring request.
- Transparent PNG export is tinted at runtime, not baked to one brand color. `MingleBrandPalette` is a theme extension; `BackendChatApp(logoColor: ...)` changes every default logo independently of controls. `MingleLogo(color: ...)` supports an individual override. Default follows the light/dark accent. The wordmark stays live rounded text.
- iOS/Android launcher PNGs exported from the same source. iOS required sizes and opaque alpha policy validated. Launcher colors are build assets: changing them needs regeneration/rebuild, not merely changing the runtime theme. App display name is Mingle on both platforms.
- Native iOS LaunchScreen and Android launch resources, including Android 12+, show the mark on warm system light/dark backgrounds. Native startup follows OS appearance; stored in-app appearance is applied after preference loading. Flutter initialization shows the branded splash for real loading only, with no artificial delay.
- Three scrollable first-run onboarding pages, swipe/Continue, progress semantics, Skip and Get started. Completing/skipping persists. Established authenticated sessions continue directly; introduction can be replayed from Settings without resetting first-run completion.
- Settings under Profile: System/Light/Dark, Reduce motion, Edit profile, Show introduction, About/licenses, confirmed Sign out. Options honor real app behavior. System reduction and user reduction are combined with OR; an in-app setting cannot turn off the OS accessibility preference. Theme animation also stops with the user reduction setting.
- Device preferences are injected behind a store port. Production reuses the existing secure-storage dependency with a separate versioned key; auth logout deletes only the session key. Serialized writes commit the state only after successful storage; errors remain visible and later writes can retry. Theme/onboarding/motion survive logout. Corrupt or unknown preference documents fall back to defaults.
- Auth credentials/profile completion and durable backend contracts stay unchanged. No new dependencies, fake notification/privacy/language/social-login controls or backend endpoints.

## Brand export

Tool: Node with `sharp` 0.35.4 available in its module path. Exports are committed; this development tool never runs in app startup or CI.

```sh
NODE_PATH=/path/to/node_modules node scripts/export-mingle-brand.cjs '#CA326E' '#FFF8F5'
```

Arguments are mark/background `#RRGGBB` colors. The SVG master uses `currentColor`. Export script updates the transparent app mask, native splash densities, and existing launcher slots. Native background resource colors are separate light/dark tokens; adjust them explicitly if changing the overall splash palette.

## Verification

- Existing suite: 46 passed + one intentional ordinary live skip; analyzer clean. The existing account flow now traverses all onboarding pages, registration/profile setup, Settings appearance/reduction, preference reload, and logout navigation. Original message/security assertions remain intact; no new test suite added.
- Formatting, asset alpha/sizes, XML parsing and plist checks passed.
- Local iOS simulator debug build succeeded in 42.8s using the preserved local automatic platform migration files. This build verifies native resources and the entry/settings implementation before the final small central-logo-color API addition; latest Dart code is covered by host checks/CI. It is not native visual acceptance.
- Android SDK is absent locally; Android XML/resources were checked, but no Android native build or runtime acceptance is claimed.
- Existing native migration/Podfile.lock changes remain local. Only the intended iOS display-name edit is staged from the already-dirty Info.plist; migration edits are excluded.
- Draft PR [#21](https://github.com/Husseinabozina/chat_app/pull/21). Implementation `45d227930809c876c85d810e0b5070ca225bd562`: [Mobile CI #26](https://github.com/Husseinabozina/chat_app/actions/runs/36994453820) completed/success; quality and complete backend/two-account integration passed. Final documentation HEAD/checks are in PR metadata. Existing workflows remain read-only/reproducible and unchanged.

## Remaining

Native visual review is deferred at the user's request; this does not establish visual acceptance. Full keyboard/Reduce Motion/dark/two-device/physical checks remain pending. Settings notification/privacy/language/account deletion require implemented contracts/localization before controls can be added.

Next product checkpoint: profile/image-message media contracts and implementation, then push delivery/routing and supported settings. Voice/files/presence/reactions need scope decisions. Groups/calls/matching remain outside the initial scope. No merge or force push.

## Latest native implementation evidence

The final implementation (including central logo recoloring API) compiled/installed/launched on iPhone 16e/iOS 26.2 in a 23.2s native build. The simulator was initially shut down, so first discovery found no device; booting only the existing task-owned 16e resolved that. No other project simulator was touched. API/PostgreSQL local fixture services were restarted after the earlier permissions transition; separate live integration passed. The running app was not visually exercised/captured, respecting the user's explicit deferral.

Proposed merge order: #15 → #16 → #17 → #18 → #19 → #20 → #21, after review/authorization. No merge or force push performed.
