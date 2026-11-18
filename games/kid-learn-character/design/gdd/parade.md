# Parade

> **Status**: Approved (independent read by game-dev-ios, merged 2026-11-18); **TASK-120 revision in review** (K-44 parade
> meter R12, F4; K-45 start without a rest R2, F2; K-46 answers MT-Q1–Q5, with the meter light R12a)
> **Author**: game-art-content for Luan (TASK-046); plan reviewed by game-dev-android
> **Last Updated**: 2026-11-18
> **Last Verified**: 2026-11-18
> **Implements Pillar**: Pillar 4 (Things the Child Loves); serves Pillar 3 (Calm Magic)

## Summary

Every time the child has met 6 different creatures, those 6 walk across the hills behind the stage, small, once,
to a light tune. It is the toy's one celebration and its happy surprise (game brief, Keep: "the most fun"). There
is no goal behind it: the parade simply keeps coming back for as long as the child plays. This GDD owns which
creatures count, when the parade starts, who walks and how, and what presses, the grown-up panel, Reduce Motion
and missing art do to it. How each figure is drawn is Cast Rendering's; the tune is Audio & Voice's.

> **Quick reference** — Layer: `Feature` · Priority: `MVP` · Key deps: `Reveal Stage`, `Cast Rendering` (also
> reads Reveal Stage's `shown`; plays Audio & Voice E12; drives the Scene's horizon lift; owns the parade meter's
> state, which the Reveal Stage draws)

## Overview

The child presses D, then C, then T, then 3… Each new creature is added to a **batch**. When the batch holds 6
different keys, 1.5 s after the 6th creature has formed (K-45), the 6 walk across the hill band from left to right
in the order they were met, bobbing as they step, while a short tune plays. A press during the walk is answered as usual, in front
of the parade, which keeps walking. Then a new batch starts. Nothing is saved: the next launch starts from zero.

*(TASK-120.)* A small **parade meter** at the top right of the stage lights one step per new creature, so the child
can see the parade coming (K-44). When the 6th step lights, the parade starts a moment later (1.5 s after that
creature has formed), even if the child keeps pressing (K-45).

This GDD owns:
- **batches** (R1): what counts as meeting a creature, and per theme;
- **arming and start** (R2), **who walks** (R3), **the walk** (R4, F3);
- what **a press** (R5), **the panel or background** (R6), **Reduce Motion** (R7) and **art not ready** (R8) do;
- digits and repeats (R9), sound (R10) and the debug start (R11);
- **the parade meter's state** (R12, F4): what it shows and when it changes. Its look and box are the art bible's
  (§7); the Reveal Stage draws it.

It does **not** own: drawing a figure, its step bob or its tiers (Cast Rendering R8, R10); the stage layout,
draw order and taps (Reveal Stage, asked for below); the queue (Press Queue); the meter's look (art bible §7); the tune
(Audio & Voice E12).

## Player Fantasy

**"Look, all my friends came back to say hello!"** After a run of keys, the creatures the child just made come
walking past together, like a little band. The child recognises them ("T-rex! The three babies!"), and the
parent, who called it the most fun part of the one-shot, gets a moment to cheer along. It is a surprise each
time, never a reward for doing something right, so it never asks the child to do anything.

## Detailed Design

### Core Rules

**R1. Batches (decided, K-17).**
- A **batch** is the list of **distinct keys** (A–Z, 0–9) **shown as a creature** since the last parade, in the
  order each was first met. A key pressed again within the batch counts once. Letters and digits both count.
- **Shown as a creature** means the reveal really showed the cast member: the morph, or the creature fading in
  (glyph missing, invalid timing set). A **glyph-only** fallback (art or silhouette missing: the glyph sparkles
  out) does **not** count (leader default, K-17). The Reveal Stage reports this with `shown(...)` (Interface).
- The key is added **when the creature is shown** (`shown` at formed time), not when it is pressed. A press that
  the Press Queue ignores, or a queued press dropped by the panel or background (K-15), never counts.
- **One batch per theme**, in memory only (nothing is saved: Settings Store, Key Table "no saved progress"). A
  theme switch keeps each theme's batch; switching back resumes it. A parade never mixes themes (K-17).
- **Batches reset at launch.** There is no cap: parades keep coming as long as the child plays (K-17).
- Each batch entry stores **`{key, castId}`** from the `shown(...)` that added it, and the parade walks **that**
  castId. It never reads Key Table's `lastShown`, which resets on a theme change. With one item per key (MVP) it
  is always the same; with production variety it is the one the child saw when the key joined the batch.

**R2. Arming and start (decided, Luan K-45, 2026-11-18; replaces "after a rest", as played).**
1. When the current theme's batch holds `parade_count` keys (6, K-17), the Parade is **Armed**. `armedAt` is the
   play time of the `shown(...)` that added the 6th key: the 6th creature's formed time.
2. While Armed, the parade starts at
   ```
   t_start = armedAt + parade_delay_s          (play clock; parade_delay_s 1.5 s)
   ```
   **No rest is needed** (K-45): presses, new reveals and queued keys neither delay nor cancel it. By then the 6th
   creature's fade-in has finished (`form_s` 0.5 s, 0.3 s reduced) and its word has ended (Audio & Voice F6 caps the
   word's end at `formedS + 1.5`), so the tune follows the name (F2). The walkers' art is prefetched from Armed (R8.1).
   *Why:* the old rule needed about 4 s without a press; Luan's child kept pressing, met more than 8 keys and never
   saw a parade (K-45). **K-45 removed the rest, not the beat** (Luan, K-46, MT-Q5): the 1.5 s after the 6th
   creature has formed stays, so the tune follows the 6th name.
3. A reveal that is playing when the parade starts keeps playing **in front** (R5); its creature, if new, joins the next
   batch (held while Armed, appended once Walking; PA-Q4).
4. **Once Walking, the parade runs on its own state and clock** (`pt`, seconds since the walk started). Presses do
   not stop it (R5).
5. **The batch empties at parade start.** Creatures shown during the walk count toward the next batch. The
   Parade can be Armed again only from **Ended**: if a new batch fills during a walk, the Parade is Armed at Ended,
   with `armedAt` = the Ended time, and that parade starts `parade_delay_s` later.

**R3. Who walks.** The batch's `parade_count` keys, **in the order they were met**: the first met leads. They walk
**left to right**, facing right (art bible §5: every cast member faces right). Each is drawn as its item's cast
member in Cast Rendering's `parade` role (R1 there: `body` and `outline` only, ~85 stage units tall).

**R4. The walk.** All positions are in **stage units** (the 1280×720 design space; the one-shot's pixels are stage
units).
- **Lane:** **the lane y from the Reveal Stage** (Interface 2): the ground line behind the stage creature (558 as
  played, which moves up when the keyboard row shows).
- **Positions:** F3. Walkers are spaced `gap` (150 u) apart; the leader enters at the left edge and the last
  walker leaves past the right edge as the walk ends.
- **Fades:** the whole parade fades in over `fade_s` (0.6 s) and out over the last `fade_s` (F3).
- **Step:** Cast Rendering's step bob (its R8): 5 u at `|sin(7t + i)|`, about 2.2 Hz, a recorded K-16 exception to
  the ≤ 1 Hz rule (art bible §2 amendment). The Parade passes each walker's index `i` and the walk clock `pt`.
