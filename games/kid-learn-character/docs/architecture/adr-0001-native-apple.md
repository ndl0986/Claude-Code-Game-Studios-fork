# ADR-0001: Native Apple stack: Swift, SpriteKit in a SwiftUI shell, one Xcode project

## Status
Proposed (awaiting Luan's approval)

## Date
2026-11-17

## Last Verified
2026-11-17 (toolchain read from this machine; no API claim below is checked against a pinned reference, see Knowledge Risk)

## Decision Makers
Luan (K-03: fully native, Apple first; this session: SpriteKit in SwiftUI, one `apple/` project,
deployment target 26+); game-leader (author). Peer review by game-dev-ios is still to do.

## Summary
The game is native on every platform (K-03). The first app is one Xcode multiplatform project under
`apple/` for iPadOS and macOS, with iPhone to follow. It is written in Swift: SpriteKit draws the
key-to-picture scene and the stardust morph (K-01: 2D first), and SwiftUI is the app shell and the
parent gate. The rules (key table, mash queue) live in a UI-free Swift package, `KidCore`. Android
(Kotlin) comes later as its own native app under `android/`, with its own ADR. The studio template
has no row for this stack, so engine-aware checks report NOT ASSESSED.

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | None from the template's engine table. Swift 6.4 (swiftlang-6.4.0.34.1), Xcode 27.1 (27A9275), SDKs: iOS 27.1, macOS 27.0, on macOS 27.2 |
| **Domain** | Core |
| **Layer** | Foundation |
| **Knowledge Risk** | HIGH. **NOT SOURCEABLE**: `docs/engine-reference/` has no SpriteKit, SwiftUI, iPadOS 27 or macOS 27 folder, and `.claude/engines/engines.tsv` has no Swift row. These SDKs postdate the model's knowledge, so API claims are proven by building and running, never from memory. |
| **References Consulted** | `design/gdd/game-concept.md`; `production/team/decisions.md` (K-01, K-03, K-05); `games/dai-dat-anh-hung/docs/architecture/adr-0001-native-per-platform.md` (precedent for a stack the template does not know) |
| **Post-Cutoff APIs Used** | Not determined. The scaffold story lists each API it relies on that is newer than the model's knowledge and checks it against the installed SDK by building. |
| **Verification Required** | The app builds, launches and is observed on an iPad Simulator (device and OS noted) and on macOS, with retained screenshots in `production/qa/evidence/` (`.claude/docs/run-and-observe.md`). Hardware-keyboard input is checked on a real iPad or Mac keyboard. `KidCore` unit tests pass. |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | None |
| **Enables** | The key-table / content-data ADR; the audio ADR; a later Android ADR; a 3D (RealityKit) ADR if K-01 moves to 3D |
| **Blocks** | The scaffold story (first Xcode project). Not blocked by approval of this ADR for design work. |
| **Ordering Note** | Written at Concept stage so `/setup-engine` has a recorded engine. `/create-architecture` and `/architecture-decision` extend it. |

## Context

### Problem Statement
Luan chose a fully native app per platform, Apple first (K-03). The template can configure Godot,
Unity, Unreal or Web, but not Swift, so the stack needs one recorded decision that code roots, test
roots and later stories can cite.

### Constraints
- Toddlers (2.5–3) with a parent: big touch targets, instant feedback, no network, no data
  (concept pillars Every Press Answers and Safe by Design); Apple Kids category rules apply.
- On-screen keyboard plus hardware keyboard on iPad and Mac, with the same behaviour.
- 2D first, 3D later for a few favourites (K-01); the scene layer must be swappable.
- MVP in about one week (concept MVP), so the toolchain must be the least-friction one.
- One developer owns the Apple app; Android comes after.

### Requirements
- Every key A–Z and 0–9 maps to a picture, sound and spoken line from a data table (JSON), not code.
- A queue of at most 3 pending keys, further presses ignored, about 3 s per reveal while queued.
- One shared stardust-morph effect for all 36 glyphs, driven by data.
- Parent-gated settings; fully offline.

## Decision

**1. Stack.** Swift. SpriteKit for the scene (glyph, particles, object, idle motion). SwiftUI for the
app shell, the on-screen toddler keyboard if it is simpler there, and the parent gate.
AVAudioEngine (or AVAudioPlayer if a build proves latency fine) for the object sound and the
voice line. XCTest for tests.

**2. One project.** A single Xcode multiplatform project under `apple/` for iPadOS and macOS now;
iPhone is added as a destination later, not a new project. Minimum deployment: iPadOS 26 and
macOS 26 (to be confirmed by the scaffold build; iOS 27 SDK on the machine). Bundle ID is set when
the name is chosen (K-04, open).

**3. Code and test roots.**

| | Code root | Unit tests | UI / device tests |
|---|---|---|---|
| Apple | `apple/` (Xcode project; the game rules in the Swift package `apple/KidCore/`) | `apple/KidCore/Tests/` and `apple/<App>Tests/` (XCTest) | `apple/<App>UITests/` |
| Android (later) | `android/` | its own ADR | its own ADR |

The template's skills default the code root to `src/`. **Every task brief must name its root
(`apple/`).** Code must never be written under `src/`.

**4. `KidCore` stays UI-free.** The key table loader, the mash queue and its timing live in a Swift
package with no SwiftUI, SpriteKit or UIKit imports, so they run as plain unit tests and can be
reused by a future 3D stage or an Android port's spec.

**5. Swappable stage.** The scene is behind a small protocol (show an entry, advance the queue), so
SpriteKit can be replaced by RealityKit for 3D favourites without changing `KidCore`.

**6. Data-driven.** Keys, pictures, sounds, spoken lines, theme packs and tuning values (queue size
3, reveal hold about 3 s) are JSON bundled in the app, never hard-coded. A shared key table can
later feed Android.

**7. The `project.yaml` engine block.** `engine.name` and `engine.code_root` stay **unset**:
`engine.name` accepts only Godot, Unity, Unreal or Web, and a wrong value would route work to the
wrong specialists. A commented block records the stack. Template checks that need an engine row
(specialist routing, code-root scans, `/security-audit` engine rows) report NOT ASSESSED and never
pass. `CLAUDE.md` and `.claude/` are symlinks to the shared repo root, so this setup does not edit
the shared Technology Stack lines; this ADR is the record.

## Alternatives Considered

### Alternative 1: Unity (C#)
- **Description**: One engine and codebase for all platforms. Luan already knows it.
- **Pros**: Familiar to Luan; one codebase also for Android; 3D is easy.
- **Cons**: Contradicts K-03 (fully native); heavy for a toddler toy; no direct benefit for the
  MVP; Apple platform features (hardware keyboard, Kids category) go through another layer.
- **Rejection Reason**: Luan reaffirmed native Swift in /brainstorm (2026-11-17).

### Alternative 2: SwiftUI only (Canvas / TimelineView, no SpriteKit)
- **Description**: Draw the morph with SwiftUI.
- **Pros**: One framework; less to learn.
- **Cons**: No built-in particle system for the stardust; harder to move to 3D later.
- **Rejection Reason**: SpriteKit gives particles and a scene graph out of the box.

### Alternative 3: Separate `ios/` and `macos/` projects
- **Description**: Two Xcode projects sharing `KidCore`.
- **Pros**: Platform-specific tuning is isolated.
- **Cons**: More duplicated setup, and not needed for the MVP.
- **Rejection Reason**: One multiplatform project is enough; split later only if a platform diverges.

### Alternative 4: Web (HTML) as the product
- **Description**: A browser game.
- **Pros**: Fastest to start.
- **Cons**: Not native (K-03); hardware keyboard and Kids-category fit are weaker.
- **Rejection Reason**: Allowed only as a throwaway sketch (`/prototype --path html`), rebuilt natively.

## Consequences

### Positive
- Best fit for iPad touch, hardware keyboards and Apple's Kids category, with the platform's own audio and tooling.
- `KidCore` makes the rules unit-testable without a Simulator and keeps a 3D swap cheap.
- Content stays data, so theme packs (concept Tier 1) are a data change plus art.

### Negative
- Android, when it comes, is a second implementation of the stage and audio.
- The template's engine-aware tooling does not cover this stack (NOT ASSESSED).
- No pinned API reference for SpriteKit or SwiftUI: API use is verified by building and running.

## Risks
- **Post-cutoff SDK APIs misremembered.** Mitigation: every API is proven by a build and a run.
- **Hardware-keyboard events differ between iPad and Mac.** Mitigation: an early spike and a real-keyboard check (concept risk).
- **Skills write code under `src/`.** Mitigation: briefs name `apple/`, and reviews reject `src/`.
- **Deployment target 26 is wrong for the child's iPad.** Mitigation: Luan confirms the iPad's OS; the scaffold build verifies the target.

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|--------------------------|
| game-concept.md | Native, Apple first: iPadOS + macOS, then iPhone (K-03) | One Xcode multiplatform project in `apple/` |
| game-concept.md | Pillar 1: every press answers, mashing never breaks | `KidCore` mash queue (max 3), unit-tested without UI |
| game-concept.md | Pillar 2 and K-01: letter morphs into the object, 2D first | SpriteKit particles for the shared morph; swappable stage for a later 3D |
| game-concept.md | Pillar 5: safe, offline, parent gate | No network code; SwiftUI parent gate |
| game-concept.md | Data-driven key, picture, sound table | Bundled JSON, read by `KidCore` |

## Performance Implications
- **CPU**: One scene, a handful of particles and one object at a time; well inside 60 fps on a current iPad.
- **Memory**: 36 pictures plus sounds; budgeted when the art bible sets sizes.
- **Load Time**: Table and first assets load before the first key is shown.
- **Network**: None.

## Migration Plan
Nothing to migrate. The paused TASK-030 iOS plan and the TASK-031 Android notes feed the next ADRs.

## Validation Criteria
- The app builds, launches and plays all 36 keys on an iPad Simulator and on macOS, with retained screenshots in `production/qa/evidence/`.
- `KidCore` tests prove the mash rule: 3 queued, the 4th ignored, hold timing from data.
- A hardware keyboard on a real iPad or Mac plays the same as touch.

## Related
- `design/gdd/game-concept.md`; `production/team/decisions.md` (K-01, K-03, K-05, K-06).
- Precedent: `games/dai-dat-anh-hung/docs/architecture/adr-0001-native-per-platform.md`.
- Follow-ups: scaffold story; key-table and audio ADRs; a "Native" row in the template's engine table (Luan's call).
