# Logo geometry and entry visual polish

Date: 2026-10-02. Branch: `fix/mobile-entry-visual-polish`, based on actual PR #22 HEAD `d89dd9e869f180d42cd9fa60ddee19c194199b2d`. Baseline Mobile CI #29 completed/success (run 37009976819). Draft [PR #23](https://github.com/Husseinabozina/chat_app/pull/23), implementation `776e9c1d88ad00c811e2f62a7fb224b87edfedb7`. Final exact-head checks are recorded in PR metadata.

## Logo repair and lessons

The user identified dark incursions at the plane's upper-left junction and lower tip, plus waviness on the traced edges. The earlier trace placed a dark silhouette underneath independently smoothed light regions. Independent boundaries could retreat, exposing that dark base; a high silhouette IoU did not detect internal color errors. Many small quadratic segments also retained pixel-scale bumps.

The supplied ZCode scripts used complementary dark/light color regions and Potrace cubic fitting. This approach improved edges and junctions, but combined the pale and deeper pink folds. This checkpoint adopts the complementary regions and curve fitting while retaining a separate pink fold and the existing six gradient stops. The pale region extends under the pink fold, which is clipped to the pale outline in both SVG and Flutter. SVG IDs are unique, including gradient IDs distinct from path IDs.

- Added development-only `scripts/trace-mingle-logo.py`: defaults resolve from the repository; accepts source/output arguments; temporary masks never enter Git. It targets this preserved four-region Mingle reference, not arbitrary PNG images.
- Trace dependencies: Python with Pillow/NumPy and Potrace 1.16 in PATH. Current parameters are alpha >128, nearest RGB L1 palette regions, turd size 30, coordinate unit 10, default corner threshold 1 and optimization tolerance 0.2. Regenerate the SVG, run the existing brand exporter (Node with sharp 0.35.4), then format generated Dart.
- Exporter now supports absolute line/cubic commands as well as the earlier move/quadratic/close commands. Flutter geometry is generated from that master; no raster is embedded in SVG and no app package was added.
- Regenerated in-app mark and all existing iOS/Android launcher/native-splash PNG resources. Palette overrides remain supported; installed native icons require rebuilding.

At 1254×1254 with alpha >128, source vs Sharp-rendered SVG silhouette IoU is 0.997776; nearest-palette dark/pale/pink region IoUs are 0.997187 / 0.993131 / 0.940865. These are geometry/color-region diagnostics, not a pixel-perfect or native acceptance score. At source pixels (555,636) and (640,860), previously contaminated by dark paint, the repaired render is pale pink. Pixel (700,775) remains deeper pink. Original/repaired full marks and enlarged junctions were visually inspected outside Git. Grain and antialiasing are not reproduced exactly.

## Entry UI

- Onboarding's second and third pages now show illustrative People/search and conversation cards with the actual app's custom glyphs, avatar artwork and bubble language. These examples are excluded from accessibility semantics and contain no interactive fake accounts.
- Added Previous page, disabled advancement during a programmatic transition/save, blocked swiping during save, and animated progress with reduced-motion support. Existing completion/Skip/replay persistence and account routing remain unchanged.
- Headings/body and illustration cards remain in the existing scrollable responsive layout; decorative preview subtitles can ellipsize. No new animation package or looping onboarding animation.
- Auth errors have a readable error surface and live accessibility announcement. Password visibility is disabled while submitting. Actual email/password auth and separate profile completion remain unchanged.
- Settings already provides introduction replay, persistent appearance/reduced motion, profile editing, licenses and confirmed logout. No placeholder settings or unsupported social/recovery controls were introduced.

## Verification and boundary

Host read-only format/analyzer passed. Default export and an isolated blue recolor succeeded; committed resources remain pink. Existing established CI gates verify this checkpoint. No test suite, backend source, dependency/lockfile or workflow changes. Mobile CI #30 (run 37020880336) completed/success on implementation `776e9c1d88ad00c811e2f62a7fb224b87edfedb7`: quality 65 files format clean, analyzer clean, 46 tests passed + one intentional ordinary live skip; backend gate and separate real two-account REST/realtime test passed. Final documentation HEAD/checks are recorded in PR metadata.

The user owns Flutter build/run. Use Flutter hot restart (`R`) to reinitialize generated static logo paths, then replay through Profile → Settings → Show introduction. A hot reload alone may retain the old static geometry. Native launcher/splash require a manual rebuild. No new iOS build or simulator launch was initiated. Consolidated native visual, scaled text, keyboard, dark, Android and physical/two-device acceptance remains pending. Existing local native migrations/linker fixes/Podfile.lock remain outside this PR.

## Exact next product checkpoint

Profile photo + image-message contract, storage/upload ownership and preview/retry, followed by push delivery/routing and supported notification settings. Consolidated native acceptance and cloud/release readiness remain required. General PNG-to-SVG plugin work is deferred by the user. No merge or force push.
