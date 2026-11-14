# ADR-0001: Native per platform: Swift for iOS, Kotlin for Android; Godot shelved

## Status
Proposed

## Date
2026-11-14

## Last Verified
2026-11-14

## Decision Makers
Luan (decision: native per platform, Godot shelved; Android draws with the pure Android SDK);
game-dev-ios (author); game-dev-android (peer review); game-art-content (content schema review);
the game team leader (relay). Task: TASK-005.

## Summary
The game ships on iOS and Android as two native apps. iOS is Swift + SpriteKit in a SwiftUI
shell, under `ios/`. Android is Kotlin + the Android SDK only (a SurfaceView game loop drawn
with Canvas, SoundPool audio, no game framework), under `android/`. Both apps read one shared,
bundled, offline `content/data/` folder of JSON (missions, quiz, VI/EN text, claims, sources,
tuning, assets), whose schema carries the history sign-off gate. Godot 4.7.2 (TASK-002) is
shelved.

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | None from the template's engine table. iOS: Swift + SpriteKit + SwiftUI (Xcode; tested on the iPhone Duo Simulator, iOS 27.1). Android: Kotlin + Android SDK (Gradle; targetSdk 35 now, 36 before the Play release) |
| **Domain** | Core |
| **Layer** | Foundation |
| **Knowledge Risk** | HIGH. **NOT SOURCEABLE**: `docs/engine-reference/` has no folder for SpriteKit, SwiftUI, iOS 27 or the Android SDK, and `.claude/engines/engines.tsv` has no Swift or Kotlin row. iOS 27 and the current Android SDK postdate the model's knowledge, so their API claims can't be checked against a pinned reference. |
| **References Consulted** | `design/gdd/game-concept.md`; `prototypes/tqt-mission/` (proto/TASK-003-mission-prototype @ `203d73e`); `design/narrative/heroes/tran-quoc-toan.md` and `design/art/art-bible.md` (design/TASK-004-art-bible-tqt-beats @ `4d7aca2`); `.claude/docs/effects-map.md` (`engine.*` keys); `.claude/engines/engines.tsv` |
| **Post-Cutoff APIs Used** | Not determined. Each setup task (TASK-006 iOS, TASK-007 Android) lists every API it relies on that is newer than the model's knowledge, and checks it against the installed SDK by building, not from memory. |
| **Verification Required** | Each app builds, launches and is observed on its Simulator or emulator (`.claude/docs/run-and-observe.md`). The release build fails on a pending claim (R12). Bundled Nunito shows every Vietnamese diacritic. Pads are at least 72 pt or dp inside the safe area. Each app's unit tests pass the shared fixtures. |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | None |
| **Enables** | Save-data ADR (stars and unlocks on the device); the content pipeline / pictures registry ADR; a later shared-logic ADR (e.g. Kotlin Multiplatform) if it is ever needed |
| **Blocks** | TASK-006 (iOS first mission), TASK-007 (Android first mission). Per `docs/CLAUDE.md`, stories citing this ADR stay blocked until Luan accepts it. |
| **Ordering Note** | Supersedes the Godot pin from TASK-002 (`setup/TASK-002-engine-godot`, kept and not merged). |

## Context

### Problem Statement
TASK-002 pinned Godot 4.7.2 to build one project for both phones. Luan decided (2026-11-14)
to build the game natively per platform instead: the best fit for touch, safe areas, fonts and
store builds on each OS, with one developer owning each platform. Two codebases need one source
of truth for the story, the quiz and the history sign-off. Otherwise the two apps drift, and
unsigned history text could ship on one of them.

### Constraints
- Primary-school children in Vietnam: landscape, touch-first, pads at least 72 pt/dp, and forgiving timing (Pillar 3).
- Fully offline, with no data collection, ads or purchases aimed at kids (Pillar 5). Content arrives in timed app updates; there is no server.
- Vietnamese first, English second, with full diacritics in a bundled font.
- Every history claim is labelled and signed off by Luan before it ships (Pillar 2).
- Two devs, one per platform. Gameplay logic is written twice.
- The template's tooling knows Godot, Unity, Unreal and Web only.

### Requirements
- Both apps play the same mission, quiz and star rule from the same data.
- Unsigned text can't reach a release build.
- Rules shared between the apps are proven by the same test cases on both platforms.
- Adding a hero is a data change plus art, not a code change (data-driven, per the coding standards).

