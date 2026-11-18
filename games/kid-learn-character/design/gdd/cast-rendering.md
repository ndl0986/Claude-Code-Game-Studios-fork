# Cast Rendering

> **Status**: Approved (independent read by game-dev-android, merged 2026-11-18)
> **Author**: game-dev-ios for Luan (TASK-044); plan reviewed by game-dev-android
> **Last Updated**: 2026-11-18
> **Last Verified**: 2026-11-18, against the art bible §2–§5, §7, §8, MorphCore, Key Table & Theme Data, Press
> Queue, Audio & Voice, the TASK-033 report and `Spike/MorphScene.swift`, and the one-shot
> `prototypes/letter-morph-dinosaur/` (`CREATURES`, `drawCreature`, `drawGlyph`, `drawReveal`, `drawParade`)
> **Implements Pillar**: Pillar 2 (The Letter Comes Alive), Pillar 4 (Things the Child Loves); serves Pillar 3
> (Calm Magic)

## Summary

Cast Rendering decides how the toy's figures **look**: the cast member (a creature or object) at three detail
sizes, the solid glyph, the glyph's halo, the stardust specks, the ground shadow, each family's idle motion, the
tap hop and the parade step. It draws what it is told, where it is told: the Reveal Stage decides **when and
where**, MorphCore decides **where each speck is**, and the Scene draws the sky. How the SVG art reaches the
screen (drawn live as vectors, or rasterised to PNG tiers at build time) is left to a later ADR backed by a
real-iPad measurement; every rule here works with both.

> **Quick reference** — Layer: `Presentation` · Priority: `MVP` · Key deps: `Key Table & Theme Data` (art,
> family, idle id, glyph and silhouette paths), `MorphCore` (speck positions); used by Reveal Stage, Parade and
> (later) Mash World

## Overview

When a toddler presses C, the gold letter rises and glows, its halo breathing in and out; it breaks into specks of
stardust that fly and settle into the triceratops's outline; then the triceratops itself fades in, stands on its
soft shadow, breathes and nods its head, and hops when touched. Every look in that sentence is this system's.

The art is authored once as a layered SVG per cast member (art bible §8) and baked by a build tool into one data
file per cast member, so the app never parses raw SVG and both rendering options read the same file. Motion is
data, not frames: each family has a few parameters (a neck that sways, a jaw that nods), applied to named parts of
the drawing. Only the figures needed now are loaded, so memory stays small (art bible §8).

## Player Fantasy

**"The letter turns into a friend, and the friend is alive."** The child sees a figure with a clear, round outline
they can name, the same outline the stardust drew a moment earlier, so the letter really seems to *become* the
dinosaur. Once formed it is never still: it breathes and sways gently, like a sleepy pet, never fast enough to
startle. When the child touches it, it hops. The grown-up sees a toy that looks like a picture book, crisp at any
size, and that never flashes.

## Detailed Design

### Core Rules

**R1. Ownership.**

| Concern | Owner |
|---|---|
| How a cast member, the glyph, the halo, the stardust and the shadow look; idle, hop and parade-step motion as functions of time | **Cast Rendering** |
| When the glyph rises, glows and dissolves; when the creature fades in (`form_s`); where each box sits on the stage; triggering the hop and its cooldown | Reveal Stage |
| Each speck's position at time `s` | MorphCore |
| Sky, hills, ground, weather, time-of-day light | Scene: Time of Day & Weather |
| Hints, queue tokens, the moon | Hint Letters, Press Queue, Parent Gate & Grown-up Panel |
| When the parade runs and where the walkers are | Parade |
| Which item a key shows; the art, family and idle id it names | Key Table & Theme Data |

MorphCore's ownership table lists "the halo pulse" under the Reveal Stage. The split is: the Reveal Stage turns the
halo on and off and passes the time; this GDD defines what the halo looks like over that time (R5, F2).

**R2. Art input: one SVG subset, one baked file.**

- **Source:** a layered SVG per cast member on a 640×440 artboard, anchor at the feet (320, 410), facing right
  (art bible §8).
- **The subset the art may use**, so that both rendering options and both platforms draw it the same:
  - paths (`circle`, `ellipse`, `rect` and arcs are converted by the bake tool into `M L H V C Q Z`, the
    morph-v1 commands);
  - solid fill, with fill opacity;
  - stroke with a width and round joins and caps;
  - group opacity;
  - transforms: translate, rotate and scale only (the bake tool applies them).
  - **Not allowed:** filters, masks, clip paths, gradients, patterns, text, CSS, embedded images, `use` and
    symbols, skew. The bake tool **rejects** a file that uses any of them and names the element.
- **Structure** (K-16: per-part idles kept):
  - named **part groups** (`root`, and any of `neck`, `head`, `jaw`, `tail`, `wing`, `egg`, `crest`…), each
    with a **pivot** point in artboard units; parts nest (`head` inside `neck`);
  - inside each part, the three **layers** `body`, `outline` and `detail`, drawn in that order within the part;
    parts are drawn in document order;
  - the `outline` layer is Ink `#2a2340` at **80%** opacity in every look (art bible §4).
- **The baked file** `cast_<theme>_<key>_<name>_<variant>.json` (beside the SVG): parts, pivots, layers, paths,
  fills and strokes, in artboard units. It is the only form the app reads. The silhouette `sil_….json` is baked
  from the same SVG (Key Table & Theme Data, MorphCore), at the idle's rest pose (R7).
- **Art bible follow-up:** the part groups with pivots and this subset add to §8's source rules (TASK-045 adds the
  part groups; it points to this subset).

