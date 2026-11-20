# Control Manifest

> **Engine**: none from the studio's engine table (`engine.name` unset on purpose, ADR-0001 D7). Native Apple:
> Swift 6.4, SwiftUI + SpriteKit + AVFoundation, Xcode 27.1, SDKs iOS 27.1 / macOS 27.0, deployment iPadOS 26 /
> macOS 26.
> **Last Updated**: 2026-11-20
> **Manifest Version**: 2026-11-20
> **ADRs Covered**: ADR-0001, ADR-0002, ADR-0003, ADR-0004, ADR-0005, ADR-0006, ADR-0011, ADR-0013 (Accepted).
> **Pending (Proposed, provisional)**: ADR-0007, ADR-0008, ADR-0009, ADR-0010, in § Pending rules only.
> **Status**: Active — regenerate with `/create-control-manifest update` when an ADR is accepted or revised.

A programmer's rules sheet: what to do and what never to do, per layer. The ADR says *why*; open it by the cited
decision (`ADR-0002 D2` = ADR-0002's Decision D2; `Alt N` = its Alternatives Considered). Stories embed the
Manifest Version; `/story-readiness` flags a story written against an older one. Naming conventions:
[`coding-conventions.md`](coding-conventions.md). TASK-131 (game-dev-ios); review game-dev-android.

**Not in this manifest as settled rules:** ADR-0007 (input adapters), ADR-0008 (kiosk), ADR-0009 (render path),
ADR-0010 (audio engine) are **Proposed**. Their rules are in § Pending: build behind the named seams, never hard-wire
an undecided option, and expect changes when their device rows close. No `docs/engine-reference/` folder exists for
this stack, so there is no deprecated-API table; deprecations are listed per ADR below.

---

## Foundation layer

*Modules, cores, types, clocks, randomness, content data and validator, contracts, settings.*

### Required patterns
**Project and modules**
- One Xcode multiplatform project under `apple/` for iPadOS and macOS; minimum deployment iPadOS 26 / macOS 26
  (ADR-0001 D2). Every task brief names its root, `apple/` (ADR-0001 D3).
- Modules: `apple/MorphCore` (depends on nothing), `apple/KidCore` (depends on `MorphCore` only), `apple/<App>`
  (SwiftUI shell, SpriteKit, adapters; depends on both), `apple/Tools` (macOS command-line tools), `apple/ContractKit`
  (test-only; only test targets depend on it). Dependencies point down only (ADR-0002 D1).
- Platform types (UIKit, AppKit, SwiftUI, SpriteKit, AVFoundation, CoreGraphics, JSON coding) appear only in
  `<App>`, `<App>Tests`, `<App>UITests` and `Tools` (ADR-0002 D1).
- Key table loader, mash queue, key filter and morph live in the Swift packages, run as plain unit tests
  (ADR-0001 D4). `MorphCore` follows `docs/architecture/morph-contract-v1.md`; its fixture
  `content/fixtures/morph-contract-v1.json` passes within ±1e-3 (ADR-0001 D4).
- Commit the cores' public surface as `contracts/kidcore-api.md` and `contracts/morphcore-api.md` (ADR-0002 Key
  Interfaces).

**Types inside `KidCore` / `MorphCore`** (ADR-0002 D2)
- Import only the Swift standard library and `Foundation`.
- Time is `Double` seconds. `Int` only for values that fit in 32 bits; `Int64` where a value may not fit; `UInt64`
  only in `RandomSource`, `MorphCore` contract types and the morph-seed derivation; `UInt8` only for byte arrays
  (`SettingsBackend`'s `[UInt8]`, ADR-0005 D2; on the ban grep's allowlist).
- Keys and characters are `String`; case folding only through the one ASCII helper `asciiUppercased`; inspect
  strings only via `unicodeScalars` / `utf8` helpers (`asciiLetters(_:)`, `scalarCount(_:)`).
- Data are plain value types (`struct`, raw-value `enum`, arrays, `Int`, `Double`, `String`, `Bool`); theme and
  content JSON is decoded at the edge (app or Tools) (ADR-0002 D2, ADR-0003 D7). The one JSON code in `KidCore` is
  the settings record's hand-written canonical reader and writer (ADR-0004 D3, ADR-0005 D1).
