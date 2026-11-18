# ADR-0009: Render path for the layered cast art (live paths, textures, or a mix)

## Status

Proposed (TASK-103, 2026-11-18). **Acceptance waits for the device rows P-2 and M-13** under the decision rule
fixed in TASK-075 (Decision, D1); the same build serves P-3 / M-12, P-11 / M-10 and P-13. No device row has run.

> **Who may move this to `Accepted`: the user, or `technical-director` on the
> user's explicit confirmation. No other agent, and no skill on its own.**

## Date

2026-11-18

## Last Verified

2026-11-18, against Cast Rendering (R1–R12, F1, F6, AC-11, AC-15, AC-17), MorphCore AC-11, the art bible §4 and §8
(the render conflict), ADR-0001, ADR-0002 (D6 `RenderSink`), ADR-0003 (D1, D4 with the K-37 a1 layer ids), ADR-0006
(D1–D3, D5, D8), the TASK-075 spike plan (ADR-0009 section), the device-checks plan (P-2, P-3, P-11, P-13, M-10,
M-12, M-13), `prototypes/DeviceSpike` Render A/B (TASK-078) with TASK-077's three test creatures, and the headless
measurement H-1 below.

## Decision Makers

Luan (accepts, after the rows); game-dev-android (author, TASK-103); game-dev-ios (expert review: TASK-075 plan and
the DeviceSpike Render screen); game-qc-ios (checks the rows and evidence pointers); game-leader.

## Summary

