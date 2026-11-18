# ADR-0013: Flash safety: where the photosensitivity checks run and what fails

## Status

Proposed (TASK-116, 2026-11-18). Acceptance is Luan's. **Gates G1–G3 can be built now. G4 waits for the stage (Scene, Cast
Rendering, Parade, Press Queue), and G5 waits for device time.** Until they run, they report NOT ASSESSED, never PASS.

> **Who may move this to `Accepted`: the user, or `technical-director` on the
> user's explicit confirmation. No other agent, and no skill on its own.**

## Date

2026-11-18

## Last Verified

2026-11-18, against:
- Accessibility (A4, F1, F2, F2b, AC-05–AC-09, Edge Cases, Tuning Knobs) and K-26 (the busy case);
- ADR-0002 (D3 clocks, D4 `RandomSource`, the `tick(now:)` frame entry);
- ADR-0003 (the content validator);
- ADR-0004 (Excluded: "Accessibility F1/F2: QC tools");
- ADR-0006 (D3 frame driver and 60 fps cap, D7 ppi, D8);
- ADR-0009 D6 ("flash gate … not decided here");
- ADR-0011 (D1 gates against observations, D2 who runs what, D4 `verify.sh`, D6 evidence);
- the device-checks plan (P-3, M-12; Spike runs);
- TASK-111's review (P-1, B-3, `TR-a11y-003`);
- the TASK-054 follow-up on per-frame dump timestamps;
- `prototypes/DeviceSpike` (RenderScene's frame dump, AudioScreen's press flash);
- the SpriteKit headers in the Xcode 27.1 SDKs (`SKRenderer.h`, `SKView.h`);
- the headless `SKRenderer` render in TASK-103 H-2 (6e455bfc).

## Decision Makers

