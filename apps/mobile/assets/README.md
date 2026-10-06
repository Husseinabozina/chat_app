# Pastel UI assets

These assets support the user's 2026-10-01 request to implement the supplied Mingle reference in the existing Flutter app. They contain decoration only; text, controls, routing and message state remain native widgets.

## Artwork

- `art/pastel_frame.png`: generated production background, 1024 × 1536 RGBA. Transparent center, edge clouds, eucalyptus and a paper plane. It is rendered behind controls with IgnorePointer/ExcludeSemantics; intensity decreases in conversation history and dark mode.
- `art/landscape_avatar.png`: generated square landscape illustration, 1254 × 1254. A shared decorative fallback, not an uploaded user photo. The native initial badge and visible name distinguish people. Actual profile-photo storage remains a separate checkpoint.
- Art direction reference: `docs/design/references/pastel-mingle-reference.png`, supplied by the user. Production assets were generated with that exact reference, not from a new visual concept or full-app collage.

## Fonts

Fonts are bundled locally; no font network request or new runtime package is required.

- Quicksand 400/500/700: upstream static files from https://github.com/andrew-paglinawan/QuicksandFamily/tree/master/fonts/statics, rounded display headings.
- Nunito 400/600/700/800: static weight instances of Google Fonts' upright variable font, readable rounded body/UI text. Source https://github.com/google/fonts/tree/main/ofl/nunito.
- Tajawal 400/500/700: upstream static Google Fonts files, Arabic fallback. Source https://github.com/google/fonts/tree/main/ofl/tajawal.

Each family includes its SIL Open Font License and copyright notice. Cairo remains the report font; the app typography is a user-reviewable implementation choice for the approved rounded direction.

Icons use Flutter's bundled Material outlined/rounded set. Platform chrome, keyboards and system safe areas remain platform-owned.

## Current Mingle identity

`brand/mingle-launcher.svg` is the canonical teal/cream/peach logo. `scripts/export-mingle-brand.cjs` generates the rounded `brand/mingle-mark.svg`, runtime PNGs, Dart vector paths and iOS/Android icon/launch assets. Settings, authentication, onboarding, About and Flutter splash share MingleLogo. Pass `BackendChatApp.logoColor` to change the runtime background; export an explicit #RRGGBB color to change native resources. Re-export after geometry edits, then format the generated Dart file.