**R3. Units and sizes.**

- **Space:** stage units, 1280×720, y pointing down (the stage every other GDD uses). The artboard maps to the stage
  through the anchor (320, 410) and the caller's position and scale.
- **Time:** seconds. `s` and `idleTime` are **play-clock** values supplied by the caller (Reveal Stage R8: uptime
  minus frozen time), so idles, the hop and the twinkle stop under the gate's freeze. The edge's 1 s switch dissolve
  is the one wall-clock time here (R4, F8).
- **Role** (what detail survives; art bible §5), chosen by the caller:

  | Role | Where | Height on the stage | Draws |
  |---|---|---|---|
  | `stage` | reveal and idle | ~280–360 units | every layer |
  | `list` | grown-up list, reference | ~70–90 units | `body` and `outline`, plus `detail` elements ≥ 6 px on screen |
  | `parade` | the walk | ~75–95 units | `body` and `outline` only |

- **The 6 px rule:** a `detail` element whose on-screen size is under `marking_min_px` (6 physical px) at a role's
  height is left out (F1). The bake tool records each detail element's box so this is a lookup, not a measure.
- **Tier** (option B only, R10): the texture used is the smallest tier whose height is at least the figure's
  on-screen height in **physical pixels** (Apple: points × screen scale; Android: dp × density). Tier heights and
  role thresholds are data.

**R4. The solid glyph.** Drawn from the same baked glyph path (`glyph_<font>_<char>.json`) as MorphCore's start
points, so when the Reveal Stage swaps the glyph for the specks at `s > glow` they lie on the same outline
(MorphCore Rule 4).
- Fill: the Letter Gold gradient, top to bottom `#fff1b8` / `#ffd36e` / `#f6a93b` (art bible §4). The gradient is
  the glyph's own; cast art may not use gradients (R2).