- Luan (accepts);
- game-qc-ios (author, TASK-116; owner of the Accessibility GDD's F2);
- game-dev-android (review, Accessibility GDD side);
- game-dev-ios (review, render side);
- game-leader.

## Summary

Accessibility A4 requires that nothing on the stage flashes, measured against WCAG 2.3.1 (F2) with a palette red check
(F2b) and a rate lint (F1). No ADR decided where those checks run or what blocks a release: ADR-0009 D6 says "not
decided here", ADR-0004 lists them only as QC tools, and ADR-0011 has no gate (TASK-111 B-3).

This ADR adds **five gates**:
- **G1–G3**, fast and run by `verify.sh` on every push: the F1 rate lint, the F2b palette check, and the detector's own
  unit tests.
- **G4**, the busy case rendered **offscreen and headless** through `SKRenderer` on a synthetic clock and fed to the
  F2 detector. QC runs it on every merge candidate that touches the stage or content.
- **G5**, the same detector on an **in-app debug frame dump** with per-frame timestamps, on a real iPad and a real Mac.
  This is the release gate (AC-08, P-3 / M-12).

Any FAIL blocks: a push for G1–G3, a merge for G4, a release candidate for all of them. NOT ASSESSED counts as a FAIL
in a release candidate.

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | None from the template's table (`engine.name` unset; ADR-0001, K-28). Swift 6.4, Xcode 27.1, SDKs iOS 27.1 / macOS 27.0, deployment 26 |
| **Domain** | Rendering (verification) |
| **Layer** | Tooling (nothing ships), plus one **Debug-only** frame-dump hook in the app target (G5), compiled out of Release |
| **Knowledge Risk** | **LOW** for `SKRenderer` offscreen rendering: SDK header read; it renders headless into a Metal texture on this Mac (TASK-103 H-2, 6e455bfc). **MEDIUM** for whether an offscreen `SKRenderer` frame matches the on-screen frame pixel for pixel (colour space, pixel format, drawable scale): checked by V2. **MEDIUM** for the dump's effect on device frame timing: it slows frames, so G5 windows by recorded timestamps (D5) |
| **References Consulted** | `SpriteKit.framework/Headers/SKRenderer.h` and `SKView.h` (Xcode 27.1, macOS 27.0 and iOS 27.1 SDKs, read 2026-11-18); `docs/engine-reference-local/native-apple/modules/spritekit.md`; `prototypes/DeviceSpike/DeviceSpike/RenderScene.swift` (frame dump) and `AudioScreen.swift`; `prototypes/DeviceSpike/tools/overlap-check.swift` (6e455bfc) |
| **Post-Cutoff APIs Used** | None. `SKRenderer` (iOS 11 / macOS 10.13), Metal textures, `CGImage` |
| **Verification Required** | V1–V6 (Validation Criteria). In short: G4 is deterministic run to run; an offscreen frame matches the device's dumped frame for the same tick (V2); the Release binary contains no dump code (V4); the device dump's frame coverage meets D5 |

### Sources (Xcode 27.1 SDK headers, read 2026-11-18)

- **`SKRenderer.h`**: "A renderer for displaying a SpriteKit scene in an existing Metal workflow."
  - `+rendererWithDevice:`, `-renderWithViewport:commandBuffer:renderPassDescriptor:` ("The pixel dimensions in which
    to render"), and `-updateAtTime:` ("Update the scene at the specified system time").
  - So the scene can be advanced on a clock we choose and drawn into our own texture, with no view or window.
- **`SKView.h`**, `-textureFromNode:`: "a snapshot of how it would have been rendered in this view"; "The texture is
  tightly cropped to the size of the node".
  - It is a re-render at the call, cropped to the node, and not the presented drawable.
  - DeviceSpike's current dump uses it on the scene. G5 must not (D5).

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0011 (Accepted: gates, who runs what, evidence); ADR-0003 (Accepted: the content validator G1/G2 extend); ADR-0002 (Accepted: `tick(now:)`, `UptimeClock`, `RandomSource`, the seams that make G4 deterministic); ADR-0006 (Accepted: D3 frame cap, D7 ppi) |
| **Enables** | ADR-0009 D6's flash item (closed here); Accessibility AC-05–AC-09; the release gate's photosensitivity row |
| **Blocks** | No story's start. A **release candidate** can't pass until G4 and G5 have run and passed (AC-08). The stories that build the F2 tool, the offscreen harness and the dump own V1–V6 |
| **Ordering Note** | G1–G3 come with the content validator and `apple/Tools` (now). G4 needs the stage composition (Scene, Cast Rendering, Parade, Press Queue's mash fixture); until then it reports `NOT ASSESSED: not started (story …)`, as in K-40. G5 needs G4's harness and device time (P-3, M-12). ADR-0009's spike rows (P-3 / M-12) rehearse G5 on DeviceSpike; they are not AC-08 |

## Context

### Problem Statement
The game is for small children, and a photosensitive seizure is the worst harm it could do. The art bible forbids
flashing ("Drift, never flash"), Accessibility A4 lists every pulse, and F2 measures the result against WCAG 2.3.1.

TASK-111's architecture review found that nothing decides:
- where F2 runs;
- what blocks a release;
- whether the detector runs at all before the device session.

ADR-0009 D6 deferred it, ADR-0004 calls F1/F2 "QC tools", and ADR-0011's gate list has no flash item. The GDD's
"the simulator runs it on every build" can't run as written: Simulator boots push this Mac's load to 40–55 (leader,
2026-11-18).

### Constraints
- **Local only (K-42):** `verify.sh` on the Mac is the CI. Headless runs need no MAC FREE; anything on the screen does
  (K-34). Every run uses `nice -n 10` and stops above a load of about 40 (ADR-0011 D2).
- **F2 needs every frame** at the display's rate and native resolution. A screen recording can cap at 60 fps and is
  not frame-accurate (P-3; TASK-106 for M-12). A screenshot shows the display's colour profile, not the rendered sRGB
  values (TASK-109's Dusk fill reads (61,77,129) on a Mac capture, against (70,85,143) on the simulator).
- **The device dump slows the frames it records** (TASK-054 follow-up), so frame index ≠ time.
- **Gates and observations stay separate** (ADR-0011 D1): a gate exits non-zero; a script never writes QC's verdict
  on an observation.

### Requirements
- **WCAG 2.3.1 as F2 states it:** 7 or more zig-zag transitions per pixel in any half-open 1 s window; the FAIL area
  `area_max` inside any 10° circular field at 300 mm; the field slid in steps ≤ `field_px`/4 (Accessibility F2).
- **The K-26 busy case:** a seeded mash with a walking parade, at Night and at Day, in light rain and in snow, with
  Reduce Motion off and on; 10 s per run.
- **Red flash:** the palette proof F2b, plus a per-frame backstop for the cases F2b doesn't cover (gamma-space
  blends measured in linear values, screen/multiply modes).
- **Repeatable:** the same commit gives the same frames and the same verdict.

## Decision

### D1. Five gates, each a mechanical rule

| Gate | What | Input | FAIL when | Runs (ADR-0011 D2) |
|---|---|---|---|---|
| **G1** F1 rate lint | every periodic animation's rate in the **shipped data** (baked timing data, theme data, every knob a rate is computed from), by F1's formula | `content/` baked output | any `rate ≥ 3 Hz`; any `rate > 1 Hz` not on F1's exception list (halo, stardust twinkle, parade step bob) | `verify.sh`, every run (developer pre-push and QC) |
| **G2** F2b palette | `R/(R+G+B)` of every colour the build can draw: the art bible palette, theme data, every SVG fill, in **8-bit sRGB and linear** | `content/` source and baked colours | any colour `≥ 0.8` in either space | `verify.sh`, every run |
| **G3** detector self-test | the F2 tool's unit tests: AC-06 (`field_px`, `area_max` for 264 / 254 / 109 ppi, plus the 72 ppi floor), AC-07 (the synthetic clips at 60 and 120 Hz, every phase offset), the timestamp windowing (D5), determinism | `apple/Tools` tests | any test fails | `verify.sh`, every run (`swift test --package-path apple/Tools`) |
| **G4** offline busy case | the stage rendered headless through `SKRenderer` on a synthetic clock (D3), each frame fed to the F2 detector (D2) and the red backstop (D4) | the built stage + content | F2 FAIL at any (t, field), or the red backstop fires (D4), or a run is incomplete (D5) | QC: `verify.sh --flash` on every merge candidate touching `apple/` or `content/`; `verify.sh --release` always. Developer: optional |
| **G5** device busy case | the same detector on the **Debug** app's frame dump with per-frame timestamps (D5), on a real iPad and a real Mac | the dump files | as G4, plus a dump that fails D5's coverage rule is **NOT ASSESSED** | QC, per **release candidate**: P-3 (iPad), M-12 (Mac, MAC FREE) |

- **G1–G3 are pure functions of the repo**, so they join ADR-0011 D4's gate list after step 3 (content).
- **Before the stage exists, G4 prints** `NOT ASSESSED flash-busy-case: not started (story <id>); 0 of 27 runs`, the K-40
  form. It does not fail a merge; `verify.sh --release` FAILs on it, as on any not-started contract.
- **G5 is recorded in the release candidate's evidence**, like the runtime PKC rows. In a merge candidate's verdict it is
  NOT ASSESSED with a pointer to P-3 / M-12, never left blank.
- **A release candidate needs G1–G5 all PASS.** NOT ASSESSED in any of them is a FAIL for the release (Privacy's gate
  order: FAIL > NOT ASSESSED > PASS).

### D2. One detector, one rule (Accessibility F2, unchanged)
- **The detector** lives in `apple/Tools` (Foundation-only Swift), used by G3, G4 and G5. Its input is a sequence of
  `(timestamp, frame)`, where a frame is linear-sRGB pixels at native resolution. Its output is a verdict line plus
  observations.
- **The rule** is the zig-zag transition rule and the half-open window `(t − 1 s, t]` **by timestamp**, never by frame
  count (D5). `flashing(p, t)` = 7 or more transitions. **FAIL** when any field position holds more than `area_max`
  flashing pixels. The field is a circle of diameter `field_px`, slid in steps ≤ `field_px`/4.
- **Speed is not allowed to change the result.** Per-pixel state and the field counts may use a Metal compute kernel
  or a summed-area table. **Downsampling, cropping and sampling every n-th frame are not allowed**, because each
  changes the result.
- **Observations, printed and never judged:**
  - the worst `(t, field)` count against `area_max`;
  - the frame rate actually seen;
  - the highest per-pixel `R/(R+G+B)` per run (D4);
  - the frame-coverage figures (D5).

### D3. G4: the offline render (headless, no Simulator)
- **A harness in a test target** (it never ships) builds the **same stage scene the app builds**: the composition of
  ADR-0006 D1, Scene, Cast Rendering, Hint Letters, Parade, Reveal Stage, the keyboard row, Reduce Motion from
  Accessibility's `reduceMotion` flag. It drives it with:
  - `UptimeClock` replaced by a **synthetic clock** `t_k = t_0 + k / rate`, with `rate = ADR-0006 D3's cap` (60 Hz
    today; if a later ADR raises the cap, G4 runs at the new cap);
  - on each step, **`tick(now: t_k)`** into KidCore (ADR-0002, the only per-frame entry), then
    **`SKRenderer.update(atTime: t_k)`**, then **`render(withViewport:…)`** into a Metal texture at the class's native
    pixel size;
  - **seeded input:** the Press Queue's mash fixture as timed input events, and fixed seeds for every `RandomSource`
    stream (ADR-0002 D4).
- **Device classes**, the stage at each class's full native size, with each class's ppi floor (D6):

  | Class | Pixels | ppi | `area_max` |
  |---|---|---|---|
  | 13" iPad (the largest iPad stage at 264 ppi; the 11" has fewer pixels and the same field) | 2752 × 2064 | 264 | 58,449 |
  | Mac, 2× built-in display, full screen | 3024 × 1964 | 254 | 54,105 |
  | Mac, 1× external display, full screen | 2560 × 1440 | **72** (the class floor, D6; external 1× displays reach ~82 ppi, and 72 is ADR-0006 D7's "unknown" boundary) | 4,347 (`field_px` 148.8) |
- **The run matrix:** the K-26 busy case, 3 classes × {Night, Day} × {light rain, snow} × {Reduce Motion off, on} =
  24 runs, **plus a Title idle run per class** (10 s at Night in light rain, Reduce Motion off: the breathe, the title
  creature's idle, the stardust twinkle and the weather together, none of which the busy case shows on the Title) =
  **27 runs**, 10 s each, 600 frames at 60 Hz.
- **Determinism:** a second G4 run on the same commit must give **identical per-frame hashes** for at least one run
  per class, or G4 is NOT ASSESSED.
- **What G4 proves, and what it doesn't:** it proves the game's content and timing, on the rule's own clock, can't
  flash. It doesn't prove the device's GPU, colour pipeline or actual frame pacing; that is G5.

### D4. The red backstop (F2b's gap)
- **The proof:** F2b proves that no blend of the palette exceeds the palette's highest ratio, **when the blend is done
  and measured in the same space**. It doesn't cover a gamma-space blend measured in linear values, or screen and
  multiply modes.
- **The backstop:** G4 and G5 compute, per frame, every pixel's `R/(R+G+B)` in 8-bit sRGB and linear, counting only
  pixels with `R + G + B ≥ red_floor`. A near-black pixel's ratio is dominated by rounding ((1,0,0) reads 1.0) and
  can't carry a WCAG "saturated red" transition.
- **The backstop FAILs** when any counted pixel reads `≥ 0.8`. The fix is then to change the colour or the blend, or to
  implement WCAG's red-flash rule (chromaticity difference > 0.2 in CIE 1976 UCS) as Accessibility's Edge Cases
  require. **Never** to raise the threshold.
- **`red_floor` = 0.1** on the 0–3 scale (normalised components) is a tuning knob for the detector story. It may only
  go down, which is stricter.

### D5. G5: the device dump, and time from timestamps
- **What the dump is:** a **Debug-only** `FlashDump` in the app target (`#if DEBUG`), off unless a launch argument
  turns it on. On each display-link tick it:
  - renders that tick's scene with an `SKRenderer` into a Metal texture at the **drawable's pixel size, pixel format
    and colour space**;
  - records `(targetTimestamp, frame index)`;
  - writes raw pixels to an on-device ring buffer that is flushed off the main thread.
- It **must not** use `SKView.texture(from:)`, which is cropped to the node and isn't the presented drawable (Sources),
  and **must not** PNG-encode on the main thread (the spike does both).
- **Time:** the detector windows by the recorded `targetTimestamp`s, never by frame index (TASK-054 follow-up).
- **Coverage rule:** a run is valid when **≥ 95% of the expected frames** (duration × observed rate) are present **and
  no gap exceeds 50 ms**. Otherwise G5 prints NOT ASSESSED for that run (a re-run, never a pass). Both transitions of
  a pair fit inside one 50 ms gap only for a flicker faster than 10 Hz; at the rule's 3.5 Hz the transitions are
  about 143 ms apart, so a 50 ms gap hides at most one.
- **Rate:** the device's actual rate is recorded per run. ProMotion iPads run at the cap (60 Hz, ADR-0006 D3) unless a
  later ADR raises it.
- **The 240 fps phone (P-3 b)** is a sanity spot check only; camera luminance isn't WCAG relative luminance.

### D6. ppi for the flash field: the class floor, never the largest
- **The rule:** a smaller ppi gives a smaller `field_px` and a smaller `area_max`, which is **stricter**. Each class has
  a **ppi floor**, the lowest ppi the game may meet in it: **264** for the iPad (every supported iPad), **254** for a Mac
  2× display, **72** for a Mac 1× external display (external 1× displays reach ~82 ppi; 72 is ADR-0006 D7's
  "unknown" boundary, so nothing real is lower). **G4 uses the floor.**
- **G5 uses the device's real ppi** from ADR-0006 D7. That is at or above the floor, so G5 is never stricter than G4 for
  the same frames. **If D7 reports "unknown", the detector takes the class floor.**
- **AC-06 is unchanged:** its unit test still checks 264 / 254 / 109 ppi (the GDD's table); G3 adds 72 ppi
  (`field_px` 148.8, `area_max` 4,347).
- **The opposite of D7's touch-target rule:** that rule takes the largest ppi so that targets come out big enough. This
  one takes the floor so that flashes are judged over the smallest area. Both rules are conservative for what they
  guard.
- **New devices:** a new device class (a lower-ppi iPad, a new Mac display) adds a G4 row; nothing else changes
  (Accessibility Edge Cases).

### D7. Scope: what the frames contain
- **Covered:** G4 and G5 capture the SpriteKit stage, which is everything the child sees while playing (Accessibility
  "Every visible system | gate").
- **Not covered:** SwiftUI overlays drawn above the stage (the gate challenge, the grown-up panel) are outside the
  render. They must hold **no periodic animation** at all. G1 lints their rates when they come from data, and code
  review checks them (a review rule for the overlay stories).
- **Title:** the Title isn't in the K-26 busy case, so G4 adds a Title idle run per class (D3). Its motion (the play
  button's breathe at 0.38 Hz, App Shell R2; the title creature's idle; the twinkle and weather) is all ≤ 1 Hz by G1, but
  only a render shows whether they add up over an area (decided by the Accessibility owner, TASK-116 review).

### Architecture Diagram

```
 content/ ──► G1 rate lint ─┐
          └─► G2 palette ───┤
 apple/Tools tests ► G3 ────┼──► verify.sh (every push)            FAIL blocks the push
                            │
 stage harness (test target)│
  synthetic clock t_k ─► tick(now:) ─► SKRenderer.update/render ─► texture ─┐
  seeded mash, seeds        27 runs (3 classes × K-26 + Title)              │
                                                                            ▼
                                                    F2 detector (apple/Tools) + red backstop
                                                                            ▲
 Debug app on iPad / Mac: FlashDump ─► (targetTimestamp, frame) ring buffer ┘
                                                                            │
 G4: verify.sh --flash (QC, merge candidates) · verify.sh --release ◄───────┤ FAIL blocks the merge
 G5: P-3 / M-12 (QC, release candidate)                                      FAIL / NOT ASSESSED blocks the release
```

### Key Interfaces

```swift
// apple/Tools (Foundation-only)
struct FlashField { let ppi: Double; let viewingDistanceMM: Double   // field_px, area_max (F2, AC-06)
                    var fieldPx: Double { get }; var areaMax: Double { get } }
struct FlashFrame { let timestamp: Double; let width: Int; let height: Int; let linear: [Float] }  // RGB, linear sRGB
struct FlashReport { let fail: Bool; let worst: (t: Double, count: Int, areaMax: Double)
                     let maxRedRatio8bit: Double; let maxRedRatioLinear: Double
                     let framesSeen: Int; let framesExpected: Int; let maxGapS: Double }
protocol FlashDetector { mutating func add(_ frame: FlashFrame); func report() -> FlashReport }
```

`verify.sh` output lines, in ADR-0011's style:
- `PASS flash-rate-lint (Accessibility F1)`;
- `PASS flash-palette (F2b): max 8-bit 0.604, linear 0.781`;
- `PASS flash-detector self-test (AC-06, AC-07)`;
- `PASS flash-busy-case 27/27 runs (worst 0 / 58449 px)` or `NOT ASSESSED flash-busy-case: not started (story …)`.

### Implementation Guidelines
- G4 and G5 **must** use the one `apple/Tools` detector. A second implementation must never exist.
- The detector **must** window by frame timestamps and **must never** count frames to measure time.
- The detector **must never** downsample, crop or skip frames.
- G4 **must** drive KidCore only through `tick(now:)` on the synthetic clock, with every `RandomSource` seeded.
  Wall-clock time and unseeded randomness **must never** enter the harness.
- G4 **must** render at each class's full native pixel size and use each class's ppi floor (D6).
- The dump **must** be compiled only in Debug. The Release bundle scan (ADR-0003 D8, ADR-0011 D4 step 5) **must**
  find no `FlashDump` symbol in the Release binary (V4).
- The dump **must** read the frame from its own `SKRenderer` pass at the drawable's size, format and colour space,
  **never** from `SKView.texture(from:)`, a screenshot or a screen recording.
- Every periodic animation's rate **must** come from data that G1 reads. A rate hard-coded in Swift is a review
  finding, and G4 catches its effect.
- Raising F2's thresholds, F1's limits, `red_floor` (upwards) or the viewing distance (upwards) is **never** a fix for
  a FAIL; each is a decision recorded in `decisions.md`.

## Alternatives Considered

### Alternative 1: The Simulator on every build (the GDD's current wording)
- **Description:** run the app in the iOS Simulator, capture frames, run F2.
- **Pros:** the real app, unchanged.
- **Cons:**
  - each boot pushes the Mac's load to 40–55;
  - a Simulator window needs MAC FREE;
  - Simulator capture is a screen recording, not frame-accurate and display-profiled;
  - the Simulator's clock is wall time, so runs aren't repeatable.
- **Rejection Reason:** `SKRenderer` on a synthetic clock renders the same scene headless, repeatably and
  frame-accurately, with no boot.

### Alternative 2: Device runs only (G5 alone)
- **Description:** check flashing only at release, on hardware.
- **Pros:** the only run that sees the real GPU and pacing.
- **Cons:** a flash introduced by a content change is found only at the release session, possibly weeks later and under
  MAC FREE. It also isn't repeatable.
- **Rejection Reason:** for a toddler safeguard, the check must run on every candidate. The device run stays as the
  release confirmation.

### Alternative 3: Static checks only (F1 + F2b)
- **Description:** trust the rate lint and the palette proof.
- **Pros:** instant, no rendering.
- **Cons:** F1 can't see out-of-phase pulses that add up over an area (Accessibility A4), and F2b can't see blends
  across spaces.
- **Rejection Reason:** both GDD sections say F2 can't be replaced. G1/G2 stay as the fast first line.

### Alternative 4: Put G4 in every developer `verify.sh` run
- **Description:** run all 27 offline runs on every push.
- **Pros:** catches a flash before it's pushed.
- **Cons:** 16,200 native-resolution frames per run is minutes, not seconds, even with a compute kernel, which would
  slow every push.
- **Rejection Reason:** QC runs G4 on every merge candidate that touches `apple/` or `content/` (where flashes come
  from), and `verify.sh --flash` lets a developer run it on demand.

## Consequences

### Positive
- The photosensitivity requirement gets a gate at every stage: push (G1–G3), merge (G4), release (G5). Each has a
  mechanical FAIL.
- G4 is headless and needs no Simulator and no MAC FREE, so it can run often.
- One detector for all three uses, so a fix or a test applies everywhere.
- It closes ADR-0009 D6's flash item, ADR-0004's "QC tools" gap and TASK-111 B-3. G1 also gives `TR-a11y-004`'s F1 part
  (AC-05) and `TR-cast-007` (idles ≤ 1 Hz) a deciding gate.

### Negative
- A test-target harness must build the real stage without a view. The stage code must be constructible headless (it
  already must be, for KidCore's tests, but the SpriteKit adapters now must be too).
- G4 costs minutes of QC time per stage-touching merge candidate.
- The Debug dump is extra code in the app target, guarded by V4.

### Neutral
- Accessibility F2's "Where" text and AC-08's last sentence name the Simulator; they move to "the offline render (G4)"
  (GDD sync, below).

## Risks
- **The offscreen frame differs from the on-screen frame** (colour space, scale, a node culled differently).
  *Mitigation:* V2 compares a G4 frame with a G5 dumped frame of the same scene and tick on each device class; a
  difference beyond rounding is a FAIL of V2 and blocks relying on G4 alone.
- **The dump changes what it measures** (slower frames, thermal throttling). *Mitigation:* timestamps (D5); the
  coverage rule; G4 as the repeatable baseline.
- **G4's matrix misses a real-play case** (a key mash pattern the fixture doesn't have). *Mitigation:* the K-26 busy
  case is Luan's worst case by decision; a new worst case is added to the fixture by a decision, and F1 still covers
  every rate.
- **SwiftUI overlays are outside the capture** (D7). *Mitigation:* no periodic animation in overlays (a review rule);
  G1 on their data rates.
- **DeviceSpike's Audio screen flashes its pad white on every press** (`AudioScreen.swift`, for ADR-0010's latency
  rows). A fast key mash flashes a large area more than three times a second.
  - It's a prototype, not shipped, and its audio rows (ADR-0010's P-1 / M-14 latency runs) are run by an adult.
  - *Mitigation:* those rows say "**not with the child watching**", and the pad's change could be a size or position
    change rather than white (a note for game-dev-ios and the device-checks plan).
  - It is outside this ADR's gates, which cover the shipped stage.

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|--------------------------|
| accessibility.md A4, F1, AC-05 | the rate lint over shipped data on every build; < 3 Hz always, ≤ 1 Hz unless named | G1 in `verify.sh` (D1) |
| accessibility.md F2, AC-06, AC-07 | field math and detector behaviour, unit-tested | G3 (D1, D2) |
| accessibility.md F2, AC-08 | the K-26 busy case, Night / Day, rain / snow, Reduce Motion off / on, at the display's rate; device run is the release gate | G4 every stage-touching merge candidate (D3); G5 per release candidate on iPad and Mac (D5), with the coverage rule and timestamp windows |
| accessibility.md F2b, AC-09 | no colour with R/(R+G+B) ≥ 0.8 in palette, theme data, SVG fills; the frame backstop | G2 (D1); the red backstop in G4 / G5 (D4) |
| accessibility.md Edge Cases | new animation fails F1 unless excepted; palette red means the red-flash rule must be implemented; a new ppi changes only `field_px` | G1; D4's fix order; D6 (the class's ppi floor; a new class = a new G4 row) |
| accessibility.md Tuning Knobs | `viewing_distance_mm` 300 (lower is stricter); scenario length 10 s (≥ 5 s) | G4 / G5 use them as data; never raised to pass (Implementation Guidelines) |
| cast-rendering.md AC-11 | shipped idles ≤ 1 Hz, a build check on the data | G1 (`TR-cast-007`) |

## Performance Implications
- **CPU / GPU (tooling only):** G1–G3 take seconds. G4 is 27 runs × 600 frames at native size; a Metal compute pass
  for luminance and per-pixel state keeps it to minutes at `nice -n 10` (the detector story measures it and records
  the time in its evidence).
- **Memory:** per-pixel state is a few floats per pixel at the largest class (~6 Mpx), about 100 MB.
- **App (Debug only):** the dump costs frame time while it's on. It is absent from Release (V4); Release has no cost.
- **Network:** none.

## Migration Plan
- Nothing to migrate in `apple/`; no game code is written by this ADR.
- **The F2 tool story** builds the detector, G3 and G4's harness, and `verify.sh --flash`.
- **The content validator** gains G1 and G2 (ADR-0003 rule additions).
- **The production dump** is the frame-dump story, before the first release candidate. DeviceSpike's dump is replaced,
  not reused: it uses `texture(from:)` and PNGs on the main thread.
- **ADR-0011 D4** gets a dated note listing G1–G3 after step 3 and `--flash` (status stays Accepted).
- **ADR-0009 D6** gets a dated note: "flash gate: decided in ADR-0013".

## Validation Criteria
Per K-34: headless runs need no MAC FREE; G5 on the Mac (M-12) does.
- **V1 (G3):** AC-06 and AC-07 pass, plus timestamp windowing: a clip with uneven frame times (a 30 ms gap every 10th
  frame) gives the same verdict as the even clip with the same content timing.
- **V2 (offscreen = on-screen):** for one scene and tick per device class, the G4 frame and a G5 dumped frame match
  within ±1 per 8-bit channel (excluding antialiased edges ≤ 1 px). This is recorded in P-3 / M-12.
- **V3 (determinism):** two G4 runs on one commit give identical per-frame hashes.
- **V4 (Release has no dump):** `nm` / the bundle scan on the Release binaries finds no `FlashDump` symbol, and the
  launch argument does nothing.
- **V5 (planted failures):** G1 fails a 1.2 Hz idle fixture and a 3.0 Hz excepted one; G2 fails `#ff0000`; G4 fails a
  planted test node flashing full-screen at 4 Hz; the backstop fails a planted saturated red frame. These are
  self-test plants (ADR-0011's self-test), never left in shipped data.
- **V6 (device):** G5 on a real iPad (P-3) and a real Mac (M-12) at the display's rate. No FAIL, coverage met, with the
  device rate and ppi recorded.

## GDD sync

**⚠️ GDD SYNC REQUIRED: `accessibility.md`.**
- F2 **Where**: "the simulator runs it on every build" → "the offline render (ADR-0013 G4) runs it on every
  stage-touching merge candidate".
- AC-08's last sentence: "The simulator run passes on every build" → "G4 passes on every stage-touching merge
  candidate".
- F2 **Capture**: add "frames are timed by their recorded timestamps".
- F2 **Scenario** and AC-08: add "**and a 10 s Title idle run** (Night, light rain, Reduce Motion off) per device
  class".
- AC-09: "the F2 capture's logged per-pixel maximum stays < 0.8" gains "**over pixels with R + G + B ≥ 0.1**
  (normalised): near-black pixels are excluded as rounding noise, since (1,0,0) reads 1.0 and can't carry a saturated-red
  transition". This excludes noise; it is **not** a threshold change (0.8 stays).
- F2 **The 10° field** table: add the **Mac 1× floor, 72 ppi: `field_px` 148.8, `area_max` 4,347** (ADR-0013 D6), with
  the note "G4 uses each class's floor; the device run uses its real ppi".

These are text changes; F2's rule and thresholds are unchanged (the 72 ppi row and the Title run are stricter, never looser). The owner (game-qc-ios) makes it in a follow-up once
this ADR is reviewed.

## Open Questions
- **120 Hz:** if a later ADR lifts ADR-0006 D3's 60 fps cap, G4 runs at the new cap and AC-07's 120 Hz tests become
  live input, not only unit tests.

## Related
- ADR-0011 (gates, evidence; extended by D1), ADR-0003 (validator; G1, G2), ADR-0002 (clock, `tick`, seeds), ADR-0006
  (D3 cap, D7 ppi; D6 here inverts D7's choice for flashes), ADR-0009 D6 (closed here), ADR-0004 Excluded (now
  decided), ADR-0010 (DeviceSpike Audio's press flash, Risks).
- `design/gdd/accessibility.md` (A4, F1, F2, F2b, AC-05–AC-09); `design/gdd/cast-rendering.md` AC-11; K-26; K-34;
  K-42; `production/qa/device-checks-plan.md` (P-3, M-12; Spike runs);
  `docs/architecture/architecture-review-2026-11-18.md` (P-1, B-3).
