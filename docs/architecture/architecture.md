# Dải Đất Anh Hùng (Land of Heroes): Master Architecture

## Document Status
- Version: 1
- Last Updated: 2026-11-14
- Author: game-dev-ios (TASK-022); peer review: game-dev-android
- Engine: **native per platform** (ADR-0001). iOS: Swift + SpriteKit in a SwiftUI shell (iOS 17+).
  Android: Kotlin + the Android SDK only (SurfaceView + hardware Canvas, SoundPool). **Engine checks:
  NOT ASSESSED / NOT SOURCEABLE**: the template has no Swift or Kotlin engine row and no engine
  reference for these stacks, so nothing here was checked against a pinned engine reference.
- Depth: rigor `standard` → workflow `standard`, density `balanced`. Standard requires the layer map
  and the critical-ADR list; the module map, data flow and API boundaries are included at the
  leader's request (TASK-022).
- GDDs covered: mission-flow, side-scroll-combat, quiz-and-stars, hints-and-onboarding,
  hero-progression, save-and-progress, language-and-text, input-and-touch, audio-and-voice-over,
  map-and-timeline; the content data contract (`content/README.md`, `content/schema/`).
- ADRs referenced: ADR-0001 (Accepted), ADR-0002 (Accepted); ADR-0003 (save format, to be written).
- TD-ARCHITECTURE: skipped (lean review mode). LP-FEASIBILITY: skipped (lean review mode).

## Engine Knowledge Gap Summary

| Domain | Risk | Why | Mitigation |
|---|---|---|---|
| All (iOS 27 SDK, SpriteKit, SwiftUI; Android SDK 35/36) | HIGH, NOT SOURCEABLE | Post-cutoff SDKs; no engine reference in `docs/engine-reference/` | Every API is proven by a build and a run; nothing is claimed from memory (ADR-0001) |
| Rendering and texture memory | HIGH | No measured budgets yet | ADR-0002 budgets; iOS and Android measurements in its Validation Criteria |
| Touch delivery | MEDIUM | SwiftUI's SpriteView dropped touch-end events for moved touches (iOS-R2-03) | iOS hosts a plain SKView and reconciles pad holds against each UITouch's phase every frame |
| Audio latency and looping | MEDIUM | m4a gapless looping differs per platform | Audio GDD: authored overlap tails and a two-player self-crossfade |

## System Layer Map

```
┌─────────────────────────────────────────────────────────────────────────┐
│ PRESENTATION  renderer (SpriteKit nodes / Canvas draw) · layout & safe  │
│               area · input plumbing (UITouch / MotionEvent → pads) ·    │
│               audio backend (AVAudioEngine / SoundPool) · fonts         │
├─────────────────────────────────────────────────────────────────────────┤
│ FEATURE       screen flow: title (map later) · intro/ending story ·     │
│               play (walk_to, beat_card, beat_play, beat_end, caption,   │
│               dialogue_line) · quiz · results · unlock · pause · skip   │
├─────────────────────────────────────────────────────────────────────────┤
│ CORE          the sim: PlayState / MissionRun (fixed 1/60 step, agreed  │
│               frame order) · combat · beat types · hints · quiz +       │
│               stars · progression · claim gate · Mulberry32             │
├─────────────────────────────────────────────────────────────────────────┤
│ FOUNDATION    content contract (content/data + schema) · loader (strict │
│               in tests, lenient at run time) · validator (R1–R20) ·     │
│               save store · platform shell (app lifecycle, build gates)  │
└─────────────────────────────────────────────────────────────────────────┘
```

**Why these layers.** The Core is pure code with no UI or platform imports (ADR-0001). That is what
lets the shared fixtures, including the frame-by-frame trace, run as plain unit tests on both apps,
and what keeps the two apps playing the same game. Feature owns the order of screens; Presentation
only draws, plays sound and turns touches into pad state. Foundation owns everything that comes from
or goes to disk.

## Module Ownership

