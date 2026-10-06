# Showcase polish — 2026-10-05

Draft PR #27, branch `feat/mobile-showcase-polish`, implementation `939e845`, base PR #26 final `497b5920cc3c152d1047bebcbdf4ec082210bb9b`.

## Changes

- A dedicated SVG launcher master: teal/cream speech bubble with a peach folded paper plane; no hearts, pairs or match motifs. iOS and Android icon sizes regenerated with the existing Sharp dependency. All in-app logos, including Settings/auth/onboarding/About and Flutter opening, now use vector geometry generated from the launcher SVG. The background color remains centrally configurable; native launch assets share the same artwork. `export-mingle-brand.cjs` exports both sources reproducibly.
- New code-native empty-conversation scene: layered message cards, flight path, folded plane and small botanical detail. One 1.8s arrival settles for recording; reduced-motion preferences show the final scene. Light/dark palettes, decorative semantics and a repaint boundary. Status panels can scroll when the keyboard/landscape reduces available height. Empty Chats and new direct conversations use the illustration and clear messaging copy.
- Separate explicit `scripts/seed-mobile-showcase.mjs`; existing demo seeder preserved. Requires loopback HTTP API, local storage and a supplied password. Dedicated reserved showcase emails and usernames; no automatic seeding during app startup. Creates 12 fictional people, 8 distinct direct conversations, 56 stable text records, one image message and 13 object-illustration avatars. Avatars are generated from original SVG with existing Sharp, uploaded through the actual private media API. Reruns reuse existing avatars and message IDs. Real timestamps/read pointers; no fabricated presence.
- Profile bios identify fictional demo accounts. This is a local presentation fixture, not real users/activity. Credentials stay outside Git.

## Verification

Host analyzer clean. Eight existing product-flow widget tests passed; local artwork-render check passed for light/dark, reduced-motion settling and short landscape layout. Rendered previews were visually inspected. Local seeding completed successfully against the actual API and private object store. No paid image generation, new app dependency, backend API/migration or workflow changes.

Native iPhone 17 Pro build/launch succeeded in 25.0s with the existing account retained. This does not imply acceptance of every screen. Exact published HEAD and CI are recorded in PR metadata and the local handoff, avoiding a self-referential commit hash. Existing iOS/macOS generated configuration changes and Podfile.lock remain excluded from the commit.

## Capture guide / remaining work

The user's existing local `@attest` account (display name `haters`) now has the same showcase content: 8 conversations, 56 texts and one image, confirmed in both REST and PostgreSQL. Its login/session is preserved. The separate showcase account from the local Arabic guide also remains available. Capture Chats, Sara's conversation (reply/image), People search for `showcase`, and Profile/Settings. Start a new direct with a person outside the eight seeded conversations to show the empty-conversation scene. A new account with no conversations shows the empty inbox. Do not delete real history to stage screenshots.

Remaining: diagnose recurring local backend hang, consolidate device acceptance including photos/keyboard/background, prepare Vercel with external Postgres/private media/shared realtime coordination, configure actual FCM/APNs/signing, Android acceptance and store preparation. Password recovery/social auth/full Arabic UI and later features remain separate scope. No merge/force push or deployment performed here.

## Existing-account follow-up — 2026-10-06

The fixture accepts `MINGLE_DEMO_VIEWER_TOKEN` for an already-authenticated local viewer and optional `MINGLE_DEMO_VIEWER_ID` to ensure the intended identity. This token is never logged or committed, and its session is not logged out by the fixture. Peer creation still requires the local fixture password; loopback-only API/storage checks and deterministic message IDs are unchanged. The account was seeded using an ephemeral token from the task-owned local backend signing configuration; no password or session records were modified. Native and Flutter launch art is exported from the same launcher SVG with rounded transparent corners. No simulator access/native build was performed for this follow-up.

## In-app identity follow-up — 2026-10-06

The Settings header was still drawing the previous pink geometry from MingleLogo. That shared painter now uses canonical launcher paths, including the cream bubble, message lines, peach plane, folded shading and rounded teal background. Auth, onboarding, About and Flutter opening all reuse it; the runtime background override remains supported. The export script generates Dart paths plus the rounded mark SVG/PNG and all native outputs from one source. No simulator or native build was used. Previous account/splash follow-up 3e7ee3c passed both jobs in Mobile CI37374286592; latest final HEAD evidence remains in PR metadata.
