# AGENTS.md

This file provides guidance when working in this repository.

The project is licensed under AGPL-3.0. Do not relicense it, and do not describe closed-source forks as allowed.

## Repository Rules

- Do not put internal instructions, agent notes, TODO process text, or hidden implementation guidance into any user-facing UI, website copy, App Store copy, screenshots, or localized strings.
- When the work can be split cleanly, use independent subagents for non-overlapping read-only research or disjoint file scopes, then integrate and verify in the main thread.
- Treat the worktree as shared. Check `git status --short` before edits, do not revert user changes, and keep staging/commits narrowly scoped when asked to commit.
- Public UI text must be concise, user-facing, and localized through `L10n` / `Localizable.xcstrings`. Avoid leaking raw technical failures unless they are only for diagnostics.
- The app is personal-use only and is not distributed on the App Store. There is no StoreKit IAP, no paywall, and no in-app feedback channel; all features are always unlocked.

## Project Overview

PhotoDelete is an iOS 16+ SwiftUI app for organizing and cleaning a real Photos library. The app uses swipe gestures, a safe candidate library, batch confirmation, album management, local cleanup history, advanced statistics, and cleanup queues. All features are free and always unlocked; there is no StoreKit purchase flow.

Privacy positioning is part of the product: no account is required, photos are processed on-device, and the app does not upload photos, videos, library contents, or cleanup decisions.

## Development Commands

### Open In Xcode

```bash
cd IOSAPP
open PhotoDelete.xcodeproj
```

Build and run through Xcode. Use a simulator for quick UI work and a real iPhone for Photos framework, iCloud Photos, limited library, deletion, favorite, and album write validation.

### Build From CLI

```bash
SIMULATOR_DESTINATION="$(scripts/resolve-ios-simulator-destination.sh)"
xcodebuild -project IOSAPP/PhotoDelete.xcodeproj -scheme PhotoDelete \
  -destination "$SIMULATOR_DESTINATION" \
  -derivedDataPath IOSAPP/DerivedData \
  clean build
```

### CI-Style Unit Test Flow

```bash
SIMULATOR_DESTINATION="$(scripts/resolve-ios-simulator-destination.sh)"
xcodebuild build-for-testing \
  -project IOSAPP/PhotoDelete.xcodeproj \
  -scheme PhotoDelete \
  -destination "$SIMULATOR_DESTINATION" \
  -derivedDataPath IOSAPP/DerivedData \
  CODE_SIGNING_ALLOWED=NO

xcodebuild test-without-building \
  -project IOSAPP/PhotoDelete.xcodeproj \
  -scheme PhotoDelete \
  -destination "$SIMULATOR_DESTINATION" \
  -derivedDataPath IOSAPP/DerivedData \
  -only-testing:PhotoDeleteTests \
  CODE_SIGNING_ALLOWED=NO
```

The GitHub Actions workflow in `.github/workflows/ios-ci.yml` follows this pattern on `macos-15` with Xcode 16.4.

### Full Simulator Test

```bash
SIMULATOR_DESTINATION="$(scripts/resolve-ios-simulator-destination.sh)"
xcodebuild test \
  -project IOSAPP/PhotoDelete.xcodeproj \
  -scheme PhotoDelete \
  -destination "$SIMULATOR_DESTINATION" \
  -derivedDataPath IOSAPP/DerivedData
```

UI tests are smoke tests. They do not replace real-device Photos validation.

### Cleanup

```bash
rm -rf IOSAPP/DerivedData
xcodebuild clean -project IOSAPP/PhotoDelete.xcodeproj -scheme PhotoDelete
```

### TestFlight Release

- TestFlight build numbers must use UTC+8 time in `yyyyMMddHHmm` format, matching Beijing/Shanghai local time. Do not generate release build numbers from UTC time.
- Before uploading, make sure the new `CFBundleVersion` is numerically greater than the highest build already visible in App Store Connect/TestFlight; otherwise testers may not receive it as an update even if the upload succeeds.
- Do not manually bump `MARKETING_VERSION` for every TestFlight upload. Reuse the current version while the pre-release train accepts new builds; if App Store Connect rejects the upload because the train is closed or `CFBundleShortVersionString` must be higher than the approved version, let `scripts/release-testflight.sh` auto-increment the last marketing-version component once, write it back to the Xcode project, and retry with a fresh UTC+8 build number.
- The release script accepts an explicit override:

