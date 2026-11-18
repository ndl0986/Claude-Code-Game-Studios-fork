# Parade

> **Status**: In Review
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
> reads Press Queue's `restingSince`, Key Table's `lastShown`; plays Audio & Voice E12)

## Overview

The child presses D, then C, then T, then 3… Each new creature is added to a **batch**. When the batch holds 6
different keys and the stage has settled, the 6 walk across the hill band from left to right in the order they
were met, bobbing as they step, while a short tune plays. A press during the walk is answered as usual, in front
of the parade, which keeps walking. Then a new batch starts. Nothing is saved: the next launch starts from zero.

This GDD owns:
- **batches** (R1): what counts as meeting a creature, and per theme;
- **arming and start** (R2), **who walks** (R3), **the walk** (R4, F3);
- what **a press** (R5), **the panel or background** (R6), **Reduce Motion** (R7) and **art not ready** (R8) do;
- digits and repeats (R9), sound (R10) and the debug start (R11).

It does **not** own: drawing a figure, its step bob or its tiers (Cast Rendering R8, R10); the stage layout,
draw order and taps (Reveal Stage, asked for below); the queue and `restingSince` (Press Queue R10); the tune
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
- Each walker's cast member is **the item last shown for that key** in that theme (Key Table `lastShown`). With
  one item per key (MVP) it is always the same; with production variety it is the one the child last saw.

**R2. Arming and start.**
1. When the current theme's batch holds `parade_count` keys (6, K-17), the Parade is **Armed**.
2. While Armed, the parade starts at the first moment when:
   ```
   restingSince ≠ none   AND   now ≥ restingSince + (revealLen − formedS) + parade_delay_s
   ```
   `restingSince` is the Press Queue's resting signal (its R10: the queue is empty and the current reveal is
   formed, at `formedAt`). `revealLen` and `formedS` are the **current** reveal's (Press Queue R6). So the parade
   starts `parade_delay_s` (1.5 s) after the creature's fade-in has finished, **as played** in the one-shot (F2).
3. While Armed, nothing else is checked: a press that starts a new reveal clears `restingSince`, and the check
   waits for the next rest.
4. **Once Walking, the parade runs on its own state and clock** (`pt`, seconds since the walk started) and no longer
   reads `restingSince`. Presses do not stop it (R5).
5. **The batch empties at parade start.** Creatures shown during the walk count toward the next batch. The
   Parade can be Armed again only from **Ended**: if a new batch fills during a walk, that parade starts at the
   first rest after this one ends.

**R3. Who walks.** The batch's `parade_count` keys, **in the order they were met**: the first met leads. They walk
**left to right**, facing right (art bible §5: every cast member faces right). Each is drawn as its item's cast
member in Cast Rendering's `parade` role (R1 there: `body` and `outline` only, ~85 stage units tall).