- Ordered state is an array or explicitly sorted; all rounding goes through one `roundHalfAwayFromZero(_:)` per core.
- No concurrency inside the cores; the app calls them on the main thread.

**Clocks, randomness, events, seams**
- Clocks per ADR-0002 D3: `UptimeClock`, play = uptime − frozenTotal derived in `KidCore` (never by the app),
  `AwayClock`, `WallClock` `{minutesOfDay, dayKey}`; each module names the clock it reads and reads no other.
- `protocol RandomSource { mutating func next() -> UInt64 }`; one stream per source, each with its own seed; a draw
  is `Double(x >> 11) · 2⁻⁵³` through one helper (ADR-0002 D4). Streams: key variety, hints, keyboard row, morph seed
  (ADR-0002 D4), plus gate code and scene weather (ADR-0004 D2).
- Every `KidCore` type needing time or chance takes it injected from a D3 clock or D4 stream (ADR-0002 Impl.).
- Use `KeyEvent` and `TouchEvent` exactly as ADR-0002 D5 defines them; adapters own every platform mapping.
- Seams, final names: `SettingsBackend`, `KioskEffects`, `AudioOutput`, `RenderSink`, `ResidencySink`,
  `ThemeSource`, `DisplayMetrics`, `AccessibilityState`, `AppLifecycle`, `DebugLog`, optional `KeyStateQuery`; one
  per-frame entry `tick(now:)` on the uptime clock (ADR-0002 D6). A new seam only by a new or superseding ADR.
- Keep ADR-0002 D7's call orders (clocks; freeze/settle; `kioskModeOn` engage) exactly.

**Content** (ADR-0003; the format is the Key Table GDD)
- `content/` layout per ADR-0003 D1; file names use the theme's `assetPrefix` (Dinosaurs `dino`); paths relative,
  lowercase, forward slashes, exact case (ADR-0003 D1).
- Theme schema v2 per Key Table §2; an unknown field or unknown major `schemaVersion` fails as V1, at build (build
  fails) and at load (theme not used, Dinosaurs fallback) (ADR-0003 D2).
- The V-rules are written once, in `KidCore`, as pure functions over decoded models and the `ContentProbe` seam;
  Tools and the app call them, never copy them (ADR-0003 D3, Impl.).
- The app validates a theme at load, off the main thread, with a bundle probe; a failing theme is never shown
  (ADR-0003 D3).
- `KidCore` receives plain models (`Theme`, `KeyEntry`, `Item`, `GlyphSet`, knob data); a decode error is a theme
  failing V1/V2, never a crash (ADR-0003 D7).
- Keys, pictures, sounds, spoken lines, theme packs and tuning values are bundled JSON data (ADR-0001 D6); a reduced
  timing set in the same data, chosen by Reduce Motion (ADR-0001 D6).
- Only ADR-0003 D1's shipped files ship (ADR-0003 D8).

**Contracts and tests** (ADR-0004)
- Each contract in `contracts/<name>-vN/` with `spec.md`, `cases.json`, `sources.lock`; `contracts/README.md`'s
  `## Registry` is the only contract list (ADR-0004 D1, D5 note). Read a superseded v1 as its v2 (ADR-0004 D1 note).
- Every runner calls only the public API of the core it tests; `ContractHarness` lives in
  `apple/KidCore/Tests/ContractTests` (ADR-0004 D5, Key Interfaces).
- Cases: one time per step `t.uptime`; draws as raw `UInt64` decimal strings per stream; `expect` compared as an
  ordered list; tolerances per field kind (time 1e-9 s, geometry 1e-6, morph 1e-3), an override only with a
  `toleranceReason` citing a GDD or ADR (ADR-0004 D4).
- Hand-written cases come from the GDDs (`"source": "gdd: <file> <section>"`), written by QC independently of the
  implementer; generated cases only on top, reviewed once (ADR-0004 D4, D7).
- A dev runs `swift test` for the package they touch before a PR (ADR-0004 D7).
- Order of work: the harness scaffold, then key-table-schema and settings-record, then each system's contract cases
  first, test-first by QC (ADR-0004 D8).

