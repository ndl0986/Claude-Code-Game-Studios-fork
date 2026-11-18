# Letter Morph — Master Architecture

## Document Status
- Version: 2 (TASK-114 refresh, 2026-11-18, against the TASK-111 review `architecture-review-2026-11-18.md`; v1 was
  TASK-059)
- Last Updated: 2026-11-18
- Engine: none from the template's engine table (`engine.name` unset on purpose, ADR-0001, K-28). Native Apple
  stack: Swift 6.4, Xcode 27.1 (27A9275), SDKs iOS 27.1 / macOS 27.0, deployment iPadOS 26 and macOS 26.
  Reference: `docs/engine-reference-local/native-apple/`, inside this game's folder (K-28 Q3; Luan: kept out of the
  template's shared `docs/engine-reference/`).
- GDDs Covered (17, all Approved): input-key-filter, key-table-theme-data, morphcore, press-queue, settings-store,
  audio-voice, cast-rendering, reveal-stage, hint-letters, parade, parent-gate-panel, child-lock-in,
  app-shell-title, scene-time-weather, privacy-kids-compliance, **onscreen-keyboard-row, accessibility** (added in v2;
  TASK-111 AD-2).
- ADRs Referenced: ADR-0001 to ADR-0006 and ADR-0011 (Accepted); ADR-0007 to ADR-0010 (Proposed, waiting on device
  rows); morph-contract-v1 (Accepted with ADR-0001). The status of each is in the ADR Audit below.
- Author: game-dev-ios (TASK-059, v1); game-dev-android (TASK-114, v2 refresh); decisions K-01…K-42.
- Workflow: standard, `docs.density: balanced`, review mode lean.
- **Deviation recorded:** Phase 0a read `docs/engine-reference-local/native-apple/` (game-local) in place of
  `docs/engine-reference/[engine]/`, since no engine is configured (K-28 Q3). The game's `docs/engine-reference/` is
  a symlink to the template's shared folder, which is left untouched (Luan). That folder states every API claim
  as PROVEN (TASK-033), SOURCED (an Apple URL) or NOT SOURCEABLE.