Cast Rendering R11 left open how the layered SVG art reaches the screen: **A**, live vector paths, or **B**, textures
per part, or a mix by role. This ADR fixes the shared structure both options draw (D2), how each option draws on
Apple (D3, D4), how memory and loading work (D5), and the **decision rule fixed in TASK-075** (D1), which the device
rows P-2 and M-13 apply. Headless, it measures what needs no device: **option B costs ~179 KB of PNG per creature
across its three tiers against ~3.3 KB of SVG for A (~6.2 MB vs ~0.1 MB extrapolated to 36 items; partial,
3 test creatures)**, and a stage texture set is **2.3–3.4 MB**, about twice Cast Rendering F6's per-set figure (a
finding for F6). Frame time and load time are **pending P-2 / M-13**; Simulator numbers were not taken (the leader
dropped the Simulator smoke: boots pushed the Mac's load into the 40s–50s, and they are never device evidence).

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | None from the template's table (ADR-0001, K-28). Swift 6.4, Xcode 27.1, SDKs iOS 27.1 / macOS 27.0, deployment 26 |
| **Domain** | Rendering |
| **Layer** | Platform adapter (app target), behind `RenderSink` (ADR-0002 D6) and Cast Rendering R12 |
| **Knowledge Risk** | HIGH for `SKShapeNode` frame cost with ~25 shapes per creature × 8 figures (unmeasured on any device); MEDIUM for texture upload time on the oldest iPad; LOW for the size and memory figures (measured headless, H-1) |
| **References Consulted** | `docs/engine-reference-local/native-apple/` (SpriteKit notes); TASK-033 measurements (one flat silhouette `SKShapeNode` only); `prototypes/DeviceSpike` Render A/B source; TASK-077 art; H-1 |
| **Post-Cutoff APIs Used** | None. `SKShapeNode`, `SKSpriteNode`, `SKTexture(cgImage:)`, `CGContext`, ImageIO are long-standing |
| **Verification Required** | H-1 (done), H-2 and H-3 (the production renderer story), rows P-2, M-13 (decide), P-3 / M-12, P-11 / M-10, P-13 (same build) |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0001 (Accepted); ADR-0002 (Accepted: D6 `RenderSink`); ADR-0003 (Accepted: D1 layout, D4 the bake and the a1 layer ids); ADR-0006 (Accepted: D1 layers, D2 stage fit, D3 frame driver, D5 Smart Invert, D8 "measured here") |
| **Enables** | The Cast Rendering adapter story; the bake tool story's output list (B adds PNG tiers, A does not); ADR-0012's render mapping |
| **Blocks** | The Cast Rendering adapter story's choice of renderer (the R12 interface and the baked format do not wait, D2) |
| **Ordering Note** | Second of the four ★ spike ADRs (TASK-075 order: 0010 → 0009 → 0007 → 0008) |

## Context

### Problem Statement
The art is layered SVG (Cast Rendering R2; ADR-0003 D4 bakes it into one JSON per creature). SpriteKit has no SVG
renderer. A draws each part's paths live (`SKShapeNode`); B draws each part as a texture. The art bible §8 records the
conflict (Luan, 2026-11-17: "record both, decide in architecture, backed by a real-iPad measurement"). The only device
data so far is TASK-033's one flat silhouette `SKShapeNode` (fine), which says nothing about ~25 shapes per creature,
three layers, eight figures at once and the full Scene worst case.

### Current State
- `DeviceSpike` Render (TASK-078) implements both options over the full stage (Scene F6 worst case, 240 specks, the
  glyph, a current and a leaving creature, a parade of 6), with an A/B switch, the Metrics recorder, a frame dump and a
  60 / 120 Hz switch. It builds headless; **no device run yet**.
- TASK-077 delivered **three** layered test creatures (sauropod 4 parts / 26 shapes, flyer 3 / 25, rex 5 / 27). The
  Dinosaurs set has 36 items; real items may carry more `detail`.

### Constraints
- Offline, no third-party rendering code (PKC-03); SpriteKit and Core Graphics only (ADR-0001).
- 60 fps cap (ADR-0006 D3; 120 Hz is measured, not adopted, here).
- The draw interface carries no platform types (Cast Rendering R12, AC-16); Android mirrors it (ADR-0012).
- The device the rule names, "the oldest supported iPad", is not yet fixed (the child's iPad model is unknown; the
  device-checks plan asks for the oldest available).

### Requirements
- p99 frame time ≤ 16.7 ms on the oldest supported iPad with the combined worst case (Cast Rendering R11, AC-17;
  MorphCore AC-11).
- One creature's load at any role well within the reduced T, 1.2 s (R10, R11).
- Resident memory per F6; crispness at ~775 px on a 13" iPad; app size reported for the 36 items.
- The outline layer reads as **one** 80% Ink stroke per part: overlapping outline strokes within a part never darken
  (art bible §4; TASK-077 art notes).

## Decision

### D1. The decision rule (fixed in TASK-075, before any row runs)
**Rule (platform-neutral).** The rows measure both options on the same build, art and stage:
| Outcome on the oldest supported iPad (P-2; the Mac, M-13, must not contradict it) | Choice |
|---|---|
| **A misses p99 ≤ 16.7 ms** with the combined worst case, **or** one creature's load at a role exceeds **1.2 s** | **B** (textures) |
| **A passes both** | **A** (live paths). App size is only the tie-break against B-build, the fallback within B (below); B-load keeps A's size (leader, 2026-11-18, closing the gap B-load opened) |
| **Only the parade fails under A** (stage and leaving pass; the 6-walker parade phase misses p99) | **Mix:** A for `stage` and `list`, B for `parade` |
| B also misses p99 | neither is accepted: raise to Luan with the per-layer node counts and the split (the stage, not the cast, is then the budget problem) |
Acceptance needs P-2 and M-13 run, or Luan accepting a recorded exception. **Headless status:** against B-build, A's
app size is smaller by ~6 MB over 36 items (H-1, partial); against B-load the sizes are the same. The frame-time and
load-time conditions are **pending P-2 / M-13**.
**Spike rows decide this ADR. Cast Rendering AC-17 and MorphCore AC-11 are partial on the spike** (3 test creatures,
not 36; no 240-speck raise) **and pass only on the production re-run. P-3 / M-12 rehearse Accessibility AC-08**
(the release gate is the production K-26 busy case).

**How "B" is built, once chosen** (a refinement within the rule, not a change to it): the rule picks the *family*
(textures). Within it, **B-load** (each part rasterised once **on the device at load**, at the tier the screen needs)
is preferred to **B-build** (PNG tiers made at build time), because it keeps A's app size and is crisp at the exact
size; **B-build** is used if B-load's measured load time on the oldest iPad exceeds 1.2 s for a creature. The spike's
option B **is** B-load (it rasterises at load, at 2.5×), so P-2 measures it directly; B-build would only load faster.

**Apple.** P-2 and M-13 use `DeviceSpike` Render with TASK-077's art, options **A-candidate** (D3: outline merged per
part, fills per element; the A the rule judges), **B** (B-load) and, for information, the original per-element A; the
Metrics recorder gives p50 / p99 over the worst case per option, and the screen logs per-creature build ms per
option. The A-candidate option ("A: candidate (ADR-0009 D3)") and H-2's **Overlap check** button are in DeviceSpike at
**d21588c0** (game-dev-ios, design/TASK-103-devicespike-a-candidate; build logs in
`production/qa/evidence/TASK-103/d21588c0/`); the follow-up **b4fa26c9** (logs 99962cff,
`production/qa/evidence/TASK-103/b4fa26c9/`) is **the build P-2 and M-13 run**: the effect-node outline by default
(D3), the device Overlap check switching to stroke or node alpha only where those blend once, parade walkers drawing
`body` + `outline` for every option (R3), and `outline=<variant>` in the `[render]` line. H-2 is answered (headless, 6e455bfc; Validation), and P-2
records which outline path (the effect node, or the texture fallback) its A-candidate numbers come from.