**Settings** (ADR-0005)
- One value under the key `"settings"` in `UserDefaults.standard`: the exact UTF-8 bytes of `KidCore`'s hand-written
  canonical writer; `read()` returns them byte for byte (ADR-0005 D1, D2).
- `write` returns nil on Apple; all backend calls on the main thread; one synchronous read at launch, before the
  first frame (ADR-0005 D2, D9).
- The writer serializes the stored `childLock`, never `childLockActive`; a record holds `"childLock":true` or no key;
  turning the lock off writes nothing (ADR-0005 D4).
- Turn off window-frame autosave and window/scene state restoration (ADR-0005 D5).
- Privacy manifest: `NSPrivacyAccessedAPICategoryUserDefaults` with `CA92.1` only (ADR-0005 D6).

**Privacy and dependencies**
- No network: no network call, no location; the macOS app has no `com.apple.security.network.client`
  (ADR-0001 D8).
- No third-party runtime or SDK enters the app without its own ADR (ADR-0001 D8).
- `DebugLog` uses `Logger` at `.debug`, nothing to disk; release builds log no child input (ADR-0002 D6, PKC-14).

### Forbidden approaches
- **Never write code under `src/`, never import `prototypes/` code** — the app is built fresh (ADR-0001 D3).
- **Never put a UI or platform import in `KidCore`/`MorphCore`** (ADR-0002 D1).
- **Never use in the cores** (ADR-0002 D2; enforced by the ban grep, ADR-0011 D4 step 1): `Date`, `Calendar`,
  `Decimal`, `Duration`, `DispatchTime`; `Float`, `CGFloat`, `Int32`, `Int8` or other sized integers (except
  `UInt64`/`Int64` where allowed and `UInt8` for byte arrays); `Character`; `uppercased(with:)`,
  `localizedUppercase`, Unicode-aware `uppercased()`/`lowercased()`; `UUID`; `JSONDecoder`, `JSONEncoder`, a JSON
  library or JSON `Codable`; `.rounded(...)` outside the helper, `round`, `lround`, `rint`.
- **Never, by review** (ADR-0002 D2; not grep-enforced): `.count`, `.first`, `.last` or `for … in` directly on a
  `String` in the cores.
- **Never let output depend on `Set` or `Dictionary` iteration order** — a review rule (ADR-0002 D2).
- **Never use one global random generator** — one system's draws would shift another's (ADR-0002 Alt 3).
- **Never use `hypot`** for segment length (`sqrt(dx²+dy²)` written out) (ADR-0001 D4).
- **Never hard-code keys, pictures, sounds, lines, theme packs or tuning values** (ADR-0001 D6); never rasterise a
  font at run time (ADR-0001 D6).
- **Never decode theme or content JSON in `KidCore`** (it receives decoded models; the settings record's
  hand-written reader/writer is the exception above); **never read `src/` from the app** (ADR-0003 D7, Impl.); never ship `src/`, SVGs,
  scripts, WAV intermediates, reports, fixtures or tools (ADR-0003 D8).
- **Never keep separate validators for build and load** (ADR-0003 Alt 3).
- **Never put a seed, an event `time`, a `play` field or a precomputed `u` in a contract case** (morph-contract-v1
  excepted for seeds); **never edit a merged `cases.json`/`spec.md`** — a change is a new `-vN`; **never widen a
  tolerance without a `toleranceReason`**; **never skip in the harness**; **never generate fixtures from the Swift
  implementation** (ADR-0004 D4–D6, Alt 2).
- **Never use a JSON library in the settings-record writer/reader** (ADR-0004 D3); never a third-party schema
  validator or a remote package, even in tests (ADR-0004 D4).
- **Settings: never** an app group, `UserDefaults(suiteName:)` or a file; never parse or transform the bytes in the
  backend; never `register(defaults:)`, `synchronize()`, KVO or `@AppStorage`; never `true` from `write`; never
  serialize `childLockActive` or write `"childLock":false`; never `NSUbiquitousKeyValueStore`, CloudKit or iCloud
  containers (ADR-0005 D1, D2, D4, D8).
- **Never run kill tests or any developer run on QC's simulator** (E9F515E9…, 475D45B4…) (ADR-0005 D3; ADR-0011 D3).

