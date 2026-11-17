# Dải Đất Anh Hùng: ON HOLD (since 2026-11-17)

A mobile game about Vietnamese historical heroes for primary-school children. The first hero is Trần Quốc Toản.
Native per platform (ADR-0001): iOS in Swift + SpriteKit, Android in Kotlin + Canvas, sharing one content set.
Luan put the game **on hold** on 2026-11-17 for a new game. Everything for it lives in this folder; the repo root
belongs to the studio framework and the next game (TASK-028).

## Layout

| Folder | What |
|---|---|
| `ios/` | Xcode project `DaiDatAnhHung.xcodeproj` (app, Debug / Release / Preview), `GameCore/` Swift package (rules, tests), `Scripts/ContentGate.swift` (the R12 history gate) |
| `android/` | Gradle project (app: debug / preview / release) |
| `content/` | the shared content: `data/` (bundled), `schema/`, `samples/`, `fixtures/`, `drafts/`, `metrics/` |
| `assets/` | art (incl. the placeholder app icons) |
| `design/` | GDDs (`gdd/`), narrative, art bible and asset specs, UX specs, accessibility requirements |
| `docs/architecture/` | ADR-0001 native per platform, ADR-0002 asset pipeline and budgets, ADR-0003 save format, architecture.md |
| `production/` | progress, project plan, stage (Systems Design), gate checks, QC evidence and tools (`qa/`), release guides (`releases/`), the team board and decisions (`team/`) |
| `tools/` | `ios/` (device install, TestFlight archive), `qa/` (iOS touch tests, release byte check), `dev/android/`, `art/` |
| `project.yaml` | this game's settings (the root's project.yaml is the next game's) |

`ios/`, `android/` and `content/` must stay siblings: the Xcode project and Gradle read `../content`.

## Where it stopped

- **iOS**: r11 frozen at 86ddce0 and QC-passed (W17 fist pad, W18 leave card, W20 skip-warning order, the iOS-R10-01
  clock fix, the Preview build). iOS-R11-01 (skip-warning text clear of the drum) is fixed at 9af55da, not frozen.
  The Preview build ran on Luan's iPhone 17 Pro (free Personal Team; the profile expires every 7 days).
- **Android**: r14 at beea731 (W17, W18, W20, hint hand).
- Last branches before the move: `feat/TASK-006-ios-native` 81d3fa4, `setup/TASK-007-android-kotlin` beea731,
  `docs/vn-history-game-plan` 4792468.

## Open items for when it resumes

- History sign-off C01–C16 (Luan): Release builds stop at the R12 gate until then. Preview builds skip it and show
  `UNSIGNED` badges.
- ADR-0002: frame time on a real phone, both platforms (needs a played mission under Instruments / frametime.sh). iOS
  idle memory is about 111 MiB (production/qa/evidence/TASK-026/device-run-1).
- TASK-025, the map screen ("Về bản đồ" goes to the title until then). D-34, the special pad's label. D-39, the Kids
  age band.
- TestFlight / Play: after enrolment (production/releases/ios-device-and-testflight.md).

## How to build (from this folder)

- iOS core tests: `cd ios/GameCore && swift test`
- iOS app: `xcodebuild -project ios/DaiDatAnhHung.xcodeproj -scheme DaiDatAnhHung -configuration Debug -destination 'platform=iOS Simulator,name=<sim>' build`
- iOS on a phone: `TEAM_ID=<team> DEVICE=<name> tools/ios/install-device.sh`
- Android: `cd android && ./gradlew testDebugUnitTest assembleDebug assemblePreview`

The studio's agents and hooks read the repo root. To work on this game again, give the session this folder's paths
in its brief (e.g. `games/dai-dat-anh-hung/production/progress.md`).
