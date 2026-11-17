# MorphCore

> **Status**: In Review
> **Author**: game-dev-android for Luan (TASK-038)
> **Last Updated**: 2026-11-18
> **Last Verified**: 2026-11-18
> **Implements Pillar**: Pillar 2 (The Letter Comes Alive); serves Pillar 1 (Every Press Answers) and Pillar 3 (Calm Magic)

## Summary

MorphCore turns a letter or digit outline into a cast member's silhouette as a cloud of stardust particles. It is
pure maths with no UI: given two outlines, a timing set and a seed, it says where every particle is at any moment
after the press. The recipe is fixed by **morph contract v1** (`docs/architecture/morph-contract-v1.md`), so the
Apple and Android apps compute the same positions. This GDD covers what MorphCore owns, the timing data, and the
tests. It never restates or changes the contract.

> **Quick reference** — Layer: `Foundation` · Priority: `MVP` · Key deps: `None` (reads Key Table & Theme Data's
> paths and the morph timing data; read by Cast Rendering, Reveal Stage and Accessibility)

## Overview

Every press in this game ends with the same small miracle: the glowing letter breaks into stardust, and the
stardust flies into the shape of the thing the letter stands for. MorphCore is the part of the game that knows
where each speck of stardust is. It is UI-free (ADR-0001 Decision 4): it does not draw, play sounds, read a
clock or remember anything between reveals. The Reveal Stage asks it, frame by frame, "where is particle *i* at
*s* seconds after the press?" and draws the answer.

The numbers follow the morph contract exactly. A port is correct when it reproduces the shared fixture
`content/fixtures/morph-contract-v1.json` within ±1e-3. The Swift reference and an independent Kotlin port
already match it bit for bit (TASK-035).

## Player Fantasy

The child never sees MorphCore; they see its result. **"My letter turned into the dinosaur."** The letter they
pressed stays recognisably *theirs* while it glows, then visibly becomes the creature: the stardust leaves from
the letter's own outline and lands on the creature's own outline, so the link between the symbol and the thing is
shown, not told. The motion is a drift, never a burst (art bible §1, "the light gently settles into the thing"):
every speck slows to a stop as it lands, and the reveal ends quieter than it began (art bible §2).

## Detailed Design

### Core Rules

