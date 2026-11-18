# ADR-0002: Module layout, seams and Kotlin-mappable types

## Status

Accepted (Luan, 2026-11-18; recorded by game-leader on Luan's explicit acceptance)

> **Who may move this to `Accepted`: the user, or `technical-director` on the
> user's explicit confirmation. No other agent, and no skill on its own.**

## Date

2026-11-18

## Last Verified

2026-11-18, against `docs/architecture/architecture.md` (v1, TASK-059), ADR-0001 (Accepted), morph-contract-v1,
the 15 Approved GDDs and `docs/engine-reference-local/native-apple/`.

## Decision Makers

Luan (accepts); game-dev-ios (author, TASK-063); game-dev-android (plan and independent review, the Kotlin mirror);
game-leader.

## Summary

The toy's rules must be testable without a device and reproducible by a later Kotlin app, so their code may not
lean on Apple types. This ADR fixes the four packages and their dependency direction, the Kotlin-mappable type
rules enforced by a build check, the four injected clocks (plus the play clock derived in `KidCore`), one
`RandomSource` per random stream, the normalized input events, the protocol seams to the platform, and the three
call chains that must never be reordered.

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | None from the template's table (`engine.name` unset, ADR-0001, K-28). Swift 6.4, Xcode 27.1, SDKs iOS 27.1 / macOS 27.0, deployment 26 |
| **Domain** | Core |
| **Layer** | Foundation |
| **Knowledge Risk** | LOW for the decisions here: plain Swift value types and Swift packages. MEDIUM for one input to D6 (`DisplayMetrics.ppi`, see Risks) |
| **References Consulted** | `docs/engine-reference-local/native-apple/VERSION.md`, `current-best-practices.md` (Structure, Frames and time), `modules/privacy-manifest.md`; `docs/architecture/architecture.md` |
| **Post-Cutoff APIs Used** | None in `KidCore`/`MorphCore`. The app adapters' APIs are each owned by their own ADR (0005–0010) |
| **Verification Required** | The scaffold story's checks in Validation Criteria |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0001 (Accepted); morph-contract-v1 (Accepted with ADR-0001) |
| **Enables** | ADR-0004 (behaviour contracts and fixtures), ADR-0003 (content data and pipeline), the first scaffold story, and every later ADR's seam references (0005–0012) |
| **Blocks** | The scaffold story and every `KidCore` story (they cite these seams and type rules) |
| **Ordering Note** | Written first in architecture.md's Required ADRs; 0004 follows, then 0003 |

## Context

### Problem Statement
`architecture.md` placed every rule in two UI-free packages and named the seams to the platform, but left the
names, the exact type rules and the enforcement to this ADR. Without them, the first stories would pick types by
habit (`Date`, `Set`, `Float`, locale case maps, banker's or platform rounding) that a Kotlin port cannot
reproduce byte for byte, and fixtures would stop agreeing across platforms.

### Current State
ADR-0001 fixed the stack, the `apple/` root and "the cores stay UI-free". The TASK-033 spike's `MorphCore` package
is the only built core; it already follows the contract. No `KidCore` code exists.

### Constraints
- Native Swift now, native Kotlin later (K-03); the same rules on both (Principle 2).
- No third-party code (PKC-03); nothing about the child stored or logged (Settings Store R2, PKC-14).
- Swift `Int` is 64-bit; Kotlin `Int` is 32-bit. Kotlin's `round` is half-even.

### Requirements
- Every rule testable with injected time and chance, deterministically.
- Every cross-platform number reproducible from a case file (ADR-0004).
- Platform types confined to the app layer and the tools.

## Decision

### D1. Packages and dependency direction
- `apple/MorphCore` — its own Swift package: morph-contract-v1 and the timing-spec loader. Depends on nothing.
- `apple/KidCore` — every other rule (architecture.md, Module Ownership). Depends on `MorphCore` only.
- `apple/<App>` — the multiplatform app target (SwiftUI shell, SpriteKit, the adapters). Depends on both.
- `apple/Tools` — macOS command-line tools (bake tool, content validator, voice durations, loudness, TTS
  pre-render, the API-surface generator). Depend on `KidCore` and `MorphCore`; nothing they produce is code in the
  bundle.
- Dependencies point down only. Platform types (UIKit, AppKit, SwiftUI, SpriteKit, AVFoundation, CoreGraphics
  types, JSON coding) appear only in `<App>`, `<App>Tests`, `<App>UITests` and `Tools`.
- *Note 2026-11-18 (K-38, TASK-079):* `apple/ContractKit` is a test-only package (fixture loading and JSON
  decoding for the contract harnesses, ADR-0004). Only test targets depend on it; it is never linked into `<App>` or
  a core. The ban grep (V1) covers it with the **import and platform rule only**: it may import Foundation, Swift,
  XCTest, Testing, `KidCore` and `MorphCore`, and no app, UI or platform-media framework and nothing from the app. The
  D2 type, JSON-coding, String and rounding bans do not apply to it, since decoding JSON is its job and it never ships.
  This adds no module to the bundle; the status stays Accepted.

### D2. Kotlin-mappable types in `KidCore` and `MorphCore`
- **Imports:** the Swift standard library and `Foundation` only.
- **Time:** `Double` seconds. **Banned:** `Date`, `Calendar`, `Decimal`, `Duration`, `DispatchTime`.
- **Integers:** `Int` only for values that fit in 32 bits (counts, indexes, `dayKey` yyyymmdd). `Int64` where a
  value may not fit (byte sizes, long counters). `UInt64` only in `RandomSource`, in `MorphCore`'s contract types
  (SplitMix64, morph-contract-v1 seeds) and in the morph-seed derivation from (key, revealId). **Banned:** `Float`,
  `CGFloat`, `Int32`, `Int8` (and the other sized integers).
- **Text:** `String` for every key and character; **`Character` is banned**. Case folding uses one ASCII-only
  helper per core (`asciiUppercased`); **banned:** `uppercased(with:)`, `localizedUppercase`, and Unicode-aware
  `uppercased()` / `lowercased()`.
- **String inspection** goes only through `unicodeScalars` or `utf8`, via helpers (`asciiLetters(_:)`,
  `scalarCount(_:)`), because iterating a `String` yields `Character`s (grapheme clusters, unlike Kotlin's UTF-16
  `Char`s). **Review rule:** no `.count`, `.first`, `.last` or `for … in` directly on a `String` in the cores; the ban
  grep catches `.count` on the key-typed names it can see (`key.count`, `character.count`, `word.count`). This
  matters for Input AC-4 ("one character") and Key Table V17 ("2–8 letters").
- **Ids:** `Int` or `String`. **Banned:** `UUID`.
- **Data:** plain value types (`struct`, raw-value `enum`, arrays, `Int`, `Double`, `String`, `Bool`). JSON is
  decoded at the edge (app or Tools). **Banned:** `JSONDecoder`, `JSONEncoder` and JSON `Codable` conformances in
  the cores.
- **Order:** no output may depend on `Set` or `Dictionary` iteration order. Ordered state (the held set, hint
  slots, player pools, touch batches) is an array or explicitly sorted. A review rule, plus contract cases that
  shuffle inputs (ADR-0004).
- **Rounding:** one `roundHalfAwayFromZero(_:)` helper per core (Settings Store F1's rule). **Banned:** every
  other rounding call (`.rounded(...)` outside the helper, `round`, `lround`, `rint`). The Kotlin port implements
  the same helper (its `round` is half-even).
- **Concurrency:** none inside the cores. The app calls them on the main thread; its own queues run adapters (the
  theme load off the main thread calls pure validation).

### D3. Clocks
| Clock | Seam | Counts | Read by | Apple | Android |
|---|---|---|---|---|---|
| Uptime | `UptimeClock.now() → Double` | awake time since boot | Input (event times), the frame tick, Press Queue | event `timestamp`; display link `targetTimestamp`; `ProcessInfo.systemUptime` | `SystemClock.uptimeMillis()` / `getEventTime()`; Choreographer `frameTimeNanos` converted to uptime |
| Play | derived in `KidCore`: `play = uptime − frozenTotal` (Reveal Stage R8) | uptime minus gate-freeze and background time | everything in Play that must stop under a freeze (Reveal Stage, Press Queue, Hint Letters, Parade, Audio plan, Scene motion, Cast Rendering idles) | — (never computed by the app) | — |
| Away | `AwayClock.now() → Double` | includes device sleep | App Shell "away" (R6, F3) | Swift `ContinuousClock` / `mach_continuous_time` | `SystemClock.elapsedRealtime()` |
| Wall | `WallClock.now() → {minutesOfDay: Double, dayKey: Int}` | local civil time | Scene looks (F1), Cast Rendering's 1 s edge dissolve | the local calendar and time zone, converted at the edge | `System.currentTimeMillis()` + `ZoneId` |

Each module names the clock it reads; no module reads one it does not name.

### D4. `RandomSource`, one per stream
- `protocol RandomSource { mutating func next() -> UInt64 }`; a draw is `u = Double(x >> 11) · 2⁻⁵³` (Key Table's
  rule), via one helper.
- **Streams**, each with its own injected source and its own seed, logged through `DebugLog` in debug builds: the
  Key Table variety pick; Hint Letters (key, slot, jitter, life, phase); the On-screen Keyboard Row; the morph seed
  from (key, revealId) (MorphCore Rule 5). One stream's draws never shift another's.
- Seeding is per platform. Tests and fixtures inject a **draw list per stream**. MorphCore's SplitMix64 inside
  morph-contract-v1 is unchanged.

### D5. Normalized events
```
KeyEvent   { character: String?, positionKey: String?,      // "A"–"Z", "0"–"9", or nil
             modifiers: Int,                                  // bitmask: shift, caps, ctrl, alt, cmd, fn, numLock
             isRepeat: Bool, physicalId: String,             // opaque, per platform
             kind: down | up | cancel | modifiersChanged,     // modifiersChanged carries the new mask
             time: Double }                                  // uptime
TouchEvent { pointerId: Int, phase: began | moved | ended | cancelled,
             xPx: Double, yPx: Double,                       // window pixels
             time: Double }                                  // uptime
```
`KidCore` converts touch pixels to stage units through Reveal Stage F1 and point-based slop (`moon_slop_pt`)
through `DisplayMetrics.pxPerPt`. The adapters own every platform mapping (UIKey/HID, NSEvent, KeyEvent/scanCode). A `modifiersChanged` event (macOS
`flagsChanged`, Android meta-state changes) lets Input's ⌘-release rule (Input I1) live in `KidCore`, not in an
adapter.

### D6. Seams (final names)
| Seam | Shape | Apple implementation |
|---|---|---|
| `SettingsBackend` | `read() → [UInt8]?`, `write([UInt8]) → Bool?` (nil when the platform cannot report), `remove()` | `UserDefaults`, one key (ADR-0005) |
| `KioskEffects` | `apply()`, `remove()`, `coverDisplays(Bool)`, `isActive: Bool`, `windowCoversDisplay: Bool` | `NSApplication` (ADR-0008); a no-op on iPad |
| `AudioOutput` | the audio-plan sink: `play(event)`, `duck(bus, to, over)`, `pause()`, `resume()`, `cut(player, fade)`, `setGain(Double)` | `AVAudioEngine` adapter (ADR-0010) |
| `RenderSink` | receives one render plan per frame (positions, alphas, looks, draw order) | SpriteKit scene (ADR-0006, 0009) |
| `ResidencySink` | `prefetch(id)`, `release(id)`, `isResident(id) → Bool` | the Cast Rendering cache (ADR-0009) |
| `ThemeSource` | decoded theme models; `ready(themeId)` | the bundle loader (ADR-0003) |
| `DisplayMetrics` | `windowPx`, `pxPerPt`, `safeAreaInsetsPx`, `ppiX`, `ppiY`, `gestureInsetsPx` (live) | window and screen values; ppi from a device table (Risks) |
| `AccessibilityState` | `reduceMotion` (read live), `guidedAccessEnabled` | `UIAccessibility` / `NSWorkspace` accessibility |
| `AppLifecycle` (events into `KidCore`) | foreground / background, active / inactive, window key gained / lost, screen parameters changed, memory warning | scene and app delegates |
| `DebugLog` | `log(line: String)`; the one-line logs and per-stream seed logs | `Logger` at `.debug` level; nothing to disk; release builds log no child input (PKC-14) |
| `KeyStateQuery` (optional) | `anyNonModifierDown(except physicalId: String) → Bool`; the adapter enumerates the platform key codes, which `KidCore` cannot know | the Mac OS key state, wired only if Input AC-1k6 passes (ADR-0007); otherwise absent and Input uses the ⌘-release rule |
| Frames | no protocol: one entry point `tick(now:)` on the uptime clock | display link `targetTimestamp` |

### D7. The three chains (call orders that must not change)
1. **Clocks:** uptime → play (derived) → away → wall, as in D3.
2. **Freeze / settle:** Parent Gate → Reveal Stage `freeze()` / `resume()` / `settle()` → Press Queue, Hint Letters
   (the challenge; the panel signal comes from the Parent Gate), Parade, Audio plan (`AudioOutput.pause`/`resume`),
   Scene motion.
3. **`kioskModeOn`:** the settings read → Child Lock-in Waiting (if `childLockActive`), which sets Input's
   `kioskModeOn` → App Shell `ready` (first frame, chord installed, window covers its display) → Child Lock-in R3
   → `KioskEffects.apply()`. `kioskModeOn` is **cleared on Off** (including Off after the engage timeout, Child
   Lock-in R7). It has three readers: Input's ⌘ exception, Child Lock-in itself, and the Parent Gate's panel, which
   shows Quit while it is on (G7; TASK-056 W-1).

### D8. The Android mirror
- Gradle modules `kidcore` and `morphcore`: **pure JVM, no `android.*` imports**, with the D6 seam names; `app`
  holds the Android adapters.
- Clocks: D3's Android column. `RandomSource` returns `ULong`, with the same `u` rule.
- `settings-record-v1` is the **same bytes** on both platforms (UTF-8 JSON, sorted keys, no whitespace, integers
  as numbers).
- Android-only gaps are ADR-0012's: DataStore vs SharedPreferences, screen pinning, gesture insets, xdpi/dpi,
  audio latency, the scanCode/keyCode mapping.

### Architecture Diagram
```
apple/<App>  ──depends──▶  apple/KidCore  ──depends──▶  apple/MorphCore
   │  adapters implement D6 seams             ▲
   ▼                                          │ (validator, parser)
 platform SDKs                          apple/Tools (build time only)
```

### Key Interfaces
D3 (clocks), D4 (`RandomSource`), D5 (events) and D6 (seams). The public surface of both cores is committed as
`contracts/kidcore-api.md` and `contracts/morphcore-api.md` (Validation Criteria), so the Kotlin port can diff
against it.

### Implementation Guidelines
- `KidCore` and `MorphCore` **must** import only the Swift standard library and `Foundation`.
- They **must never** use the D2 banned types or calls; the build check enforces it.
- Every `KidCore` type that needs time or chance **must** take it from a D3 clock or a D4 stream, injected.
- Platform code **must** stay in `<App>` or `Tools`; a seam is added here (by a new or superseding ADR), never by
  an adapter reaching into the core.
- Output **must never** depend on `Set` or `Dictionary` order; use arrays or an explicit sort.
- All rounding **must** go through `roundHalfAwayFromZero`; all case folding through `asciiUppercased`.

## Alternatives Considered

### Alternative 1: One package for both cores
- **Description**: `MorphCore` as a target inside `KidCore` (ADR-0001 allowed it).
- **Pros**: one package to build.
- **Cons**: the Android module names would not mirror; the morph contract's isolation (its own versioned fixture)
  is weaker.
- **Estimated Effort**: slightly less.
- **Rejection Reason**: the Kotlin mirror and contract isolation matter more.

### Alternative 2: Foundation time types in the cores
- **Description**: `Date` / `TimeInterval` / `Duration` and `Calendar` for wall time.
- **Pros**: idiomatic Swift.
- **Cons**: no 1:1 Kotlin mapping; freeze arithmetic and fixtures need plain numbers; time-zone handling would leak
  into the rules.
- **Estimated Effort**: similar.
- **Rejection Reason**: Kotlin mapping and fixture comparability.

### Alternative 3: One global random generator
- **Description**: a single seeded RNG for every random choice.
- **Pros**: one seed to log.
- **Cons**: a change in one system's draw count shifts every other system's results; fixtures cannot isolate a
  stream.
- **Estimated Effort**: less.
- **Rejection Reason**: cross-platform cases would not line up.

## Consequences

### Positive
- Every rule is testable with `swift test`, deterministically, with no device.
- The Kotlin port has a fixed type map, a fixed seam list and a committed API surface to diff against.
- The build check turns the type rules into a failing build, not a review comment.

### Negative
- Small helpers replace standard calls (`asciiUppercased`, `roundHalfAwayFromZero`, the `u` rule), and wall time
  is converted at the edge.
- More protocols at the edge; each adapter is a little boilerplate.

### Neutral
- `MorphCore` is already compliant (TASK-033/035), except that its future code also passes the ban grep.

## Risks
- **Apple ppi is NOT SOURCEABLE.** No public API gives an Apple screen's pixel density, so `DisplayMetrics.ppiX/Y`
  comes from a bundled device-model table until ADR-0006 sources it. **Unknown model:** use a conservative ppi
  that makes physical targets **larger, never smaller** (~~the lowest ppi in the table for that device class~~), and
  write one `DebugLog` line naming the model. Android reads `xdpi`/`ydpi`.
  - *Amendment 2026-11-18 (K-34, Luan; status unchanged, Accepted):* the direction above was inverted. The rule is
    **assume the HIGHEST ppi in the device class, so physical targets never shrink** (a target of M mm is drawn as
    M × ppi_assumed / 25.4 px, so assuming a lower ppi than the real one would make it smaller). ADR-0006 D7 is the
    detailed rule (the iPad table, the Mac `CGDisplayScreenSize` path, the 72 dpi no-EDID case).
- **The ban grep misses a case** (a type alias, a new API). Mitigation: the committed API surface and code review;
  the grep list grows by ADR revision.
- **Iteration order slips in through a library call.** Mitigation: contract cases that shuffle inputs (ADR-0004).
- **`Int` overflow on Kotlin** for a value assumed to fit in 32 bits. Mitigation: D2's rule plus range checks in the
  content validator and the settings validation.

## GDD Requirements Addressed

TR-IDs are **provisional** (architecture.md's baseline; the registry is empty until `/architecture-review`).

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|--------------------------|
| morphcore.md, morph-contract-v1 | TR-morph-001: positions within ±1e-3 of the shared fixture | D1 own package; D2 plain types; D4 keeps SplitMix64 inside the contract |
| input-key-filter.md R2–R6, R8 | TR-input-001: classify keys by character, position, modifiers, held set | D5 `KeyEvent`; D2 String keys with ASCII folding; arrays for the held set |
| input-key-filter.md R5, R6 | TR-input-003: kiosk ⌘ exception under `kioskModeOn` | D7 chain 3; D6 `KeyStateQuery` optional |
| reveal-stage.md R8 | TR-reveal-002: play clock, freeze / resume / settle | D3 play clock derived in `KidCore`; D7 chain 2 |
| reveal-stage.md R10, F1 | TR-reveal-003: stage fit, published rects | D6 `DisplayMetrics`; D5 touches in window px converted by F1 |
| app-shell-title.md R6, F3 | TR-shell-001: "away" counts device sleep | D3 `AwayClock`; D6 `AppLifecycle` |
| scene-time-weather.md R2, F1 | TR-scene-001: looks from the local wall clock | D3 `WallClock` {minutesOfDay, dayKey} |
| settings-store.md R1–R7, F1 | TR-settings-001: one record, atomic, F1 rounding | D6 `SettingsBackend`; D2 `roundHalfAwayFromZero`; D8 same bytes |
| child-lock-in.md R2–R7 | TR-lock-001: engage only after ready + R3 | D6 `KioskEffects`; D7 chain 3 |
| key-table-theme-data.md §4 | TR-keytable-002: the variety pick | D4 its own stream |
| hint-letters.md R3–R6, F5, R11 | TR-hints-001: hint draws; target size in mm | D4 its own stream; D6 `DisplayMetrics` (ppi, gesture insets) |
| cast-rendering.md R10, F6 | TR-cast-002: load on demand, residency | D6 `ResidencySink` |
| audio-voice.md R1–R6 | TR-audio-001: the event schedule, freeze pause | D6 `AudioOutput`; D7 chain 2 |

## Performance Implications
- **CPU**: negligible; plain value types and protocol calls. The frame entry is one `tick(now:)`.
- **Memory**: negligible.
- **Load Time**: none.
- **Network**: none (PKC-01).

## Migration Plan
None: no `KidCore` code exists. The TASK-033 `MorphCore` package moves into `apple/MorphCore` with the scaffold
story and must pass the ban grep there.

## Validation Criteria
The scaffold story implements and must pass:
1. **Ban grep** over `KidCore/Sources` and `MorphCore/Sources`, failing the build with file and line, for: imports
   other than the Swift standard library and `Foundation`; `Date`, `Calendar`, `Decimal`, `Duration`,
   `DispatchTime`, `UUID`; `JSONDecoder`, `JSONEncoder`, JSON `Codable`; `Character`, `Float`, `CGFloat`, `Int32`,
   `Int8`; `UInt64` outside `RandomSource`, the `MorphCore` contract types and the morph-seed derivation;
   `key.count`, `character.count`, `word.count` (use the scalar helpers); `.uppercased(with:`, `localizedUppercase`, `.uppercased()` / `.lowercased()` outside the ASCII helper;
   `round(`, `lround(`, `rint(`, `.rounded(` outside `roundHalfAwayFromZero`. A planted `Date`, `UIKit` import and
   `Character` each fail it; the clean tree passes.
2. **Rounding test:** `roundHalfAwayFromZero` gives 2.5 → 3, −2.5 → −3, 7.5 → 8, 0.5 → 1; Settings F1's cases
   (slider 7.4 → 7, 7.5 → 8, 0.4 → 0; read 6.6 → 7). The same cases go into settings-record-v1 (ADR-0004).
3. **Clocks and streams:** a test drives all four clocks and two independent draw lists through one `KidCore`
   type, and shows that adding a draw to one stream leaves the other's results unchanged.
4. **Committed API surface:** `contracts/kidcore-api.md` and `contracts/morphcore-api.md`, generated from the
   symbol graph by a Tools command; the build fails if they are stale.
5. **Not required now:** a Linux / Foundation-only build of the cores (noted for ADR-0011).

## Related
- `docs/architecture/architecture.md` (Module Ownership, API Boundaries, Required ADRs).
- ADR-0001 (stack, roots, UI-free cores); morph-contract-v1.
- `docs/registry/architecture.yaml` (the stances this ADR registers).
- Decisions K-03, K-11, K-15–K-28.