## Decision

**1. Platforms and stacks.**
- **iOS:** Swift, with SpriteKit for the game scene inside a SwiftUI app shell (title, menus and overlays may be SwiftUI or SpriteKit, as TASK-006 chooses). Bundle ID `com.galaxyandsun.daidatanhhung`. Landscape only. XCTest.
- **Android:** Kotlin and the Android SDK only. One SurfaceView with a game loop that draws on Canvas, and SoundPool audio. **No game framework** (no libGDX, Korge or similar). Runtime parsing uses kotlinx.serialization (approved). JUnit plus androidTest.
- **Godot shelved.** The TASK-002 branch stays as a record. It is not merged, and nothing from it ships.

**2. Code and test roots.**

| | Code root | Unit tests | UI / device tests |
|---|---|---|---|
| iOS | `ios/` (Xcode project; the game core in a Swift package or group with no UIKit/SpriteKit imports where it can) | `ios/<App>Tests/` (XCTest) | `ios/<App>UITests/` |
| Android | `android/` (Gradle; a pure-Kotlin core with no `android.*` imports) | `android/app/src/test/` (JUnit) | `android/app/src/androidTest/` |
| Shared | `content/` (data, not code) | `content/fixtures/` run by both | — |

The template's skills default the code root to `src/`. **Every task brief must name its root
(`ios/` or `android/`).** Code must never be written under `src/`.