### Performance guardrails
- Theme validation at load: off the main thread, one pass per load (ADR-0003 Performance).
- Settings record under 1 KB; launch read synchronous, a few ms (ADR-0005 D2, D9).
- Cores: one `tick(now:)` per frame, negligible CPU/memory (ADR-0002 Performance).

---

## Presentation layer

*The stage view, frame driver, display metrics, accessibility, overlays.*

### Required patterns
- One `SKView` per window, wrapped with `UIViewRepresentable`/`NSViewRepresentable`, implementing `RenderSink`;
  the adapter only maps the render plan onto nodes — no rule lives in the scene (ADR-0006 D1).
- One stage root with fixed layer children and fixed `zPosition`: z0 backdrop, z10 parade walkers, z20 leaving
  creature, z30 current creature, z35 on-screen keyboard row, z40 glyph/specks, z50 starlights/sparkles, z60 hint
  letters, z70 queue tokens + parade meter (light above the meter by child `zPosition` 1), z80 the moon
  (ADR-0006 D1 and notes).
- The gate challenge and the grown-up panel (55% dim) are SwiftUI overlays above the `SKView` in the same window
  (ADR-0006 D1).
- `scaleMode = .resizeFill`; the stage root carries KidCore's Reveal Stage F1 transform (scale, centring, y flip);
  touches go out as `TouchEvent` in window px with the published `pxPerPt`, no stage transform in the adapter
  (ADR-0006 D2).
- Any resize, rotation, multitasking or screen change emits `displayMetricsChanged` and `screenChanged`; the reveal
  in progress is not restarted (ADR-0006 D2).
- Frame driver: iPad `CADisplayLink`, Mac `NSView.displayLink`; each callback calls `tick(now: targetTimestamp)`;
  `preferredFrameRateRange` min 30, max 60, preferred 60; a dropped frame is just a bigger time step
  (ADR-0006 D3).
- iPad: every scene size supported, landscape first (ADR-0006 D4). Status bar hidden throughout: iPadOS 27
  `.toolbarVisibility(.hidden, for: .statusBar)`, iPadOS 26 `.statusBarHidden(true)`, one `#available` branch. Home
  indicator auto-hidden and edges deferred in the Title and Play only, following `edgeDeferral`
  (`.persistentSystemOverlays`, `.defersSystemGestures(on:)`) (ADR-0006 D4 note).
- Mac, kiosk off: one resizable window, minimum 960 × 540 pt, `.fullScreenPrimary` allowed (ADR-0006 D4). Kiosk on:
  see § Pending, ADR-0008.
- Smart Invert: the `SKView` sets `accessibilityIgnoresInvertColors = true` on iPad; the panel overlay does not
  (ADR-0006 D5). Reduce Motion is read live and applied at the next reveal (ADR-0006 D6).
- ppi: iPad from a bundled model-identifier table, each row citing Apple's tech-specs page; Mac from
  `CGDisplayScreenSize`; unknown → the class's highest ppi + one `DebugLog` line (ADR-0006 D7).
- Flash safety in app code (ADR-0013): every periodic animation's rate comes from data G1 reads (Impl.); SwiftUI
  overlays hold no periodic animation (D7); a pressed-state change covers at most the class floor `area_max` (iPad
  58,449 px, Mac 2× 54,105 px, Mac 1× 4,347 px) or changes luminance by less than ΔL 0.1, so overlay buttons use a
  style that meets this (D7); every random draw comes from a seeded `RandomSource` (Impl.).
- The Debug-only `FlashDump` (ADR-0013 D5): under `#if DEBUG`, off unless a launch argument turns it on; after the
  view's update it calls its own `SKRenderer`'s `render` only into a texture at the drawable's size, format and
  colour space, records `(targetTimestamp, frame index)`, flushes off the main thread.

### Forbidden approaches
- **Never use SwiftUI `SpriteView`** (ADR-0006 D1, Alt 1); **never make the gate or panel a separate window, sheet or
  popover** (ADR-0006 D1, Alt 3).
- **Never rely on child order within a layer node** (`ignoresSiblingOrder` may be set) (ADR-0006 D1 note).
- **Never set `UIRequiresFullScreen`** (deprecated in 26.0) (ADR-0006 D4).
- **Never drive KidCore per frame from anything but `tick(now:)`; never catch up dropped frames or step in fixed
  increments** (ADR-0006 D3, Alt 2).
