# Pastel native UI comparison

Date: 2026-10-02. Workflow: product-design image-to-code/design-qa.

## Visual truth and scope

- User-approved Chats concept: `docs/design/references/approved-chats-preview.png`, 853 × 1844 pixels; intended portrait viewport approximately 390 × 844 logical pixels.
- Original supplied board: `docs/design/references/pastel-mingle-reference.png`, 1536 × 1024 pixels. Its component/screen direction also informs Conversation/auth/profile.
- Implementation: PR #19, code `9dbf88c359d446d8b9853573cedc478243e3006c`, Flutter 3.47.5 on iPhone 16e/iOS 26.2.
- Required state: populated direct Chats, light theme; additional Conversation/auth/profile states after the main comparison.

## Capture and comparison evidence

- Earlier native motion implementation screenshot: workspace `output/motion-ui/chats.png`, 790 × 1676 including Simulator chrome. This is a populated/light Chats capture, preceding final status-bar and explicit empty-state corrections. User accepted the native pastel direction and requested custom icons/motion. The former Mac lock is resolved.
- Native build/launch succeeded (749.7s). Runtime remained attached for hot reload/restart.
- Historical old profile screenshot: workspace `output/pastel-ui/profile-before.png`, 790 × 1676 including Simulator window/device frame. It is from PR #18's old appearance and is not the new implementation evidence.
- Density normalization: pending native capture. Normalize/crop actual app content and compare at the same logical viewport/state; do not stretch the board or confuse device chrome with application content.
- Full-view combined comparison of latest corrected implementation: pending. The user requested automated verification first and consolidated visual review; no new combined comparison is claimed here.
- Focused heading/search/rows/nav comparison of final corrected implementation: pending.

## Findings

- [P1] Native fidelity cannot yet be verified.
  Location: Chats and remaining existing screens.
  Evidence: the source concept and an earlier native capture exist, but no normalized combined comparison of the latest corrected implementation has been completed. Full motion/Reduce Motion/dark/keyboard acceptance remains outstanding.
  Impact: fonts, decoration placement, proportions and copy cannot be reviewed from a build/CI result.
  Fix: use one consolidated final native review to capture the corrected app and compare normalized full/focused regions with the source. Fix substantive findings before final visual acceptance.

## Required fidelity surfaces

- Fonts/typography: bundled rounded families implemented; actual heading character, Arabic fallback, sizes and wrapping require native comparison.
- Spacing/layout rhythm: native rows/search/navigation implemented; alignment, density, safe-area and responsive rhythm unverified visually.
- Colors/tokens: cream/blush/navy and dark variants implemented; real rendering/contrast still require visual review.
- Image quality/asset fidelity: production PNG decoration and fallback supplied separately from controls; native crop/sharpness/placement not reviewed.
- Copy/content: only scoped direct text features are present; approved concept fixture names/content and the real local account data may differ. Match states and distinguish data differences from design drift.

## Comparison history

1. User compared the old functional appearance with supplied references; missing artwork/custom typography/navigation identified.
2. Implementation introduced those elements; local/CI functional checks passed.
3. User approved the complete Chats concept after clarifying the isolated avatar's intended small placement.
4. Historical native comparison was blocked by screen lock. On 2026-10-02 the Mac was unlocked, populated Chats was captured and the user accepted the native direction.
5. Custom icons/motion/demo were implemented. A low-contrast light-mode native status bar was observed on People and explicit theme-aware overlay styles were added. Final hot reload reported lost device connection; no post-fix visual pass is claimed.
6. The user requested automated verification first, with visual review consolidated. The code/CI checkpoint can remain Draft independently of this outstanding gate.

## Implementation checklist

1. Restore the task-owned app attachment for the final consolidated native review.
2. Capture native Chats at the intended light/portrait state.
3. Normalize content regions and produce full/focused combined comparison evidence.
4. Fix P0/P1/P2 findings, recapture and compare again.
5. Review Conversation/auth/profile, then applicable dark/text-scale/keyboard states.
6. Update this file, CURRENT_STATE, acceptance checklist and PR verification. Keep PR Draft until the review is complete.

final result: blocked

## Latest implementation scope

`feat/mobile-motion-demo` preserves the approved raster artwork/rounded fonts and adds user-authorized original vector icons, reduced-motion-aware interactions, explicit empty-state plane scene, distinct New conversation chooser and loopback-only demo data. Existing automated checks are documented in `docs/project/MOTION_DEMO_CHECKPOINT.md`. These are functional/source checks, not a rendered QA pass.

Final result remains blocked by unfinished consolidated native review and post-fix status-bar evidence, not by host screen lock.