**R4. The walk.** All positions are in **stage units** (the 1280×720 design space; the one-shot's pixels are stage
units).
- **Lane:** the hill band behind the stage creature (the one-shot's ground line at y 478). The exact y is the
  Reveal Stage's (Interface).
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
- While **Armed** or **Waiting for art**, the panel or background do not cancel the batch: the queue is cleared and
  the reveal settles (Press Queue R8, R9), which gives a rest, and the parade starts after the panel closes or
  the app returns, by R2.2. *Time in the background does not count toward the delay* (Press Queue R9: background
  time never counts).

**R7. Reduce Motion (decided, K-17).** The same `parade_s` walk; Cast Rendering halves the step bob (its R8). No
other change: same path, same fades. The reduced timing set changes the reveals (and so F2's start time), not the
walk.

**R8. Art not ready (decided, K-17).**
1. At start, the Parade asks Cast Rendering whether each walker's art is resident at the `parade` role
   (`isResident`), and prefetches any that are not (`prefetch`).
2. It waits up to `art_wait_s` (0.5 s) in **Waiting for art**, then walks **without any figure still missing**.
   The others keep their own index `i`, so the gaps stay where the missing walker would have been.
3. **Skip rule (rescaled for a batch of 6):** if fewer than `ceil(parade_count × skip_fraction)` walkers are ready
   (fewer than **3 of 6**), the parade is **skipped**: it does not count as played, the batch is kept, the Parade
   stays **Armed**, and it tries again at the next rest. One debug log line either way.
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

### States and Transitions

| State | Entered when | Does | Left when |
|---|---|---|---|
| **Counting** | launch; after Ended | adds keys from `shown(kind: creature)` to the current theme's batch | the batch reaches `parade_count` → Armed |
| **Armed** | batch full | checks R2.2 each tick; new distinct keys go to the **next** batch, in order (this one is full) | R2.2 holds → Waiting for art |
| **Waiting for art** | the start condition held | prefetches; waits ≤ `art_wait_s` | ready, or the wait ran out → Walking (≥ 3 ready), or back to Armed (skip, R8.3); panel/background → Armed |
| **Walking** | art ready | owns `pt`; draws the walkers; plays E12 at `pt = 0`; empties the batch | `pt ≥ parade_s`, panel (fade) or background (drop) → Ended |
| **Ended** | the walk ended | releases parade figures | at once → Counting (or Armed if the next batch is already full) |

While Armed, extra distinct keys shown before the parade starts are **held for the next batch**, in order (the
batch never grows past `parade_count`). A theme switch while Armed leaves that theme Armed; the new theme's own
batch is used from then on.

### Interactions with Other Systems

| System | Direction | What passes |
|---|---|---|
| Reveal Stage | in | `shown(revealId, key, castId, kind)`; the lane y; draw order; tap routing on walkers; panel and background signals |
| Press Queue | in | `restingSince` (R10); the current reveal's `formedS` and `revealLen` (R6) |
| Cast Rendering | out / in | `drawCast(item, parade, x, y, i, pt)` per walker; `isResident`, `prefetch`, `release`; the step bob (its R8) |
| Key Table & Theme Data | in | `lastShown[key]` per theme → the walker's item; the current theme id |
| Audio & Voice | out | parade start / end → E12 |
| Accessibility | in | the Reduce Motion flag (passed on to Cast Rendering's step bob) |
| Parent Gate & Grown-up Panel | in | panel open → fade out (R6) |
| App Shell & Title | in | background → drop (R6); the visible stage width W (stage fit, Interface) |

### Interface needed from the Reveal Stage (for its author to restate)

1. **`shown(revealId, key, castId, kind)`**, sent **once per reveal at formed time**, with `kind` = `creature` (the
   morph or the creature fade-in) or `glyphOnly` (the sparkle-out fallback). Built from Cast Rendering's
   `willForm(item)` (its R9), which the Reveal Stage already asks at `startReveal`. This is **separate** from the
   Press Queue's `formed(revealId)`, which stays as it is.
2. **The parade lane:** the y of the hill band in stage units, behind the stage creature.
3. **Draw order:** backdrop → **parade** → the leaving creature → the current reveal and creature → hints, tokens,
   sparkles.
4. **Taps on a walker:** a touch on a walking figure is a `sparkle(point)`, never a `creatureTap` (K-17). Input's
   hit order (its R7) already falls through to a sparkle when the point is not on the stage creature; the Reveal
   Stage must not treat a parade figure as a creature.
5. **Stage fit:** the visible stage width W (stage units) on the current screen. It depends on the stage-fit rule
   (letterbox, crop or extended sky), which App Shell or the Reveal Stage owns. F3 takes W as an input.
6. **Panel and background:** the same signals the Press Queue gets (its R8, R9).

## Formulas

**F1. Batch and arming.**
```
batch(theme)  = ordered list of distinct keys k with shown(kind: creature) since the last parade start
armed         = |batch(current theme)| ≥ parade_count
```
Example: D, C, D, T, 3, C, A, B → batch D, C, T, 3, A, B (6) → Armed at B. The repeated D and C added nothing.

**F2. Start time** (as played):
```
t_start ≥ restingSince + (revealLen − formedS) + parade_delay_s
```
| Variable | Meaning | Normal set | Reduced set (provisional) |
|---|---|---|---|
| `formedS` | the current reveal's formed time (Press Queue R6) | T = 2.45 s | T = 1.2 s |
| `revealLen` | the current reveal's length | T + form_s = 2.95 s | 1.2 + 0.3 = 1.5 s |
| `restingSince` | `formedAt` of the current reveal (Press Queue R10) | r0 + 2.45 | r0 + 1.2 |
| `parade_delay_s` | the pause after the creature has formed | 1.5 s | 1.5 s |
| `t_start` | earliest parade start | **r0 + 4.45 s** | **r0 + 3.0 s** |

For a fallback reveal `revealLen = formedS`, so the parade starts `parade_delay_s` after its end. **The tune never
meets the word:** Audio & Voice F6 caps the word's end at `T + 1.5`; the parade starts at `T + form_s + 1.5`, so
the margin is `form_s` (0.5 s normal, 0.3 s reduced). If the timeout marked the reveal formed (Press Queue R5),
`formedAt` is that time and the same rule holds.

**F3. The walk.**
```
n          = parade_count (walkers, including any missing ones: indices stay fixed, R8.2)
speed      = (W + 200 + n · gap) / parade_s                   stage units per second
x_i(pt)    = −100 + speed · pt − i · gap                      i = 0 is the leader
y_i(pt)    = lane_y − bob_i(pt)                               bob from Cast Rendering R8 (×0.5 Reduce Motion)
alpha(pt)  = min(1, pt / fade_s, (parade_s − pt) / fade_s)
```
- The leader starts at x = −100 (off the left edge), and at `pt = parade_s` the last walker (`i = n − 1`) is at
  `−100 + W + 200 + n·gap − (n − 1)·gap = W + 100 + gap = W + 250`: off the right edge, for any n.
- A walker is drawn only while `−150 ≤ x ≤ W + 150` (as played).

| n | W | speed | across the screen |
|---|---|---|---|
| 6 (K-17) | 1280 | (1280 + 200 + 900) / 11 = **216.4 u/s** | one walker crosses 1280 u in 5.9 s |
| 6 | 960 | (960 + 1100) / 11 = **187.3 u/s** | 5.1 s |
| 8 (the one-shot) | 1280 | 2680 / 11 = 243.6 u/s | 5.3 s |
| 8 | 960 | 2360 / 11 = 214.5 u/s | 4.5 s |

**Physical speed** (n = 6), which depends on the stage-fit rule (Interface 5):

| Device | Screen | Fit by width (W 1280) | Fit by height (W visible) |
|---|---|---|---|
| 11" iPad (2420×1668 px, 264 ppi) | 232.8 × 160.5 mm | 1 u = 0.182 mm → **39 mm/s** | 1 u = 0.223 mm, W ≈ 1044 → 194.9 u/s → **43 mm/s** |
| 10.1" Android tablet, 16:10 | 217.5 × 136 mm | 1 u = 0.170 mm → **37 mm/s** | 1 u = 0.189 mm, W ≈ 1152 → 204.7 u/s → **39 mm/s** |

About 4 cm a second: a slow, easy walk for small eyes to follow.

## Edge Cases

| Case | What happens |
|---|---|
| **The same key pressed 10 times** | Counts once in the batch (R1). With 1 item per key, the child sees the same creature each time and no parade until 6 different keys. |
| **Only digits** (1, 2, 3, 4, 5, 6) | A valid batch: six number groups walk, each as one figure (R9). |
| **A reveal falls back to glyph-only** (art missing) | Does not count (R1). The key can count later when its art is there. |
| **A press while Armed** | The new reveal clears `restingSince`; the parade waits for the next rest (R2.3). The press's key, if new, is held for the next batch. |
| **A press while Walking** | The reveal plays in front; the parade keeps walking (R5). Its key counts toward the next batch. |
| **A new batch fills during a walk** | Armed again only after Ended; it starts at the first rest after that (R2.5). |
| **Panel opens while Walking** | Fades out, counts as played, not replayed (R6). |
| **Panel opens while Armed or Waiting for art** | The batch is kept; the parade starts at the first rest after the panel closes (R6). |
| **Background while Walking** | Dropped, counts as played (R6). Background time never counts toward the delay. |
| **Theme switched while Armed** | That theme stays Armed for when it comes back; the new theme counts its own batch (R1). |
| **Theme switched during a walk** | Not possible: a theme is switched in the panel, and the panel ends the walk first (R6). |
| **Art missing for 1–3 walkers** | Walk without them after ≤ 0.5 s; gaps stay (R8). |
| **Art missing for 4 or more walkers** | Skipped, stays Armed, retried at the next rest (R8.3). If the art never loads, the parade never plays for that batch; one debug line per try. |
| **A walker is the current creature** | Both copies are drawn: the stage tier in front, the parade tier behind (R8.4). |
| **Reduce Motion toggled mid-walk** | The bob halves (or doubles back) from the next frame; the walk's path and length do not change (R7). |
| **Debug start while Walking** | Ignored (R11). |
| **Debug start with an empty batch** | The first 6 keys in canonical order walk (R11). |
| **A very wide or narrow screen** | Only `speed` changes with W (F3); the walk still lasts `parade_s` and every walker leaves the screen. |
| **Two rests in a row while Armed and art keeps failing** | One try per rest; no retry loop inside a rest. |

## Dependencies

**Upstream (Parade reads):**
- **Reveal Stage** (no GDD yet): `shown(...)`, the lane, draw order, tap routing, the stage width (Interface).
- **Cast Rendering** (`design/gdd/cast-rendering.md`, TASK-044): the `parade` role, the 256 px tier, the step bob
  (R8), `isResident` / `prefetch` / `release`. **Follow-up for that GDD:** its F6 residency says "8 × parade set";
  with K-17 it becomes `parade_count` (6). The leader has sent this to game-dev-ios.
- **Press Queue** (`design/gdd/press-queue.md`): `restingSince` (R10), the current reveal's `formedS` and
  `revealLen` (R6). Follow-up: its R10 example "`now ≥ restingSince + parade_delay_s`" is replaced by F2 here.
- **Key Table & Theme Data:** `lastShown[key]` per theme, the current theme id.
- **Accessibility:** the Reduce Motion flag.

**Downstream (depend on Parade):**
- **Audio & Voice:** E12, the parade tune at walk start (its R1).
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
| `parade_delay_s` | 1.5 | 0.5–5 | game brief (pinned) | pause after the last creature has formed; below 0.5 it would start under the creature's fade-in margin |
| `gap` | 150 u | 110–220 | one-shot | spacing; a parade figure is ~85 u tall and narrower than 110 u |
| `fade_s` | 0.6 | 0.2–1.5 | one-shot | fade in and out |
| `art_wait_s` | 0.5 | 0–1.0 | K-17 | how long the start waits for art |
| `skip_fraction` | 0.5 | 0.3–1.0 | rescaled for 6 (K-17) | the share of walkers that must be ready |

The step bob (5 u, ~2.2 Hz, ×0.5 Reduce Motion) is Cast Rendering's knob. **Interactions:** raising `parade_count`
with a fixed `gap` makes the line longer and the walk faster (F3); raise `parade_s` with it to keep the pace.

## Visual/Audio Requirements

- The only energy-4 moment of the toy (art bible §2): sideways motion plus a warm horizon lift (peach in morning
  and day, amber at dusk and night), drawn by the Scene / Reveal Stage while Walking.
- Figures at parade size keep their outline trait, eye and body colour; spots, stripes and blush are dropped (art
  bible §5, Cast Rendering role `parade`).
- No gold on the walkers (art bible §4).
- The tune: Audio & Voice E12, a light 12-note tune (the one-shot's `paradeTune`).

## UI Requirements

None in release. Debug builds expose `startParade(manual)` (R11), for example in the debug menu.

## Cross-References

- `design/game-brief.md`: Challenge, Goal, Keep.
- `design/gdd/systems-index.md`: system #11.
- `design/gdd/press-queue.md`: R6, R8–R10.
- `design/gdd/cast-rendering.md` (TASK-044): R1 roles, R8 step bob, R9 `willForm`, R10 residency, F6.
- `design/gdd/audio-voice.md`: E12, F2, F6.
- `design/gdd/key-table-theme-data.md`: `lastShown`, numbers, the 0 item.
- `production/team/decisions.md`: K-15, K-16, K-17.
- `prototypes/letter-morph-dinosaur/index.html`: `startParade`, `drawParade`; `config.js`: `parade_delay_s`,
  `parade_s`.

## Acceptance Criteria

Logic criteria use an injected clock and fake Reveal Stage, Press Queue and Cast Rendering.

1. **AC-1 Distinct keys.** `shown(creature)` for D, C, D, T, 3, C, A, B gives the batch D, C, T, 3, A, B and Armed
   after B; the repeats add nothing.
2. **AC-2 Glyph-only.** `shown(glyphOnly)` for E adds nothing to the batch.
3. **AC-3 Start time.** Armed, with the last reveal at r0 = 0 on the normal set (formedS 2.45, revealLen 2.95) and an
   empty queue: Waiting for art is entered at t = 4.45 s, not earlier. With the reduced set (1.2, 1.5): at 3.0 s.
4. **AC-4 A press while Armed.** A press at t = 4.0 s (before 4.45) starts a reveal; no parade starts until the
   next rest plus F2.
5. **AC-5 Order.** The walkers are the batch in the order met, leader first; their items are each key's
   `lastShown`.
6. **AC-6 Walk positions.** With n 6, W 1280, gap 150, parade_s 11: speed 216.4 u/s ±0.1; x_0(0) = −100;
   x_5(11) = 1530 (W + 250); alpha(0) = 0, alpha(0.6) = 1, alpha(11) = 0.
7. **AC-7 Own clock.** After the walk starts, setting `restingSince` to none (a press) changes no walker's x; the
   walk still ends at `pt = 11`.
8. **AC-8 Next batch.** Keys shown during the walk form the next batch; if it reaches 6 during the walk, the next
   parade starts only after Ended and at a rest (F2).
9. **AC-9 Panel.** Panel open at `pt = 5`: alpha reaches 0 within 0.6 s, the state is Ended, and closing the panel
   does not replay it.
10. **AC-10 Background.** Background at `pt = 5`: nothing drawn, Ended on return, no replay.
11. **AC-11 Per theme.** Three keys in Dinosaurs, switch to a test theme, three keys there: neither theme is Armed;
    back in Dinosaurs, three more keys arm it with only Dinosaurs keys.
12. **AC-12 Art not ready.** With 2 of 6 walkers not resident and never arriving: the walk starts at the wait's end
    (0.5 s) with 4 walkers at their own indices. With 4 of 6 missing: skipped, still Armed, one debug line.
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

## Open Questions

None for Luan; K-17 answered all of them. Follow-ups for other GDDs (not blocking this one):
- **Reveal Stage:** restate the Interface section (shown, lane, draw order, walker taps, stage width).
- **App Shell / Reveal Stage:** the stage-fit rule that sets W (F3).
- **Cast Rendering:** F6 "8 × parade set" → `parade_count` (sent to game-dev-ios by the leader).
- **Press Queue:** R10's example start rule is superseded by F2 here.

**Resolved (Luan, K-17, 2026-11-18):** P1 letters and digits count, digits walk as their group; P2 every 6 distinct
keys per batch, no cap; P3 a press lets the parade keep walking behind; P4 panel or background fade it out, counted,
not replayed; P5 per theme; P6 Reduce Motion halves the bob only; P7 wait ≤ 0.5 s then walk without missing
figures (skip rule rescaled here); P8 debug start only; P9 a tap on a walker only sparkles. Leader defaults: the
unit is the key; a glyph-only fallback does not count.