- **Never set `accessibilityIgnoresInvertColors` on the panel overlay; never treat an unknown ppi as a lower value**
  (ADR-0006 D5, D7).
- **Never use `SKEmitterNode` or unseeded SpriteKit/GameplayKit randomness on the stage** (ADR-0013 Impl.).
- **`FlashDump`: never `updateAtTime:`, never `SKView.texture(from:)`, a screenshot or a screen recording, never
  PNG-encode on the main thread, never compiled outside Debug** — the Release scan finds no `FlashDump` symbol
  (ADR-0013 D5, Impl., V4).
- **Never hard-code a periodic animation rate in Swift** (ADR-0013 Impl.).

### Performance guardrails
- 60 fps cap, frame p99 within 16.7 ms (ADR-0006 D3, Performance); device cost is measured under ADR-0009.
- Overlay press feedback: ≤ class floor `area_max` or ΔL < 0.1 (ADR-0013 D7).

---

## Tooling layer

*`apple/Tools`, `tools/ci/`, contracts harness runs, flash gates. Nothing here ships.*

### Required patterns
- Tools use only Apple frameworks and our own code (K-31); the bake tool, loudness meter and encoder are own Swift
  (ADR-0003 D4, D5, Impl.); `tools/ci/` uses system command-line tools and our code (ADR-0011 Impl.).
- Content build (ADR-0003 D3–D6): the validator runs at build with a file-system probe and fails naming theme, rule
  and item; cast SVG accepted only in D4's subset (elements, attributes, values, the `<part>_<layer>` id rule with
  `body`/`outline`/`detail`, `data-pivot`), every rejection naming element, attribute and line; baked output is
  byte-stable and committed with its source; a staleness check re-bakes in memory and re-measures `voiceDurations`;
  loudness by ITU-R BS.1770 within ±1 LU of the class target; sfx ≤ 2.0 s; voice files named by line id from the
  engine-agnostic TTS adapter (K-41 engine).
- `tools/ci/verify.sh` before every push; a failing gate means nothing is pushed (ADR-0011 D2). Gate order: ban grep →
  API-surface staleness → content gates → flash G1–G3 → `swift test` → (with `--app`) the bundle scan
  (ADR-0011 D4 and note).
- Every run `nice -n 10`, its own `-derivedDataPath`, stop above load ~40; MAC FREE for anything taking the screen,
  keyboard or focus, not for headless runs (ADR-0011 D2).
- Developer scripts read `DEV_SIM_UDID` (`--dev`), QC's read `QC_SIM_UDID` (`--qc`); `sim-guard.sh` refuses the other
  side's simulators (ADR-0011 D3 and note).
- Scanned Release builds are signed (Personal Team or ad-hoc with entitlements) (ADR-0011 D3).
- `pkc-scan.sh` prints only `OBSERVED …` lines; QC writes every PKC verdict (ADR-0011 D1, D5).
- Evidence under `production/qa/evidence/<TASK>/<short-sha>/`, belonging to that one commit (ADR-0011 D6).
- Flash gates (ADR-0013 D1–D6): one detector in `apple/Tools` for G3, G4, G5, windowing by timestamps; G4 renders
  the stage headless through `SKRenderer` on a synthetic clock at the ADR-0006 cap, seeded, at each class's native
  size and ppi floor; a release needs G1–G5 all PASS; NOT ASSESSED until run, never PASS.

### Forbidden approaches
- **Never third-party tools (ffmpeg, an SVG library) in the content pipeline** (ADR-0003 Alt 2); **never hand-edit
  `voiceDurations`** (ADR-0003 D4).
- **Cast SVG: never** `<defs>` content, `use`, `symbol`, `pattern`, `mask`, `clipPath`, `filter`, gradients, `text`,
  `image`, `foreignObject`, `style`, `class`, `url(#…)` paint, named colours other than `none`, `currentColor`,
  skew transforms, units or percentages (ADR-0003 D4).
- **Never a script that prints PASS/FAIL for PKC rows** (ADR-0011 Alt 2); **never `CODE_SIGNING_ALLOWED=NO` for a
  scanned build**; **never `defaults read` for PKC-05** (ADR-0011 D3, D5).