```bash
BUILD_NUMBER=202606111630 scripts/release-testflight.sh
```

`scripts/release-testflight.sh` runs tests unless `SKIP_TESTS=1`, checks that App Icon PNGs do not contain alpha channels, archives, exports, uploads to App Store Connect/TestFlight, and handles one automatic marketing-version retry when Apple closes the current train.

## Architecture

### App Shell

- `PhotoDeleteApp.swift`: App entry point, UI-test defaults, gesture preference migration, selected app language, and selected appearance.
- `ContentView.swift`: Root view hosting the main tab interface (no onboarding flow).
- `MainTabView.swift`: Two tabs: Organize, Albums.

### Core Data And Services

- `Models.swift`: Photo categories, gesture actions/presets, review modes, album models, app appearance, and advanced cleanup models.
- `DataManager.swift`: Central observable state, candidate libraries, reviewed asset IDs, album lists, batch operations, advanced summaries, and cleanup statistics coordination.
- `PhotoLibraryManager.swift`: Photos authorization, paged photo loading, classification into videos/screenshots/live photos/favorites, image/video requests, caching, write operations, and `PHPhotoLibraryChangeObserver`.
- `LibrarySnapshotStore.swift`: Local JSON snapshots for photo-library and album-list IDs to speed up reloads.
- `CleanupStatsStore.swift`: Local cleanup-session history, monthly summaries, streaks, and persisted cleanup totals.
- `CleanupAchievements.swift`: Achievement definitions, progress, newly unlocked milestone evaluation.
- `AppLanguage.swift`, `Localization.swift`, `Localizable.xcstrings`: Runtime language selection for system, `zh-Hans`, `zh-Hant`, and `en`.
- `DesignSystem.swift`: Shared colors, layout constants, app constants, haptics, toasts, buttons, and permission cards.

### User Interface

- `HomeView.swift`: Main library entry points, categories, permission cards, progress indicators, and the efficient-cleanup queue section at the bottom.
- `SwipePhotoView.swift`: Core review UI. Contains card mode, two-row browser mode, gesture handling, local undo, album quick filing, `RealPhotoCard`, video/photo preview helpers, `BatchConfirmView`, and completion celebration.
- `AlbumsView.swift`: User album listing, album order, create, rename, delete, and album detail flows. Do not imply that deleting an album deletes the photos inside it.
- `AdvancedView.swift`: Efficient-cleanup queue detail screens for similar photos, large files, screenshots, videos, and image/video compression. Reached from the cleanup queue section in `HomeView.swift`.
- `CleanupAchievementsView.swift`: Achievement list and progress display.
- `CleanupHistorySections.swift`: Monthly summaries and cleanup history sections shown from the achievements screen.
- `GestureSettingsView.swift`: Gesture presets, review sort order, media playback, and haptics preferences. Opened from the review session in `SwipePhotoView.swift`.

### Website And Marketing

- `site/`: Static website and privacy policy. Deploys to Cloudflare Pages through `.github/workflows/deploy-site.yml`.
- `Marketing/PhotoDeleteCampaign/`: App Store screenshots, actual iOS screenshots, promo copy, and screenshot generation assets.
- `Marketing/PhotoDeleteCampaign/actual-ios-screenshots-v4/`: Preferred source for current real-app UI screenshots. Do not use older concept art as primary UI evidence when real screenshots are needed.

## Photo Management Workflow