**1. What MorphCore owns.**
- **Build a morph** once per reveal from three inputs:
  - the **glyph path** (the pressed key's baked outline, from Key Table & Theme Data);
  - the **silhouette path** (the cast member's one compound path, from Key Table & Theme Data);
  - a **morph spec**: particle count, seed and the contract's timing fields (contract §1).
  The result holds the start points, end points, pairing and per-particle draws (contract §3–§5). It is
  immutable.
- **Answer position(i, s)** for any particle *i* and any time *s* (seconds since the press), by contract §6.
- **Expose the morph's duration T** and its **phase at s** (Formulas F2, F6), derived from the spec.
- **Provide the v1 path parser** that the bake tool's CI check uses to parse every key-table path (contract §8).

**2. What MorphCore does not own.**

| Concern | Owner |
|---|---|
| Mapping unit-box positions to the screen (the glyph's box, the creature's box on the stage) | Reveal Stage |
| Drawing particles (size, colour, twinkle, blending, fade-out) and the solid glyph and creature pictures | Cast Rendering and Reveal Stage; how SVG reaches the screen is the later SVG-rendering ADR |
| The glyph's halo pulse (~2.2 Hz, art bible §2) and the creature's fade-in (`form_s`) | Reveal Stage |
| How long a reveal holds while keys wait, and when the next reveal starts | Press Queue (systems-index circular-dependency note) |
| Whether the normal or the reduced timing set applies | Accessibility (supplies the Reduce Motion / "Remove animations" flag) |
| Where the seed comes from | The caller (Reveal Stage), through an injected source (Rule 5) |

**3. Positions out, nothing else.** Positions are in the contract's unit box: centred on (0, 0), longer side 1,
y pointing down (contract §3.4). The glyph's points (`from`) and the silhouette's points (`to`) are each
normalised to their own unit box. Placing those two boxes on screen is the Reveal Stage's job.

**4. The solid glyph comes first.** While `s ≤ glow` every particle sits exactly on its start point, which lies on
the glyph's outline. During that time the stage draws the **solid glyph**, not particles: the glyph rises from its
key and grows (`letter_in_s`), then glows with its halo (`glow_s`). At `s > glow` the stage swaps the solid glyph
for the particles. Because the particles start on the same baked outline the glyph is drawn from, the swap has no
jump, as long as the stage maps the glyph's unit box to the glyph's drawn box at that moment.

**5. Determinism and seeds.**
- The same glyph path, silhouette path, spec and seed give the same positions on every platform, within ±1e-3.
  That is what the shared fixture proves.
- The seed is an input. Its **source is not part of the cross-platform contract**: MorphCore takes any injectable
  unsigned 64-bit source, and the two platforms need not derive seeds the same way. Tests inject fixed seeds.
- **Seed policy (decided, Luan 2026-11-18):** a **different morph on every press**. The caller derives the seed
  from (key, press count), where the press count is the number of reveals started since launch, so a reveal can
  be reproduced from those two values. Debug builds log the key, the count and the seed with each reveal. The
  mixing function is each platform's own (it is not part of the contract).

**6. Interruption.** A morph holds no running state, so there is nothing to cancel inside MorphCore. When the Press
Queue starts the next reveal, the Reveal Stage stops asking the old morph and builds a new one. At most one morph
is active at a time (the TASK-033 spike's 60 s mash at 10 presses/s held at most one).

**7. No hold in the spec.** The production morph spec has no `hold` field (the spike's `MorphSpec.hold` is not
carried over). The hold belongs to the Press Queue.

**8. Timing data.** Both timing sets are bundled content data, never code (ADR-0001 Decision 6):
- the **normal** set;
- the **reduced** set, used when Reduce Motion (iOS/macOS) or "Remove animations" (Android) is on (art bible
  §7). It is just another spec; the contract's rules don't change (contract §1).
- The data uses the designer-facing fields of the one-shot prototype (Tuning Knobs). MorphCore's loader turns
  them into the contract's spec by Formula F1 (**decided**, Luan 2026-11-18: the rise folds into the glyph phase,
  `travel = flow + spread`, so one speck's flight is `flow_s`; `morph_speed` stays a knob).
- **Particle count (decided, Luan 2026-11-18):** **240**, the count measured in TASK-033. It is raised only after
  the real-iPad measurement (AC-11). It is in the same data.
- The reduced values are **provisional** data values, tuned in play. The Accessibility GDD owns the switch.

**9. Validation.** The timing data ships inside the app, so it is checked **at build time**: a test (AC-7) loads
the shipped normal and reduced sets and fails the build on any value out of range, missing or not a number. The
same test reports (but does not fail on) a reveal (F5) longer than the Press Queue's hold; the Press Queue GDD
decides whether that becomes an error. At run time the loader checks again. A set that fails is rejected as a
whole, **no morph is built**, and the reveal takes the missing-glyph fallback (the creature fades in); debug
builds log it. There are no hard-coded fallback timings (ADR-0001 Decision 6), and a morph is never built from
an invalid spec.

### States and Transitions

MorphCore itself is stateless. A built morph has phases that are pure functions of *s* (F6):

| Phase | When | Particles | The stage shows |
|---|---|---|---|
| Glyph | `s ≤ glow` | exactly on `from[i]` | the solid glyph (rise, then glow and halo) |
| Dissolve | `glow < s ≤ glow + dissolve` | drift off the outline by up to `drift` | stardust in the letter's outline |
| Travel | `glow + dissolve < s < T` | each flies along its curve, starting at its own delay | stardust flowing to the creature |
| Formed | `s ≥ T` | exactly on `to[perm[i]]` | the creature fades in, stardust fades out (`form_s`, Reveal Stage) |

The Reveal Stage reports "formed" to the Press Queue at `s ≥ T`. MorphCore only exposes T.

### Interactions with Other Systems

| System | Direction | What passes |
|---|---|---|
| Key Table & Theme Data | in | the glyph path for each key and the silhouette path for each cast member, as v1-subset path strings |
| Accessibility | in | the Reduce Motion / "Remove animations" flag that picks the timing set |
| Reveal Stage | out | build a morph per reveal; position(i, s), T and phase(s) each frame |
| Cast Rendering | out | unit-box positions to draw particles at |
| Press Queue | none directly | the Press Queue owns the hold. Constraint for its GDD: the normal hold should be ≥ T + `form_s` (F5) |
| Bake tool / CI | out | the v1 parser that rejects any key-table path outside the subset |

## Formulas

The particle maths is **contract §2–§6** and is not repeated here. These formulas define how the tuning data
becomes the contract's spec, and the timings that follow from it.

**Variables** (seconds unless noted; ranges in Tuning Knobs):

| Variable | Meaning |
|---|---|
| `letter_in_s` | the glyph rises from its key and grows |
| `glow_s` | the glyph glows at the centre |
| `dissolve_s` | the glyph becomes stardust in its own outline |
| `flow_s` | **one particle's flight time** to the silhouette |
| `spread_s` | the largest start delay between particles; arrivals spread over this window |
| `drift` | unit-box units: the largest dissolve drift per axis |
| `swirl` | unitless: how much each flight curves |
| `particles` | the particle count N |
| `morph_speed` | unitless multiplier; 2 = twice as fast |

**F1. Data → contract spec.**
```
glow     = (letter_in_s + glow_s) / morph_speed
dissolve = dissolve_s / morph_speed
spread   = spread_s / morph_speed
travel   = (flow_s + spread_s) / morph_speed
drift    = drift            (unchanged)
swirl    = swirl            (unchanged)
count    = particles
```
`letter_in_s` folds into the contract's `glow` because particles don't move while the glyph rises (Rule 4).

**F2. Per-particle flight time.** In the contract, particle *i* starts flying at `glow + dissolve + delay_i`, with
`delay_i ∈ [0, spread)`, and flies for `travel − spread` (contract §5–§6). With F1:
```
flight = travel − spread = flow_s / morph_speed
```
So `flow_s` keeps its prototype meaning, the time one speck takes to fly. Mapping `flow_s` straight to `travel`
instead would silently shorten every flight by `spread`: 0.9 − 0.35 = 0.55 s.

**F3. Morph duration.**
```
T = glow + dissolve + travel
  = (letter_in_s + glow_s + dissolve_s + flow_s + spread_s) / morph_speed
```

**F4. Arrival window.** The first particle can land at `glow + dissolve + flight`; the last lands by T. Arrivals
are spread over `spread`.

**F5. Visible reveal length** (owned by the Reveal Stage, stated here for the Press Queue's constraint):
```
reveal = T + form_s / morph_speed
```

**F6. Phase at s.** Glyph if `s ≤ glow`; Dissolve if `s ≤ glow + dissolve`; Travel if `s < T`; otherwise Formed.

**F7. What drift and swirl look like.**
- Drift: each particle moves up to `drift` per axis while dissolving, so at most `drift·√2` in total. With
  drift 0.06, that is 6% of the glyph's longer side per axis.
- Swirl: the curve's control point sits `bow` times the flight distance to the side (contract §6), so the
  sideways bulge at the flight's midpoint is `|bow|/2` of the straight distance. Since `|bow| ≤ swirl`, the
  largest bulge is `swirl/2`: 17.5% of the distance at swirl 0.35. Swirl 0 means straight flights.

**F8. Settling.** The contract's `smooth(u) = v²(3 − 2v)` has zero slope at both ends. Every particle starts and
ends its flight at zero speed, which is the "gently settles" of the art bible. This is a property of contract v1
and needs no tuning.

**Worked examples.**

| | glow | dissolve | travel | spread | flight (F2) | T (F3) | + form (F5) |
|---|---|---|---|---|---|---|---|
| Fixture `D-dinosaur` (the TASK-033 spike) | 0.45 | 0.35 | 1.1 | 0.35 | 0.75 | **1.9** | — |
| Normal (one-shot values via F1, decided) | 0.45 + 0.35 = 0.8 | 0.4 | 0.9 + 0.35 = 1.25 | 0.35 | **0.9** | **2.45** | 2.95 (≤ hold 3.0) |
| Reduced (provisional, Q3) | 0.25 + 0.15 = 0.4 | 0.2 | 0.5 + 0.1 = 0.6 | 0.1 | 0.5 | **1.2** | 1.5 with `form_s` 0.3 |

The fixture checks `D-dinosaur` at s = 0, 0.625 (mid-dissolve: 0.45 + 0.35/2), 0.95 (T/2) and 1.9 (T), which
matches F3 and F6.

## Edge Cases

| Case | What happens |
|---|---|
| **Silhouette path missing or empty** (no points, or total length 0) | No morph is built. The glyph glows and sparkles out (the fallback agreed for the Key Table & Theme Data GDD, written in parallel); debug builds log it. Never a crash. |
| **Glyph path missing or empty** | No morph is built. The creature fades in on its own; debug builds log it. |
| **A path fails to parse at run time** | Treated as missing (the two rows above). CI should make this impossible (contract §8). |
| **Count 1** | One particle; no shuffle draws (contract §5). Covered by fixture `count-1`. |
| **Zero-length segments, a lone trailing `M`** | Handled by the contract (kept segments; dropped 1-point subpaths). Covered by fixture `zero-length`. |
| **A silhouette with several pieces** (digit 3 → three baby dinosaurs; 0 → an empty nest) | Points are shared by arc length over all pieces together (contract §3), so a smaller baby gets fewer particles. **Decided (Luan, 2026-11-18): keep this v1 behaviour**; an even share per piece would be contract v2. |
| **Thin glyphs** (I, 1, l) | The unit box scales by the longer side, so a thin glyph keeps its proportions and stays narrow. |
| **Count or any timing out of range** | The build-time test fails (Rule 9). If bad data still reaches a device, no morph is built and the creature fades in; debug builds log it. |
| **`s < 0`** (a frame timestamp before the press) | Treated as the Glyph phase: positions are `from[i]` (contract §6, `s ≤ glow`). |
| **`s` far past T** | Positions stay exactly on `to[perm[i]]`. |
| **`dissolve` = 0** (e.g. `morph_speed` with `dissolve_s` at a floor) | The Dissolve phase is empty, and the contract never divides by it. Allowed by the contract; the data range keeps `dissolve_s ≥ 0.1` anyway. |
| **Reduce Motion changes during a reveal** | The running reveal keeps its spec; the next press uses the new set. |
| **A new reveal starts before T** | The old morph is dropped mid-flight (Rule 6). The Press Queue owns when that may happen. |
| **Two platforms disagree on a case** | The contract and fixture decide. A port that misses ±1e-3 is wrong; the fixture is not regenerated to fit it (contract versioning). |

## Dependencies

**Upstream (MorphCore reads):**
- **Key Table & Theme Data:** glyph and silhouette path strings (morph input data, not how anything is drawn;
  ADR-0001 Decision 6).
- **Morph timing data:** the normal and reduced sets with the particle count, bundled content. The file's name
  and location are chosen in architecture.
- **Accessibility:** the reduced-motion flag (Vertical Slice; the MVP uses the normal set).

**Downstream (read MorphCore):**
- **Reveal Stage:** builds a morph per reveal and asks for positions, T and the phase.
- **Cast Rendering:** draws particles at the positions.
- **Accessibility:** relies on the reduced set existing and being honoured.

**Normative references (this GDD defers to them):**
- `docs/architecture/morph-contract-v1.md` ("morph-v1"): the recipe.
- `content/fixtures/morph-contract-v1.json`: the shared fixture, 4 cases + 8 tokenizer cases.
- `docs/architecture/adr-0001-native-apple.md`, Decisions 4 and 6.
- The later Android ADR adopts the same contract and fixture (ADR-0001, Open follow-up 5).

## Tuning Knobs

All values live in the morph timing data. The normal set and the count are decided (Rule 8); the reduced set is
provisional and tuned in play (Q3).

| Knob | Normal | Reduced (provisional) | Range | Source | Effect |
|---|---|---|---|---|---|
| `letter_in_s` | 0.45 | 0.25 | 0.1–1.5 | one-shot config | longer rise from the key |
| `glow_s` | 0.35 | 0.15 | 0–1.5 | one-shot config | longer look at the solid glyph |
| `dissolve_s` | 0.4 | 0.2 | 0.1–1.5 | one-shot config | slower break into stardust |
| `flow_s` | 0.9 | 0.5 | 0.2–2.5 | one-shot config | each speck's flight time (F2) |
| `spread_s` | 0.35 | 0.1 | 0–1.0 | TASK-033 spike | wider spread of start times and arrivals |
| `drift` | 0.06 | 0.02 | 0–0.15 | TASK-033 spike | how far stardust wanders while dissolving (F7) |
| `swirl` | 0.35 | 0 | 0–1 | one-shot config, spike | how much flights curve (F7); 0 = straight |
| `particles` | **240** | 240 | 100–900 | measured in TASK-033 (decided); art bible §8's 420 waits for the iPad measurement | denser stardust; above 240 is NOT ASSESSED on a device |
| `morph_speed` | 1 | 1 | 0.5–2 | one-shot config | scales every time (F1) |

`form_s` (0.5 in the one-shot) is the Reveal Stage's knob, not MorphCore's. The hold (~3 s) is the Press Queue's.

**Interactions between knobs:** T (F3) grows with every time knob. Keep the normal `reveal` (F5) at or below the
Press Queue's hold, or a waiting key will start before the creature has formed. Raising `spread_s` lengthens T
without changing any single flight.

## Visual/Audio Requirements

MorphCore has none of its own. The art bible rules it serves are drawn by others:
- the glyph is the brightest thing on screen, and the stardust keeps the glyph's outline before it becomes the
  creature (§1; MorphCore's `from` points lie on that outline, the drawing is Reveal Stage and Cast Rendering);
- the halo pulses at ~2.2 Hz while the glyph glows (§2, Reveal Stage);
- the reveal ends quieter than it began (§2): the motion settles (F8), and the light fades (Reveal Stage);
- detail per size (§5) applies to the creature pictures, not to the silhouette path.

## Game Feel

- **The press answers at once:** s = 0 is the press, and the glyph phase starts there (Pillar 1).
- **Drift, never flash:** smoothstep easing gives every speck a soft start and a soft landing (F8).
- **Readable flights:** `flow_s` sets each flight directly (F2). The 0.9 s is slower than the spike's
  0.75 s, matching the one-shot that Luan played.
- **Reduced motion is shorter and straighter:** less drift, no swirl, about half the duration.

## UI Requirements

None. MorphCore has no UI.

## Cross-References

- `design/gdd/systems-index.md`: system #3; the Press Queue ↔ Reveal Stage circular-dependency note.
- `design/art/art-bible.md`: §1–§2 (visual rule, halo, settling), §5 (detail per size), §7 (Reduce Motion), §8
  (420 particles, silhouette export).
- `design/tech/TASK-033-anim-runtime.md`: why the morph is procedural and native; the measured numbers.
- `prototypes/letter-morph-dinosaur/config.js`: the one-shot's timing knobs (never imported).
- `production/qa/evidence/TASK-033/procedure-ipad.md`: the iPad device procedure.

## Acceptance Criteria

Each criterion applies to **both** platforms (the Apple `MorphCore` and the later Android port) unless marked.

1. **AC-1 Fixture cases.** For every case in `content/fixtures/morph-contract-v1.json`, the implementation's
   `from`, `to` and `positions` at every listed time are within ±1e-3 of the fixture; `pairing` and `rngFirst4`
   are exactly equal.
2. **AC-2 Tokenizer cases.** Every tokenizer case's polylines equal the fixture's (all 8).
3. **AC-3 Versioning.** The implementation declares its contract id ("morph-v1"), and a test fails if it differs
   from the fixture's `contract` field. Changing any contract rule means a new version and a regenerated fixture;
   the fixture is never regenerated to make a failing port pass.
4. **AC-4 Purity.** MorphCore builds with no UI or platform framework imports (no SwiftUI, SpriteKit, UIKit,
   AppKit; no android.*), reads no clock, and building the same morph twice gives identical results.
5. **AC-5 Phase ends.** For a test spec, positions at `s ≤ glow` equal `from[i]` exactly, and at `s ≥ T` equal
   `to[perm[i]]` exactly; `phase(s)` follows F6 at each boundary.
6. **AC-6 Data mapping.** Loading the timing data gives the contract spec of F1. A unit test checks the
   normal set: glow 0.8, dissolve 0.4, travel 1.25, spread 0.35, flight 0.9, T 2.45.
7. **AC-7 Validation.** Each range rule in Tuning Knobs has a test: an out-of-range, missing or non-numeric value
   rejects the set, and the loader then builds no morph (the stage gets "no morph"). A build-time test validates
   the shipped normal and reduced sets and fails the build if either is invalid.
8. **AC-8 Reduced set.** With the reduced-motion flag injected on, a new morph uses the reduced set; a morph
   already built keeps its spec.
9. **AC-9 Empty paths.** An empty or unparsable glyph or silhouette builds no morph and never throws to the stage;
   the stage gets "no morph" with which side was missing.
10. **AC-10 Key-table paths (CI).** Every glyph and silhouette path in the key table parses with the v1 parser
    and has a non-zero total length. Shared with Key Table & Theme Data and the bake tool.
11. **AC-11 Performance (advisory, NOT ASSESSED).** With the default particle count, frame time p99 during a
    reveal is at or below one display refresh (16.7 ms at 60 Hz, 8.3 ms at 120 Hz) on a real iPad, measured with
    `production/qa/evidence/TASK-033/procedure-ipad.md`. The budget is proposed; the Mac spike run (26.7 ms p99 at
    75 Hz, whole app) did not meet it, so it is checked on the device before the count is raised. Android is measured in its own spike
    on a low-end tablet. Until then the count stays at the measured 240. The spike's numbers (SpriteKit, 240
    particles, frame p99 17.1 ms Simulator and 26.7 ms Mac) are not device numbers.

12. **AC-12 Seed policy (each platform's own test).** Two presses of the same key in one session give different
    seeds; the same (key, press count) gives the same seed; debug builds log key, count and seed per reveal.

## Open Questions

- **Q3. Reduced set (provisional).** The reduced values in Tuning Knobs are provisional data values, tuned in
  play; the Accessibility GDD owns the switch. Whether reduced motion should also lower the particle count is
  part of that tuning.

**Resolved (Luan, 2026-11-18), now in the rules:** Q1 particle count 240 until the iPad measurement (Rule 8);
Q2 a different morph per press, seeded from (key, press count) (Rule 5); Q4 the F1 timing mapping (Rule 8, F1);
Q5 arc-length sharing across pieces stays v1 (Edge Cases).
