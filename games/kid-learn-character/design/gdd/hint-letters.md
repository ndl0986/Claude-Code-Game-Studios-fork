# Hint Letters

> **Status**: Approved (independent read by game-qc-android, merged 2026-11-18)
> **Author**: game-dev-android for Luan (TASK-047); plan reviewed by game-qc-android
> **Last Updated**: 2026-11-18
> **Last Verified**: 2026-11-18, against Input & Key Filter R7/F1, Press Queue R3/R4/R11, Key Table (36 keys), art
> bible §2–§4, §6, §7, the one-shot (`config.js` hint_*, `index.html` spawnHint / hintAt / takeHint / drawHints),
> decisions K-06, K-08, K-10, K-15, K-16, K-18, K-20
> **Implements Pillar**: Pillar 1 (Every Press Answers) for a touch-only child; serves Pillar 3 (Calm Magic)

## Summary

Hint Letters float three glowing letters (or digits) in the sky. They are the touch-only child's keyboard: a touch
on a hint is a press of its key. They drift slowly, linger about six seconds, fade, and are replaced by others, so
over a few minutes every letter and digit of the theme turns up. They never overlap each other, the moon, the
queue tokens or the creature on stage. The brief replaced the prototype's fixed DINOSAUR key row with them.

> **Quick reference** — Layer: `Feature` · Priority: `MVP` · Key deps: `Key Table & Theme Data` (the 36 keys),
> `Input & Key Filter` (touch layer 1, hit radius), `Press Queue` (per-press outcome, queued keys); works with
> `Reveal Stage` (router, stage fit, cast bounds) and `Parent Gate & Grown-up Panel` (freezes)

## Overview