**3. Shared content (`content/`, details in `content/README.md`).**
- `content/data/` is the only folder bundled into the apps (Android: `assets.srcDirs("../../content/data")`; iOS: a folder reference). `schema/`, `samples/` and `fixtures/` are test-only.
- Every story, scene, intro, ending, banner and quiz line is a **Text** `{id, vi, en, claims[]}`: a stable dotted id, both languages, and at least one claim (invented C12 counts). Only UI strings in `strings.json` have no claims.
- Claim labels are fact, fact_as_recorded, interpretation, legend or invented, with an optional `relabel_condition` (C06 and C08). Sources S1–S4 live in `sources.json` with `to_confirm` or `confirmed`.
- Beats carry type, theme, buttons and per-type params. The fight params are the prototype's `enemies`, `max_active` and `from_left`. The banner is defined once as Text and never baked into art. There is no text inside any picture.
- Quiz: 3–5 questions, 3 picture choices each, `correct_index`, and a `why` line. Stars count retries as a **total across the whole quiz**: 0 earns 3★, 2 or fewer earns 2★, more earns 1★. Finishing always unlocks the next hero.
- Gameplay tuning (the prototype's `config.js`) is `content/data/tuning.json`: `{value, min, max, unit}` in a 1280×720 world, read by both apps.
- Assets: `assets.json` maps ids to files and sizes. Audio is m4a (AAC) or wav, with no OGG. One bundled OFL font: `data/fonts/nunito.ttf`.
- All text is NFC. Lines are at most 120 characters, and EN also fits a per-field budget in `rules.json`.
- Rules R1–R12 in `content/README.md` define validation. Each app's unit tests check them, using JSON Schema in tests only (networknt on Android, a small validator in the Swift tests). There is no CI script yet.

**4. The claim gate.** A pending claim fails the **release build**: a Gradle task before
`assembleRelease`, and an Xcode build phase on the Release configuration. At run time, a
release app also hides, quietly and with a log entry, any mission whose claims are not all
approved. A debug build plays it with an `UNSIGNED Cxx` badge. QC tests debug builds.

**5. Schema versions.** Every file has `schema_version` "MAJOR.MINOR". An app refuses a newer
MAJOR at build time (R11), never at run time. Schema changes need both devs and game-art-content.

**6. The `project.yaml` engine block.** `engine.name` and `engine.code_root` stay **unset**.
`engine.name` accepts only Godot, Unity, Unreal or Web, and `code_root` takes one folder, not
two. A commented block records the native stacks. Template checks that need an engine row
(specialist routing, code-root scans, `/security-audit` engine rows) therefore report
NOT ASSESSED, and never pass.

### Architecture Diagram

```
                 content/  (written by game-art-content + devs; Luan signs off history)
   schema/ samples/ fixtures/  ── test-only ──┐
   data/  ── bundled at build ──┐             │
                                │             │
          ┌─────────────────────┴──┐   ┌──────┴────────────────────┐
          │ ios/  Swift            │   │ android/  Kotlin          │
          │ Build phase: R11, R12  │   │ Gradle task: R11, R12     │
          │ Codable loader         │   │ kotlinx.serialization     │
          │ Core (rules, states)   │   │ Core (rules, states)      │
          │ SpriteKit scene        │   │ SurfaceView + Canvas loop │
          │ SwiftUI shell          │   │ SoundPool                 │
          │ XCTest ◄─ fixtures ────┼───┼─► JUnit                   │
          └────────────────────────┘   └───────────────────────────┘
```

### Key Interfaces
- The content files and their JSON Schemas in `content/schema/` are the contract between the two apps and the content writer.
- The fixture files in `content/fixtures/` are input plus expected output that both cores must reproduce exactly: `quiz-stars`, `quiz-scoring`, `claim-gate` and `validity`.
- The two cores use the same names for states and tuning keys: the prototype's enemy states `enter`, `approach`, `windup` (the `telegraph` time), `strike`, `rest`, `hurt` (knock-back) and `flee` and the `tuning.json` keys. A shared fixture can then describe both.

### Implementation Guidelines
- **Must** read every gameplay value and every player-facing word from `content/data/`. **Must never** hard-code a tuning value or a player-facing string in Swift or Kotlin.
- **Must** keep the game core free of UI-framework imports, so the fixtures run as plain unit tests.
- **Must** run every case in `content/fixtures/` in the app's unit tests and fail on any mismatch.
- **Must** fail the release build on a pending claim, an unknown claim id or a newer MAJOR `schema_version`.
- **Must never** put text inside a picture, or bake the banner's words into art.
- **Must never** add a network call, analytics, ads or purchases (Pillar 5) without a new ADR approved by Luan.
- **Must** write code only under `ios/` or `android/`, never under `src/`.
- Feel (timing on screen, knock-back, button size, multi-touch) is **not** in the shared fixtures. It is checked by per-platform QC on the device type.

## Alternatives Considered

### Alternative 1: Godot 4 (one project, both platforms)
- **Description**: The TASK-002 pin: GDScript, the Compatibility renderer, export templates for Android and iOS.
- **Pros**: One codebase, one set of tests, and specialist agents in the template.
- **Cons**: The template marks the engine route less proven. Native feel, safe areas and store tooling go through an extra layer, and the team had chosen one owner per platform.
- **Rejection Reason**: Luan chose native per platform (2026-11-14). The branch is kept in case that choice is revisited.

### Alternative 2: Unity
- **Description**: C#, one project, both stores.
- **Pros**: Mature mobile pipeline; strong if ads or IAP are ever needed.
- **Cons**: Heavier for a small 2D kids' game. Licence terms. Ads and IAP are out (Pillar 5).
- **Rejection Reason**: Same as Godot: native per platform was chosen, and Unity's strengths aren't needed.

### Alternative 3: Cross-platform UI frameworks (Flutter, React Native) or the web build in a wrapper
- **Description**: One codebase rendering a 2D game on both phones.
- **Pros**: One codebase, with the browser prototype as a head start.
- **Cons**: Game loops, audio latency and multi-touch are weaker. Luan stopped browser testing and asked for native.
- **Rejection Reason**: Luan's direction (2026-11-14): skip the cross-platform version and rebuild natively.

### Alternative 4: Kotlin Multiplatform for the shared game core
- **Description**: One Kotlin core (rules, states, quiz) compiled for both, with native rendering on each.
- **Pros**: The rules are written once.
- **Cons**: A new toolchain on iOS and a Swift/Kotlin interop layer, for a first game with two devs who each own a platform.
- **Rejection Reason**: Deferred, not rejected. Shared data plus shared fixtures cover the drift risk for now. A later ADR can revisit it if the two cores diverge.

### Alternative 5 (Android only): a 2D framework (libGDX, Korge) instead of the pure SDK
- **Description**: A game framework on top of Kotlin.
- **Pros**: A ready-made loop, sprite batching and audio.
- **Cons**: A new dependency, a larger APK and another layer to learn.
- **Rejection Reason**: Luan chose the pure Android SDK with SurfaceView, Canvas and SoundPool (2026-11-14).

## Consequences

### Positive
- Each app uses its platform's own touch, safe-area, font and audio handling, and builds with its own store tooling.
- History text and the sign-off gate live in one place; neither app can ship unsigned text in a release build.
- A hero is added as data plus art. Both apps pick it up without code changes.
- The shared fixtures make the rules (stars, scoring, claim gate, validity) provably the same on both.

- **TASK-006 and TASK-007 are a native vertical slice** of one mission, proving the game on real devices (Luan, 2026-11-14). They are not yet the production codebase: the full build follows epics and stories, and slice code is kept, refactored or rewritten as those decide. Mission, combat, quiz and hint rules are formalised in the GDDs (TASK-008); a rule the prototype left unclear is noted for TASK-008, not invented.

### Negative
- Gameplay code is written and maintained twice, and every feature costs two implementations and two QC passes.
- The template's engine-aware tooling (specialist agents, engine reference, code-root checks) does not cover this stack. Those checks report NOT ASSESSED.
- There is no pinned API reference for SpriteKit, SwiftUI or the Android SDK. API use is verified by building and running, not from a doc.

## Risks
- **The two cores drift in feel or rules.** Mitigation: shared fixtures for the rules; the same state names and tuning keys; per-platform QC against the same acceptance list.
- **Post-cutoff SDK APIs** (iOS 27, the current Android SDK) are misremembered. Mitigation: every API is proven by a build and a run on the Simulator or emulator; nothing is claimed as verified from memory.
- **Skills write code under `src/`.** Mitigation: task briefs name `ios/` or `android/` (rule above), and reviews reject `src/`.
- **Unsigned text ships.** Mitigation: the release-build gate (R12), the runtime guard and the debug badge.
- **Fonts miss a diacritic.** Mitigation: one bundled Nunito, an NFC check (R7), and screenshots of VI text in QC.

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|--------------------------|
| game-concept.md | Android + iOS phones, touch-first, landscape | Native app per platform; landscape only; pads at least 72 pt/dp (`tuning.json` `pad_min`) in the safe area |
| game-concept.md | Pillar 2: every claim labelled and signed off | Claim register with labels and sign-off; Text requires claims; R4–R6 and the release gate R12 |
| game-concept.md | Pillar 3: small hands, short text | 120-character line limit, one sentence per box, EN budgets; shared star rule (no blocked progress) |
| game-concept.md | Pillar 4: passing the quiz unlocks the next hero | `rules.json` `finishing_unlocks_next_hero`, `next_hero` in the mission |
| game-concept.md | Pillar 5: offline, no data collection | Everything bundled from `content/data/`; no network. Stars and unlocks stay on the device (save format: a later ADR) |
| game-concept.md | Vietnamese first, English second; diacritics | `{vi, en}` on every Text; NFC; bundled Nunito |
| game-concept.md | Content added in timed app updates | `content_version` in `index.json`; a hero is data plus art |

## Performance Implications
- **CPU**: Native loops (SpriteKit; a SurfaceView with a fixed 1/60 s step on Android). Low-end Android is the floor, and TASK-007 profiles it.
- **Memory**: Content JSON is small (a few kB per hero) and parsed once at launch. Pictures dominate and are budgeted in `assets.json` byte sizes.
- **Load Time**: All content and sounds load before the title screen draws.
- **Network**: None.

## Migration Plan
Nothing ships from Godot. TASK-002's branch is kept and not merged. The browser prototype
(`203d73e`) is the functional spec: its `config.js` values move to `content/data/tuning.json`
and its beats to `content/samples/heroes/sample/mission.json` until game-art-content writes
`content/data/heroes/tqt/`. Save data (stars, unlocks, language) stays on the device, in
UserDefaults on iOS and SharedPreferences on Android; its format is deferred to a save-data ADR.

## Validation Criteria
- Both apps build, launch and play the sample mission and quiz on their Simulator or emulator, with retained screenshots in `production/qa/evidence/TASK-006/` and `TASK-007/`.
- Both apps' unit tests pass every case in `content/fixtures/`.
- A release build with one pending claim fails on both platforms; with all claims approved it passes.
- VI text with every diacritic renders correctly in Nunito on both platforms.

## Related
- Supersedes the Godot pin in TASK-002 (branch `setup/TASK-002-engine-godot`, not merged).
- `content/README.md`: the data model and validation rules R1–R12.
- `design/gdd/game-concept.md` (pillars); `design/narrative/heroes/tran-quoc-toan.md` and `design/art/art-bible.md` (TASK-004).
- Follow-ups: a save-data ADR; the `pictures.json` registry; a "Native" row in the template's engine table (Luan's call).