- **Length:** `parade_s` (11 s, pinned by the game brief). It ends at `pt ≥ parade_s` → **Ended**.

**R5. A press during the parade (decided, K-17: as played).**
- A press is handled by the Press Queue as always. The new reveal plays **in front**, at full size; the parade
  **keeps walking behind** it, on its own clock (R2.4). It never pauses, cuts or speeds up.
- The stage creature can still be tapped (its hop and sound). **Tapping a walking figure only sparkles** (K-17);
  it is not a creature tap (Interface: the Reveal Stage routes it).
- Creatures shown during the walk join the next batch (R2.5).

**R6. Grown-up panel or background (decided, K-17; the K-15 pattern).**
- **Panel opens** while Walking: the parade fades out over `fade_s` under the panel's dim, **counts as played** and
  is **not replayed**. The batch is already empty (R2.5).
- **App goes to the background** while Walking: the parade is dropped at once (nothing is drawn in the
  background), counts as played, and is not replayed on return.
- *(K-20)* The panel opens only after the gate's **correct answer**; the fade above applies then, not when the
  gate challenge starts. The challenge itself **freezes** the parade (R6a).
- While **Armed** or **Waiting for art**, the panel or background do not cancel the batch, and the parade never
  starts under the panel or in the background. When the panel closes or the app returns, `armedAt` is set to that
  moment, so the parade starts `parade_delay_s` later (R2.2; K-45). Waiting for art returns to Armed (PA-Q9).
  *Time in the background does not count* (play clock).

**R6a. Gate challenge freeze (K-20).** While the parent-gate number challenge shows, the Reveal Stage calls
`freeze()`, and on a wrong answer or a timeout `resume()` (Interface 6).
- **Walking:** `freeze` pauses the walk clock `pt` and every walker where it is, and asks Audio & Voice to
  **pause E12**; `resume` continues the walk and the tune from where they stopped. A correct answer opens the
  panel, and R6's fade-out applies.
- **Armed or Waiting for art:** frozen time **does not count** toward `parade_delay_s` (F2) or the art wait, the
  same as background time. The batch is kept.
- **Counting:** nothing changes (no `shown` arrives while frozen).