| Module | Layer | iOS | Android | Implements | Tests |
|---|---|---|---|---|---|
| Content models + loader | Foundation | `GameCore/Content.swift`, `Tuning.swift` | `core/content/Model.kt`, `ContentLoader.kt`, `core/Tuning.kt`, `core/UiIds.kt` | content contract | content + schema tests (strict) |
| Validator (R1–R20, R8c wrap fit) | Foundation | `GameCore/Validator.swift` | `core/content/Validator.kt`, `LineFit.kt` | content README rules | `fixtures/validity.json` |
| Release build gate (R11, R12) | Foundation | `ios/Scripts/ContentGate.swift` (Release build phase) | `ContentGateTask` (Gradle, before preReleaseBuild) | ADR-0001 | release build fails on a pending claim |
| Save store | Foundation | `Progress` + `KeyValueStore` (UserDefaults today) | `Store` + `PrefsStore` (SharedPreferences today) | save-and-progress | flow and progress tests; **ADR-0003 replaces the store** |
| Sim: play | Core | `GameCore/Play.swift` (PlayState) | `core/Mission.kt` (MissionRun) | mission-flow, side-scroll-combat, hints | combat ACs, G2 strategies, **trace-tqt.json** |
| Sim: quiz + stars | Core | `GameCore/Quiz.swift` | `core/Quiz.kt` | quiz-and-stars | quiz-stars, quiz-scoring, quiz-shuffle fixtures |
| Progression | Core | `Progression` in `Flow.swift` | `core/Progression.kt` | hero-progression | open-rule tests; R17/R18 |
| Claim gate | Core | `GameCore/ClaimGate.swift` | `core/ClaimGate.kt` | content contract R12 | claim-gate fixture |
| RNG | Core | `GameCore/Rng.swift` | `core/Rng.kt` | (determinism) | rng fixture, trace rng_draws |
| Touch → pads | Core (rules) / Presentation (plumbing) | `TouchPads`, `PadLayout` in `Input.swift`; `GameScene` touches | `core/Touch.kt`; `GameView` | input-and-touch | stuck-input, second-pointer, pad layout tests |
| Screen flow, skip, medal | Feature | `Game` in `Flow.swift` | `core/Game.kt` | mission-flow, hero-progression | flow and D-07 tests |
| Renderer, layout, art | Presentation | `GameScene.swift`, `Art.swift`, `Draw.swift` | `Renderer.kt`, `Figures.kt`, `Draw.kt`, `GameView.kt` (loop and input plumbing) | art bible, UX | screenshots (QC evidence) |
| Audio | Presentation | `Audio.swift` (AVAudioEngine, synthesised placeholders) | `Audio.kt` (SoundPool) | audio-and-voice-over | QC (feel), not fixtures |
| Debug tools (not shipped) | Foundation | `TraceTests`, the Simulator screenshot jumps | `FontMetricsActivity` (generates `content/metrics/nunito-advances.json` for R8c), `AtlasBenchActivity` (ADR-0002 measurements), `TraceTest` (`TRACE_WRITE` regenerates the trace) | content contract, ADR-0002 | — |
| App shell | Foundation | `DaiDatAnhHungApp.swift` (SwiftUI + plain SKView, async boot) | `GameActivity.kt`, `GameApp.kt` | lifecycle, AC10 auto-pause | QC |

**Owners.** game-dev-ios owns the iOS column; game-dev-android owns the Android column; both devs own
the schema, fixtures and tuning together (a change needs both devs plus game-art-content for text and
claims). game-art-content owns all player text, claims, sources and art direction.

## The Parity Boundary

The two apps share **data and tests, not code**:
1. **The content contract.** `content/data/` (bundled), `content/schema/` (tests only), and the rules
   R1–R20 in `content/README.md`. Both apps load the same files and both validators enforce the same
   rules.
2. **The fixtures** in `content/fixtures/`: rng, quiz stars, scoring, shuffle, claim gate, validity
   (one or more cases per rule) and **`trace-tqt.json`**, a frame-by-frame replay of the real mission
   (149 snapshots: hero, enemies, partner, dialogue, training, RNG draws). Both cores replay it exactly.
