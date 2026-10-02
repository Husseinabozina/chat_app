# Original Mingle logo fidelity repair

Date: 2026-10-02. Branch: `fix/mobile-logo-fidelity`. Base: actual PR #21 remote HEAD `49cd87c75a666f6bc174794a4a27a36474f44705`; Mobile CI #27 completed/success. New PR/CI pending publication.

## Why this changed

The user identified that the simplified monochrome vector had lost the original logo's proportions, plane folds and pink color variation. The original generated transparent PNG was recovered from this task's generated-image library and preserved in `docs/design/references/original-mingle-logo.png`. It supersedes the temporary monochrome treatment documented in PR #21.

## Implemented

- Traced the actual reference into four SVG layers: conversation contour, plane silhouette, pale main fold and lower pink fold. No raster is embedded in the vector. Small generated speckles/raster grain are cleaned; this is a faithful vector interpretation, not pixel-identical reproduction of texture.
- Three gradients/six editable stops preserve the original color relationships. A silhouette comparison at 1254×1254, alpha threshold 128, measured intersection-over-union 0.996720 (geometry evidence only; not a color or native visual acceptance score).
- `scripts/export-mingle-brand.cjs` generates `mingle_logo_paths.dart` directly from the SVG master. Runtime `MingleLogo` uses Flutter Canvas paths and shaders; it requires no SVG/image package and no runtime raster tint.
- `MingleBrandPalette` exposes separate gradient stops. Existing app-level/per-logo color overrides derive lighter fold colors automatically; default light/dark app themes both preserve the original palette. Controls retain their existing colors.
- Regenerated transparent mark, iOS/Android launcher PNG sizes and native splash images. Launcher/splash resources are build assets; runtime recoloring does not modify installed native resources.
- Exporter preserves the master palette by default, accepts optional `#RRGGBB` mark/background colors, validates expected vector layers/gradient stops and generates geometry from the master viewBox.
- Original reference and a direct comparison were visually inspected. Comparison export is outside the repository; the reference itself is committed for future design reconciliation.

No onboarding, authentication, Settings, backend contract, migration, dependency, lockfile or CI workflow behavior changes. Existing onboarding is three pages, persisted after completion/Skip; replay through Profile → Settings → Show introduction.

## Local verification

- Default export succeeded. Optional blue recolor succeeded in an isolated temporary export tree, preserving highlights/folds and leaving committed pink resources intact.
- Generated Dart formatting and analyzer clean. Exporter JavaScript syntax/formatting checked.
- No new tests added. Existing Mobile CI will run the established mobile suite and complete backend/two-account integration; results must be recorded after publication.
- No new iOS/Android build or simulator visual review for this logo. User requested to build/run manually. Previous local iOS linker recovery succeeded in 32.9s before this change; those native configuration edits remain outside this PR.

## Manual preview and next checkpoint

In the user's existing Flutter terminal, press `r` to hot reload the new in-app logo. Stop/re-run the app when checking launcher/native splash resources. Replay onboarding from Settings. Native functional/visual acceptance, Android runtime and physical/two-device behavior remain pending. After the logo checkpoint, the documented product work is profile/image-message media contracts, then push and supported notification settings.

No merge or force push. Proposed order is #15 → #16 → #17 → #18 → #19 → #20 → #21 → this logo PR, after review and explicit authorization.