**R7. Reduce Motion (decided, K-17).** The same `parade_s` walk; Cast Rendering halves the step bob (its R8). No
other change: same path, same fades. The reduced timing set changes the reveals (and so F2's start time), not the
walk.

**R8. Art not ready (decided, K-17).**
1. **At Armed** *(K-45: was "at start")*, the Parade asks Cast Rendering whether each walker's art is resident at
   the `parade` role (`isResident`), and prefetches any that are not (`prefetch`), so the 1.5 s beat covers most loads.
2. At `t_start` it waits up to `art_wait_s` (0.5 s) in **Waiting for art** for any walker still missing, then walks
   **without any figure still missing**.
   The others keep their own index `i`, so the gaps stay where the missing walker would have been.
3. **Skip rule (rescaled for a batch of 6):** if fewer than `ceil(parade_count × skip_fraction)` walkers are ready
   (fewer than **3 of 6**), the parade is **skipped**: it does not count as played, the batch is kept, the Parade
   stays **Armed**, and it tries again after the **next formed reveal** (any `shown`): `armedAt` = that time, start
   `parade_delay_s` later. One try per formed reveal *(K-45: was "per rest")*. One debug log line either way.
4. Residency during a parade (Cast Rendering F6): the stage set (`2 + queue_max` figures) **plus** up to
   `parade_count` parade figures at the 256 px tier (about 180 KB each, ~1.1 MB for 6). A walker that is also the
   current creature needs its small-tier copy as well; the stage-tier copy does not serve the parade role. The
   parade's figures are released at Ended.

**R9. Digits, 0 and repeats (decided, K-17).**
- A digit walks as **its group** at parade size: "3" is the three babies, "0" is the empty nest (Key Table
  numbers). The group is one cast member, so it takes one place in the line.
- Repeats count once per batch (R1). After a parade, the same key counts again in the next batch, so favourites
  come back.

**R10. Sound.** Only Audio & Voice E12: the parade tune at walk start, ducked under any voice line (its F2). No
creature sounds during the walk. By F2 below the tune starts at least 0.5 s after the last word ended (normal
set), so in practice it is never ducked at its start.

**R11. Debug start (decided, K-17).** Release builds have **no** "Play the parade" control. **Debug builds** accept
`startParade(manual)`: it starts at once (skipping the rest check), uses the current theme's batch, and, if the
batch holds fewer than `parade_count`, fills it with the first keys in canonical order (A, B, C…) not already in
it. A manual start while Walking is ignored. A manual parade empties the batch like any other.

**R12. The parade meter (decided, Luan K-44, 2026-11-18; details TASK-120).**
- **What it is:** the toy's **one HUD element**, a small bar of `parade_count` (6) cells at the top right of the safe
  stage, just left of the queue-token row. Its size, box, shape and colours are the art bible's (§7 "Parade meter").
  It shows how many creatures of the current batch the child has met; when every cell is lit, the parade is coming.
  **No number and no text** (K-44, leader default). The count is the number of lit cells, never colour alone.
- **Not a score:** it is never saved, never shows a total and empties with each parade (concept anti-pillars;
  K-44).
- **A key joins the batch at its `shown(kind: creature)`** (R1, formed time), **not** at the settle; `filled`
  counts it from then. Its cell **lights when the meter light lands** (R12a, `meter_fly_s` 0.9 s later; at once under
  Reduce Motion) and then fills over `meter_step_s` (0.4 s, F4). Cells light left to right, the way the parade walks.
  A repeat key, a glyph-only reveal, and an ignored or dropped press light nothing and send no light (R1).
- **What it shows:** `filled` = the **counting batch** of the current theme, at most `parade_count` (F4): the
  batch while Counting, Armed or Waiting for art; from Walking entry, the next batch (PA-Q4). Keys held while Armed
  are not shown beyond full.
- **Full:** the Parade is Armed at the 6th key's `shown` (R2). The meter shows its **full look** from `fullAt`, when
  the 6th light lands and its cell lights (`armedAt + meter_fly_s`; `armedAt` under Reduce Motion): a soft Starlight
  glow around the bar, breathing at `meter_pulse_hz` (0.5 Hz) between alpha 0.35 and 0.45 (F4). In the usual case it
  shows for about 0.6 s before the parade starts at `armedAt + 1.5` (the brief full look K-45 expected), and longer
  while the panel holds the start (R6), during the art wait, or after a skip (R8).
- **Handover:** at Walking entry the glow fades out, and every cell beyond the next batch's count fades back to
  unlit, both over `fade_s` (0.6 s), while the parade fades in. Cells for held keys stay lit. During the walk,
  creatures shown light cells of the next batch as usual (R5). If the next batch fills during the walk, the meter is
  full but **steady** (no glow) until Ended, when the Parade is Armed (PA-Q4) and the glow starts.
- **Per theme, nothing saved:** each theme's meter is its batch (R1). After a theme switch (made in the panel) the
  meter shows the new theme's count from the first frame after the panel closes, with no fill animation. It is empty
  at launch.
- **Gate, panel and background:** the meter is part of the stage: it sits under the panel's dim and is drawn nowhere
  in the background. When the gate challenge or the panel shows, or the app goes to the background, a light in flight
  is removed and its cell is lit at once; while they show, a fill in progress completes and the glow holds at its
  middle (F4). Closing or returning replays no light and no fill.
- **Reduce Motion** (Accessibility A1, from the next frame): **no light flies**; the cell lights at the `shown` and
  still fades over 0.4 s (fades stay, as for the keyboard row); the full glow is **steady** at 0.40, with no breathe
  (as the glyph halo holds steady, K-16).
- **Not a target:** a touch on the meter is an empty-stage sparkle (Input R7 layer 5).
- **Play only** (decided, Luan K-46, MT-Q1): shown **from Play entry**, empty or at the batch's count, fading in with
  the Play entry; **not on the Title** (App Shell R2).
- **No sound of its own** (decided, K-46, MT-Q2), and the light is silent too: the parade tune E12 is the full
  moment's sound.
- **Beside the tokens** (decided, K-46, MT-Q4): left of the queue-token row on the same line, placed from `queue_max`
  (art bible §7); the tokens keep the corner.
- **Flash safety:** F4's bounds hold: its one rate is ≤ 1 Hz (Accessibility F1, no exception), the glow's swing is
  below ΔL 0.1, fills and lights come at most once per formed reveal, and a light passes each pixel once (ADR-0013).
- **Drawn by the Reveal Stage** from the Parade's meter snapshot (Interface 7), in the queue-token layer; its box is
  published with the token circles for Hint Letters' clearances (its F4).

**R12a. The meter light (decided, Luan K-46, MT-Q3; designed in TASK-120).** A small light flies from each new
creature to its cell, so the child sees which creature filled the meter. Small and calm.
- **When:** it launches at the `shown(kind: creature)` that adds a key to the counting batch (R1), the same moment
  the key counts. Only keys that get a cell send one: a repeat, a glyph-only reveal, or a key held while Armed (the
  meter is already full) sends none.
- **From and to:** from the top centre of the creature's **cast box** (Reveal Stage R10, published from `formedS`) to
  the centre of its cell (art bible §7: cell `i` at `meter_cx − 67.5 + 27·i`, y 58).
- **Path and time:** one quadratic curve that first rises, then glides right into the cell (F4: control point straight
  above the start, at the cell's height), over `meter_fly_s` (**0.9 s**) with a sine ease-in-out. It stays above the
  hint slots' bubbles near the meter (F4) and never reaches the moon.
- **Look:** a small Starlight four-point star, like the press starlight but smaller, **16 units** tip to tip, with a
  soft Starlight glow of radius 8 at 40%; never gold (§4). No trail, no sparkle on arrival. Over its last
  `meter_land_s` (0.15 s) it fades out while its cell starts to light (art bible §7).
- **The cell lights on arrival:** `litAt = launchAt + meter_fly_s`, then fills over `meter_step_s` (F4). So the 6th
  cell is full at `armedAt + 1.3`, before the parade starts at `armedAt + 1.5` (constraint:
  `meter_fly_s + meter_step_s ≤ parade_delay_s`).
- **One at a time:** reveals form at least 1.2 s apart (the reduced `formedS`), longer than a flight, so at most one
  light is in the air.
- **During a parade and the handover:** a creature shown during the walk sends its light to its cell of the **next**
  batch as usual, drawn above the walkers. If it lands on a cell that is draining (F4), the lighting wins for that
  cell. A light is never in flight at Walking entry in the usual case (the 6th lands 0.6 s before it); if one is, it
  keeps flying to its cell in the next batch.
- **Gate, panel, background, theme switch:** the light is removed and its cell lit at once (R12); a theme switch
  happens in the panel, so no light crosses themes.
- **Reduce Motion:** no light; the cell lights at the `shown` (R12).
- **Not a target;** taps go through it (an empty-stage sparkle or whatever is under it).
- **Draw layer:** with the meter in the queue-token layer (ADR-0006 D1, z 70), **above** the meter, so it lands on
  its cell; above the hints, the parade and the creature it leaves.

### Precise rules for the contract (TASK-101; parade-v1)

Normative. Times are the play clock (Reveal Stage R8: uptime minus frozen and background time); "a tick" is a frame
of the Parade's update.
- **Start (PA-Q1; rewritten for K-45, TASK-120):** Armed → Waiting for art at the **first tick** with
  `play ≥ armedAt + parade_delay_s` (**inclusive**). `armedAt` is the play time of the `shown(...)` that filled the
  batch, set again by R6 (panel close, app return), R8.3 (the try after a skip) and PA-Q4 (Ended with a full next
  batch). The Parade no longer reads `restingSince`, `formedS` or `revealLen`.
- **The art wait (PA-Q2):** if every walker's parade art is resident at that tick, the parade is **Walking in the
  same tick**. Otherwise it walks at the **first tick at which all are resident**, or at the first tick with
  `play − waitStart ≥ art_wait_s` (**inclusive**), whichever comes first. At that timeout it walks if
  `ready ≥ ceil(parade_count × skip_fraction)` (3 of 6: **2 → skip, 3 → walk**). A **skip** returns to Armed, and the
  next try is anchored at the **next formed reveal** (R8.3): one try per formed reveal *(K-45; was one per rest)*.
- **Walking entry (PA-Q3),** in one step, in this order: request E12, set `paradeWalking` on, move the walkers out of
  the batch, set `pt = 0`.
- **Batches and held keys (PA-Q4):**
  - while Armed or Waiting for art, a newly shown key that is **not already in the full batch and not already held**
    is appended to the **held** list, in order (once);
  - the walkers are the **first `parade_count`** keys of the batch, in order; at Walking entry the next batch
    **starts as the held list** (plus any batch keys beyond `parade_count`, in order);
  - keys shown while Walking are appended to that next batch, deduplicated;
  - at Ended, if the next batch already holds `parade_count` keys, the Parade is **Armed at once**, with
    `armedAt` = that tick (R2.5).
- **Ended (PA-Q5):** at the **first tick with `pt ≥ parade_s`** (inclusive). On **panel open** while Walking the state
  is **Ended at once** and `paradeWalking` turns **off at once** (the Scene's lift fades on its own λ); the 0.6 s
  fade-out is drawn as a visual only. On **background**: Ended at once. The parade figures are **released** when
  nothing of the parade is drawn any more (at Ended, or after the panel fade-out has finished).
- **F3 (PA-Q6):** `x_i`, `alpha` and `speed` are pure functions; the draw test `−150 ≤ x − rect.minX ≤ W + 150` is
  **inclusive**; `alpha = clamp(min(pt / fade_s, (parade_s − pt) / fade_s), 0, 1)`.
- **Reduce Motion (PA-Q7):** the output is the bob amplitude passed to Cast Rendering, 5 → 2.5 units, from the
  **next tick**.
- **Per theme (PA-Q8):** each theme keeps its own batch, held list and Armed state; only the **current** theme's is
  checked for a start.
- **Freeze and interruptions while Waiting (PA-Q9):** the gate freeze holds the art wait (play clock). The panel or
  the background while Waiting for art returns to **Armed**, with the batch and held list kept, and `armedAt` is set
  at the close or the return (R6).

### States and Transitions

| State | Entered when | Does | Left when |
|---|---|---|---|
| **Counting** | launch; after Ended | adds keys from `shown(kind: creature)` to the current theme's batch | the batch reaches `parade_count` → Armed |
| **Armed** | batch full (`armedAt`) | prefetches the walkers' art; checks R2.2 each tick (no rest needed, K-45); new distinct keys go to the **next** batch, in order (this one is full); the meter's full look (R12) | `play ≥ armedAt + parade_delay_s` → Waiting for art |
| **Waiting for art** | the start time came | waits ≤ `art_wait_s` for missing art | ready, or the wait ran out → Walking (≥ 3 ready), or back to Armed (skip, R8.3); panel/background → Armed |
| **Walking** | art ready | owns `pt`; draws the walkers; plays E12 at `pt = 0`; empties the batch; signals the Scene's horizon lift | `pt ≥ parade_s`, panel (fade) or background (drop) → Ended; `freeze` pauses `pt` here (R6a) |
| **Ended** | the walk ended | releases parade figures | at once → Counting (or Armed if the next batch is already full) |

While Armed, extra distinct keys shown before the parade starts are **held for the next batch**, in order (the
batch never grows past `parade_count`). A theme switch while Armed leaves that theme Armed; the new theme's own
batch is used from then on.

### Interactions with Other Systems

| System | Direction | What passes |
|---|---|---|
| Reveal Stage | in / out | in: `shown(revealId, key, castId, kind)`; the lane y; draw order; tap routing on walkers; panel and background signals. Out: the **meter snapshot** (R12, Interface 7), which it draws |
| Press Queue | — | nothing since K-45 (TASK-120): the start no longer reads `restingSince`, `formedS` or `revealLen` |
| Cast Rendering | out / in | `drawCast(item, parade, x, y, i, pt)` per walker; `isResident`, `prefetch`, `release`; the step bob (its R8) |
| Key Table & Theme Data | in | the current theme id (the walker's castId comes from `shown`, R1) |
| Scene: Time of Day & Weather | out | `paradeWalking` on / off (Walking state) → the warm horizon lift (art bible §2) |
| Audio & Voice | out | parade start / end → E12 |
| Accessibility | in | Accessibility's `reduceMotion` (its A1; never the OS API) (passed on to Cast Rendering's step bob; next frame) |
| Parent Gate & Grown-up Panel | in | panel open → fade out (R6) |
| App Shell & Title | in | background → drop (R6) |

### Interface needed from the Reveal Stage (for its author to restate)

1. **`shown(revealId, key, castId, kind)`**, sent **once per reveal at formed time**, with `kind` = `creature` (the
   morph or the creature fade-in) or `glyphOnly` (the sparkle-out fallback). Built from Cast Rendering's
   `willForm(item)` (its R9), which the Reveal Stage already asks at `startReveal`. This is **separate** from the
   Press Queue's `formed(revealId)`, which stays as it is.
2. **The parade lane:** the ground-line y in stage units behind the stage creature (558 as played =
   478 + `GROUND_SHIFT` 80), moving up with the keyboard row.
3. **Draw order:** backdrop → **parade** → the leaving creature → the current reveal and creature → hints, tokens,
   sparkles.
4. **Taps on a walker:** a touch on a walking figure is a `sparkle(point)`, never a `creatureTap` (K-17). Input's
   hit order (its R7) already falls through to a sparkle when the point is not on the stage creature; the Reveal
   Stage must not treat a parade figure as a creature.
5. **Visible rect (K-20):** the Reveal Stage contains the 1280×720 safe stage and extends the sky and ground, so
   the visible rect always holds the safe stage: `rect.width ≥ 1280`. iPads and 16:10 tablets fit by width
   (`rect.minX = 0`, `rect.width = 1280`, the extension is vertical); wide Mac windows fit by height
   (`rect.minX < 0`, `rect.width > 1280`: the hills extend sideways and the parade walks farther). F3 reads
   `rect.minX` and `W = rect.width`.
6. **Panel, background and the gate:** the Reveal Stage's R8 signals: `settle` for the panel and the background,
   and `freeze()` / `resume()` for the gate challenge (K-20). The Press Queue follows the same signals (its R8, R9,
   and R8a: the gate freeze on the play clock).
7. **The parade meter** *(TASK-120, K-44)*: the Reveal Stage draws the meter from the Parade's **meter snapshot**
   `{cells: parade_count, filled, litAt[], armed, armedAt, fullAt, drainAt, flight}` (R12, R12a, F4; `drainAt` = the
   Walking-entry time, or none; `fullAt` = when the last cell lit, or none; `flight` = `{cell, from, to, launchAt}`
   or none; TASK-120), with the art bible §7 look, in the
   queue-token layer, and publishes its **meter box** next to the token circles for Hint Letters' clearances (F4
   there). It routes a touch on the meter as an empty-stage `sparkle(point)`.

## Formulas

**F1. Batch and arming.**
```
batch(theme)  = ordered list of distinct keys k with shown(kind: creature) since the last parade start
armed         = |batch(current theme)| ≥ parade_count
```
Example: D, C, D, T, 3, C, A, B → batch D, C, T, 3, A, B (6) → Armed at B. The repeated D and C added nothing.

**F2. Start time** (K-45, TASK-120; no rest):
```
t_start = armedAt + parade_delay_s
```
| Variable | Meaning | Normal set | Reduced set (provisional) |
|---|---|---|---|
| `armedAt` | play time of the `shown(...)` that filled the batch (the 6th creature's formed time), or the re-anchor (R6, R8.3, PA-Q4) | r0 + T = r0 + 2.45 | r0 + 1.2 |
| `parade_delay_s` | the beat after the 6th creature has formed | 1.5 s | 1.5 s |
| `t_start` | the parade's start (Waiting for art) | **r0 + 3.95 s** | **r0 + 2.7 s** |

- **Finished forming:** the fade-in ends at `r0 + T + form_s` (2.95 s; 1.5 s reduced), before `t_start` in both sets.
- **The tune never meets the word:** Audio & Voice F6 caps the 6th word's end at `r0 + T + 1.5` = `armedAt + 1.5`
  = `t_start` (margin ≥ 0, inclusive; a typical word ends earlier).
- **Pressing does not delay it:** a child pressing a new key every 3 s (each reveal queued behind the last) still gets
  the parade at `armedAt + 1.5`. Before K-45 the start was `restingSince + (revealLen − formedS) + parade_delay_s`
  (r0 + 4.45 s, and only after about 4 s with no press).
- A fallback reveal's `armedAt` is its formed time (glyph-only reveals never arm, R1); a timeout-formed reveal (Press
  Queue R5) uses that time.

**F3. The walk.**
```
n          = parade_count (walkers, including any missing ones: indices stay fixed, R8.2)
speed      = (W + 200 + n · gap) / parade_s                   stage units per second
x_i(pt)    = rect.minX − 100 + speed · pt − i · gap           i = 0 is the leader; W = rect.width (Interface 5)
y_i(pt)    = lane_y − bob_i(pt)                               bob from Cast Rendering R8 (×0.5 Reduce Motion)
alpha(pt)  = min(1, pt / fade_s, (parade_s − pt) / fade_s)
```
- The leader starts 100 u left of the visible left edge, and at `pt = parade_s` the last walker (`i = n − 1`) is
  at `rect.minX + W + 250` (`−100 + W + 200 + n·gap − (n − 1)·gap = W + 100 + gap`): off the right edge, for any n.
- A walker is drawn only while `−150 ≤ x − rect.minX ≤ W + 150` (as played).
- Under K-20, `W ≥ 1280` always; the 960 rows below are kept only to show how speed scales with W.

| n | W | speed | across the screen |
|---|---|---|---|
| 6 (K-17) | 1280 | (1280 + 200 + 900) / 11 = **216.4 u/s** | one walker crosses 1280 u in 5.9 s |
| 6 | 960 | (960 + 1100) / 11 = **187.3 u/s** | 5.1 s |
| 8 (the one-shot) | 1280 | 2680 / 11 = 243.6 u/s | 5.3 s |
| 8 | 960 | 2360 / 11 = 214.5 u/s | 4.5 s |

**Physical speed** (n = 6), under K-20's stage fit (Interface 5):

| Device | Fit | W | Speed |
|---|---|---|---|
| 11" iPad (2420×1668 px, 264 ppi; 232.8 × 160.5 mm) | by width | 1280 | 1 u = 0.182 mm → 216.4 u/s → **39 mm/s** |
| 10.1" Android tablet, 16:10 (217.5 × 136 mm) | by width | 1280 | 1 u = 0.170 mm → 216.4 u/s → **37 mm/s** |
| Wide Mac window, 2400 × 900 pt on a 27" 5K display (1 pt = 0.233 mm) | by height | 1920 (720 u = 900 pt, 1 u = 0.291 mm) | (1920 + 1100) / 11 = 274.5 u/s → **80 mm/s** |

About 4 cm a second on a tablet: a slow, easy walk for small eyes to follow. On a wide Mac window the walk covers
more ground in the same 11 s, so it is faster on the glass; that is the cost of K-20's "the parade walks farther"
with a pinned `parade_s`.

**F4. The parade meter** *(TASK-120, K-44)*.
```
filled        = min(|counting batch(current theme)|, parade_count)
                counting batch = the batch (Counting, Armed, Waiting for art); from Walking entry, the next batch (PA-Q4)
cell i        = 0 … parade_count − 1, left to right; lit when i < filled
litAt_i       = launchAt_i + meter_fly_s    (the light lands, R12a); = the shown's time under Reduce Motion, or
                when a light is removed (gate, panel, background), the time it was removed with a_i = 1 at once
a_i(t)        = e + (1 − e) · ease(clamp((t − litAt_i) / meter_step_s, 0, 1))     lit cell
              = e                                                                  unlit cell
ease(u)       = 1 − (1 − u)²                                                       ease-out
drain         : from drainAt (the Walking-entry time) each cell i ≥ filled goes linearly from its alpha to e over fade_s
glow(t)       = ramp(t) · (g0 + g1 · sin(2π · meter_pulse_hz · (t − fullAt)))      Armed or Waiting for art, t ≥ fullAt
              = from drainAt, linearly from its value at drainAt to 0 over fade_s; 0 otherwise
ramp(t)       = clamp((t − fullAt) / meter_step_s, 0, 1)
fullAt        = litAt of the last cell (armedAt + meter_fly_s; armedAt under Reduce Motion or when the cells are
                already lit, as at Ended with a full next batch)

the light (R12a), τ = (t − launchAt) / meter_fly_s in [0, 1]:
P0 = (castBox.midX, castBox.minY)        P2 = (meter_cx − 67.5 + 27·i, 58)        P1 = (P0.x, P2.y)
u(τ)   = (1 − cos(π · τ)) / 2                                                       sine ease-in-out
B(u)   = (1 − u)² · P0 + 2u(1 − u) · P1 + u² · P2
       → x(u) = P0.x + u² · (P2.x − P0.x),   y(u) = P2.y + (1 − u)² · (P0.y − P2.y)
alpha  = 1, fading linearly to 0 over the last meter_land_s
```
| Variable | Meaning | Value |
|---|---|---|
| `e` | an unlit cell's alpha (`meter_empty_alpha`) | 0.25 |
| `meter_step_s` | a cell's fill time, and the glow's ramp | 0.4 s |
| `g0`, `g1` | the full glow's middle alpha and swing (`meter_glow`) | 0.40, 0.05 (g1 = 0 under Reduce Motion) |
| `meter_pulse_hz` | the full glow's breathe | 0.5 Hz |
| `fade_s` | the handover fade (the parade's own) | 0.6 s |
| `meter_fly_s` | the light's flight | 0.9 s |
| `meter_land_s` | the light's fade-out at the end of its flight | 0.15 s |

All on the play clock. While the gate challenge or the panel shows, a fill in progress completes (`a_i = 1`) and the
glow holds at `ramp · g0`; a light in flight is removed when either shows, or at the background (R12a).

**The light's path, checked:** from the widest creature's box top (640, 280) to cell 5 at the default `queue_max`
(1001.5, 58), `x(u) ≥ 860` (where the R2 hint bubble could be, x 860–980 at most) only for `u ≥ 0.78`, where
`y ≤ 58 + 0.048 · 222 = 68.7`; the bubble's top is at y ≥ 130 (R2 at y 190 after jitter, radius 60). So the light
passes above every hint near the meter, and its x stays within 640…1134 (the moon is at x 66).

Examples: D, C, D → `filled` 1 at D's `shown`, 2 at C's; the second D changes nothing. D shown at 9.1 s: its light
lands at 10.0 (`litAt`); the cell has alpha 0.25 at 10.0, 0.25 + 0.75 · 0.75 = 0.81 at 10.2 and 1 at 10.4. The 6th
light lands at `fullAt` 20.0: glow 0.5 · (0.40 + 0.05 · sin(0.2π)) = 0.215 at 20.2 (ramp), 0.40 + 0.05 = 0.45 at 20.5
(a quarter period). The light at τ = 0.5: u = 0.5, x = P0.x + 0.25 · (P2.x − P0.x), y = P2.y + 0.25 · (P0.y − P2.y). Walking entry with the held list [K]: `filled` → 1; cells 1–5
fade to 0.25 over 0.6 s; cell 0 stays at 1.

**Flash bounds (ADR-0013):**
- **Rates (F1, G1):** the only periodic part is the glow at 0.5 Hz, ≤ 1 Hz: no exception needed.
- **The pulse is not a transition:** Starlight at 0.35–0.45 alpha changes relative luminance by **≤ 0.085** in every
  look (≤ 0.067 if the renderer blends in sRGB values), on the track and on the sky (art bible §7 table), below WCAG's 0.1, so F2 counts no transitions from it.
- **Fills are rare:** a cell fills once per formed reveal (reveals form ≥ 1.2 s apart, the reduced `formedS`) and the
  drain happens once per parade: at most 2 transitions per pixel in any 1 s window, below F2's 7, **at any size**.
- **The light (R12a) is a moving bright spot:** it passes each pixel on its path **once** per flight (dark → bright
  → dark: 2 transitions), and at most one flight starts in any 1.2 s, so a pixel on the path sees at most 2
  transitions in any 1 s window from it, below 7, **at any size**. It is not periodic (no F1 rate). Its disc with
  glow (radius 8) is about 200 square units, 700 px on an 11" iPad; the strip it sweeps in one flight (16 units wide,
  a path of about 480 units for the widest creature to cell 5) is about 26,800 px there (floor 58,449). Where it lands, the cell lighting follows the light's own fade, so
  that pixel goes dark → bright once. G4's busy case includes the light (it fires on every new key).
- **Area (the D7 style):** the meter's box with its glow, 176 × 36 units, is 22,156 px on an 11" iPad (1.87 px per
  unit; floor 58,449), 25,344 px in a 1280-pt window on a 2× Mac (2.0; floor 54,105) and 3,564 px in the smallest
  window on a 1× display (0.75; floor 4,347). A larger window on a 1× display exceeds that floor; the transition
  count above still keeps the meter out of F2. G4's busy case includes it; the Title run does not (no meter on the
  Title) (follow-up, ADR-0013 D3).