3. **The rule for deliberate changes.** A change to a combat or flow rule regenerates
   `trace-tqt.json` on Android (`TRACE_WRITE`) and both apps replay it before merging.

**May differ per platform:** drawing, the input plumbing (but not the pad rules), the audio backend,
the storage backend (but not the saved keys or their meaning), and app lifecycle code.

## Data Flow

**Content → sim → render (every frame):**
```
content/data (bundled) ──load at launch──▶ ContentSet ──▶ Game (flow) ──▶ PlayState / Quiz
        │                                                    ▲                │
   validator (tests) + build gate (Release: R11, R12)        │ StepInput      │ state + events
                                                             │                ▼
   UITouch / MotionEvent ─▶ pad holds (TASK-019 rules) ─▶ StepInput   renderer · audio
```
1. **Launch:** the app loads `content/data/` once (lenient decode at run time; strict in tests),
   reads the save once, and builds the Game off the main thread (iOS) behind the launch colour.
2. **Each frame:** the frame delta (clamped to 0.25 s) feeds an accumulator; each fixed 1/60 s step
   takes one `StepInput` (pads held, pads tapped this step) and runs the agreed frame order
   (combat GDD: defend → swing → new swing with auto-face → move → clamp/camera → beat start →
   spawn/enemies → fight end → effects).
3. **After the steps:** the renderer reads state (no logic in drawing); play events (swoosh, drum,
   clang, bonk, cheer) and UI sounds go to the audio module.
4. **Menu actions** (Next, Skip, ask, answers, pause) are calls into the Game between frames; they
   fire on touch-up inside, and story advances are debounced (`advance_debounce`).
5. **Saving:** only at quiz finish (one atomic unit, before results), on title/map load
   (`seen_open`) and on a settings change (`lang`, `sound`). Nothing is saved mid-mission.

## API Boundaries

- **Core in:** one input frame per step, `{held, tapped}` (per-platform names: iOS `StepInput`, Android `InputFrame`); flow actions (`start`, `next`, `skip`,
  `skipAnyway`, `keepReading`, `ask`, `answer(slot)`, `pause`, `resume`, `home`, `replay`,
  `toggleLang`, `toggleMute`); `backgrounded()`.
- **Core out:** read-only state (screen, phase, hero, enemies, partner, dummies, quiz, hints, visible
  pads) and drained event lists (play events, UI sounds).
- **Store:** a key-value interface today (`KeyValueStore` / `Store`); ADR-0003 replaces it with a
  versioned save document behind the same Core calls (`Progress.load`, `recordQuiz`, `markSeenOpen`,
  `saveLang`).
- **Assets:** pictures, sounds and fonts are looked up by id through `assets.json`; never by path in
  code (ADR-0002).
- **Text:** UI strings by id (`strings.json`, a missing id shows its key in debug); story text is
  always a `Text` with claims.

**Must / must never** (for the control manifest):
- The Core **must never** import UI, rendering, audio or platform frameworks.
- Every gameplay value **must** come from `tuning.json` / `rules.json`; no hard-coded fallbacks.
- Every player-facing word **must** come from content; no text inside pictures.
- Both apps **must** pass every shared fixture, including the trace, before a merge.
- A release build **must** fail on a pending claim or a newer schema MAJOR.
- Input **must** clear every held pad on the Input GDD Rule 11 triggers: pointer cancel, focus loss,
  pause, backgrounding and an audio route change or interruption. A pad stays held from down to up
  (Rule 9); a hidden pad is filtered by the beat's buttons, not released; a screen change only cancels
  a pressed menu button.

## Save Format (summary; the decision lands in ADR-0003)

**Requirements** (save-and-progress GDD, D-16): saved keys `save_version`, `lang`, `sound`,
`completed.<hero>`, `seen_open.<hero>`, `stars.<hero>` (best, never lowered), `medal.<hero>` (never
cleared); unlocks are **derived** (D-16), never stored; the quiz-finish write is one atomic unit before
results; read once at launch; a newer save is read-only for an older app (no writes at all, settings
included); corrupt or missing data → a quiet fresh start keeping valid keys; unknown heroes' keys are
kept; no personal data and no network.