- Edge: a cream stroke, 6 units, highlight cream `#f8efdc` at **100%** (K-25; it was 85%). (The one-shot's
  `rgba(255,250,235,0.85)` is L ≈ 0.96, above the art bible's frame cap of L 0.88; highlight cream is L 0.87.)
- Alpha and position come from the Reveal Stage.
- **Per look** (art bible §2; K-25; F8):
  - **The edge follows the sky, not the clock** (K-25): against a bright sky (the Scene's blended sky-mid
    luminance `skyMidL` above the crossover `L_x` ≈ 0.308) it is a **deep amber outline `#80450f`** (L 0.089; K-25
    replaces §4's `#8a4b12` for this edge) at 100%, 6 units; against a darker sky it is the cream edge. So the edge
    is always the better of the two. In practice that is amber in Morning and Day and cream at Dusk and Night.
  - **The switch** happens once when `skyMidL` crosses `L_x`, with hysteresis ±0.005 (to amber at ≥ 0.313, to
    cream at ≤ 0.303), as a **1 s cross-dissolve on the wall clock**; there is no luminance blend of the two
    colours (a mixed edge would drop to ~1.5:1).
  - **Contrast** (K-25, the dated exception to art bible §2 rule 2): ≥ 3:1 against the sky mid band at the ends of
    every crossfade (w = 0, 1), and ≥ 2.5:1 inside a 15-min crossfade or the 3 s jump fade (measured minimum
    **2.57:1** at `skyMidL` 0.307; the edge actually shown floors at **2.53:1** under the ±0.005 hysteresis). The Scene's 160-case build check uses this edge model and skips the 1 s dissolve
    window (Scene R5, F2).
  - At **Night** the glyph **drops its palest stop** (the top stop becomes `#ffd36e`, so the gradient runs
    `#ffd36e` → `#f6a93b`), blended with `lookBlend` (F8).
  - The glyph itself never dims.

**R5. The halo.** A warm glow behind the glyph while it glows (art bible §2 rule 1, K-08).
- Only the **blur** changes: it pulses between 60% and 100% of `halo_blur_max`, at **~2.2 Hz** (F2; one-shot
  `sin(14t)`, 2.23 Hz). The fill never pulses; its alpha is the glyph's alpha.
- **Reduce Motion (K-16):** the halo holds steady at `halo_steady` (80%) with no pulse.
- Colour `rgba(255, 200, 90, 0.95)` (one-shot), plus a soft glow disk of radius 230 units behind the glyph,
  `rgba(255, 214, 110, 0.25 × alpha)` (one-shot `glowDisk`). It is part of the glyph, so it is the one glow a
  figure has; cast members never glow (art bible §5).
- The one-shot's blur ran 44–60 units (73–100%); this GDD uses the art bible's 60–100%.
- **Per look** (art bible §2; F8): in **Morning and Day** the halo is a **saturated amber**, `rgba(246, 169, 59,
  0.95)` (`#f6a93b`, the glyph's own bottom stop; proposal, the art bible names no hex); at **Night** the halo
  **shrinks to 70%**: `halo_blur_max` and the glow disk's radius × 0.7 (230 → 161 units). Blended with `lookBlend`.
- **Published:** the halo's current glow radius (230 units, down to 161 at full Night), which the Scene's weather
  fade reads (Scene R3, F3d).

**R6. Stardust specks.** Kept **as played** (K-16), a recorded exception to the art bible's "gold only for
letters" and "other pulses ≤ 1 Hz" rules, because the stardust *is* the letter in motion.
- **Count:** MorphCore's (240, its Rule 8). Positions come from MorphCore, mapped by the Reveal Stage.
- **Per speck,** drawn once per reveal: size `1.4 + 2.4·u` stage units; colour gold `#ffd27a` with probability
  `dust_gold_share` (0.7), else Starlight `#fbeec8`; a twinkle phase in [0, 2π).
- **Shape:** above `star_min_size` (3.2 units) a four-point star of half-size × 0.55, else a soft round dot.
- **Twinkle:** alpha × `0.6 + 0.4·sin(9t + phase)` (~1.43 Hz, F3). **Reduce Motion (K-29):** the twinkle **holds
  steady** at a fixed alpha × **0.6** (the mean of the term, which runs 0.2–1.0, so the stardust keeps its average
  brightness), the same pattern as the halo's steady midpoint. It is
  **reveal-locked** (Accessibility A2): a running reveal keeps its twinkle; the next reveal follows the flag
  *(TASK-062)*.
- **Determinism:** the per-speck draws come from each platform's **own** seeded random stream, seeded from the
  reveal's seed (MorphCore Rule 5). They are reproducible on one platform and tested on each platform; they are
  **not** part of the cross-platform morph contract, which is unchanged.
- **Blending, as maths (F4):** specks add, then the sum is capped, so overlapping specks never outshine the glyph
  (art bible §2 rule 3). On Apple that is additive blending plus a cap; on Android `BlendMode.PLUS` plus a cap. How
  the cap is achieved is the ADR's.

**R7. Shadow and idles.**
- **Ground shadow:** an ellipse 210 × 18 artboard units under the anchor, Ink-violet `#3b2f45` at 25% × the
  figure's alpha (one-shot). A hovering flyer keeps its shadow on the ground (art bible §5).
- **Idles are parameters, not frames** (art bible §8): each family's idle id (Key Table `families`) names a list of
  part motions `{part, kind: rotate | translate, amplitude, rateHz, phase}` applied around the part's pivot.
  - **Breathe**, shared by everyone, on `root`: 0.33 Hz, scale in y ±1.2%, a bob of 5 units (one-shot
    `sin(2.1t)`, `bob_px`).
  - **Family idles** (art bible §5): sauropod neck sway, raptor head look, ankylosaur tail wag, rex jaw nod, nest
    egg wobble with a peek, flyer wing flap. Each is ≤ 1 Hz (a build check); the one-shot's rates are the
    starting data (sauropod sway `sin(1.4t)`, 0.22 Hz).
  - **Number babies:** each baby bobs on its own phase (one-shot `|sin(3t + ph)|`, 0.95 Hz).
- **Phase 0 at formed:** `idleTime = s − formedS`, and every idle is at its rest pose at `idleTime = 0`. The
  silhouette is baked at that rest pose, so the creature that fades in matches the shape the stardust drew.
- **Reduce Motion (K-16):** every idle amplitude × `reduce_motion_scale` (0.5). **Idles are ambient (K-29):** a
  change of the flag applies **on the next frame**, also to a figure already idling, eased over `idle_rm_ease_s`
  (0.3 s) **in both directions** (on and off) so nothing
  jumps; the halo, hop and twinkle stay reveal-locked *(TASK-062)*.
- **Night dim** (art bible §2: "the creature and ground take a 15% ambient dim"): at **Night** every cast drawing
  (the stage creature, the leaving one, the title creature, parade walkers) and its ground shadow is multiplied by
  0.85 in colour (F8), blended with `lookBlend`. The ground is the Scene's. The glyph and the stardust are not
  dimmed.

**R8. Tap hop and parade step.**
- **Tap hop:** the whole figure rises on a sine arch, `hop_px` (26 units) over `hop_s` (0.45 s) (one-shot). The
  Reveal Stage starts it and owns the cooldown; this GDD only gives its shape (F5). A hop during an idle adds to
  it. **Reduce Motion:** the hop is `hop_px × reduce_motion_scale` = **13 units** (proposal: K-16 says "smaller").
- **Parade step:** a step bob of 5 units at `|sin(7t + i)|` (~2.2 Hz), as played; a K-16 exception to ≤ 1 Hz.
  Reduce Motion: × 0.5. The Parade owns where the walkers are.

**R9. Will a creature form?** At `startReveal` the Reveal Stage asks Cast Rendering `willForm(item)`, answered
without waiting:
- **true** if the item's art passed the theme load check (Key Table §5: every referenced file exists; a theme
  with a missing file is never made Active) or is already resident;
- **false** if the art is known to be missing or bad this run (Key Table's "despite the gate" case, or a file
  that already failed to load, state Failed): the reveal takes the art-missing fallback (the glyph glows
  and sparkles out, Key Table and MorphCore edge cases).

The Reveal Stage returns this with `{formedS, revealLen}` so the Press Queue and Audio & Voice know whether the
cast sound and word will play (`hasWord`, Press Queue review note), without guessing. A rarer failure after that
(the file decodes badly when loaded) is handled by R10's late-art rule; the answer given at start is not changed.

**R10. Loading on demand and late art.** (art bible §8 memory rule; K-16; Press Queue R6.)
- **Resident set:** only the current figure, the one leaving, the figures of the keys waiting in the queue
  (prefetched), and the parade's `parade_count` figures (6, K-17) at the `parade` role. A walker that is also the
  current stage creature needs its parade-role copy too: the two roles are separate resident sets. Nothing else is
  kept (F6).
- **Prefetch:** when a key is queued, its item is resolved for prefetch and its art loads off the main thread. The
  reveal still resolves its item at start (Key Table §4); if that gives a different item (the pick rule), the
  prefetched one is dropped and the new one loads.
- **A press that starts at once** loads its art at start. The art is needed only at `formedS` (T: 2.45 s normal,
  1.2 s reduced). The measurement plan must show that loading fits (R11).
- **Late art (F7):** if the art is not resident at `formedS`, the stardust **holds the silhouette's shape** (the
  specks stay on their end points, still twinkling) for up to the late-art wait, then the creature fades in over
  `form_s` as usual. If the art is still not resident when the wait runs out, the specks sparkle out (the
  art-missing look) with one debug log line.
- **The Press Queue's numbers never move:** `formed` is still reported at `formedS`, and `revealLen` is the one
  returned at start.
- **Chosen (F7):** while no key is waiting the full `late_art_wait_s` (0.5 s) applies; the moment a key is queued
  during the wait, the wait is cut to the hold bound, and if that bound has already passed the specks sparkle out
  at once. So a late fade-in that *starts* while a key waits always ends within `holdEff`.
- **Accepted limit of that choice:** if a key is queued only after the wait has ended, while the late fade-in is
  still running, the hold may pass mid-fade-in; the next reveal then starts and the half-faded creature leaves
  with the Reveal Stage's normal leaving fade. This needs late art *and* a key at that moment, and costs at most
  the rest of one fade-in (≤ `form_s`).

**R11. How the SVG art reaches the screen: two options, decided by a later ADR.**

Both options read the same baked file (R2), honour R3–R10, and sit behind one draw interface (R12). The art
bible's conflict (§8) is recorded, not decided, here.

| | **Option A: live vector** | **Option B: PNG tiers at build time** |
|---|---|---|
| How | parse the baked file once at load; draw each part's paths. Apple: `CGPath` into `SKShapeNode`s, or rendered once per role into a texture on the device. Android: `Canvas.drawPath` or a Compose `DrawScope` | the build rasterises the baked file into one PNG per **part** per tier (stage ≤ 1024 px, list, parade 256 px); parts become sprites rotated about their pivots |
| For | crisp at any size; small app; an art change is a file change | fast to draw and proven in SpriteKit (the spike's specks are textured sprites); predictable frame cost |
| Against | per-frame cost of many paths **unverified** for detailed creatures (the spike drew only one flat silhouette `SKShapeNode`); load time per creature unverified | larger app (parts × tiers × cast); a re-export on every art change; part seams to check |
| Memory | path data plus any per-role textures (measured) | F6 |

**Measurement plan for that ADR** (the oldest supported real iPad, and a Mac):
1. A stage creature idling, a leaving creature fading out, 240 specks flying with the cap, the glyph with its
   halo, over the Dusk scene; then a parade of `parade_count` (6) figures.
   **Combined with the Scene's worst case** (Scene F6) in the same run: Night, snow 60 + windy, 3 clouds, 50 stars,
   mashing halving off and Reduce Motion off, so one device measurement covers the whole stage.
2. Measure: frame time p50 / p99 (target p99 ≤ 16.7 ms, art bible §8), the load time of one creature at each
   role (it must fit well within the reduced T, 1.2 s), peak memory, app-size delta for the 36 Dinosaurs items,
   and crispness at ~775 px on screen (a 13" iPad).
3. Harness: the TASK-033 Metrics recorder and its iPad procedure.
4. Both options with the same Dinosaurs art. The ADR picks one, or a mix (for example A for `stage`, B for
   `parade`).

**R12. The draw interface** (no platform types; stage units and seconds):
- `drawCast(castId, role, pose)` with `pose = {position, scale, alpha, idleTime, hop}`;
- `drawGlyph(key, position, scale, alpha, halo: {on, time})`;
- `drawDust(points[], looks, s, alpha)`: `points` from MorphCore, mapped by the Reveal Stage; `looks` from R6;
- `willForm(item)` (R9), `prefetch(item)`, `release(item)`; `isResident(item)` for R10.

### States and Transitions

A figure's art has a load state; drawing itself is stateless (a pure function of the pose and time).

| State | Meaning | Leaves to |
|---|---|---|
| **Absent** | not loaded | Loading (prefetch, or a reveal start) |
| **Loading** | off the main thread | Resident (done) or Failed (bad file) |
| **Resident** | drawable at its roles | Absent (released: no longer current, leaving, queued or in the parade) |
| **Failed** | bad or missing art this run | — (the item uses the art-missing look; one log line) |

### Interactions with Other Systems

| System | Direction | What passes |
|---|---|---|
| Key Table & Theme Data | in | `art`, `family`, `variant`, `hueSlot`, the family's idle id, the glyph paths; the theme's load check (R9) |
| MorphCore | in | speck positions (via the Reveal Stage), the reveal seed for the speck looks (R6) |
| Reveal Stage | in / out | in: `drawCast`, `drawGlyph`, `drawDust` each frame, `willForm`, `prefetch`, `release`, hop start; out: `willForm`, `isResident` |
| Press Queue | none directly | its numbers (`formedS`, `revealLen`, `holdEff`) are read through the Reveal Stage; R10 never moves them |
| Audio & Voice | none directly | `willForm` reaches it through the Reveal Stage (`hasWord`) |
| Parade | in | `drawCast(…, parade, …)` for each walker; the step bob (R8) |
| Accessibility | in | Accessibility's `reduceMotion` (its A1; never the OS API), read live: halo, hop and twinkle from the next reveal; idles on the next frame (R5, R6, R7, R8; K-29) |
| Scene: Time of Day & Weather | in / out | in: `look`, `lookBlend` (Scene R1, F1) for the halo, top stop and Night dim, and **`skyMidL`** (the blended sky-mid luminance with the weather tint; Scene interface ask, K-25) for the edge switch (R4, R5, R7, F8); out: the halo's current glow radius (R5). The Scene draws behind; Cast Rendering never changes the sky |
| Mash World (Full Vision) | in | the same draw calls |

## Formulas

**F1. Detail kept at a role.**
```
onScreen_px(e) = e.size_artboard × (role_height_units / 440) × stage_to_px
keep(e)        = layer(e) ≠ detail  OR  (role ≠ parade AND onScreen_px(e) ≥ marking_min_px)
```
| Variable | Meaning | Value |
|---|---|---|
| `e.size_artboard` | the smaller side of a detail element's box, artboard units | from the baked file |
| `role_height_units` | the figure's height on the stage | stage ~320, list ~80, parade ~85 |
| `stage_to_px` | physical px per stage unit on this screen; set by the stage-fit rule (Reveal Stage, TASK-049) | 11" iPad landscape (2388 × 1668): 1.87 fitting by width (2388/1280), 2.32 by height (1668/720) |
| `marking_min_px` | the smallest marking kept | 6 px |

Example (11" iPad, fit by width, 1.87): a 10-unit spot on the artboard, `list` at 80 units → 10 × 80/440 × 1.87 =
3.4 px → left out; at `stage` (320) → 13.6 px → kept. Fit by height (2.32) gives 4.2 px and 16.9 px: the same
result.

**F2. Halo blur.**
```
blur(t) = halo_blur_max × (0.8 + 0.2 × sin(2π × halo_hz × t))      (normal: 60–100%)
blur(t) = halo_blur_max × halo_steady                                (Reduce Motion: steady 80%)
```
`halo_hz` 2.2 (K-08), `halo_blur_max` 60 units (one-shot `20 + 40`), `t` = seconds since the glow began. Example:
t = 0.114 s (a quarter period) → 100%; t = 0.341 s → 60%. Period 0.455 s.

**F3. Speck alpha.**
```
a_i(s) = a_phase(s) × (0.6 + 0.4 × sin(dust_twinkle_w × s + phase_i))      dust_twinkle_w = 9 rad/s (1.43 Hz)
                                                   Reduce Motion: a_i(s) = a_phase(s) × 0.6 (the term's mean)
```
`a_phase(s)` (fade in over the dissolve, out over the fade-in) is the Reveal Stage's. Range 0.2–1.0 × `a_phase`.

**F4. The stardust cap.** For each output pixel and colour channel:
```
C = max( C_scene,  min( C_cap,  C_scene + Σ_i a_i × c_i ) )
```
`c_i` the speck colour (linear), `a_i` from F3 times its coverage of the pixel, `C_cap` = the glyph's top colour
`#fff1b8` (L 0.88, the frame cap, art bible §2, §4). Example: three gold specks of alpha 0.8 over a dusk sky add
to more than the cap → the pixel shows the cap, never brighter. With one speck the cap is not reached. The outer
`max` means specks only ever **add** light: where a scene channel is already above the cap (the Day sky's blue,
highlight cream), the pixel keeps its scene value and is never darkened by a speck (game-dev-android's read).

**F5. Idle and hop.**
```
idle_p(t) = k × A_p × sin(2π × f_p × t + φ_p)      for each part motion p, t = idleTime
hop(τ)    = k_h × hop_px × sin(π × clamp(τ / hop_s, 0, 1))
```
`k = 1` normally, `reduce_motion_scale` (0.5) with Reduce Motion; `k_h` the same. `f_p ≤ 1 Hz` (build check),
except the parade step (K-16). Example: hop at τ = 0.225 s → 26 units (13 with Reduce Motion); at τ = 0.45 s → 0.

**F6. Texture memory (option B; option A where it renders textures).**
```
bytes(set)     = Σ_parts w_part × h_part × 4                 (RGBA, 8-bit)
with mipmaps   = bytes × 4/3
resident       = (2 + queue_max) × bytes(stage set) + parade_count × bytes(parade set)
```
A stage set at 1024 px tall on the 640:440 artboard is at most 1024 × 704 × 4 ≈ **2.9 MB** if drawn as one image;
split into parts the sum of the part boxes is capped at 1.5× that by a build check (overlap at the joints). With
`queue_max` 3: 5 × 2.9 ≈ **14.4 MB** (19.2 MB with mipmaps; up to 1.5× with parts). The parade, with
`parade_count` 6 (K-17): 6 × 256 × 176 × 4 ≈ **1.1 MB**, counted even when a walker is also the stage creature
(its parade copy is separate). A digit walks as its group in one file, so it is one figure. Loading all 26 stage figures would be ≈ 75–100 MB, which is why nothing else stays resident.

**F7. The late-art wait.**
```
bound  = holdEff − formedS − form_s                     (from startReveal's locked numbers)
wait   = late_art_wait_s                                 while no key is waiting
wait   = min(late_art_wait_s, max(0, bound))             from the moment a key is queued
```
| Case | holdEff | formedS | form_s | bound | wait while a key waits |
|---|---|---|---|---|---|
| normal set, no word extension (hold 3.0, revealLen 2.95) | 3.0 | 2.45 | 0.5 | 0.05 | **0.05 s** |
| normal, "nest" 0.5 s | 3.20 | 2.45 | 0.5 | 0.25 | **0.25 s** |
| normal, "quetzalcoatlus" 1.15 s | 3.85 | 2.45 | 0.5 | 0.90 | **0.5 s** |
| reduced set (T 1.2, form 0.3), hold 3.0 | 3.0 | 1.2 | 0.3 | 1.5 | **0.5 s** |
| no key waiting, any set | — | — | — | — | **0.5 s** (K-16) |

So with keys waiting in the normal set, Luan's 0.5 s applies only when the word extends the hold. With nothing
waiting, nothing can replace the creature, so the full 0.5 s is safe.

**F8. Per-look factors** (from the Scene's `lookBlend = (prev, P, w)` and `skyMidL`, Scene F1, F2; K-25).
```
md(X) = 1 if X ∈ {Morning, Day} else 0;      nt(X) = 1 if X = Night else 0
d     = (1 − w)·md(prev) + w·md(P)          the Morning/Day share   (halo colour)
n     = (1 − w)·nt(prev) + w·nt(P)          the Night share         (halo size, top stop, dim)

edge:      amber #80450f (100%) while skyMidL ≥ L_x + 0.005 was last crossed upward,
           cream #f8efdc (100%) while skyMidL ≤ L_x − 0.005 was last crossed downward;   L_x = 0.308, 6 units
           a crossing starts a 1 s cross-dissolve on the wall clock (alpha, not colour mixing)
           state: at launch the edge starts as the one for the current value, with no dissolve: amber if
           skyMidL ≥ L_x (0.308), else cream (TASK-104, CR-Q1: with no crossing history, L_x picks the better edge);
           a return from the background keeps the state (the hysteresis runs on the published skyMidL, which the
           Scene's 3 s clock-jump fade moves continuously); the thresholds are inclusive (≥ 0.313, ≤ 0.303); the
           dissolve starts on the crossing frame and the mix moves at 1 per second; a reverse crossing during a
           dissolve turns it around from the current mix toward the new edge at the same rate (1 per s), so it
           ends after (current mix) × 1 s and never lengthens a switch (no jump)
haloColour = mixLin(rgba(255,200,90,0.95),  rgba(246,169,59,0.95),  d)
haloScale  = 1 − 0.3·n          × halo_blur_max and × the glow-disk radius (230)
topStop    = mixLin(#fff1b8, #ffd36e, n)                                     the glyph's (and F4's C_cap)
castDim    = 1 − 0.15·n         × every cast drawing's colour and its shadow, applied in linear RGB
```
`mixLin` blends in linear RGB (Scene F2), and `castDim` multiplies linear RGB, so the Scene's build check and this
drawing agree on every in-between frame. `L_x` is where amber and cream give the same contrast:
`(skyMidL + 0.05)² = (0.869 + 0.05)(0.089 + 0.05)`, so `skyMidL + 0.05 = 0.357`. Against the mid band, amber gives
≥ 3:1 for `skyMidL` ≥ 0.367 and cream for ≤ 0.256; between them the better edge stays ≥ 2.57:1, and the edge actually shown, which can lag by the ±0.005
hysteresis, stays ≥ 2.53:1 (cream at 0.313, amber at 0.303).

Sky-mid luminances (art bible §2 mid stops; luminance is linear in linear RGB, so a blend is the weighted mean):
Morning 0.615, Day 0.555, Dusk 0.098, Night 0.029.

| Wall time (Scene F1) | lookBlend | skyMidL | edge | d | n | haloScale | castDim |
|---|---|---|---|---|---|---|---|
| 12:00 | (Morning, Day, 1) | 0.555 | amber (4.4:1) | 1 | 0 | 1.0 | 1.0 |
| 16:07 | (Day, Dusk, 0.467) | 0.342 | amber (2.8:1) | 0.533 | 0 | 1.0 | 1.0 |
| ≈ 16:08:16 | (Day, Dusk, 0.551) | 0.303 | **switch** to cream, 1 s dissolve | 0.449 | 0 | 1.0 | 1.0 |
| 18:00 | (Day, Dusk, 1) | 0.098 | cream (6.2:1) | 0 | 0 | 1.0 | 1.0 |
| 23:00 | (Dusk, Night, 1) | 0.029 | cream (11.6:1) | 0 | 1 | 0.7 (161 u) | 0.85 |
| 06:05 | (Night, Morning, 0.333) | 0.224 | cream (3.4:1) | 0.333 | 0.667 | 0.8 | 0.9 |
| ≈ 06:07:16 | (Night, Morning, 0.484) | 0.313 | **switch** to amber, 1 s dissolve | 0.484 | 0.516 | 0.85 | 0.92 |

The skyMidL here is for clear weather; the Scene publishes the value with its weather tint, and the switch uses
that.

The stardust cap of F4 uses the current `topStop`, so at Night the specks never outshine the two-stop glyph.

## Edge Cases

| Case | What happens |
|---|---|
| **Art missing or failed the theme check** | `willForm` = false; the glyph glows and sparkles out (R9); one log line. No cast sound or word (`hasWord` false, through the Reveal Stage). |
| **Art not loaded at `formedS`** | The specks hold the shape for the F7 wait, then the creature fades in; if still not loaded, the specks sparkle out; one log line (R10). `formed` stays at `formedS`. |
| **Sound during the late-art wait** | The cast sound (Audio E8, s = T) and the word (E9, T + 0.25) play on time while the specks still hold the silhouette. Accepted: the wait is ≤ 0.5 s and the shape is already the creature's; Audio does not hold E8. |
| **A key is queued during the late-art wait** | The wait is cut to the F7 bound; if it has passed, the specks sparkle out at once. |
| **A key is queued during a late fade-in** (after the wait) | The fade-in continues; if the hold passes first, the next reveal starts and the creature leaves with the normal leaving fade (R10, accepted limit). |
| **The baked file fails to decode at load, after `willForm` said true** | Treated as late art that never arrives (R10). The word may already be playing over the sparkle-out; logged. |
| **A part named in the idle data is missing from the art** | That motion is skipped; the rest play; the bake tool reports it as an error at build. |
| **A forbidden SVG feature** | The bake tool rejects the file at build and names the element (R2). |
| **A detail marking under 6 px at `list`** | Left out at that size (F1). |
| **Reduce Motion turns on mid-reveal** | The halo, hop and twinkle change from the next reveal (MorphCore's rule); idles, including a figure already idling, change on the next frame, eased over `idle_rm_ease_s` (0.3 s) both ways (K-29). |
| **Many specks overlap** (a thin glyph, a mash) | The cap holds (F4): never brighter than the glyph's top colour. |
| **The same item queued twice** | One resident copy serves both. |
| **A theme change while figures are resident** | The new theme's figures load for the next reveal; the old ones are released when no longer current or leaving. |
| **The parade starts while a stage figure is resident** | Both are allowed; the resident cap includes the parade set (F6). If the stage creature is also a walker, its parade-role copy is loaded as well. |
| **A flyer that hovers** | Its shadow stays on the ground line (R7). |
| **Number 3 (three babies in one file)** | Each baby is a part with its own bob phase (R7); the silhouette is the three together (MorphCore). |
| **The look changes during a reveal** (a 15-min crossfade, or the Scene's 3 s clock-jump fade) | The halo, top stop and dim follow `lookBlend` frame by frame; the edge switches once, with a 1 s dissolve, when `skyMidL` crosses `L_x` (F8); nothing snaps. |
| **`skyMidL` hovers at the crossover** (a weather tint landing on L_x) | The ±0.005 hysteresis holds the current edge; no flicker. |
| **Night with Reduce Motion** | The halo holds steady at `halo_steady` × 0.7 of its size (R5, F8). |
| **Mac window resized** | The tier is chosen again from the new physical height (R3); a change loads the new tier and swaps when ready. |

## Dependencies

- **Upstream:**
  - Key Table & Theme Data (`design/gdd/key-table-theme-data.md`): the item's `art`, `family`, `variant`,
    `hueSlot`; `families` → idle id (its R1 says the idle parameters live in Cast Rendering data: R7 here); the
    glyph paths; the theme load check (§5) that `willForm` reads.
  - MorphCore (`design/gdd/morphcore.md`): speck positions, T, the seed; its Rule 4 (glyph swap on the same
    outline) and its ownership table (the halo split, R1 here).
  - Scene: Time of Day & Weather (`design/gdd/scene-time-weather.md`): `look`, `lookBlend` and `skyMidL` (its R1,
    F1, F2) for the per-look edge, halo, top stop and Night dim (R4, R5, R7, F8).
  - App Shell & Title (`design/gdd/app-shell-title.md`): the title creature (its R2) and memory-warning shedding
    (its R8, against R10's resident set).
- **Downstream (each must name Cast Rendering):**
  - Reveal Stage: every draw call, `willForm`, `prefetch` and `release`, the hop trigger, the late-art rule (R9,
    R10, R12); it passes `willForm` on as `hasWord` (Press Queue review note).
  - Parade: `drawCast` at the `parade` role and the step bob.
  - Accessibility: the Reduce Motion flag (R5, R7, R8).
  - Mash World (Full Vision).
- **Peers:** Press Queue (`design/gdd/press-queue.md`): its `formedS`, `revealLen`, `holdEff` are never moved
  (R10, F7). Audio & Voice (`design/gdd/audio-voice.md`): the creature-tap sound (E10) plays with the hop; the
  word plays only when `willForm` is true.
- **Documents:** art bible §2 (rules 1–3), §3, §4, §5, §7 (Reduce Motion), §8 (source format, memory rule, the
  SVG conflict); decisions K-08, K-16; ADR-0001 (SpriteKit; open follow-up: the SVG-rendering ADR).
- **Art bible follow-ups (TASK-045, game-art-content):** the K-16 exceptions, §8 part groups with pivots, the
  pointer to R2's subset, and §8's particle count 420 → 240.

## Tuning Knobs

All values are bundled data (ADR-0001 Decision 6), checked at build.

| Knob | Value | Safe range | Source | Effect |
|---|---|---|---|---|
| `halo_hz` | 2.2 | fixed | K-08 | the halo's pulse |
| `halo_blur_max` | 60 units | 30–90 | one-shot | how soft the halo is |
| `halo_steady` | 0.8 | 0.6–1.0 | proposal (K-16 "holds steady") | the halo with Reduce Motion |
| `dust_gold_share` | 0.7 | fixed | K-16 as played | gold vs Starlight specks |
| speck size | 1.4–3.8 units | 1–6 | one-shot | stardust grain |
| `star_min_size` | 3.2 units | 2–5 | one-shot | which specks are stars |
| `dust_twinkle_w` | 9 rad/s (1.43 Hz) | fixed | K-16 as played | speck twinkle |
| breathe | 0.33 Hz, ±1.2%, bob 5 units | ≤ 1 Hz, 0–3%, 0–15 | one-shot `bob_px` | the shared idle |
| family idles | per idle id | each ≤ 1 Hz | one-shot | each family's character |
| `hop_px` / `hop_s` | 26 units / 0.45 s | 0–60 / 0.2–1.0 | one-shot | the tap hop |
| `reduce_motion_scale` | 0.5 | 0.3–0.7 | **proposal** (K-16 "half amplitude", "smaller hop") | idles, hop (13 units) and parade step with Reduce Motion |
| `idle_rm_ease_s` | 0.3 s | 0.1–0.6 | proposal (TASK-062; K-29 "next frame" is when it starts) | how long an idling figure eases to the new amplitude when Reduce Motion turns on or off |
| shadow | 210 × 18, 25% | — | one-shot | grounding |
| `marking_min_px` | 6 px | 4–8 | art bible §5 | detail per size |
| tier heights | stage 1024, list 192 (proposal), parade 256 px | — | art bible §8 | option B textures |
| `late_art_wait_s` | 0.5 s | 0–0.5 | K-16 | the most a late figure is waited for (F7) |

## Acceptance Criteria

Logic tests use an injected clock and a fake drawing surface; screenshots are retained in
`production/qa/evidence/`.

1. **AC-1 Sizes (screenshots):** one cast member of each family drawn at `stage`, `list` and `parade`, on the Dusk
   and Day looks; retained screenshots; `detail` absent at `parade`.
2. **AC-2 Outline trait at 64 px:** each cast member's all-white render (the silhouette) at 64 px tall matches its
   golden image, and a human review names each one and tells it from its family siblings (Key Table T4, art bible
   §3).
3. **AC-3 Outline colour:** sampled outline pixels of a stage render equal Ink `#2a2340` at 80% over the body
   (within 2/255 per channel).
4. **AC-4 Bake tool:** a test SVG with each forbidden feature (filter, mask, gradient, text, image, CSS, skew) is
   rejected with the element named; a valid one bakes to the expected file.
5. **AC-5 Parts:** rotating a part 10° about its pivot moves the pivot point by 0 and a point 100 units away by
   17.4 units (±0.1).
6. **AC-6 6 px rule (F1):** the F1 example: a 10-unit spot is kept at `stage` and left out at `list` with
   `stage_to_px` 1.87 and with 2.32.
7. **AC-7 Halo (F2):** blur at t = 0.114 s is 100% and at 0.341 s is 60% (±1%); the glyph fill alpha is constant
   while the blur pulses; with Reduce Motion the blur is constant 80%.
8. **AC-8 Glyph swap:** the solid glyph's outline and the MorphCore start points overlay within 1 px at the swap.
9. **AC-9 Specks:** for a fixed seed, the speck looks are the same on every run on one platform (per-platform
   test); 70% ± 5% gold over 240 specks for 100 seeds; specks above 3.2 units are stars.
10. **AC-10 Cap (F4):** 50 specks of alpha 1 on one pixel never exceed `C_cap`; under a 10/s mash for 60 s no
    pixel of the dust layer exceeds it (sampled); a speck over a scene pixel whose channel is already above the
    cap (e.g. Day sky blue) leaves that pixel unchanged, never darker.
11. **AC-11 Idles:** at `idleTime` 0 every part is at rest (the render matches the silhouette within 1 px of
    outline); every idle in the shipped data is ≤ 1 Hz (build check); with Reduce Motion every amplitude is half.
12. **AC-12 Hop (F5):** 26 units at τ = 0.225 s, 0 at 0.45 s; 13 units with Reduce Motion.
13. **AC-13 willForm (R9):** true for an item with valid art; false for missing art, and that reveal draws the
    glyph sparkle-out and reports no word.
14. **AC-14 Late art (R10, F7):** with a test seam delaying the load: formed is reported at `formedS`; with no key
    waiting the specks hold for 0.5 s then the creature fades in; with a key queued and the normal no-extension
    hold, the wait is 0.05 s; when the load never finishes the specks sparkle out with one log line; a fade-in that
    starts while a key waits ends ≤ `r0 + holdEff`.
15. **AC-15 Resident set (F6):** across a 60 s mash, never more than `2 + queue_max` stage sets plus the parade set
    resident (instrumented count).
16. **AC-16 No platform types:** the draw interface (R12) uses only stage units, seconds and ids (code review).
17. **AC-17 Measurement (device, NOT ASSESSED):** the R11 measurement plan run on the oldest supported iPad and a
    Mac for both options; results recorded for the SVG-rendering ADR.
18. **AC-18 Per look (F8, K-25):** at the F8 table's times (injected wall clock through the Scene), the edge, the
    halo colour and scale, the top stop and the creature's colour factor match the table (colours within 1/255 per
    channel); the edge switches to cream when `skyMidL` falls to 0.303 and to amber when it rises to 0.313, each as
    a 1 s ± 1 frame wall-clock dissolve; `skyMidL` oscillating 0.304–0.312 causes no switch; the cream edge is drawn
    at 100%; `castDim` 0.85 multiplies linear RGB; the glyph's fill is never dimmed; and with this edge model the
    Scene's 160-case check finds ≥ 3:1 at w = 0 and 1 and ≥ 2.5:1 elsewhere, outside the 1 s dissolve window.

**NOT ASSESSED:** every device performance figure (frame time, load time, memory, app size) until AC-17 runs; the
look of either option on a real iPad screen.

## Open Questions

- None open for Luan.
- **Decided (Luan, K-16, 2026-11-18):** Reduce Motion softens (half idles, smaller hop, steady halo); per-part
  idles kept (named parts with pivots); stardust as played (70% gold, ~1.4 Hz twinkle, the parade step), a
  recorded exception; art late: hold the shape up to 0.5 s, then fade in.
- **Chosen by the author:** the full 0.5 s wait while no key waits, cut to the hold bound when a key is queued
  (F7); `reduce_motion_scale` 0.5 for "smaller hop" (13 units) and `halo_steady` 0.8 (proposals in Tuning Knobs).
- **For the SVG-rendering ADR:** option A or B (or a mix), from the R11 measurement.