- **Never push after a failing gate** (ADR-0011 D2).
- **Flash: never a second detector; never count frames for time; never downsample, crop or skip frames; never wall
  clock or unseeded randomness in G4; never attach the G4 scene to an `SKView`; never raise a threshold to fix a
  FAIL** (ADR-0013 D2, D4, Impl.).

### Performance guardrails
- G1–G3 run in seconds; G4 (27 runs × 600 frames) is a long QC run, `--flash`/`--release` only (ADR-0013
  Performance, Alt 4).

---

## Pending rules (Proposed ADRs — provisional until their device rows close)

> Build against the seams below; **never hard-wire an option an ADR has not decided**. A rule here may change when
> the ADR is accepted or revised; the manifest is regenerated then. Only the user (or the technical-director on the
> user's explicit confirmation) sets an ADR to Accepted.

### ADR-0007 Input adapters — waits for M-1, M-2, M-3 (keyboard), P-15, P-4 (keyboard)
- Per platform: a thin reader + a pure, unit-tested mapper to `KeyEvent`/`TouchEvent` in the app target; `KidCore`
  never sees platform key codes (D1). `physicalId` is `hid:<usage>` or `mac:<keyCode>` (D2).
- Events reach `KidCore` synchronously on the main thread inside the platform callback, which returns the key-down
  disposition (D3). iPad: a first responder overriding the four `presses…` methods, calling `super` with only the
  passed presses. Mac: one `NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .keyUp, .flagsChanged])`
  installed before the first frame (D3).
- Hardware system keys (volume, brightness, media, power) never become a `KeyEvent` (D2).
- Never a global monitor, an event tap, accessibility trust or `IOHID…`; never `UIKeyCommand`s (Impl., Alt 1, Alt 2).
- **Undecided:** `KeyStateQuery` (D4) depends on M-1 — do not build against it yet.

### ADR-0008 Kiosk lock-in — waits for M-3, M-4, M-5, M-6, M-7, P-4
- Mac options: `[.hideDock, .hideMenuBar, .disableAppleMenu, .disableProcessSwitching, .disableForceQuit,
  .disableSessionTermination, .disableHideApplication]` + `.disableScreenCornerInteractions` under
  `#available(macOS 27, *)`, from one pure, unit-tested function of the OS version (D2).
- The kiosk window subclasses `NSWindow` (`canBecomeKey`/`canBecomeMain` true); one cover window per other screen,
  rebuilt on screen-parameter changes; options and covers off on `didResignActive` (D3–D5). The adapter applies
  effects, `KidCore` decides when (D6). iPad: report `isGuidedAccessEnabled`, text guidance only (D7).
- No separate `NSWindow`, sheet, popover or `NSAlert` while `childLockActive` can be true (Impl.); never
  `requestGuidedAccessSession`, a shielding window or MDM (D7, Alt 2, Alt 3).
- **Undecided:** borderless window vs native full screen (D1) — build both behind `KioskEffects`.

### ADR-0009 Render path — waits for P-2 (oldest supported iPad) and M-13
- One `CastFigure` adapter with two backends behind `RenderSink`; both read the same baked file; parse once at load,
  never per frame (D2, Impl.). Roles: `stage` all layers, `list` body + outline + detail ≥ 6 px, `parade` body +
  outline (D2). The outline is one unit per part at 80% group opacity; per-look colour is a multiply at draw time,
  never baked (D2).
- Option A outline: the merged outline path stroked opaque in an `SKEffectNode` with `shouldRasterize`, one per part,
  at 0.8 — confirmed on a device (iPad13,4, TASK-127 H-2). Fills stay one `SKShapeNode` each; never merge fills
  (D3). Set colours only when the F8 factor changes (D3).
- Loading off the main thread; a figure is resident only when every part is ready (D5).
- **Undecided:** A / B / mix (D1) — do not hard-wire either backend.

### ADR-0010 Audio engine — waits for P-1, P-7, P-8, P-9, M-14 (P-7 recorded FAIL (open) in TASK-127)
- Session `.soloAmbient`, mode `.default`, set once before the engine starts; log the actual IO buffer and output
  latency (D1). The graph (7 players → gates → 4 buses → submix → PeakLimiter → main mixer) is built and started
  once; nothing is attached, created or stopped on a press (D2).
- All graph work on one serial `.userInteractive` queue; a sounding player is cut before a new sound; a state
  machine with a generation token per player (D4).
- Cut: never stop, pause or replace a sound until its gain is below −60 dBFS; `cut_settle_s` 0.04 (proposed) (D5).
  Freeze resumes from the held frame minus a rewind of max(20 ms, IO + 5 ms), capped at `cut_settle_s` (D7).
- iPadOS 27 notifications `didBecomeInactiveNotification` / `resumptionRecommendationNotification`, 26
  `interruptionNotification`, via `#available`; `playAudio()`/`connectNode` on 27, `play()`/`connect` on 26 (D8,
  Impl.). One adapter type owns AVFAudio (Impl.).
- Never `AVAudioPlayer` per sound, `.ambient` or `.playback`, a hard `stop()`/`pause()`/`.interrupts` cut, or
  scheduling on the main thread (Alt 1–3, 5). No runtime speech synthesis (D10).
- **Undecided:** the gate-fade cut (D5) is unproven on device; the fallback is a per-sample gain ramp (Alt 4).

---

## Global rules (all layers)

### Naming conventions
See [`coding-conventions.md`](coding-conventions.md): Swift API Design Guidelines for types and functions (N1–N7),
files (F1–F4), packages/modules/targets incl. the `LetterMorph` module / `Letterlings` product split (M1–M5),
tests (T1–T5), and pointers for content ids (Key Table V6, ADR-0003 D1). `project.yaml` has no `naming.*` keys
(no Swift engine row) and `technical-preferences.md` is unconfigured, so that file is the source.

### Performance budgets
| Target | Value | Source |
|---|---|---|
| Frame rate | 60 fps cap (`preferredFrameRateRange` 30–60) | ADR-0006 D3 |
| Frame budget | p99 ≤ 16.7 ms | ADR-0006 Performance; ADR-0009 D1 (pending) |
| Creature load | ≤ 1.2 s per role | ADR-0009 D1 (pending) |
| Memory ceiling | none set (`project.yaml` / art bible §8: no budget) | — |
| Draw calls | none set | — |

### Approved libraries / add-ons
- None. Apple frameworks and our own code only; a third-party runtime needs its own ADR (ADR-0001 D8; K-31 for
  tools). Build-machine-only exception: the K-41 TTS engine (ADR-0003 D6 note).

### Deprecated / version-gated APIs (no engine-reference table for this stack)
- `UIRequiresFullScreen` — deprecated in iPadOS 26 (ADR-0006 D4).
- `.statusBarHidden(true)` — use only on iPadOS 26; `.toolbarVisibility(.hidden, for: .statusBar)` on 27
  (ADR-0006 D4 note).
- `AVAudioPlayerNode.play()`, `AVAudioEngine.connect(_:to:format:)`, `AVAudioSession.interruptionNotification` —
  deprecated on 27; branch with `#available` (ADR-0010, pending).
- `.disableScreenCornerInteractions` — macOS 27+ only (ADR-0001 D9b; ADR-0008 D2, pending).
- `wantsPriorityOverSystemBehavior` — does not block system shortcuts; do not rely on it (ADR-0001 Engine Compat.).
- Any API not yet built on the 27 SDKs is proven by building and running, never from memory (ADR-0001 Engine
  Compat.).

### Cross-cutting constraints
- No network, no third-party runtime, no tracking identifiers in any layer (ADR-0001 D8; ADR-0011 PKC scans).
- Every number a GDD states is a hand-written contract case (ADR-0004 Impl.); the GDD decides when results disagree
  (ADR-0004 D5).
- Platform code stays in `<App>` or `Tools`; a new seam only by an ADR (ADR-0002 Impl.).
- Android mirror (later, ADR-0012): Gradle `kidcore` and `morphcore` are pure JVM with no `android.*` imports and the
  same seam names; `RandomSource` returns `ULong`; `settings-record-v1` is the same bytes on both platforms
  (ADR-0002 D8).
- Evidence for every player-observable change is a retained screenshot (coding-standards.md); device sessions follow
  `production/qa/device-checks-plan.md`.