**Proposed for ADR-0003:** one versioned JSON document with the same shape on both apps, written
atomically (write-then-rename) off the main thread and flushed before the app backgrounds; per-key
salvage on load; a migration step per `save_version`; the store moves from UserDefaults /
SharedPreferences to that file.

**Open:** D-22, platform backup of the save (iCloud / Google backup). Recommendation: **allow** (only
game flags, ~2 KB, no personal data; a child keeps progress on a new device). Luan decides.

## ADR Audit

| ADR | Status | Covers | Gaps |
|---|---|---|---|
| ADR-0001 Native per platform | Accepted | stacks, code roots, content contract, claim gate, build gates | engine rows NOT SOURCEABLE (stated) |
| ADR-0002 Asset pipeline and budgets | Accepted | 1.5× art, ≤ 2048², per-beat loading, ≤ 64 MB, sky band, iOS 17 | iOS memory and real-device frame time open after acceptance |

No conflicts between the two. Neither covers saving, input, audio or content versioning; those are
below.

## Required ADRs

Numbered as proposals in priority order; ADR-0003 is next.

| # | ADR | Layer | Critical at standard? | Why | Serves |
|---|---|---|---|---|---|
| ADR-0003 | Save format and storage | Foundation | **Yes** | Data loss and migration can't be fixed after release; both apps must store the same document | save-and-progress, hero-progression |
| ADR-0004 | Input model and layout | Foundation / Presentation | **Yes** | TASK-019 pad rules, safe area and pad sizing, the TASK-013 full-screen backdrop rule, map touch (clusters, drag threshold) | input-and-touch, map-and-timeline |
| ADR-0005 | Audio and voice-over | Presentation | Yes (before VO recording) | formats, VO per Text id, buses and ducking, looping, the sound setting | audio-and-voice-over |
| ADR-0006 | Content versioning and pipeline | Foundation | Yes (before the first content update) | schema MAJOR/MINOR policy, `content_version`, R-rules as gates, trace regeneration | content contract, language-and-text |
| ADR-0007 | Map renderer | Feature | No (Alpha) | cluster algorithm, k-dependent layout; may fold into ADR-0004 | map-and-timeline |

## GDD Traceability

| GDD | Modules | ADR |
|---|---|---|
| mission-flow | Sim: play; screen flow | ADR-0001 |
| side-scroll-combat | Sim: play | ADR-0001 |
| quiz-and-stars | Sim: quiz | ADR-0001 |
| hints-and-onboarding | Sim: play (hints) | ADR-0001 |
| hero-progression | Progression; save store | ADR-0003 (to write) |
| save-and-progress | Save store | ADR-0003 (to write) |
| language-and-text | Content, validator (R8, R8b, R8c), renderer fonts | ADR-0001, ADR-0006 (to write) |
| input-and-touch | Touch → pads, layout | ADR-0004 (to write) |
| audio-and-voice-over | Audio | ADR-0005 (to write) |
| map-and-timeline | Screen flow (Alpha), renderer | ADR-0004 / ADR-0007 (to write) |

Gaps are flagged, not filled: the tr-registry has no TR-ids yet (`/architecture-review` assigns them).

## Architecture Principles

1. **Data, not code, is shared.** The apps agree through content, schemas and fixtures; the trace
   makes "the same game" testable frame by frame.
2. **The Core is pure.** No UI or platform code in the sim, so every rule is unit-testable.
3. **Release can't ship unsigned history.** The claim gate is a build gate and a run-time guard.
4. **Safe for kids by construction.** Offline, no personal data, no stuck input, nothing that fails
   or shames.
5. **Measure, don't assume.** Budgets, timings and device behaviour are proven on a build and a run,
   never from memory (the stacks are NOT SOURCEABLE).

## Open Questions

- D-22: platform backup of the save (recommendation: allow).
- ADR-0003 to ADR-0006: to be written in the order above.
- iOS memory measurement (ADR-0002) after iOS QC r3; real-device frame time on both platforms.
- The map renderer's details wait for Alpha.