- Default gestures: left = delete candidate, right = keep, up = favorite candidate, down = skip.
- Left/right/up are user-configurable through gesture presets; down remains a skip/keep gesture.
- Swipe actions mark assets as reviewed locally and move to the next unreviewed photo.
- Deletions and favorites are staged in `deleteCandidates` and `favoriteCandidates`.
- Nothing is deleted immediately. `BatchConfirmView` shows pending assets and calls `DataManager.executeBatchOperations()`.
- On success, `PhotoLibraryManager` commits Photos changes, `DataManager` applies local incremental updates, `CleanupStatsStore` records a session, and achievement progress is recalculated.
- Undo restores the previous asset position and reviewed/candidate state for the last local action.

## Photos Framework Notes

- Required permissions live in `IOSAPP/Config/PhotoDelete-Info.plist`:
  - `NSPhotoLibraryUsageDescription`
  - `NSPhotoLibraryAddUsageDescription`
  - `PHPhotoLibraryPreventAutomaticLimitedAccessAlert`
- Authorization access states:
  - `.notDetermined`: request only when the user starts photo work
  - `.authorized`: full access
  - `.limited`: supported, with a manage-limited-library path
  - `.denied` / `.restricted`: send the user to Settings
- Simulator testing can import seed photos, but real device testing is required for iCloud Photos, limited library picker behavior, real deletion prompts, favorites, large libraries, and performance.
- Screenshot detection uses Photos smart albums plus device/screen-size heuristics. Avoid claiming ML duplicate detection unless the implementation actually does it.

## Testing Strategy

- Add or update unit tests in `IOSAPP/PhotoDeleteTests/` for model logic, stats, achievements, localization gates, snapshots, and pure data behavior.
- Add UI smoke coverage in `IOSAPP/PhotoDeleteUITests/` for navigation surfaces that do not depend on a seeded real library.
- Use a physical iPhone for end-to-end Photos write paths: permission prompt, limited access, delete confirmation, favorite write, album write, iCloud optimized storage, large libraries, and recovery after app backgrounding.
- For App Store screenshot work, prefer a seeded simulator plus the real iOS app, then store outputs under `Marketing/PhotoDeleteCampaign/actual-ios-screenshots-*` or `appstore-upload/`.

## Development Guidelines

- Prefer existing SwiftUI patterns and shared UI from `DesignSystem.swift`.
- For native SwiftUI UI, navigation, accessibility, and iOS 26 Liquid Glass rules, use `IOSAPP/UI_GUIDELINES.md` as the source of truth.
- Keep photo-library mutations behind `DataManager` and `PhotoLibraryManager`; do not write Photos changes directly from random views.
- Keep user-visible strings localized. If adding text, update `Localizable.xcstrings` for Simplified Chinese, Traditional Chinese, and English.
- Keep local persistence small and transparent: UserDefaults for preferences/reviewed IDs, Application Support JSON for snapshots and cleanup history.
- Do not add analytics, tracking SDKs, or network photo upload paths without explicit product approval and privacy-policy updates.

## AI Execution Style

- Default to autonomous execution: read the code, configs, and README first, then decide by repository convention. Do not interrupt for minor uncertainty, and do not ask "should I continue".
- Only interrupt to ask when: deleting or overwriting user data, missing required credentials or external IDs, a change alters architecture boundaries or public APIs, or ambiguity blocks safe delivery.
- Prefer the smallest, lowest-risk, easiest-to-revert change. Report results, key assumptions, and verification outcomes after finishing instead of narrating process questions.
- When a context-compaction boundary is near, first write a handoff note under `docs/kimi/` capturing the current goal, completed items, pending items, key files, key assumptions, unverified risks, and the next action.
- An explicit commit/push instruction (e.g. "commit", "push") is full authorization: classify the worktree changes, commit them by logical group, and push. Only interrupt when unsure whether a change belongs in a commit or when a push has conflicts.

## Minimal Intrusion And Long-Term Design

- Default to minimal diffs: local edits over rewrites, thin layers over refactors, reuse over new abstractions. Do not widen file scope, responsibility boundaries, or call chains without an explicit request.
- Keep fixes, features, and refactors in separate commits; no ride-along "while I'm here" optimizations.
- Design for the person reading this in three months: naming, layering, and dependency direction must stay human-readable.
- Short-term hacks (patch-style special cases, one-off scripts in the main tree) are banned by default; genuine exceptions follow the Exceptions section below.
- Minimal intrusion does not mean short-sighted: even local changes must land inside the correct responsibility boundary.