A toddler on an iPad without a keyboard needs something to touch. The first prototype showed a fixed row of
letters; after play Luan dropped it ("no need to show the DINOSAUR row; suggest with random letters on the main
screen", brief After-play, and the Avoid list's "fixed DINOSAUR key row"). Hint Letters are that suggestion: a few
cream bubbles with a gold letter, in the sky only (art bible §4), each a touch target about 27 mm across on an 11"
iPad. This GDD defines which keys appear, where, for how long, what a touch does to the hint, how hints behave when
the panel, the parent-gate challenge or the background interrupts play, and Reduce Motion. The press itself
belongs to Input & Key Filter and the Press Queue.

## Player Fantasy

For the child: "the sky is full of letters I can catch." Something glowing is always within reach; touching it
makes it fly up as the big letter. If the child misses and touches again, the hint waits for them (it holds still
once touched, and a fading hint still counts). Different letters keep arriving, so the child meets the whole
alphabet without anyone choosing it for them.

For the grown-up: hints invite play without asking for anything. They never say "wrong", never flash, never
cover the creature, and they stop drifting when Reduce Motion is on.

## Detailed Design

### Core Rules

**R1. Ownership.**

| Concern | Owner |
|---|---|
| Which keys are hinted, where hints sit, their drift, life, look, pulse, consume and fade | **Hint Letters** |
| Turning a touch on a hint into a press (layer 1, `hitRadius`) | Input & Key Filter (its R7, F1) |
| Accept, queue or ignore the press | Press Queue (its R3, R4) |
| Calling `originFor(key)` before `press(p)`; the stage transform, `stage_to_px` and the safe stage; the cast member's bounds; the sparkle and ping on an ignored press | Reveal Stage (K-20) and Audio & Voice (E1/E2) |
| The panel and the gate challenge | Parent Gate & Grown-up Panel |
| Entering Play from the title; the background | App Shell & Title |

Hint Letters has no sound of its own: an accepted hint press chimes (Audio E1), an ignored one pings (E2).

**R2. Count.** In Play, `hint_count` hints (3) are on screen whenever a free slot exists (one-shot `hint_count`;
art bible §7 conflict 2, "the 3 random hints"). On the title screen there are none: touches there belong to the
App Shell (Input & Key Filter, Title state).

**R3. Which key a new hint shows** (F1). Uniformly at random from the theme's 36 keys in Key Table canonical order
(A–Z, then 0–9; brief: "every letter A–Z and digit 0–9, as random glowing hint letters"), **excluding**:
- keys already shown as hints;
- the key of the current reveal;
- keys waiting in the Press Queue (K-18), read from its snapshot (Press Queue R11).

So no two hints show the same key, and no hint repeats what is on stage or waiting. If the pool is empty, nothing
spawns this time (R6 retries).

**R4. The seed.** One random 64-bit seed per launch for all hint draws (key, slot, jitter, life, drift phase),
injectable in tests, a separate stream from Key Table's variety seed and the morph seed (as Key Table R4). Debug
builds log it at launch.

**R5. Where: slots, jitter and clearances** (F4). Positions are in **stage units**, the 1280×720 safe stage, y
down. With K-20's stage fit the safe stage is contained and the sky and ground extend beyond it; **hints stay inside
the safe stage**.

- **Eight candidate slots**, four in each sky area (one-shot `HINT_AREAS` left x 110–380 and right x 900–1170,
  y 150–420; art bible §4, §6: sky only):

  | | Left | Right |
  |---|---|---|
  | top | L1 (130, 200), L2 (360, 200) | R2 (920, 200), R1 (1150, 200) |
  | bottom | L3 (130, 410), L4 (360, 410) | R4 (920, 410), R3 (1150, 410) |

  L1, L3, R1, R3 are the **outer** slots; L2, L4, R2, R4 the **inner** ones.
- **Spawning:** take the free slots (not occupied, R6) in a seeded random order. For each, draw a jitter `(jx, jy)`
  uniform in ±`hint_jitter` (10) per axis and **check F4 on the jittered centre**. If it fails, draw again, up to
  4 times; then try zero jitter; if that fails too, the slot is blocked for this spawn and the next slot is tried.
  If no slot passes, nothing spawns this time (R6 retries).
- **The moon, token and glyph positions are not this system's:** the moon's circle comes from the Parent Gate, the
  token circles and the glyph and cast boxes from the Reveal Stage, as published rectangles in stage units. The
  values below are the one-shot's and the art bible's, used until those GDDs publish theirs; the build check
  (AC-5) re-runs on the published values.
- **Clearances** (F4), all on the jittered centre and all including the drift (F3, at most 12.8 units):
  - each other hint: centres ≥ 185.6 apart (hit circles plus drift never touch);
  - the moon (66, 62), radius 50: ≥ 148;
  - each queue token (1214, 58), (1148, 58), (1082, 58), glow radius 40: ≥ 138;
  - the current cast member's box (from the Reveal Stage): ≥ 97.8 from the box;
  - the glyph's box (x 475–805, y 155–485, the 330-unit glyph at 640, 320): ≥ 97.8 (every slot passes statically);
  - the safe stage's edges: the circle plus drift stays inside 0–1280 × 0–720;
  - Android: outside the system gesture insets (R11).
- **Static margins** (zero jitter): L1 is 152.1 from the moon; R1 is 142.0 from the nearest token (1148, 58); every
  slot clears the glyph box with 17.2 to spare beyond its 97.8, and each circle plus drift stays 42.2 inside the
  stage edges. So every slot passes at zero jitter when no
  creature is in the way, and a valid position always exists. Some jitters fail (L1 at (−10, −10) is 138.9 from the
  moon; R1 at jy = −10 is about 132.5 from the middle token); they are redrawn.
- **The widest creature** (an estimate until the art exists: 320 units tall at the 640:440 aspect, about 465
  wide, so x 407–873, y 280–600 around the anchor (640, 600)) blocks the **four inner slots** at their static
  centres: L2 is 92.8 from the box corner (407, 280), L4, R2 and R4 are closer. An inner top slot can still take a
  hint if a redrawn jitter clears the box (for example L2 at (−10, −10) is 106.5 away). The four outer slots stay,
  enough for 3 hints. The AC uses the shipped creatures' real bounds.
- The look stays as played: two loose clusters of letters at random spots in the left and right sky.

**R6. Life, spawning and the hint clock.**

- **`hintTime`:** the monotonic uptime clock (Input R8, Press Queue R5), advancing **only in Play while nothing is
  frozen** (R9): it stops while the panel or the gate challenge is open and does not count time in the
  background. All hint ages and the spawn gap use it.
- **Gap:** while fewer than `hint_count` hints are on screen, a spawn is attempted when the gap has run out, and
  the gap (`hint_gap_s`, 0.7 s) restarts from **that attempt**, whether it spawned or was skipped (one-shot
  `hintGap`). **Entering Play** (from the title) and **returning from the background** clear the hints and attempt a
  spawn at once, so three hints appear at 0, 0.7 and 1.4 s. A freeze does not replay this (R9).
- **Life:** `life = hint_life_s × U(0.8, 1.2)` = 4.8–7.2 s (one-shot), drawn at spawn. Alpha and scale follow F2:
  fade and scale in over `fade_in_s` (0.6 s, 85% → 100%), fade out over the last `fade_out_s` (0.8 s), then the
  hint is removed. **A fading hint still counts** (Input R7).

**R7. Drift and pulse.**

- **Drift** (F3) is a pure function of the hint's age and its seeded phase: ±10 units in x at 0.7 rad/s and ±8 in y
  at 1.3 rad/s (one-shot; 0.11 and 0.21 Hz, under art bible §2 rule 2's ≤ 1 Hz). The one-shot's global clock is not
  used, so a hint's path is reproducible from its spawn.
- **A touched hint holds still** (Input R7, art bible §7 conflict 1): from the touch on, its drift offset is frozen
  where it is.
- **Pulse until the first press** (brief "pulsing gently until the first press"; K-18): until the first press in
  this Play entry (any source, any outcome), every hint pulses at 4 rad/s (0.64 Hz): size × (1 + 0.06·p), glow
  alpha 0.35 + 0.2·p, glow blur 18 + 14·p, with `p = 0.5 + 0.5·sin(4·hintTime)` (one-shot). After the first press
  it stops for the rest of this Play entry. It resets on each entry to Play from the title (K-18); a freeze, the
  panel or the background do not reset it.

**R8. What a press does to a hint.** The Press Queue returns the outcome in Input's callback (Press Queue R4), and
Hint Letters acts in the same callback:

| Press | `started` or `queued` | `ignored` (queue full) |
|---|---|---|
| A touch on a hint (`source = hint(id)`) | the hint is **consumed**: removed with a 10-spark burst at its centre (one-shot `takeHint`); the glyph rises from its centre (`origin`) | the hint **stays** (K-15), holds still (R7), and **restarts its life** at full opacity: its age is set to `fade_in_s` (K-18). The sparkle and ping are the Reveal Stage's and Audio's |
| A hardware key whose key is shown as a hint (K-18) | the same: that hint is consumed and the glyph rises from it | the hint is unchanged (no touch happened, so it neither holds still nor restarts) |
| A keyboard-row key whose key is shown as a hint | the same as a hardware key | the same as a hardware key |

- **`originFor(key)`:** the Reveal Stage's router calls it **before** `press(p)` (K-20, leader 2026-11-18). It
  returns the current centre of the hint showing `key`, or none. The press keeps its `source`; only `origin` is
  set, so the glyph rises from the bubble. At most one hint shows a key (R3), so the answer is unique. (Input &
  Key Filter's R8 line "origin nil for a hardware key" is updated by its owner in TASK-050.)
- A second touch on the same hint while it is still on stage is another press of its key (Input R7).
- When a hint is consumed, a new one comes at the next gap (R6), never in the same frame.

**R9. Freezes and interruptions.**

| Event | Hints | `hintTime` | The 0 / 0.7 / 1.4 s sequence |
|---|---|---|---|
| **Gate challenge opens** (the number challenge before the panel, K-20) | frozen where they are: ages, lives, drift and the gap hold; no spawn; no touch reaches them (the challenge has the screen) | stopped | — |
| Gate challenge: wrong answer or timeout | resume exactly where they were | resumes | **not replayed** |
| Gate challenge: correct answer | the panel opens (next row) | stays stopped | — |
| **Panel open** | frozen under the dim (K-18) | stopped | — |
| Panel closed | resume where they were | resumes | **not replayed** |
| **App to background** | cleared | not counted | — |
| Return from the background | three fresh hints | resumes | **replayed** (K-18) |
| **Entering Play** from the title | none before; fresh hints | starts | **played**; the pulse resets (R7) |
| **Theme change** (only in the panel) | unchanged: hints are keys, and every theme has all 36 (Key Table); a hint's item resolves when its reveal starts (Key Table R3) | — | — |
| **Keyboard row turned on** | unchanged: hints stay in the sky (art bible §7 conflict 2) | — | — |
| **Reduce Motion turned on** | applies at once to every hint: drift stops (offsets frozen), the pulse stops (R10) | — | — |

**R10. Reduce Motion** (K-18, art bible §7): no drift, no pulse, no scale-in (the hint fades in at full size),
and a consumed hint fades out over `consume_fade_s` (0.3 s) instead of the spark burst. Fades, life and spawning are
unchanged.

**R11. Platforms.**

- **iPad:** touches (Input R1). No edge rule is needed: hints stay in the safe stage.
- **Mac:** hints are shown and clicking one is a touch (K-18; Input R1: `mouseDown`, `rightMouseDown`,
  `otherMouseDown`). Hover does nothing. A small window can fall below the size floor; F5 then scales the hints.
- **Android tablets (the later Android app):** the hit circle plus drift must stay outside
  `getSystemGestureInsets()` (the back-gesture edges), converted to stage units; slots that would cross an inset
  are blocked (F4). The insets are **read live** through `View.setOnApplyWindowInsetsListener`, because they change
  with rotation and the navigation mode. A hint already on screen that a new inset now crosses is not moved; it
  lives out its life, and its slot is blocked for the next spawn. Physical size uses `DisplayMetrics.xdpi` /
  `ydpi`, not `densityDpi` (F5). **NOT ASSESSED** until an Android build.
- **Phones:** out of scope until the phone / Android ADR (K-03: the MVP is iPad and Mac). Below the size floor the
  F5 scale-up applies.

**R12. The look** (art bible §3, §4, §7). A rounded square bubble `hint_size` 120 units (corner radius 36%),
highlight cream `#f8efdc`, the letter in Letter Gold ink `#b9631c` at about 80 units (0.66 × size) in the bundled
glyph font, a soft gold glow disk behind it and one twinkle star at the top-right corner (one-shot `drawHints`).
Gold means "a letter lives here" (art bible §4). Draw order is the Reveal Stage's (its R10): hints are drawn above the creature, the glyph, the specks and the
sparkles, and below the queue tokens and the moon, matching the touch order (Input R7: a hint is above a cast
member).

### States and Transitions

| State | Meaning | Leaves to |
|---|---|---|
| **Off** | the title screen, or before Play | Running (entering Play: the sequence plays) |
| **Running** | `hintTime` advances; hints spawn, drift, age and fade | Frozen (gate challenge or panel), Off (background: cleared) |
| **Frozen** | gate challenge or panel open; nothing moves or spawns | Running (challenge failed or timed out, panel closed: no replay) |

Per hint: **Fading in** (age < 0.6) → **Shown** → **Fading out** (last 0.8 s) → removed; or **Consumed** (removed
at once with the burst or the Reduce Motion fade). An ignored touch puts it back at the start of Shown and makes it
**Still** (no drift) for the rest of its life.

### Interactions with Other Systems

| System | Direction | Interface |
|---|---|---|
| Key Table & Theme Data | in | the 36 keys in canonical order |
| Input & Key Filter | out / in | out: each hint's centre and `hitRadius` (layer 1); in: the press with `source = hint(id)` |
| Reveal Stage | in / out | in: `stage_to_px` and the safe stage (K-20), the current cast member's box, the freeze signals; out: `originFor(key)`, the hints to draw |
| Press Queue | in | the outcome of each press (R8); the queued keys and current key from its snapshot (R3) |
| Audio & Voice | none | the chime and ping come from the outcome (E1/E2) |
| Parent Gate & Grown-up Panel | in | challenge open / failed / timed out; panel open / closed (R9) |
| App Shell & Title | in | Play entered; background and return (R9) |
| Accessibility | in | the Reduce Motion flag, read live (R10) |
| On-screen Keyboard Row | none | hints stay in the sky either way |
| Parade | none | the parade walks the hill line, below the sky band |
| Settings Store | none | nothing is stored (Settings Store R2) |

## Formulas

**F1. Key pick.**
```
pool = keys36 − hintKeys − {currentKey} − queuedKeys
P(k) = 1 / |pool|   for k in pool;   no spawn if |pool| = 0
```
Example: three hints D, 7, Q, current reveal B, queue [K, K]: pool = 36 − 3 − 1 − 1 = 31 keys, each 1/31.

**F2. Alpha and scale over age.**
```
alpha(a) = min( clamp(a / fade_in_s, 0, 1),  clamp((life − a) / fade_out_s, 0, 1) )
scale(a) = 0.85 + 0.15 × smoothstep(clamp(a / fade_in_s, 0, 1))        (1 with Reduce Motion)
```
`a` = age on `hintTime`. Example: life 6.0: a = 0.3 → alpha 0.5, scale 0.925; a = 3 → 1, 1; a = 5.6 → 0.5. An
ignored touch sets `a = fade_in_s`, so alpha and scale are 1 at once.

**F3. Drift.**
```
x(a) = cx + 10 × sin(0.7 × a + φ)          y(a) = cy + 8 × sin(1.3 × a + φ)
|offset| ≤ sqrt(10² + 8²) = 12.8 units
```
`(cx, cy)` the jittered slot centre, `φ` in [0, 2π) drawn at spawn. Reduce Motion or a touch freezes the offset.
Example: φ = 0, a = π/1.4 ≈ 2.24 s → x = cx + 10, y = cy + 8 × sin(2.92) ≈ cy + 1.8.

**F4. Valid position** (checked on the jittered centre `c`; with the size factor `k` from F5).
```
R        = k × (hitRadius + 12.8)                         = 87.8 at k = 1   (hitRadius 75, Input F1)
hint     : |c − c_other| ≥ 2R + 10k                       = 185.6
moon     : |c − (66, 62)| ≥ R + 50 + 10k                   = 147.8 → 148
token_i  : |c − token_i| ≥ R + 40 + 10k                    = 137.8 → 138     token_i ∈ {(1214,58), (1148,58), (1082,58)}
box      : dist(c, box) ≥ R + 10k                          = 97.8           box ∈ {cast member, glyph}
stage    : R ≤ c.x ≤ 1280 − R  and  R ≤ c.y ≤ 720 − R
insets   : the circle of radius R around c is outside every gesture inset (Android)
```
`dist(c, box)` is 0 inside the box, else the distance to its nearest point. Examples: L1 (130, 200) → moon 152.1 ✓;
L1 jittered (120, 190) → 138.9 ✗ (redraw); R1 (1150, 200) → token (1148, 58) 142.0 ✓; slot spacing 230 × 210 minus
2 × 10 jitter → ≥ 190 ✓.

**F5. Physical touch size and the floor.**
```
hit_d_mm = 2 × hitRadius × stage_to_px / ppi × 25.4
k        = max(1, hit_floor_mm / hit_d_mm)           (hit_floor_mm = 18)
```
With `k > 1`, the bubble, `hitRadius`, the drift clearance, the spacing and every clearance box scale by `k`
(F4); the slot positions do not, so slots that no longer fit are blocked.

| Device | stage_to_px (K-20 contain, width fit) | ppi | hit diameter | k |
|---|---|---|---|---|
| 11" iPad (2388 × 1668) | 2388 / 1280 = 1.87 | 264 | 280 px ≈ **27.0 mm** | 1 |
| 13" iPad (2752 × 2064) | 2.15 | 264 | 322 px ≈ 31 mm | 1 |
| Mac, 1280-pt window on a 2× 254-ppi screen | 2.0 | 254 | 300 px = 30 mm | 1 |
| Mac, 700-pt window, same screen | 1.09 | 254 | 164 px ≈ 16.4 mm | 1.10 |
| 10" Android tablet (later; `xdpi`) | screen px / 1280 | `xdpi` | by formula | NOT ASSESSED |

`stage_to_px` comes from the Reveal Stage (K-20). On the Mac, `ppi` comes from the display's physical size
(`CGDisplayScreenSize`) and the window's backing scale; on Android from `DisplayMetrics.xdpi` / `ydpi`.

**Capacity at k > 1:** at `k = 1.2` the hint spacing is 222.7, so the two slots in one column (210 apart) cannot
both hold a hint; L1 and R1 also fail the scaled moon and token clearances (167.4 and 157.4 against 152.1 and
142.0), and the widest creature blocks the inner slots (117.4). That leaves L3 and R3: **2 hints** on screen, not 3.
This is stated, not hidden; it occurs only on a small Mac window.

**Where it starts** (game-qc-android): at zero jitter L1 fails the scaled moon clearance once `97.8k + 50 > 152.1`,
i.e. `k > 1.044`, and R1 the token clearance once `97.8k + 40 > 142.0`, `k > 1.043`. Between about 1.044 and 1.18 they
pass only with a favourable jitter (L1 at (+10, +10) is 165.5 from the moon). So with the widest creature on stage,
from `k ≈ 1.044` (including the 700-pt Mac row, `k = 1.10`) the screen may show 2 hints rather than 3.

## Edge Cases

- **All 36 keys excluded** (cannot happen with 3 hints, 1 current and ≤ 3 queued: at most 7 excluded) → no spawn;
  stated for completeness (F1).
- **No free slot** (a wide creature plus occupied slots) → no spawn; retried at the next gap (R5, R6).
- **A jitter fails a clearance** → redrawn up to 4 times, then zero jitter, then the next slot (R5).
- **A creature appears where a hint already is** (a reveal starts after the hint spawned): the hint is not moved;
  the cast clearance applies to the next spawns. The hint is drawn above the creature (R12, Reveal Stage R10), and
  the creature's touch layer is below the hint's (Input R7), so what the child sees on top is what a touch hits; the overlap lasts at most
  the hint's remaining life.
- **The child touches a fading hint** → it counts (R6), and if ignored it restarts its life (R8).
- **Two fingers on two hints** → two presses in the sorted batch order (Input R7); each hint follows its own
  outcome.
- **A hardware key matches a hint while that hint is being touched** → two presses of the same key in delivery
  order; the first accepted one consumes the hint, and `originFor` gives none for the second.
- **Queue full and the child keeps touching the same hint** → each touch is ignored, the hint stays still at full
  opacity and its life restarts each time (R8); the Reveal Stage sparkles and Audio pings each time.
- **The panel opens mid-fade** → the hint freezes at that alpha; after closing it continues the fade (R9).
- **The gate challenge fails** → hints resume exactly; no new sequence (R9).
- **Background, then return** → three fresh hints at 0 / 0.7 / 1.4 s (R9).
- **Reduce Motion toggled with hints on screen** → drift and pulse stop at once; hints keep their positions (R9,
  R10).
- **A small Mac window** → the size floor scales hints up (F5); with the widest creature only 2 may fit.
- **Android gesture insets change** (rotation, nav mode) → read live; on-screen hints stay, blocked slots skip
  (R11).
- **Debug: the seed** is logged; the same seed with the same press and clock sequence gives the same hints.

## Dependencies

- **Upstream (all Approved):**
  - Key Table & Theme Data (`design/gdd/key-table-theme-data.md`): the 36 keys in canonical order. Its
    Interactions already name Hint Letters.
  - Input & Key Filter (`design/gdd/input-key-filter.md`): touch layer 1, `hitRadius` (F1 there), "a fading hint
    still counts", "holds still once touched", the Title state. Its R8 origin line is updated by its owner in
    TASK-050 for `originFor`.
  - Press Queue (`design/gdd/press-queue.md`): the outcome in the callback (its R4 already says "Hint Letters
    consumes the touched hint for started and queued; for ignored the hint stays"), the snapshot (R11).
- **Peers / downstream (each must name Hint Letters):**
  - Reveal Stage (TASK-049): calls `originFor(key)` before `press(p)`; publishes `stage_to_px`, the safe stage and
    the cast member's box; passes the freeze signals.
  - Parent Gate & Grown-up Panel: the challenge and panel freezes (R9).
  - App Shell & Title: Play entry and the background (R9).
  - Accessibility: the Reduce Motion flag (R10).
- **Documents:** the brief (After-play, Avoid, line 38); art bible §2 rules 1–3, §3 (hint shape), §4 (colours, sky
  only), §6 (sky band), §7 (sizes, motion, Reduce Motion, conflicts 1–2); decisions K-06, K-08, K-10, K-15, K-16,
  K-18, K-20.

## Tuning Knobs

All values are bundled data, checked at build (ADR-0001 Decision 6). A value missing, not a number or out of range
fails the build.

| Knob | Value | Safe range | Source | Effect |
|---|---|---|---|---|
| `hint_count` | 3 | 0–4 (only 4 outer slots survive the widest creature) | one-shot, art bible §7 | letters on screen |
| `hint_life_s` | 6.0 (× U(0.8, 1.2)) | 3–12 | one-shot | how long a hint lingers |
| `hint_gap_s` | 0.7 | 0.3–2.0 | one-shot | time between spawn attempts |
| `fade_in_s` / `fade_out_s` | 0.6 / 0.8 | 0.2–1.0 / 0.3–1.5 | one-shot, art bible §7 | softness of arrival and leaving |
| `hint_size` | 120 units | 100–150 | art bible §7 | bubble size (with `hitRadius` = 75 at size 120, Input F1) |
| `hint_jitter` | 10 units | 0–12 | this GDD | how loose the clusters look; above 12 the slot spacing (≥ 185.6) fails |
| drift amplitude / rates | ±10, ±8 / 0.7, 1.3 rad/s | ≤ ±12 / ≤ 6.28 rad/s (≤ 1 Hz) | one-shot, art bible §2 | the float; clearances include it |
| pulse | 4 rad/s, ±6% | ≤ 6.28 rad/s | one-shot | the invitation before the first press |
| `consume_fade_s` | 0.3 | 0.15–0.6 | this GDD (proposal) | the Reduce Motion consume |
| `hit_floor_mm` | 18 | 15–25 | game-qc-android's review | the smallest physical touch target |
| slots | 8, R5 table | each must pass F4 statically | this GDD | where hints may appear (build check) |

**Interactions:** raising `hint_size` or the drift raises every clearance (F4) and may block slots; raising
`hint_count` above the slots that survive the widest creature leaves the extra hints unspawned.

## Acceptance Criteria

Logic tests use an injected seed and an injected `hintTime`, a fake Press Queue (outcomes on demand, a snapshot),
a fake Reveal Stage (cast box, `stage_to_px`, freezes) and the slot table. No wall clock, no frames.

- **AC-1 Spawn sequence:** WHEN Play is entered at hintTime 0, THEN spawns happen at 0, 0.7 and 1.4 s, and no more
  while 3 are on screen.
- **AC-2 Gap from the attempt:** GIVEN every slot blocked at 2.0 s, THEN no spawn, and the next attempt is at 2.7 s
  (not on the next frame).
- **AC-3 Exclusions:** over 10,000 seeded spawns, no new hint's key equals a hint on screen, the current key or a
  queued key; with the pool fixed, each key's frequency is 1/|pool| ± 2%.
- **AC-4 Jittered clearances:** over 100,000 seeded spawns, no jittered centre violates any F4 clearance (hint,
  moon, tokens, cast box, glyph box, stage edges); the drifted hit circles never overlap each other or the moon
  over the hints' whole lives.
- **AC-5 Static slots:** every slot passes F4 at zero jitter with no creature (build check); L1 = 152.1 from the
  moon, R1 = 142.0 from the nearest token.
- **AC-6 Widest creature:** with the widest shipped creature's box held on stage, the inner slots are blocked at
  their static centres (L2, L4, R2, R4 at the estimate) and 3 hints still spawn on the outer slots.
- **AC-7 Never empty (seeded, worst case):** over 10,000 simulated minutes **with the widest shipped creature held
  on stage**, at `k = 1.0`, `1.10` and `1.2`, with presses and outcomes from a seeded mash: Play is never without a
  hint for more than one gap (0.7 s) after the first spawn, and no two hit circles overlap; at `k = 1.2` at most 2
  hints are on screen.
- **AC-8 Life and fades (F2):** every life is in 4.8–7.2 s; alpha and scale match F2 at the example ages within
  1e-6; a hint is removed at age = life.
- **AC-9 Drift (F3):** a hint's position is a pure function of (spawn data, age): the same seed and times give the
  same positions; |offset| ≤ 12.8.
- **AC-10 Outcomes (R8):** a hint touch with `started` or `queued` consumes the hint; with `ignored` the hint stays,
  holds still and its alpha is 1 at once; a hardware key matching a hint consumes it on `started`/`queued` and
  leaves it unchanged on `ignored`.
- **AC-11 originFor:** returns the matching hint's current centre, or none; the press's `source` is unchanged; the
  started reveal's `origin` is that centre.
- **AC-12 Fading still counts:** a touch inside `hitRadius` at alpha 0.1 is a press (via Input layer 1).
- **AC-13 Pulse:** the pulse runs until the first press of a Play entry and stops; it restarts on the next entry
  from the title; a panel close or background return does not restart it.
- **AC-14 Gate challenge freeze (K-20):** WHEN the challenge opens at hintTime 3.0, THEN hintTime stops, no hint
  moves, ages or spawns; WHEN it fails or times out after 8 s of uptime, THEN every hint resumes at its age from 3.0,
  no hint was added or removed, and the 0 / 0.7 / 1.4 sequence does not replay.
- **AC-15 Panel freeze:** the same as AC-14 for the panel open and close (K-18).
- **AC-16 Background:** WHEN the app goes to the background and returns, THEN the old hints are gone and three new
  ones spawn at 0, 0.7, 1.4 s of hintTime after the return.
- **AC-17 Title:** no hint exists or spawns on the title screen.
- **AC-18 Reduce Motion (R10):** no drift, no pulse, scale 1 from the first frame, and a consume fades over 0.3 s
  without sparks; turning it on mid-life freezes the offsets at once.
- **AC-19 Size floor (F5):** for each F5 row, `hit_d_mm` and `k` match within 0.1 mm / 0.01; at `k > 1` the bubble,
  `hitRadius` and clearances scale by `k`.
- **AC-20 Android gesture insets (NOT ASSESSED until an Android build):** with a fake inset of 48 px on both side
  edges, no spawn's circle crosses it; changing the inset live blocks the newly crossing slots for the next spawn
  without moving hints on screen.
- **AC-21 Data:** the build fails for each knob missing, not a number or out of range, and for a slot that fails F4
  statically.
- **AC-22 Look (retained screenshots):** on Day and Night, at the 11" iPad (extended sky and ground, K-20) and a
  16:9 Mac window: the worst case of the widest creature, 3 hints, 3 queue tokens and the moon, with no overlap;
  plus one Reduce Motion frame; plus the full-queue case where a touched hint stays (Press Queue AC-19).

**NOT ASSESSED:** Android gesture insets and `xdpi` (AC-20) until an Android build; whether 27 mm targets and a 6 s
life suit a 2.5-year-old's aim (playtest).

## Open Questions

- None open.
- **Decided (Luan):** K-15 (an ignored hint stays), K-18 (hardware key consumes its hint; queued keys excluded;
  pulse until the first press, reset per Play entry; an ignored hint restarts its life; panel freezes, background
  respawns; the Mac shows hints; Reduce Motion: no drift, no pulse, no scale-in, a plain fade), K-20 (stage fit;
  the gate challenge freezes the hints).
- **Chosen by the author (game-qc-android's review):** fixed slots with seeded jitter instead of random tries;
  the 18 mm floor with scale-up and "2 hints at k = 1.2" stated; a hardware or row key that is ignored leaves its
  hint unchanged; `consume_fade_s` 0.3 (proposal).