## Edge Cases

| Case | What happens |
|---|---|
| **The same key pressed 10 times** | Counts once in the batch (R1). With 1 item per key, the child sees the same creature each time and no parade until 6 different keys. |
| **Only digits** (1, 2, 3, 4, 5, 6) | A valid batch: six number groups walk, each as one figure (R9). |
| **A reveal falls back to glyph-only** (art missing) | Does not count (R1). The key can count later when its art is there. |
| **A press while Armed** | The new reveal plays; the parade still starts at `armedAt + 1.5 s`, behind it (R2, K-45). The press's key, if new, is held for the next batch. |
| **The child keeps pressing** (a new reveal every ~3 s) | The parade starts 1.5 s after the 6th creature formed, whatever is pressed (K-45: the fix from Luan's playtest). |
| **A press while Walking** | The reveal plays in front; the parade keeps walking (R5). Its key counts toward the next batch. |
| **A new batch fills during a walk** | Armed at Ended; it starts 1.5 s later (R2.5). The meter shows it full and steady (no glow) during the walk (R12). |
| **Panel opens while Walking** | Fades out, counts as played, not replayed (R6). |
| **Panel opens while Armed or Waiting for art** | The batch is kept; the parade does not start under the panel, and starts 1.5 s after the panel closes (R6). |
| **Background while Walking** | Dropped, counts as played (R6). Background time never counts toward the delay. |
| **Theme switched while Armed** | That theme stays Armed for when it comes back; the new theme counts its own batch (R1). |
| **Theme switched during a walk** | Not possible: a theme is switched in the panel, and the panel ends the walk first (R6). |
| **Art missing for 1–3 walkers** | Walk without them after ≤ 0.5 s; gaps stay (R8). |
| **Art missing for 4 or more walkers** | Skipped, stays Armed (the meter stays full), retried 1.5 s after the next formed reveal (R8.3). If the art never loads, the parade never plays for that batch; one debug line per try. |
| **A walker is the current creature** | Both copies are drawn: the stage tier in front, the parade tier behind (R8.4). |
| **Reduce Motion toggled mid-walk** | The bob halves (or doubles back) from the next frame; the walk's path and length do not change (R7). |
| **Debug start while Walking** | Ignored (R11). |
| **Debug start with an empty batch** | The first 6 keys in canonical order walk (R11). |
| **A very wide or narrow screen** | Only `speed` changes with W (F3); the walk still lasts `parade_s` and every walker leaves the screen. |
| **Art keeps failing while the child keeps pressing** | One try per formed reveal; no retry loop between reveals (R8.3). |
| **Meter: a repeat key, a glyph-only reveal, an ignored press** | No cell lights (R1, R12). |
| **Meter: a 7th distinct key while Armed** | The meter stays full; the key is held and sends no light; its cell is lit from Walking entry (F4 drain keeps it). |
| **Light: the panel or gate opens, or the app goes to the background, mid-flight** | The light is removed and its cell lit at once (R12a). |
| **Light: Reduce Motion turned on mid-flight** | The light is removed and its cell lights from that frame (R12a; next frame). |
| **Light: lands on a draining cell** (a key shown just after Walking entry) | The lighting wins for that cell (R12a). |
| **Light: keyboard row on** | It starts from the raised creature's cast box (`row_lift`); the path rule is the same. |
| **Meter: theme switched in the panel** | On close the meter shows the new theme's count at once, with no fill animation; switching back shows the old count (R12). |
| **Meter: launch** | Empty: nothing is saved. |
| **Meter: background and return** | Nothing is drawn in the background; on return it shows the same state, with no replayed fill. |
| **Meter: Reduce Motion toggled while full** | The glow stops breathing (or resumes) from the next frame; the fills still fade (R12). |
| **Meter: a touch on it** | An empty-stage sparkle; it is not a target (R12). |
| **Meter: keyboard row on, portrait or a wide window** | It stays at the safe stage's top right (art bible §7): `row_lift` does not move it; portrait (K-39) adds sky above it; a wide Mac window adds hills to its right. |

## Dependencies

**Upstream (Parade reads):**
- **Reveal Stage** (`design/gdd/reveal-stage.md`): `shown(...)`, the lane y, draw order, tap routing, the visible rect (K-20),
  `freeze` / `resume` (Interface).
- **Cast Rendering** (`design/gdd/cast-rendering.md`, TASK-044): the `parade` role, the 256 px tier, the step bob
  (R8), `isResident` / `prefetch` / `release`. Its F6 and R10 now count `parade_count` figures (merged in
  e2d665e).
- **Press Queue** (`design/gdd/press-queue.md`): no longer read since K-45 (TASK-120). Follow-up: its R10's
  `restingSince` example for the Parade is superseded by F2 here, and the Parade can be dropped from its readers.
- **Key Table & Theme Data:** the current theme id.
- **Accessibility:** the Reduce Motion flag.

**Downstream (depend on Parade):**
- **Reveal Stage:** draws the parade meter from the meter snapshot and publishes its box (Interface 7; TASK-120).
- **Hint Letters:** keeps its hints clear of the meter box (its F4; TASK-120).
- **Audio & Voice:** E12, the parade tune at walk start (its R1), paused and resumed on the gate freeze (its R6).
- **Scene: Time of Day & Weather (#15):** reads `paradeWalking` and draws the warm horizon lift while Walking (its R7).
- **Hint Letters:** reads `paradeWalking`; during the walk the hints fade to a lower opacity and hold still, with no
  new spawns, and stay tappable (K-26).
- **Accessibility:** relies on R7.
- **Mash World** (Full Vision): may reuse the batch later.

**Normative:** game brief (Keep: parade_s 11, parade_delay_s 1.5); K-06, K-11, K-15, K-16, **K-17**; art bible §2
(K-16 amendment: step bob exception), §5 (the parade walk), §7 (calmer parade under Reduce Motion).

## Tuning Knobs

All bundled data. Pinned values come from the game brief or K-17.

| Knob | Value | Safe range | Source | Effect |
|---|---|---|---|---|
| `parade_count` | 6 | 3–10 | K-17 (was 8 in the brief) | more creatures between parades, longer line |
| `parade_s` | 11 | 6–20 | game brief (pinned) | the walk's length; also the speed (F3) |
| `parade_delay_s` | 1.5 | 1.5–3 | game brief (pinned); K-45 measures it from the 6th creature's formed time, with no rest | the beat between the 6th creature and the parade; below 1.5 the tune can start under that creature's word (Audio & Voice F6 cap) |
| `meter_step_s` | 0.4 | 0.2–1.0 | TASK-120 | a cell's fill time and the glow's ramp |
| `meter_empty_alpha` | 0.25 | 0.15–0.4 | TASK-120 | how visible unlit cells are |
| `meter_glow` | g0 0.40, g1 0.05 | g1 ≤ 0.05 | TASK-120 | the full glow; above 0.05 the swing nears ΔL 0.1 (F4) |
| `meter_pulse_hz` | 0.5 | 0.2–1.0 | TASK-120 | the full glow's breathe; ≤ 1 Hz (Accessibility F1) |
| `meter_fly_s` | 0.9 | 0.6–1.1 | TASK-120, K-46 | the light's flight; slower is calmer, but `meter_fly_s + meter_step_s ≤ parade_delay_s` so the 6th cell is full before the parade |
| `meter_land_s` | 0.15 | 0.1–0.3 | TASK-120 | the light's fade into its cell |
| `gap` | 150 u | 110–220 | one-shot | spacing; a parade figure is ~85 u tall and narrower than 110 u |
| `fade_s` | 0.6 | 0.2–1.5 | one-shot | fade in and out |
| `art_wait_s` | 0.5 | 0–1.0 | K-17 | how long the start waits for art |
| `skip_fraction` | 0.5 | 0.3–1.0 | rescaled for 6 (K-17) | the share of walkers that must be ready |

The step bob (5 u, ~2.2 Hz, ×0.5 Reduce Motion) is Cast Rendering's knob. **Interactions:** raising `parade_count`
with a fixed `gap` makes the line longer and the walk faster (F3); raise `parade_s` with it to keep the pace.

## Visual/Audio Requirements

- The only energy-4 moment of the toy (art bible §2): sideways motion plus a warm horizon lift (peach in morning
  and day, amber at dusk and night), drawn by **Scene: Time of Day & Weather** while the Parade signals
  `paradeWalking` (Walking state).
- Figures at parade size keep their outline trait, eye and body colour; spots, stripes and blush are dropped (art
  bible §5, Cast Rendering role `parade`).
- No gold on the walkers (art bible §4).
- The tune: Audio & Voice E12, a light 12-note tune (the one-shot's `paradeTune`).
- **The parade meter** (R12): its size, box, shape and colours per look are the art bible's §7 "Parade meter".
  Starlight, never gold (§4). No sound of its own (K-46). **The meter light** (R12a): a 16-unit Starlight star, art
  bible §7.

## UI Requirements

- **The parade meter** (R12, R12a, F4; art bible §7): the child's one HUD element, drawn by the Reveal Stage in Play
  only (not on the Title, K-46), with its light. No text, no number, not a target.
- Debug builds expose `startParade(manual)` (R11), for example in the debug menu.

## Cross-References

- `design/game-brief.md`: Challenge, Goal, Keep.
- `design/gdd/systems-index.md`: system #11.
- `design/gdd/press-queue.md`: R6, R8–R10.
- `design/gdd/cast-rendering.md` (TASK-044): R1 roles, R8 step bob, R9 `willForm`, R10 residency, F6.
- `design/gdd/audio-voice.md`: E12, F2, F6.
- `design/gdd/key-table-theme-data.md`: numbers, the 0 item.
- `production/team/decisions.md`: K-15, K-16, K-17.
- `prototypes/letter-morph-dinosaur/index.html`: `startParade`, `drawParade`; `config.js`: `parade_delay_s`,
  `parade_s`.

## Acceptance Criteria

Logic criteria use an injected clock and fake Reveal Stage, Press Queue and Cast Rendering.

1. **AC-1 Distinct keys.** `shown(creature)` for D, C, D, T, 3, C, A, B gives the batch D, C, T, 3, A, B and Armed
   after B; the repeats add nothing.
2. **AC-2 Glyph-only.** `shown(glyphOnly)` for E adds nothing to the batch.
3. **AC-3 Start time (K-45).** The 6th distinct key's reveal starts at r0 = 0 on the normal set (formed at 2.45):
   Armed at 2.45, Waiting for art at t = 3.95 s, not earlier. With the reduced set (formed at 1.2): at 2.7 s.
4. **AC-4 A press while Armed (K-45).** A press at t = 3.0 s (before 3.95) starts a reveal; the parade still enters
   Waiting for art at 3.95 s, and that reveal keeps playing in front.
5. **AC-5 Order.** The walkers are the batch in the order met, leader first, each with the castId stored from its
   `shown(...)`; a theme switch and back (which resets Key Table's `lastShown`) does not change them.
6. **AC-6 Walk positions.** With n 6, W 1280, gap 150, parade_s 11: speed 216.4 u/s ±0.1; x_0(0) = −100;
   x_5(11) = 1530 (W + 250); alpha(0) = 0, alpha(0.6) = 1, alpha(11) = 0. With a wide-Mac rect (minX −320, W 1920):
   speed 274.5 u/s ±0.1, x_0(0) = −420, x_5(11) = 1850 (minX + W + 250).
7. **AC-7 Own clock.** After the walk starts, a press and a new reveal change no walker's x; the walk still ends at
   `pt = 11`.
8. **AC-8 Next batch.** Keys shown during the walk form the next batch; if it reaches 6 during the walk, the Parade
   is Armed at Ended and the next parade starts 1.5 s after Ended (R2.5).
9. **AC-9 Panel.** Panel open at `pt = 5`: alpha reaches 0 within 0.6 s, the state is Ended, and closing the panel
   does not replay it.
10. **AC-10 Background.** Background at `pt = 5`: nothing drawn, Ended on return, no replay.
11. **AC-11 Per theme.** Three keys in Dinosaurs, switch to a test theme, three keys there: neither theme is Armed;
    back in Dinosaurs, three more keys arm it with only Dinosaurs keys.
12. **AC-12 Art not ready.** With 2 of 6 walkers not resident and never arriving: the walk starts at the wait's end
    (0.5 s) with 4 walkers at their own indices. With 4 of 6 missing: skipped, still Armed, one debug line; the next
    try enters Waiting for art 1.5 s after the next formed reveal, and not before it.
13. **AC-13 Reduce Motion.** With the flag on, the walk path and `parade_s` are unchanged and the bob amplitude passed
    to Cast Rendering is halved.
14. **AC-14 Tap on a walker.** A touch on a walking figure produces a sparkle and no creature tap, hop or sound.
15. **AC-15 Debug start.** In a debug build, `startParade(manual)` with a batch of 2 walks 6 (the 2, then the first
    keys in canonical order not in it); while Walking it is ignored. A release build has no such entry point.
16. **AC-16 Tune.** E12 is requested exactly once per walk, at `pt = 0`; a skipped parade requests none.
17. **AC-17 No cap.** Over a scripted session of 40 distinct-key batches (repeating keys across batches), 40 parades
    play.
18. **AC-18 Looks right (device, screenshot).** A retained screenshot in `production/qa/evidence/` of a walk at
    `pt ≈ 5` on the iPad shows the 6 small figures on the hill band behind the stage creature, facing right, with no
    gold on them.
19. **AC-19 Gate freeze (K-20).** Walking at `pt = 4`, `freeze()` for 20 s then `resume()`: every walker's x is
    unchanged across the freeze, E12 was asked to pause and resume, and the walk ends at `pt = 11` (31 s after its
    start). Armed with 0.5 s of the 1.5 s beat left, a 20 s freeze followed by `resume()` starts the parade 0.5 s
    after the resume, not at once. A correct answer during the freeze fades the parade out (R6).
20. **AC-20 No rest needed (K-45).** A scripted child presses a new distinct key every 3.0 s for 30 s, so the queue
    is never empty: the first parade enters Waiting for art exactly 1.5 s after the 6th creature's `shown`, and a
    parade plays for every 6 distinct keys.
21. **AC-21 Panel while Armed (K-45).** Armed at 10.0; the panel opens at 10.8 and closes at 30.0: no parade starts
    under the panel, and Waiting for art is entered at 31.5. Background at 10.8, return at 50.0: entered at 51.5.
22. **AC-22 Meter fill.** `shown(creature)` for D at 9.1, C, D: `filled` is 1 at D's `shown` and 2 at C's, unchanged
    by the second D; cell 0's `litAt` is 10.0 (the light lands), its alpha 0.25 up to 10.0, 0.81 at 10.2 and 1 at
    10.4. `shown(glyphOnly)` for E and an ignored press change nothing and send no light.
23. **AC-23 Meter full.** At the 6th distinct key's `shown` at 19.1: `filled` 6, the snapshot is `armed` with
    `armedAt` 19.1 and `fullAt` 20.0; glow 0 before 20.0, 0.215 at 20.2 and 0.45 at 20.5; the glow is 0 while not
    Armed or Waiting for art; Waiting for art at 20.6 (`armedAt + 1.5`).
24. **AC-24 Handover.** Walking entry with the held list [K]: `filled` 1; cells 1–5 reach 0.25 at +0.6 s; cell 0 stays
    1; the glow reaches 0 at +0.6 s. Keys shown during the walk light the next cells.
25. **AC-25 Meter under the gate and panel.** Armed with a fill in progress: while the challenge or the panel shows,
    that cell's alpha is 1 and the glow holds at 0.40; nothing changes on close except by R1 and R2.
26. **AC-26 Meter per theme and launch.** Three keys in Dinosaurs, switch to a test theme in the panel: on close
    `filled` 0, with no fill animation; back to Dinosaurs: 3. A fresh launch: 0.
27. **AC-27 Meter Reduce Motion.** With the flag on, the glow is 0.40 at every time while Armed (g1 = 0), and the
    fills still take 0.4 s.
28. **AC-28 Meter taps.** A touch on the meter produces an empty-stage sparkle, no press and no change to the meter.
29. **AC-29 Meter flash data.** G1 reads `meter_pulse_hz` 0.5 and passes with no exception; the build's palette check
    (G2) includes the meter's colours.
30. **AC-30 Meter looks (device, screenshots).** Retained screenshots in `production/qa/evidence/` on the iPad of the
    meter empty, at 3 of 6 and full, in Day and Night: no text, no gold, inside the safe stage at the top right,
    clear of the queue tokens with 3 tokens showing; and one of a light mid-flight, a small Starlight star above the
    hints.
31. **AC-31 The light's path.** D shown at 0 with the cast box top centre (640, 300) and cell 0 at (866.5, 58): the
    light is at (640, 300) at 0, at (696.6, 118.5) at 0.45 s (u 0.5) and at (866.5, 58) at 0.9 s, with alpha 1 until
    0.75 and 0 at 0.9; `flight` is none after 0.9.
32. **AC-32 Light and Reduce Motion.** With the flag on, no `flight` is ever set and `litAt` equals the `shown`'s
    time; turning it on mid-flight removes the light and lights the cell from that frame.
33. **AC-33 Light interrupted.** A light in flight when the gate challenge shows, the panel opens or the app goes to
    the background is removed, and its cell's alpha is 1 at once; nothing flies on close or return.
34. **AC-34 One light at a time.** Over a scripted 60 s session of mashing, at most one `flight` exists at any tick,
    and a held key (a 7th distinct key while Armed) sets none.
35. **AC-35 Light during a walk.** A key shown at `pt = 2` sends its light to its cell in the next batch (index 0 if
    no keys were held) and lights it at `pt = 2.9`, drawn above the walkers.

## Open Questions

**Resolved (Luan, K-46, 2026-11-18), now in the rules:** MT-Q1 the meter shows from Play entry (R12); MT-Q2 no sound
(R12); **MT-Q3 yes, a light flies from each new creature to its cell** (R12a; Luan chose it over the recommendation
below); MT-Q4 beside the tokens, placed from `queue_max` (R12; art bible §7); MT-Q5 the 1.5 s beat stays: K-45
removed the rest, not the beat (R2). The questions as they were asked:

| # | Question | Recommendation (TASK-120) |
|---|---|---|
| MT-Q1 | Show the meter from Play entry (empty at first), or hide it until the first creature joins the batch? | **From Play entry**, empty: an empty bar says "something fills here" before the first creature, which is the gap Luan's playtest found. Not on the Title either way. |
| MT-Q2 | A sound when the meter fills? | **No.** The parade tune E12 starts 1.5 s later and is the full moment's sound; an extra sting would be a reward sound (anti-pillars). |
| MT-Q3 | A small light that flies from the new creature to its cell? | **No, not for the MVP:** it crosses the stage over the glyph and creature on every new key. The cell lighting as the creature forms carries the link. |
| MT-Q4 | The very corner for the meter, moving the queue tokens left of it, instead of the meter left of the tokens? | **Keep the tokens where they are** (meter at x 846–1022 at the default `queue_max` 3, art bible §7): no change to the Reveal Stage's token row or Hint Letters' token clearances; both are still the top right. |
| MT-Q5 | K-45's beat: 1.5 s after the 6th creature has formed, or the parade at its fade-in end (0.5 s)? | **1.5 s** (`parade_delay_s`, the brief's pinned value): the child hears the creature's name first, and the tune never starts under it (F2). 0.5 s would duck the tune under the name. |

Follow-ups for other GDDs (not blocking this one):
- **Reveal Stage:** restate the Interface section (shown, lane y, draw order, walker taps, visible rect,
  freeze/resume).
- *Closed:* Audio & Voice pauses and resumes E12 on the gate freeze (its R6, TASK-050).
- *Closed:* the Scene's horizon lift on `paradeWalking` (Scene R7).
- *Closed:* the stage fit is K-20 (Interface 5); Cast Rendering's `parade_count` fix is merged (e2d665e).
- **Press Queue:** R10's example start rule is superseded by F2 here; since K-45 the Parade reads nothing from it.
- **Reveal Stage:** draw the meter from the snapshot in the token layer and publish its box (Interface 7; TASK-120
  adds the lines there).
- **App Shell & Title:** the meter is Play only (K-46); the Title shows none.
- **Accessibility:** the meter in A4's pulse table (the glow at 0.5 Hz; the light is one-shot motion, not a pulse), A6
  (the count is cells, not colour), A7 (not a target) and A3 (Reduce Motion: no light).
- **ADR-0006 D1:** the meter's `zPosition` (with the queue tokens, z 70) and its light, above the meter in that layer. **ADR-0013:** G4's busy case covers it (the Title
  run has no meter).
- **parade-v1:** 21 of its 30 cases drive the start through `restingSince` and change under K-45; the 9 walk, count
  and per-theme cases (AC1, AC2, AC6 ×6, AC11) do not. A parade-v2 with K-45's start and the meter's cases (AC-20 to
  AC-35, with the light).

**Resolved (Luan, K-17, 2026-11-18):** P1 letters and digits count, digits walk as their group; P2 every 6 distinct
keys per batch, no cap; P3 a press lets the parade keep walking behind; P4 panel or background fade it out, counted,
not replayed; P5 per theme; P6 Reduce Motion halves the bob only; P7 wait ≤ 0.5 s then walk without missing
figures (skip rule rescaled here); P8 debug start only; P9 a tap on a walker only sparkles. Leader defaults: the
unit is the key; a glyph-only fallback does not count.