## Code Constraints

These limits apply to new code and to code being modified. Do not mass-refactor existing files that predate them; when touching an over-limit file, prefer splitting the part you changed.

- Function/method body: `<= 20` lines. SwiftUI view `body`: `<= 15` lines.
- Type (class/struct/enum): `<= 100` lines. Single file: `<= 200` lines; split by responsibility beyond that.
- Function parameters: `<= 4`; wrap excess into a parameter struct.
- Branches (`if / else / switch / case`) per function: `<= 3`. Nesting depth: `<= 2`. Consecutive `&& / ||` in one condition: `<= 2`.
- No nested ternary expressions. Prefer early returns over stacked `else` success paths.
- One file, one responsibility; keep state, UI, data conversion, and business rules separate. Split large SwiftUI views into child views or separate files instead of piling UI into one `body`.

## Naming Rules

- Function names use `verb + noun`.
- Boolean variables and functions use state words or adjectives; avoid `is / has / can / should` prefixes in new code.
- Extract complex conditions into named local variables before branching.
- No weak names like `flag`, `temp`, `check1`.
- File names follow Swift convention: PascalCase matching the primary type in the file.

## Modern Swift Usage

- Use modern Swift and Swift concurrency (`async/await`); do not spread nested completion-handler pyramids in new code.
- Do not add or spread deprecated APIs; follow `IOSAPP/UI_GUIDELINES.md` for current SwiftUI, navigation, and iOS 26 idioms.

## Git Workflow

- After each distinct code change, make a git commit by default, following the `git-commit` skill's process rather than ad hoc hand-written messages.
- On an explicit commit instruction, classify all worktree changes first: one commit per logical change; unrelated groups get separate commits. Do not mix unrelated files into one commit.
- Commit messages must accurately describe the change and keep history clean. After committing, `git push` to the current remote branch; the commit instruction itself includes push authorization.
- If push fails, conflicts, or authentication fails, report the reason immediately; never claim a push succeeded when it did not.

## Exceptions

- Local over-limit code is allowed only for: algorithm implementations, fixed-format third-party SDK callbacks, and long static mapping tables.
- Every exception must carry a `// REASON: ...` comment stating why it exists and when it can be cleaned up. Exceptions relax only the necessary lines, never a whole file.

## Pre-Output Self-Check

- Function, type, file, and `body` line limits respected; branch, nesting, and operator budgets respected; early returns used where possible.
- Boolean naming compliant; no deprecated API introduced.
- Could this be split into a clearer child view, file, or single-responsibility unit?

## Documentation Rules

- Kimi-generated documents (notes, summaries, plans, reports) must be stored under `docs/kimi/`; do not write them into the `docs/` root or other documentation directories. Create `docs/kimi/` on first use.

## Post-Launch Stability

The app is no longer distributed; it runs as a personal build. The rules below still protect the local install from data loss.

- **Zero user-data loss**: changes to persisted formats (UserDefaults keys, `LibrarySnapshotStore` JSON, `CleanupStatsStore` history) must migrate or stay backward compatible; wipe-and-rebuild of persisted state is banned. Migrations need old-to-new path tests.
- **External contracts are breaking changes**: UserDefaults key names, `Localizable.xcstrings` keys, and bundle/App Group identifiers. Renames or semantic changes require stating the blast radius and getting explicit instruction first.
- **Change grading**: bug fixes use the smallest possible diff with no ride-along refactors. Dependency upgrades and architecture changes require an approved plan before implementation.
- **Commit gate**: before committing, the project must build and affected tests must pass using the CI-style commands above.

## Debugging References

- `IOSAPP/DEBUGGING_GUIDE.md`: Photos setup, simulator vs real device notes, permission and performance debugging.
- `IOSAPP/Config/PhotoDelete-Info.plist`: Source of truth for photo-library permission usage descriptions.
- `RELEASE_CHECKLIST.md`: App Store/TestFlight readiness checklist.
