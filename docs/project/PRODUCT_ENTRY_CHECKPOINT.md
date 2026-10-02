# Product opening flow correction

2026-10-02. Branch `fix/mobile-product-entry`, base actual PR #23 final HEAD `1dd304b054e53b382fa98317a858ccbd8b66e60e`, freshly verified green via GitHub PR checks.

- Main entry now always composes current Mingle. Plain debug run no longer silently opens the old Firebase prototype. Debug local defaults are 127.0.0.1:55418 (iOS/macOS) and 10.0.2.2:55418 (Android emulator); physical devices override explicitly, release/profile require API configuration. Archived Firebase is explicitly selectable through main_legacy.dart. No backend technology replacement.
- Initialization shows the existing brand screen for at least 800 ms in parallel with session/preferences restoration. Longer actual initialization continues to show loading. No simulator/build started.
- Removed automatic onboarding completion on restored accounts. An unset flag leads to first-run introduction, then restored account or sign-in. Completion/Skip is persisted; normal relaunch/logout does not reset it. Already completed devices do not replay onboarding. Removed Settings replay and the replay-only widget branch, as requested. No forced logout or preference deletion.
- Consecutive messages by the same sender within five minutes/on the same local date now group through spacing and corner geometry. Replies/deleted messages separate groups. Timestamp, read state, visibility keys and read ordering remain unchanged.
- Host format/analyzer passed; existing full read-only Mobile CI verifies publication. No tests added, no workflow or dependencies modified. Existing local native migrations/linker fixes/Podfile.lock excluded.

Next product checkpoint: profile/image media with private S3-compatible storage and validated uploads, followed by push and release work. Native acceptance remains separate.