### D2. One structure, both options (platform-neutral)
- Both options read **the same baked file** (ADR-0003 D4): parts with pivots, nested; inside each part the layers
  `body`, `outline`, `detail` in that order, identified by the a1 id rule (`<part>_<layer>`, last segment).
- **A figure is a tree of part nodes**, each at its pivot relative to its parent part, so idles (Cast Rendering R7)
  rotate parts about pivots in both options; the stage root carries ADR-0006 D2's fit and y flip.
- **Role** (R3) selects what is drawn: `stage` every layer; `list` `body` + `outline` + `detail` elements ≥ 6 px
  (F1, using the bake's recorded detail boxes); `parade` `body` + `outline` only. A walker that is also the stage
  creature has two resident copies (R10).
- **The outline layer is drawn as one unit per part** with its 80% group opacity, so overlaps within a part never
  darken. (Overlaps *between* parts may, as in the SVG, where each part's outline group has its own opacity.)
- Per-look colour (Cast Rendering F8, K-25) is a **multiply on the part's colours at draw time**, not baked into the
  art, in both options.
- Everything above `RenderSink` (KidCore's render plan, R12's `drawCast(castId, role, pose)`) is the same for A, B and
  the mix; switching is an adapter change, and the baked format never changes with it.

### D3. Option A, live paths
**Rule.** Parse the baked file once per figure at load; draw each part's paths with solid fills and round strokes.
**Merge only the outline layer**, into one stroked path per part. **Fills stay one shape each**: merging fills into one
path is not safe, because with the default nonzero winding rule two overlapping shapes of opposite winding cancel and
leave a hole (game-dev-ios, TASK-103 review).

**Apple.** One `SKShapeNode` per fill shape and one per part's merged outline path (`fillColor`, `strokeColor`,
`lineWidth`, `.round` joins and caps, antialiased). **The outline is the merged path stroked opaque inside an
`SKEffectNode` with `shouldRasterize`, one per part, at the layer's opacity (0.8)**: H-2 (headless, 6e455bfc) showed a
single `SKShapeNode` blends its own self-overlap **twice** at 0.8 (crossing 0.961 against arm 0.800, for stroke alpha
and node alpha alike), and the effect node blends **once**. The effect node is the default; **if the device's
Overlap check shows a single node blending once** (stroke alpha first, then node alpha), that cheaper form is used on
that device and P-2 records it (the spike's `outline=<variant>`). The effect node holds only that part's outline, which never
changes, so its raster is reused while the part's own node rotates (idles); a per-look colour change (F8) re-rasterises
it once. P-2 checks two things this introduces: the raster stays crisp at the stage size, and it is not rebuilt per
frame (the frame log after a reveal starts). If either fails, the outline layer becomes a texture (B's rasteriser for
that layer alone). Per-look colour sets `fillColor` / `strokeColor` from the base colour × F8's
factor, only when the factor changes (the 1 s edge dissolve, F8), not every frame.
**Node count**, measured by game-dev-ios on TASK-077's three SVGs: outline merged per part and fills per element give
**19–23 nodes per stage figure and 12–15 per parade walker**. The spike draws one node per SVG element (25–27 per
figure, 8 figures, every layer in the parade), so **its A is about 15–25% above this candidate**: an upper bound, but
a close one.

### D4. Option B, textures per part
**Rule.** Each part becomes one texture per tier, drawn as a sprite at its pivot. A tier is the smallest whose
**height** is at least the figure's on-screen height in physical pixels (R3; tiers are data: stage ≤ 1024, list and
parade 256). Each part's texture is its layers rasterised **with the layer's group opacity applied once** (an offscreen
layer per group), so the outline matches A and the SVG.

**Apple.** B-load: off the main thread, a `CGContext` per part at the tier scale (tier / 440 px per artboard unit),
each layer drawn inside a transparency layer at its group alpha, then `SKTexture(cgImage:)`; textures for one figure
are created before the figure is shown (R10's resident check). B-build (fallback, D1): the bake tool writes
`cast/<stem>/<part>@<tier>.png` (ADR-0003 D1's optional layout) with the same rasteriser. Per-look colour: the
sprite's `color` with `colorBlendFactor` 1 multiplies the texture by F8's factor. Mipmaps off for `stage` (drawn near
1:1), on for `list` if the panel scales it.

### D5. Memory and loading (platform-neutral, with H-1's figures)
- **Resident set** per Cast Rendering R10 / F6: current, leaving, the queued keys' figures (`queue_max` 3), and the
  parade's 6 at the parade role.
- **Measured texture bytes** (H-1, w × h × 4, parts only): stage set **2.27–3.41 MB**, parade set **0.14–0.21 MB**. So
  B's resident set is **≈ 5 × 2.8 + 6 × 0.17 ≈ 15 MB** (≈ 20 MB with mipmaps), within the F6 envelope; A's resident set
  is path data only (a few KB per figure) plus SpriteKit's tessellation buffers (measured by P-2).
- **F6 finding (for Cast Rendering):** F6 computes "a stage set at 1024 px tall … 1024 × 704 ≈ 2.9 MB", which treats
  1024 as the artboard's **width**. R3 makes a tier a **height**, so a whole-artboard stage image is 1490 × 1024 ≈
  6.1 MB; the part boxes cover only 37–56% of it (H-1), so real sets land at 2.3–3.4 MB, close to F6's per-set
  figure, but the 1.5× cap should be stated against the 1490 × 1024 image. Recorded for the Cast Rendering owner; no
  number in this ADR depends on F6's figure.
- **Loading** happens off the main thread (R10); a figure becomes resident only when every part is ready. B-load's
  rasterisation cost on the **Mac CPU** was 10–18 ms per stage set and ~1.3 ms per parade set (H-1); **device load time
  is pending P-2** against the 1.2 s bound.

### D6. Frame rate, flash gate, windows, Smart Invert (same build, not decided here)
- 60 fps stays the cap (ADR-0006 D3); P-2 records 120 Hz numbers for information (ADR-0006 D8).
- P-3 / M-12 rehearse Accessibility F2 on the spike's frame dump; the release gate is the production busy case.
- P-11 / M-10 close ADR-0006's window and ppi rows; P-13 checks the stage half of Smart Invert (ADR-0006 D5).
None of these changes the choice in D1.

### Architecture Diagram
```
baked cast JSON (ADR-0003 D4) ──load (off main)──▶ figure tree: parts at pivots, layers by a1 id
                                                     │
                       ┌─────────────── D1 picks ────┴──────────────┐
             A: SKShapeNode per part-layer-style          B: SKSpriteNode per part (texture per tier;
                (outline = one stroked path)                  B-load on device, B-build fallback)
                       └──────────────┬──────────────────────────────┘
KidCore render plan ── RenderSink.drawCast(castId, role, pose) ──▶ stage root (ADR-0006 D2) z20 leaving, z30 current, z10 parade
```

### Key Interfaces
| Interface | Owner | Note |
|---|---|---|
| `drawCast(castId, role, pose)`, `prefetch`, `release`, `isResident`, `willForm` | Cast Rendering R12 (KidCore side) | unchanged by the choice |
| `RenderSink` | ADR-0002 D6 | the Apple adapter holds the renderer A, B or the mix |
| baked cast JSON | ADR-0003 D4 | the same for both; B-build adds PNG tiers only if D1 lands there |

### Implementation Guidelines
- Write the renderer as one `CastFigure` adapter type with two backends behind it; the role decides the backend in the
  mix. Production code is written fresh from this ADR, not copied from `DeviceSpike` (prototype rule).
- A: merge each part's outline layer into one path at load, keep fills one shape each (D3); B: rasterise with group
  alpha. Parse once at load, never per frame.
- Unit tests (H-2): for each TASK-077 creature, A's and B's part bounding boxes agree within 1 px at each role; the
  outline overlap test (two overlapping strokes in one part read one alpha, not two).

## Alternatives Considered

### Alternative 1: A only, decided now
- **Rejected for now**: `SKShapeNode` cost at ~25 shapes × 8 figures with the worst-case stage is unmeasured; the
  rule needs P-2.

### Alternative 2: B-build only (PNG tiers at build time)
- **Kept as the fallback within B** (D1): proven frame cost, but ~6 MB more app (partial, H-1), a re-export on every
  art change, and fixed tiers (less crisp at sizes between tiers).

### Alternative 3: Render each figure once per role into a single texture (no parts)
- **Rejected**: idles rotate parts (K-16, R7), so a single texture would freeze the figure or need a re-render per
  frame.

### Alternative 4: A third-party SVG renderer
- **Rejected**: PKC-03 (no third-party code), and SpriteKit would still need textures.

## Consequences

### Positive
- The choice is an adapter change: the baked format, R12 and KidCore are the same for A, B and the mix.
- B-load keeps A's app size if textures win; the outline look is specified the same for both.
- The size and memory numbers no longer wait for a device (H-1).

### Negative
- Two backends exist until P-2 decides (the spike already has both; production writes the chosen one first).
- A per-look colour change re-sets node colours (A) during the 1 s edge dissolve; B's multiply is cheaper.

### Neutral
- The F6 arithmetic note goes to the Cast Rendering owner; nothing here depends on it.

## Risks
- **Partial evidence: 3 test creatures against 36 items.** Real items may have more `detail` shapes; the 36-item app
  size and memory are linear extrapolations, and P-2 runs on the test art. Mitigation: the production re-run of Cast
  Rendering AC-17 on the Dinosaurs set; the bake tool reports shapes per figure so outliers show at build.
- **"The oldest supported iPad" is not fixed.** Mitigation: P-2 records the model; a newer device's pass does not
  accept A for older ones (the row is re-run if the floor moves down).
- **A near miss is a real signal.** The spike's original A (one node per SVG element, every layer in the parade) is
  only about 15–25% above D3's candidate, so P-2 does not discount a narrow failure. DeviceSpike gains an
  **A-candidate** option (game-dev-ios; the leader accepted it): outline merged per part, fills per element. Its
  parade walkers must draw `body` + `outline` only (R3's parade role) for the "only the parade fails" row to judge
  the right A. **D1's A is the A-candidate's numbers**; the original A is recorded for information only. B is B-load at
  2.5× (an upper bound for B-build's load).
- **Texture upload stalls** on first draw (B) on an older GPU. Mitigation: textures created at load, off the main
  thread, before the figure is resident; P-2's frame log covers the first frames after a reveal starts.

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|--------------------------|
| cast-rendering.md R11, AC-17 | the render-path decision and its measurement | D1 (rule), D3, D4; rows P-2, M-13 (AC-17 partial on the spike: 3 creatures; passes only on the production re-run) |
| cast-rendering.md R2, R3, R7 | one baked file; roles; idles about pivots | D2 |
| cast-rendering.md R10, F6, AC-15 | resident set and memory | D5, H-1 |
| cast-rendering.md R12, AC-16 | no platform types in the draw interface | D2, Key Interfaces |
| cast-rendering.md F8 | per-look colour | D2, D3, D4 |
| morphcore.md AC-11 | p99 ≤ one refresh with 240 specks | D1 (the same run); partial on the spike, passes only on the production re-run (no 240-speck raise here) |
| art-bible.md §4, §8 | 80% outline; the render conflict; memory rule | D2, D3, D4, D5 |

## Performance Implications
- **CPU / GPU**: pending P-2 / M-13 (frame p50 / p99 per option, per phase: reveal, leaving, parade).
- **Memory**: B ≈ 15 MB resident (≈ 20 MB with mipmaps), measured headless (H-1); A path data plus tessellation
  (P-2).
- **Load time**: B-load 10–18 ms per stage set on the Mac CPU (H-1, not device evidence); device pending P-2.
- **App size**: A +~0.1 MB, B-build +~6.2 MB, B-load +~0.1 MB for 36 items (H-1, partial).

## Migration Plan
None: no cast rendering exists in `apple/`. The adapter story implements D2 and the backend D1 picks.

## Validation Criteria
Per K-34: headless runs need no MAC FREE; the Mac rows do.

**Headless:**
- **H-1 Size and memory (done, 2026-11-18, Mac CPU, not device evidence).** `option-b-size.swift`
  (in `production/qa/evidence/TASK-103/551108fd/`) parses TASK-077's three SVGs with the R2 subset and the a1 layer
  ids, rasterises every part per tier with group opacity (PNGs encoded in memory only), and reports:
  | Creature (parts, shapes) | SVG bytes (A) | B PNG bytes: stage 1024 / list 256 / parade 256 | Stage set texture | Part boxes / one image | Mac CPU raster ms (stage) |
  |---|---|---|---|---|---|
  | sauropod (4, 26) | 3,081 | 115,524 / 24,503 / 22,853 | 2.27 MB | 0.37 | 18.2 |
  | flyer (3, 25) | 2,888 | 132,791 / 26,002 / 23,999 | 3.41 MB | 0.56 | 12.8 |
  | rex (5, 27) | 3,836 | 136,270 / 28,429 / 27,016 | 2.60 MB | 0.43 | 9.8 |
  Per creature: **B ≈ 179 KB of PNG vs A ≈ 3.3 KB of SVG** (baked JSON is expected to be similar or smaller);
  ×36 (**partial, linear**): **≈ 6.2 MB vs ≈ 0.1 MB**. F6's 1.5× part-box cap holds (0.37–0.56 of the whole image).
- **H-2 Equivalence (the adapter story).** A's and B's part boxes within 1 px per role for the three creatures; the
  **outline-overlap test** (D2, D3): an outline stroke that crosses itself, drawn by A and by B over a flat fill,
  reads one alpha (0.8 Ink) at the crossing, not two. It decided D3's group-alpha question before P-2 (game-qc-ios;
  leader's option a). **Result (2026-11-18, headless, game-dev-ios, 6e455bfc, `SKRenderer` offscreen; `tools/overlap-check.swift`,
`production/qa/evidence/TASK-103/6e455bfc/`):** one
  `SKShapeNode` at 0.8 blends its self-overlap **twice** (crossing 0.961, arm 0.800; stroke alpha and node alpha
  alike); an `SKEffectNode` with `shouldRasterize` at 0.8 blends **once**. So D3's outline is the merged path inside an
  effect node per part. DeviceSpike's **Overlap check** button repeats it on the device as the first step of the
  session (a confirmation, since the device GPU could differ), and P-2 records **which outline path it measured** (the
  effect node, or the texture fallback), so its A numbers belong to the A that would ship. The A-and-B box equivalence
  half of H-2 stays with the adapter story.
- **H-3 Bake output (the bake tool story).** The baked JSON for the three creatures parses back with the a1 rule; its
  byte size is recorded next to H-1's SVG figure.
- Simulator frame times: **not taken** (leader, 2026-11-18): every boot pushed the Mac's load to 40–55, and Simulator
  numbers are never device evidence.

**Device rows (pending; the decision rule above):** P-2 (`ipad-1/P-2/`: frame p50 / p99 per option (A-candidate,
B-load, and the original A for information) over the worst case, per-creature load per role and per option, peak memory, the model and ProMotion, crispness at ~775 px on a 13"
if available), M-13 (`mac-1/M-13/`), and on the same build P-3 / M-12 (F2 rehearsal), P-11 / M-10, P-13, as in
`production/qa/device-checks-plan.md`.

## Related
- Cast Rendering GDD (R2, R3, R7, R10–R12, F1, F6, F8, AC-11, AC-15–AC-17); MorphCore GDD AC-11; art bible §4, §8.
- ADR-0003 (D1, D4 and its K-37 clarification); ADR-0006 (D1–D3, D5, D8); ADR-0002 (D6).
- `production/team/TASK-075-spike-plan.md` (ADR-0009 section); `prototypes/DeviceSpike` (README, `RenderScene.swift`);
  `prototypes/DeviceSpike/art/README.md` (TASK-077).
- ADR-0012 (Android) maps D2–D5's Rules: A as `Canvas.drawPath` on the hardware layer, B as per-part bitmaps.