- TD-ARCHITECTURE: 2026-11-18 — skipped — lean mode
- LP-FEASIBILITY: 2026-11-18 — skipped — lean mode
- Independent read: v1, game-dev-android (pending in v1's status block); v2 refresh reviewed by game-qc-android
  (TASK-114, approve-from-diff)

## Summary

Every rule of the toy lives in two UI-free Swift packages, `MorphCore` (the morph contract) and `KidCore` (every
other system as a pure state machine or formula, with injected clocks and random draws), whose types map one to
one onto Kotlin, so a later Android app can reproduce them against shared case files. The Apple app layer is a
thin set of adapters (SwiftUI shell, SpriteKit stage, UIKit/AppKit input, AVAudioEngine, UserDefaults, the Mac
kiosk) and is the only place platform types appear.

## Engine Knowledge Gap Summary

From `docs/engine-reference-local/native-apple/` (Phase 0d):

| Domain | Risk | Why | What it blocks |
|---|---|---|---|
| SpriteKit drawing of layered per-part art at 60 fps on an iPad | **HIGH** | spike drew one flat silhouette only; no device run | ADR-0009 (render path), after Cast Rendering R11's device run |
| AVAudioEngine latency, `.soloAmbient`, interruptions on a real iPad | **HIGH** | Mac/Simulator estimates only; session behaviour NOT SOURCEABLE | ADR-0010 (audio), after the TASK-033 iPad procedure |
| iPad hardware keys (`pressesBegan`, `UIKey`) on a device | **HIGH** | built and ran on the Simulator; no key pressed | ADR-0007 (input) |
| Mac kiosk with a physical keyboard; native vs borderless full screen; crash with kiosk on | **HIGH** | ⌘H/⌘Q/⌘Space proven; ⌘Tab, ⌘⌥Esc, Mission Control, hot corners NOT ASSESSED | ADR-0008 (lock-in) |
| Guided Access with hardware keys | **HIGH** | Apple does not say | ADR-0008 |
| iPadOS window rules (any shape; full-screen opt-out) | MEDIUM | App Shell R7 claim NOT SOURCEABLE | ADR-0006 (stage runtime) |
| Privacy manifest reasons (UserDefaults CA92.1, SystemBootTime 35F9.1) | LOW | SOURCED 2026-11-18 | — |
| `KidCore` / `MorphCore` (Swift stdlib + Foundation, value types, Double) | LOW | plain Swift; MorphCore built and passed its fixture in TASK-033/035 | — |

Rule for all HIGH domains: no ADR decides from memory; each has a measurement or build first (Required ADRs).

## Architecture Principles

1. **Rules are data-free code; content is code-free data.** Every rule is in `KidCore`/`MorphCore`; every value a
   designer tunes is bundled JSON validated at build time (ADR-0001 Decision 6). No timing literal in app code.
2. **One truth, two platforms.** A cross-platform behaviour is a versioned contract with hand-written cases from
   its GDD; the GDD decides any disagreement, never "Swift wins" (ADR-0004 below).
3. **Platform types stay at the edge.** Only the app layer and build tools import UIKit, AppKit, SwiftUI,
   SpriteKit, AVFoundation or JSON decoding. `KidCore` and `MorphCore` use only Kotlin-mappable types.
4. **Injected time and chance.** Four named clocks and one `RandomSource` per random stream are injected everywhere; tests and
   fixtures drive them, so every rule is deterministic under test.
5. **Safe by design is structural.** No network code path exists (PKC-01); the kiosk can never engage before its
   way out works (Child Lock-in R3, R5); nothing about the child is stored (Settings Store R2).

## System Layer Map

```
┌──────────────────────────────────────────────────────────────────────────────┐
│ APP LAYER  apple/<App>  (SwiftUI shell, SpriteKit, UIKit/AppKit, AVFoundation) │
│  StageView+SpriteKit scene · frame driver (display link) · input adapters      │
│  audio engine adapter · UserDefaults backend · kiosk effects · Guided Access   │
│  observer · clock adapters · Cast Rendering draw adapters · lifecycle, memory  │
├──────────────────────────────────────────────────────────────────────────────┤
│ KIDCORE  apple/KidCore  (Swift stdlib + Foundation value types only)           │
│  Presentation logic: Reveal Stage · Cast Rendering math · Scene · App Shell    │
│  Feature logic:      Press Queue · Hint Letters · Parade · Parent Gate & Panel │
│                      Child Lock-in · Audio & Voice plan                        │
│  Foundation logic:   Input & Key Filter · Key Table & Theme Data · Settings    │
├──────────────────────────────────────────────────────────────────────────────┤
│ MORPHCORE  apple/MorphCore  (morph-contract-v1)                                │
├──────────────────────────────────────────────────────────────────────────────┤
│ CONTENT & CONTRACTS  content/ (themes, glyphs, timing data)                    │
│                      contracts/<name>-vN/ (spec + cases)                       │
├──────────────────────────────────────────────────────────────────────────────┤
│ TOOLS  apple/Tools (macOS CLIs, build-time only, nothing in the bundle)        │
│  bake tool · content validator · voiceDurations · loudness · TTS pre-render    │
└──────────────────────────────────────────────────────────────────────────────┘
```

- **Dependencies point down only.** The app depends on `KidCore` and `MorphCore`; `KidCore` depends on
  `MorphCore` (Reveal Stage builds morphs) and on nothing else; `MorphCore` depends on nothing. Tools depend on
  `KidCore` (the validator's V-rules) and `MorphCore` (the v1 parser).
- **Privacy & Kids Compliance** has no runtime module: its PKC rules are build checks and scans (ADR-0011).
- **Layer choice for Presentation logic:** Reveal Stage, Cast Rendering, Scene and App Shell each split into a
  pure part in `KidCore` (timelines, formulas, state machines) and a drawing or OS part in the app. That keeps
  their numbers testable and shareable with Android, while the render path (ADR-0009) can change underneath.

## Module Ownership

Each GDD system's pure part lives in `KidCore` (or `MorphCore`); its platform part lives in the app.

| System (GDD) | `KidCore` / `MorphCore` (pure) | App layer (platform) |
|---|---|---|
| Input & Key Filter | classifier on normalized events (R2–R7), held set, chord, Title/Play/Inactive/challenge routing, `kioskModeOn` input, hit tests F1/F2 | `pressesBegan`/`UIKey` and `NSEvent` local-monitor adapters → normalized events; touch/click adapters; OS key state read (ADR-0007) |
| Key Table & Theme Data | theme model, V-rules validator, pick rule and peek (§4), the variety draw | bundle loading, JSON decode, off-main-thread load; the validator also runs in Tools |
| MorphCore | `MorphCore`: morph-contract-v1 parser, sampler, SplitMix64, `position(i, s)`, T, phase; timing-spec loader (F1) | — |
| Press Queue | the whole state machine (R2–R13, F1–F5) | — |
| Settings Store | record v1, validation, migration, F1/F2, change notifications, behind `SettingsBackend` | `UserDefaults` backend: one JSON value under one key, atomic (ADR-0005) |
| Audio & Voice | the audio plan: E1–E12 schedule, F1 gain chain, F2 duck, F3 mash, F6 word_end, player policy | `AVAudioEngine` adapter: primed players, scheduling, fades, limiter, session (ADR-0010) |
| Cast Rendering | F1 role/tier, F2 halo, F3 speck alpha, F4 cap, F5 idle/hop, F6 residency policy, F7 late-art wait, F8 per-look | draw adapters (option A live paths or B PNG tiers, ADR-0009); texture residency |
| Reveal Stage | router, `startReveal` and F5 lengths, timeline, `formed`/`shown`, play clock with freeze/resume/settle, stage fit F1, cooldown F6, published boxes, `haloOn`, `mashing` | the SpriteKit scene graph and draw order; frame driver (ADR-0006) |
| Hint Letters | spawn, slots, jitter, clearances, life, drift, `originFor`, freeze/Dimmed (R1–R12, F1–F5) | drawing the bubbles |
| Parade | batches, arming F2, walk positions F3, art wait, freeze | drawing walkers through Cast Rendering |
| Parent Gate & Grown-up Panel | moon hold F1, chord step, challenge with injected words, sleep, timeout, auto-close, confirm holds | panel UI (SwiftUI overlay in the main window, App Shell R7) |
| Child Lock-in | Off/Waiting/Locked/Suspended, R3 preconditions, engage timeout R7, failure flag, behind `KioskEffects` | `presentationOptions`, covers on extra displays, full-screen mode; Guided Access observer (ADR-0008) |
| App Shell & Title | launch order, Title/Play/Gate/Panel/Background, pending start, F3 away (continuous clock), F4 memory escalation | scene/window lifecycle, memory warnings, launch screen, Title drawing |
| Scene: Time of Day & Weather | F1 look/lookBlend, F2 skyMidL, F3 weather motion, F4 counts, F5 lift, build-check data | drawing the sky, hills, ground and weather |
| Privacy & Kids Compliance | — | build scans and checks (ADR-0011) |

**Where platform types are allowed:** only in `apple/<App>`, `apple/<App>Tests`, `apple/<App>UITests` and
`apple/Tools`. `KidCore` and `MorphCore` may use the Swift standard library and Foundation value types, under the
type rules below. A build check enforces it (scaffold story check (d)).

### Kotlin-mappable types in KidCore and MorphCore (pinned for ADR-0002)
- **Time:** `Double` seconds everywhere. No `Date`, `Calendar`, `Decimal`, `Duration`, `DispatchTime`.
- **Wall time:** an injected `WallClock` returning `{minutesOfDay: Double (local, fractional), dayKey: Int
  (yyyymmdd local)}`.
- **Ids:** `Int` or `String`. No `UUID`.
- **Chance:** one injected `RandomSource` **per stream**: the Key Table variety pick, Hint Letters (key, slot,
  jitter, life, phase), the On-screen Keyboard Row, and the morph seed from (key, revealId) (MorphCore Rule 5).
  Each is `next() → UInt64`, `u = (x >> 11) · 2⁻⁵³` (Key Table's rule), with its own injected source and its own
  debug-logged seed, so one stream's draws never shift another's. Seeds are a platform concern; contracts feed
  draws per stream (below).
- **Data:** plain value types (`struct`, `enum` with raw values, arrays, `Int`, `Double`, `String`, `Bool`). JSON
  is decoded at the edge (app or Tools); `KidCore` takes decoded models. No `Codable` JSON in `KidCore`.
- **Concurrency:** none inside `KidCore`; the app calls it on the main thread and hands results to its own queues
  (the theme load off the main thread is an app adapter calling pure `KidCore` validation).

## Data Flow

**1. Launch (App Shell R1).** Settings read (backend → `KidCore` record, synchronous); on the Mac with
`childLockActive`, Child Lock-in enters **Waiting at this read** and sets Input's `kioskModeOn` → `themeId` to the
Key Table load (app: off the main thread; decode JSON → `KidCore` validate; Audio decodes PCM) → first frame: the
Title (Scene look from `WallClock`) → Mac: App Shell `ready` (first frame, chord installed, window covers display)
→ Child Lock-in applies the kiosk (Locked) once `ready` and its R3 hold.

**2. A press (one frame).**
```
OS event → app input adapter → normalized KeyEvent (uptime time)
  → KidCore.Input classifier → press | startPlay | openPanel | gateTouch | sparkle | creatureTap | nothing
  → KidCore.RevealStage router: origin (Hint Letters originFor) → PressQueue.press(p)
       → outcome {started | queued | ignored}  (same callback)
       → AudioPlan (E1/E2) → app audio adapter ; Hint Letters consume/keep ; starlight/sparkle effects
  → if started: Key Table resolve (§4) → MorphCore morph(seed from key, revealId) → Cast Rendering willForm
       → {formedS, revealLen, hasWord} back to the Press Queue
frame tick (display link targetTimestamp → play clock):
  PressQueue.tick → RevealStage timeline (s) → MorphCore positions → CastRendering math (F2–F8)
  → render plan → app draw adapters (SpriteKit) in the Reveal Stage R10 order
  → Scene (look from WallClock, motion from play clock) behind
```

**3. Freeze, settle (Reveal Stage R8).** Parent Gate opens the challenge → `RevealStage.freeze()` → the play clock
stops → Press Queue (no ticks), Hint Letters (challenge freeze), Parade (`pt` paused), Audio plan (pause), Scene
motion stop. Wrong answer or timeout → `resume()`. Correct → panel → `settle()` (Press Queue clears and marks
formed; Parade fades; hints freeze from the panel signal). Background → `settle()`, the play clock excludes
background time.

**4. Content build (Tools).** SVG (subset, Cast Rendering R2) → bake tool → `cast_….json`, `sil_….json`;
glyphs from the OFL font → `glyph_….json`; TTS pre-render → `.m4a`; decoded lengths → `voiceDurations`;
loudness check; validator (Key Table V-rules, MorphCore v1 parse, Scene caps, Cast Rendering bake rejections)
gates the build.

**5. Settings change.** Panel control → `KidCore` Settings (validate, write the whole record through the
backend, one notification on the main thread) → consumers (Audio gain, Key Table theme, Scene weather, Keyboard
Row, Child Lock-in).

## API Boundaries

All seams are protocols in `KidCore` (names provisional; ADR-0002 fixes them).

| Seam | Shape | Implemented by |
|---|---|---|
| `UptimeClock` | `now() → Double` (event and frame times; Input R8) | app: event `timestamp`, `targetTimestamp`, `systemUptime` |
| `PlayClock` | derived: `uptime − frozenTotal` (Reveal Stage R8) | `KidCore` itself, from `UptimeClock` + freeze state |
| `AwayClock` | `now() → Double`, counts sleep (App Shell R6); named so it does not shadow Swift's `ContinuousClock` | app: Swift `ContinuousClock` / `mach_continuous_time` |
| `WallClock` | `{minutesOfDay, dayKey}` (Scene R2) | app: the local calendar and time zone |
| `RandomSource` (one per stream) | `next() → UInt64` | app: one seeded generator per stream, seed logged in debug; tests and fixtures: a draw list per stream |
| `KeyEvent`, `TouchEvent` | normalized events (input-filter-v1) | app input adapters |
| `SettingsBackend` | `read() → bytes?`, `write(bytes) → ok?`, `remove()` | app: `UserDefaults` single key |
| `KioskEffects` | `apply()`, `remove()`, `coverDisplays()`, `isActive`, `windowCoversDisplay` | app: `NSApplication` (Mac); no-op on iPad |
| `AudioOutput` | play / duck / pause / cut a planned event; set gain | app: `AVAudioEngine` adapter |
| `ThemeSource` | decoded theme models + "ready" | app: bundle loader |
| `RenderSink` | receives the frame's render plan (positions, alphas, looks, draw order) | app: SpriteKit scene |
| `ResidencySink` | prefetch / release / isResident | app: Cast Rendering texture or path cache |

**The three chains** (named because a mistake there traps or loses the child):
- **Clocks:** uptime (events, frames) → play (everything in Play that must stop under a freeze) → away (`AwayClock`,
  sleep-inclusive; App Shell) → wall (Scene looks, the 1 s edge dissolve). No module reads a clock it does not name.
- **Freeze / settle:** Parent Gate → Reveal Stage (`freeze`/`resume`/`settle`) → Press Queue, Hint Letters
  (challenge; the panel signal comes from the Parent Gate), Parade, Audio plan, Scene motion.
- **`kioskModeOn`:** Settings `childLockActive` → Child Lock-in Waiting (sets Input's `kioskModeOn` at the settings
  read) → App Shell `ready` → Child Lock-in R3 → `KioskEffects.apply()`; Input's ⌘ exception reads `kioskModeOn`.

### The Android mirror (pinned for ADR-0002 and ADR-0004)
- Gradle modules `kidcore` and `morphcore`: **pure JVM, no `android.*` imports**; `app` holds the Android
  adapters. Same seams, same names.
- Clocks: uptime → `SystemClock.uptimeMillis()` / `MotionEvent.getEventTime()`; play derived the same way;
  continuous → `SystemClock.elapsedRealtime()`; wall → `System.currentTimeMillis()` + `ZoneId` →
  `{minutesOfDay, dayKey}`.
- `RandomSource`: the same `UInt64 → u` contract (`ULong` in Kotlin), one per stream as on Apple.
- `settings-record-v1` is **the same bytes** on both platforms: UTF-8 JSON, sorted keys, no whitespace, integers
  as numbers.
- Android-only gaps go to ADR-0012: DataStore vs SharedPreferences, screen pinning instead of the kiosk, gesture
  insets, xdpi/dpi for tiers and target size, audio latency, the scanCode/keyCode mapping (Input R4).

### Cross-platform contracts (for ADR-0004)

Location: `games/kid-learn-character/contracts/<name>-vN/` with `spec.md` and `cases.json`, outside `apple/`.
`morph-contract-v1` stays where it is (`docs/architecture/morph-contract-v1.md`,
`content/fixtures/morph-contract-v1.json`), because the prototype, its generator and the GDDs cite those paths;
`contracts/README.md` points to it, and it moves only with a v2.

**The current list is the K-40 registry in `contracts/README.md`** (ADR-0004 D5 note); that table, not this
document, is the source. As of v2 (2026-11-18) it has **14 rows**: 12 current contracts, all written (ADR-0004 D8),
and 2 superseded versions:

| Contract | Covers (GDD) | Registry row |
|---|---|---|
| morph-contract-v1 (lives in `docs/architecture/`) | MorphCore positions, T, phases | MorphCore's own test (not a registry row; ADR-0004 D5) |
| key-table-schema-v1 | theme files → validator verdicts (V1–V18); pick and peek with draws (§4) | runner (model + file layers) |
| settings-record-v2 | records → decoded values, defaults, migration; exact written bytes; the non-finite slider | runner |
| input-filter-v2 | normalized key/touch events + state → outcomes (chord, `kioskModeOn`, stale ⌘ release, Title and challenge routing, moon slop, `gateDigitUp`) | not-started |
| press-queue-v1 | press/tick sequences → outcomes, holdEff (F1), timeouts | not-started |
| reveal-timing-v1 | startReveal → formedS, revealLen, hasWord; stage fit F1; published boxes | not-started |
| audio-plan-v1 | E1–E12 times (owns E6–E9), F1 gain chain, F3 mash, F6 word_end | not-started |
| hint-letters-v1 | R13 draw and tick order, F1–F5, the 0 / 0.7 / 1.4 s sequence, freeze and Dimmed | not-started |
| parade-v1 | batches, F2 start, F3 positions, freeze | not-started |
| scene-look-v1 | WallClock + weather → look, lookBlend, skyMidL; F8 factors and the edge switch | not-started |
| app-shell-v1 | state machine, F3 30 min on the continuous clock, single pending start, the ready set | not-started |
| gate-logic-v1 | hold, slop, the 10 s sleep, timeout, keypad matching | not-started |
| keyboard-row-v1 | word draw, Due and change, hit rects (Keyboard Row F1–F4) | not-started |
| settings-record-v1 → v2, input-filter-v1 → v2 | superseded (K-40); kept unedited, never run | superseded-by |

**Excluded, with reasons:** Child Lock-in (Apple only; Android uses screen pinning); seeds and stardust looks
(per platform, Cast Rendering R6); render-path drawing (depends on ADR-0009; its pure formulas ride in
reveal-timing-v1 and scene-look-v1); audio graph (per platform).

**Fixture rules:**
- (a) Every number a GDD states (F-tables, worked examples, ACs) is a hand-written case, sourced
  `"gdd": "<file> <section>"`.
- (b) Generated cases come on top, marked `"generated"`, reviewed once.
- (c) When platforms disagree, **the GDD decides**.
- (d) A case file changes only with a version bump (`<name>-vN`).
- (e) `UInt64` values are decimal strings.
- (f) Cases feed **draws per stream** (`"draws": {"hints": [0.12, 0.87, …]}`, each consumed in a documented
  order), not seeds; only
  morph-contract-v1 keeps its SplitMix64 seed, because the contract specifies the generator.
- (g) Tolerances: 1e-9 s for time, 1e-6 for geometry in stage or unit space, 1e-3 for morph positions (contracted).

## Technical Requirements Baseline

(**v2:** the TR registry `docs/architecture/tr-registry.yaml` now holds the permanent IDs (84 rows, TASK-111) and is
the source for stories; `requirements-traceability.md` maps them to ADRs. The table below is v1's baseline, kept for
context, plus the keyboard row and accessibility rows v1 lacked (TASK-111 AD-2). Cite the registry, not this table.)

| TR-ID (provisional) | GDD | Requirement | Layer |
|---|---|---|---|
| TR-input-001 | input-key-filter R2–R6 | classify normalized key events: character first, position fallback, modifiers, held set, chord | KidCore |
| TR-input-002 | input-key-filter R7, F1 | touch layers and hint hit radius | KidCore |
| TR-input-003 | input-key-filter R5, R6 | kiosk ⌘ exception and the Mac chord, under `kioskModeOn` | KidCore + app |
| TR-keytable-001 | key-table-theme-data §5, §6 | bundled themes validated at build and at load; refuse unknown versions | Tools + KidCore |
| TR-keytable-002 | key-table-theme-data §4 | item pick with no immediate repeat; peek for prefetch | KidCore |
| TR-morph-001 | morphcore, morph-contract-v1 | positions within ±1e-3 of the shared fixture | MorphCore |
| TR-queue-001 | press-queue R3–R7, F1 | accept/queue/ignore, holdEff, formed once, timeout | KidCore |
| TR-settings-001 | settings-store R1–R7 | one record, atomic, per-field validation, migration | KidCore + app |
| TR-audio-001 | audio-voice R1–R4 | event schedule, no stacking speech, mash ceiling, nothing decoded on a press | KidCore + app |
| TR-audio-002 | audio-voice AC-16 | press → chime within one frame of the first answering frame on a device | app (★ device) |
| TR-cast-001 | cast-rendering R2, R11 | SVG subset → baked file; one draw interface for both render options | Tools + app |
| TR-cast-002 | cast-rendering R10, F6 | load on demand, resident cap, late-art wait that never moves the queue | KidCore + app |
| TR-cast-003 | cast-rendering F8 | per-look edge switch on skyMidL, halo, dim (K-25) | KidCore |
| TR-reveal-001 | reveal-stage R3–R5 | startReveal lengths, formed/shown, timeline, shared transforms | KidCore |
| TR-reveal-002 | reveal-stage R8 | play clock, freeze/resume/settle | KidCore |
| TR-reveal-003 | reveal-stage R10, F1 | stage fit contain-and-extend; published rects and boxes | KidCore + app |
| TR-hints-001 | hint-letters R2–R9 | spawn, clearances, life, originFor, freeze/Dimmed | KidCore |
| TR-parade-001 | parade R1–R8, F2, F3 | batches per theme, start rule, walk across the visible rect | KidCore |
| TR-gate-001 | parent-gate-panel G1–G10 | two-step gate, sleep, timeout, auto-close, confirm holds | KidCore + app |
| TR-lock-001 | child-lock-in R2–R7 | engage only after ready + R3; never trap; engage timeout | KidCore + app (★ device) |
| TR-lock-002 | child-lock-in R8 | iPad Guided Access instructions and observation | app (★ device) |
| TR-shell-001 | app-shell-title R1–R9 | launch order, Title starts, pending start, away rule, windows, memory | KidCore + app |
| TR-scene-001 | scene-time-weather R2–R9 | wall-clock looks, weather, skyMidL, caps build check, two clocks | KidCore + app |
| TR-pkc-001 | privacy-kids-compliance PKC-01…14 | no network, no SDK, no identifiers, privacy manifest, scans | Tools / CI |
| TR-kbrow-001…004 | onscreen-keyboard-row F1–F4, R12, AC-1, AC-3, AC-16 | layout, hit rect, light, word draw and change; theme words with v1 fallback; a z 35 layer on the press path; off by default, ≥ 18 mm | KidCore + app |
| TR-a11y-001…006 | accessibility A1, A10, F1, F2, F2b, AC-01–AC-16 | one Reduce Motion flag; Smart Invert opt-out; flash gate and red-flash check; palette and idle lints; 18 mm child floor; nothing stored, sent or logged | KidCore + app + Tools |

## ADR Audit

All eleven ADRs exist (v2; TASK-111 AD-1). Four are Proposed because their decision rules wait on device rows,
which the owner has put on hold; none conflicts with another (TASK-111, Cross-ADR Conflicts).

| ADR | Status | Covers | Waits on |
|---|---|---|---|
| ADR-0001 Native Apple | Accepted | stack, packages, roots, UI-free cores, stage protocol, lock-in, no network | — |
| morph-contract-v1 | Accepted (with ADR-0001) | MorphCore cross-platform math | — |
| ADR-0002 Modules, seams and types | Accepted | packages, the four clocks, `RandomSource`, Kotlin-mappable types, seams, the ban grep | — |
| ADR-0003 Content data and pipeline | Accepted | theme schema v2, bake tool, SVG subset (a1 layer ids, K-37), validator V1–V18, voice durations, TTS pre-render | — |
| ADR-0004 Contracts, fixtures, harness | Accepted | the contract list and rules, the harness on both platforms, the K-40 registry and not-started state | — |
| ADR-0005 Settings persistence (Apple) | Accepted | one canonical record under one `UserDefaults` key, CA92.1, backups | — |
| ADR-0006 Stage runtime | Accepted | composition, frame driver (≤ 60 fps), stage fit, windows, Smart Invert, Reduce Motion, ppi | — |
| ADR-0007 Input adapters | **Proposed** | reader → mapper, key ids, the synchronous disposition, `KeyStateQuery` only if M-1 passes, touches | M-1, M-2, M-3, P-15, P-4 |
| ADR-0008 Kiosk and lock-in | **Proposed** | borderless window preferred, the options set, the key-able window, covers, activation, Guided Access | M-3–M-7, P-4 |
| ADR-0009 Render path | **Proposed** | A (live paths, A-candidate) vs B (textures; B-load preferred) or a mix, by TASK-075's fixed rule | P-2, M-13 (H-2 done headless) |
| ADR-0010 Audio engine | **Proposed** | `.soloAmbient`, the graph, no-click cut and freeze, interruptions, latency split | P-1, P-7, P-8, P-9, M-14 |
| ADR-0011 Build, verify, PKC | Accepted | gates vs observations, `verify.sh`, `pkc-scan.sh`, simulator guards, evidence | — |

## Required ADRs

v2 status (TASK-111 review). Any run on Luan's Mac needs the leader's MAC FREE; iPad runs use a Personal Team build
(K-28 Q2).

| # | Item | Status | Next |
|---|---|---|---|
| 1 | ADR-0002, 0003, 0004, 0005, 0006, 0011 | **Done** (Accepted) | — |
| 2 | ADR-0007, ADR-0008 ★ | Proposed | accept after M-1…M-7, P-4, P-15 (TASK-111 B-1) |
| 3 | ADR-0009, ADR-0010 ★ | Proposed | accept after P-2, M-13 and P-1, P-7, P-8, P-9, M-14 (TASK-111 B-1) |
| 4 | Flash safety gate (TR-a11y-003): where Accessibility F2 and F2b run, and that a FAIL blocks a release candidate | **Needed** (TASK-111 B-3) | an ADR-0011 amendment or a small ADR; with it the F1 / A5 lints (TR-a11y-004) and hint-knob validation |
| 5 | Grown-up panel accessibility (VoiceOver, Dynamic Type, target sizes; TR-gate-006) | Advisory (TASK-111) | an ADR or the panel story |
| 6 | iPad presentation (`edgeDeferral`, status bar, home indicator; TR-shell-004) | **Covered by an ADR-0006 dated note** (K-42) | — |
| 7 | ADR-0012 Android | Later | Kotlin modules, adapters, the Android gaps listed above (TASK-111 AD-4: nothing writes it yet) |

## The First Scaffold Story (described here; not created in TASK-059)

**v2: done.** TASK-079 built it and merged as a4adca84 (QC's `--qc` evidence PASS, df6a154e): the packages, the app
targets, the ban grep, `verify.sh` and `pkc-scan.sh`, the contract harness with the K-40 registry, and the headless
Title screenshot. The Mac launch, the first signed build and the macOS UI test wait for MAC FREE. The goal as
written in v1 follows, unchanged.

**Goal:** the `apple/` skeleton that every later story builds on.
- One Xcode multiplatform project under `apple/` (iPadOS + macOS, deployment 26); local packages `apple/KidCore`
  and `apple/MorphCore` (MorphCore as its own package, so Android mirrors the name); app target; unit tests
  `apple/KidCore/Tests`, `apple/MorphCore/Tests`, `apple/<App>Tests`; UI tests `apple/<App>UITests`.
- **It must prove:**
  - (a) `xcodebuild` builds for the iPad Simulator (the dev simulator, never QC's E9F515E9…) and for macOS;
  - (b) `swift test` passes for `KidCore` and `MorphCore`;
  - (c) the contract harness runs: `morph-contract-v1` cases pass within ±1e-3, and the harness picks up any
    `contracts/<name>-vN/cases.json` present;
  - (d) the import and type check: `KidCore` and `MorphCore` import only the Swift standard library and
    Foundation, and use none of `Date`, `Calendar`, `Decimal`, `UUID`, `Duration`, `JSONDecoder` or JSON `Codable`
    (an allowlist grep in the build);
  - (e) a PKC baseline: no network entitlement; a `PrivacyInfo.xcprivacy` skeleton with `CA92.1` and `35F9.1`;
  - (f) it launches to a blank Title, observed with a retained screenshot on the Simulator
    (`production/qa/evidence/`); the Mac launch only after MAC FREE.

## Open Questions

- ~~The iPadOS full-screen claim~~ **v2: closed.** ADR-0006 D4 (Accepted) decides the window rules; K-39 allows
  every orientation and window shape with contain-and-extend (App Shell R7). Its device row is P-11.
- **One owner per fixture case:** each number lives in exactly one contract (audio-plan-v1 owns the E6–E9 times;
  reveal-timing-v1 owns the startReveal outputs, stage fit and the boxes).
- ~~The On-screen Keyboard Row has no contract yet~~ **v2: closed.** keyboard-row-v1 is written (36 cases,
  not-started in the registry).
- ~~Seam names are provisional until ADR-0002~~ **v2: closed.** ADR-0002 D3, D6 fix them (Accepted).
- **v2, open:** the flash-safety gate's home (Required ADRs #4); ADR-0012 (#7).
- The ★ ADRs cannot be decided until their device runs; their GDD rules are written to work with every option.
