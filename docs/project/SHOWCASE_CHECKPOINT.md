# Showcase polish — 2026-10-05

Draft PR #27, branch `feat/mobile-showcase-polish`, implementation `939e845`, base PR #26 final `497b5920cc3c152d1047bebcbdf4ec082210bb9b`.

## Changes

- A dedicated SVG launcher master: teal/cream speech bubble with a peach folded paper plane; no hearts, pairs or match motifs. iOS and Android icon sizes regenerated with the existing Sharp dependency. The approved in-app/splash logo stays independently editable. `export-mingle-brand.cjs` exports both sources reproducibly.
- New code-native empty-conversation scene: layered message cards, flight path, folded plane and small botanical detail. One 1.8s arrival settles for recording; reduced-motion preferences show the final scene. Light/dark palettes, decorative semantics and a repaint boundary. Status panels can scroll when the keyboard/landscape reduces available height. Empty Chats and new direct conversations use the illustration and clear messaging copy.
- Separate explicit `scripts/seed-mobile-showcase.mjs`; existing demo seeder preserved. Requires loopback HTTP API, local storage and a supplied password. Dedicated reserved showcase emails and usernames; no automatic seeding during app startup. Creates 12 fictional people, 8 distinct direct conversations, 56 stable text records, one image message and 13 object-illustration avatars. Avatars are generated from original SVG with existing Sharp, uploaded through the actual private media API. Reruns reuse existing avatars and message IDs. Real timestamps/read pointers; no fabricated presence.
- Profile bios identify fictional demo accounts. This is a local presentation fixture, not real users/activity. Credentials stay outside Git.

## Verification

Host analyzer clean. Eight existing product-flow widget tests passed; local artwork-render check passed for light/dark, reduced-motion settling and short landscape layout. Rendered previews were visually inspected. Local seeding completed successfully against the actual API and private object store. No paid image generation, new app dependency, backend API/migration or workflow changes.

Native iPhone 17 Pro build/launch succeeded in 25.0s with the existing account retained. This does not imply acceptance of every screen. Exact published HEAD and CI are recorded in PR metadata and the local handoff, avoiding a self-referential commit hash. Existing iOS/macOS generated configuration changes and Podfile.lock remain excluded from the commit.

## Capture guide / remaining work

Sign in using the dedicated showcase account from the local Arabic guide. Capture Chats, Sara's conversation (reply/image), People search for `showcase`, and Profile/Settings. Start a new direct with a person outside the eight seeded conversations to show the empty-conversation scene. A new account with no conversations shows the empty inbox. Do not delete real history to stage screenshots.

Remaining: diagnose recurring local backend hang, consolidate device acceptance including photos/keyboard/background, prepare Vercel with external Postgres/private media/shared realtime coordination, configure actual FCM/APNs/signing, Android acceptance and store preparation. Password recovery/social auth/full Arabic UI and later features remain separate scope. No merge/force push or deployment performed here.
