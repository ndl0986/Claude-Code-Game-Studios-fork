# Reveal Stage

> **Status**: Approved (independent read by game-dev-android, merged 2026-11-18)
> **Author**: game-dev-ios for Luan (TASK-049); plan reviewed by game-dev-android
> **Last Updated**: 2026-11-18
> **Last Verified**: 2026-11-18, against Press Queue (R2–R11, F1), Cast Rendering (R1, R7–R12, F1, F7), MorphCore
> (Rules 3–6, 9), Audio & Voice (E1–E12, R6), Key Table & Theme Data (R3, fallbacks), Input & Key Filter (R7, R8),
> the Parade plan and GDD (TASK-046), decisions K-13, K-15–K-18, K-20, the art bible §2, §4, §5, §7, and the
> one-shot (`drawReveal`, `drawPrev`, `tapCreature`, layout constants)
> **Implements Pillar**: Pillar 1 (Every Press Answers), Pillar 2 (The Letter Comes Alive); serves Pillar 3 (Calm
> Magic)

## Summary

The Reveal Stage runs the Play screen. It routes every input to the Press Queue and fans the answer out in the same
callback; it runs each reveal's timeline (the glyph rises and glows, turns to stardust, the creature forms and
idles); it places everything on the 1280×720 stage and fits that stage to any screen; it handles taps on the
creature, the grown-up gate's freeze, the panel and the background. It decides **when** and **where**. Cast
Rendering decides how things **look**, MorphCore where each speck is, and the Press Queue which reveal plays and
for how long.

> **Quick reference** — Layer: `Gameplay` · Priority: `MVP` · Key deps: `Press Queue`, `Cast Rendering`,
> `MorphCore`, `Audio & Voice`, `Key Table & Theme Data` (also `Input & Key Filter`, `Hint Letters`; read by
> Parade, Accessibility, App Shell & Title, Mash World)

## Overview

A child presses C. Input turns it into a press; the Reveal Stage asks Hint Letters whether a C hint is on screen
(if so, the letter will rise from that bubble), hands the press to the Press Queue, and in the same callback the
chime plays and a starlight twinkles at the press point. If the queue says "started", the Reveal Stage resolves the
item (the triceratops), builds the morph, and runs it frame by frame: the gold C rises and glows, breaks into 240
specks that fly into the triceratops's outline, and at `T` the triceratops fades in, says its grumble, then
"triceratops". It reports "formed" to the queue and "shown" to the Parade. When the next key starts, this creature
fades away and the next letter rises. The child can tap the creature to make it hop.

## Player Fantasy

**"I press, and something wonderful happens right there."** Every press answers at the place it came from: the
letter flies out of the bubble the child touched, or up from the keyboard. The child can always follow what
happens, because one thing happens at a time and in order, and the creature stays to be looked at and touched.
The grown-up sees a calm toy that fills any screen without black bars, never cuts a word short, and stops still
when they open the grown-up gate.

## Detailed Design

### Core Rules

**R1. The Play scene, the router and the frame driver.**
- **Router:** in Play, the Reveal Stage receives Input's events (press, `sparkle(point)`, `creatureTap(point)`;
  Input R8) on the main thread. For a press it fills the origin (R2), calls the Press Queue's `press(p)`
  synchronously, and in the same callback hands the outcome to Audio & Voice (E1/E2), Hint Letters (consume or
  keep) and its own effects (R6). No consumer waits a frame (Press Queue R4).
- **Frame driver:** once per frame, with the frame's time on the play clock (R8):
  1. `tick(now)` on the Press Queue (its R5), which may start a reveal;
  2. update the current reveal's timeline and late-art state (R5);
  3. draw in the R10 order.
- The Title, panel and background states are App Shell's; the Reveal Stage is active only in Play.
- **The stage view** (the one view that draws the Scene, the cast and the stage, owned here; App Shell owns the
  window around it) sets **`accessibilityIgnoresInvertColors = true`** (K-30): Smart Invert leaves the stage alone,
  because inverting it would break the art bible §4 contrast and colour meanings. The grown-up panel follows Smart
  Invert (Parent Gate). Classic Invert is OS-wide and the user's choice *(TASK-062)*.

**R2. Where a press comes from** (Input R8, K-18).
- A **hint** touch and a **keyboard-row** key bring their own `origin` (the hint's centre, the key's centre).
- A **hardware key** has `origin = nil` from Input. Before `press(p)` the router asks Hint Letters
  `originFor(key)` (TASK-047): the centre of an on-screen hint showing that key, or nil. If nil, the origin is the
  **keyboard anchor** (640, 700), or the matching row key's centre when the keyboard row is on.
- The hint matched this way is consumed by Hint Letters **only** on `started` or `queued`; on `ignored` it stays
  (K-15). The source stays `hardwareKey`.
- This enrichment happens after Input, so Input's rule "origin is nil exactly for a hardware key" still holds for
  Input's own output (follow-up in Dependencies).

**R3. Starting a reveal.** The Press Queue calls `startReveal(revealId, key, source, origin, r0)` (its R6). The
Reveal Stage, before returning:
1. resolves the item: Key Table `resolve(key)` with the theme active now (its §4 pick rule);
2. derives the seed from (key, revealId) by the platform's own mix (MorphCore Rule 5; revealId is the "reveal
   count");
3. asks Cast Rendering `willForm(item)` (its R9);
4. picks the case and returns **`{formedS, revealLen, hasWord}`**, locked for this reveal with the timing set
   (Press Queue R6; F5 gives the numbers):

| Case | What plays | formedS | revealLen | hasWord |
|---|---|---|---|---|
| **Morph** (glyph, silhouette, valid set, `willForm` true) | glyph → stardust → creature | `T` | `T + form_s` | true if the item has a word line in the active locale |
| **Glyph missing** | the creature fades in, no stardust | F5 | = formedS | true if the item has a word line in the active locale |
| **Art or silhouette missing** (`willForm` false) | the glyph rises, glows, then sparkles out | `glow + sparkle_out_s` | = formedS | **false** |
| **Invalid timing set** (MorphCore Rule 9) | the glyph rises over `fallback_rise_s` (the invalid set's own values are not used) and glows until `fallback_glow_s`, then fades out over `fallback_fade_s` while the creature fades in (a crossfade, no stardust) | F5 | = formedS | true if the item has a word line in the active locale |

5. builds the morph (MorphCore) in the morph case, and starts the leaving fade of the previous creature (R5).

**`hasWord` = the case forms a creature AND the active locale has the item's word line** *(TASK-088b, RT-Q2)*. It
tells the Press Queue (its F1 word term) and Audio & Voice (E9) whether the word will play. The cast sound (E8)
has its own condition (R6). Glyph-only reveals still say the letter (Key Table fallback).

**R4. `formed` and `shown`.** When the reveal's time first reaches `s ≥ formedS`, the Reveal Stage sends, once:
- **`formed(revealId)`** to the Press Queue (its R7); never overloaded;
- **`shown(revealId, key, castId, kind)`** to the Parade, `kind = creature` for the morph and the fade-in cases,
  `glyphOnly` for the art-missing case (Parade R1; a glyph-only reveal does not count as met, K-17).
If the queue marks the reveal formed some other way (its timeout R5, or a settle R8), the Reveal Stage still sends
`shown` once at that moment, so the Parade never misses a creature. A late real `formed` is ignored by the queue.

**R5. The timeline** (`s = now − r0`, normal set; the reduced set runs the same steps with its own values,
MorphCore F1).

| Step | When | What the Reveal Stage does | Drawn by |
|---|---|---|---|
| Rise | `0 ≤ s ≤ letter_in` | the glyph moves from `origin` to the glyph centre (640, 320), scale 0.25 → 1, smoothstep (F2) | Cast Rendering `drawGlyph` |
| Glow | `letter_in < s ≤ glow` | the halo is **on** (its look is Cast Rendering's R5) | Cast Rendering |
| Dissolve | `glow < s ≤ glow + dissolve` | swap the glyph for the 240 specks; the glyph's alpha fades out as the specks' fades in | Cast Rendering `drawDust` |
| Travel | until `T` | specks at MorphCore's positions, mapped by the two box transforms (R10) | Cast Rendering |
| Formed | `s = T` | `formed`, `shown` (R4); the creature fades in over `form_s` with the pop (F3); the specks fade out over `form_s + 0.2` | Cast Rendering `drawCast` |
| Idle | after the fade-in | `idleTime = s − formedS` (plus any late-art wait, below); taps allowed (R7) | Cast Rendering |

- **Glyph swap without a jump:** the glyph and the specks' start points use the **same** glyph transform (unit
  box → the glyph's drawn box at that moment), and the creature and the specks' end points use the **same**
  creature transform (unit box → the silhouette's artboard box → the stage at the anchor). So the swap at
  `s > glow` and the creature fade-in land exactly (MorphCore Rules 3–4).
- **Late art** (Cast Rendering R10, F7): if `isResident(item)` is false at `formedS`, the specks hold the
  silhouette for the F7 wait and the creature's fade-in starts when the art arrives. The Reveal Stage reads the
  queue snapshot (Press Queue R11) to know whether a key is waiting, which cuts the wait. `formed` is not moved.
  The idle starts at rest when the fade-in starts (`idleTime` counts from then), so the creature matches the
  silhouette. If the art never arrives, the specks sparkle out and `shown` stays `creature` (it was announced at
  `formedS`; one log line).
- **The leaving creature:** when a new reveal starts, the previous creature fades out over `leave_s` (0.45 s),
  sinks 12 units and shrinks 8% (as played, F4). It is always formed, because the queue starts a reveal only after
  `formed` (Press Queue R3, R5). It is not tappable.
- **Prefetch:** on a `queued` outcome, the Reveal Stage asks Key Table for a **peek** of the item that key would
  show (without changing `lastShown`) and calls Cast Rendering `prefetch` (its R10). At start the real resolve runs;
  if it picks a different item, the prefetched one is released.

**R6. What a press looks and sounds like at once** (Press Queue R4, art bible §4, §7).

| Outcome | At the origin | Sound (Audio & Voice) | Hint Letters |
|---|---|---|---|
| `started` | a starlight (four-point star, Starlight colour) | chime (E1) | consume the hint |
| `queued` | a starlight; a token appears in the queue row | chime (E1) | consume the hint |
| `ignored` | a sparkle burst (8 specks, as played) | ping (E2) | the hint stays |
| `sparkle(point)` from Input (empty stage) | a sparkle burst at the point | ping (E3) | — |

- Reveal sounds: E6 at `s = 0`, E7 at `s = glow`, E8 at `s = formedS` when the case forms a creature (not art
  missing) and the item's `sfx` is present, and E9 at `formedS + word_offset_s` (0.25 s) only when `hasWord`
  *(TASK-088b, RT-Q1)*; the word is never cut by a waiting key (K-13; the Press Queue's hold covers it).
  E8 and E9 play on time during a late-art wait (Cast Rendering edge case). Ducking is Audio's.
- The **queue tokens** are drawn from the Press Queue snapshot (its R11): small round cream bubbles with the key in
  Letter Gold ink, in a still row at the top right of the safe stage, 66 units apart from x 1214, y 58 (as
  played). They appear without bounce (art bible §7).
- The **parade meter** *(TASK-120, K-44)* is drawn from the Parade's **meter snapshot** (Parade R12, F4, Interface 7)
  with the art bible §7 look (x 846–1022, y 40–76 with its glow), just left of the token row, inside the safe stage,
  in the token layer. A touch on it is an empty-stage `sparkle(point)`.

**R7. Tapping the creature.**
- The Reveal Stage publishes the **current, formed** creature's hit shape to Input (its R7 layer 4): the
  silhouette path in artboard space, tested after a box pre-check. It exists from `formedS` (even during the
  fade-in) until the next reveal starts. The leaving creature and parade walkers have none; a touch there falls
  through to a sparkle (Input R7, K-17).
- A `creatureTap` outside `tap_cooldown_s` (0.9 s since the last counted tap): the hop (Cast Rendering F5), the
  creature's sound again (Audio E10), and a small burst (6 specks) at the point.
- Inside the cooldown: a small sparkle (4 specks) only, no sound (Audio E4).
- A tap never replays the word (Audio E10) and never touches the Press Queue.

**R8. Freeze, settle and the play clock** (K-15, K-20).
- **The play clock:** `play = uptime − frozenTotal`. Every time the Reveal Stage uses (frame times, `r0`, `s`,
  cooldowns) and every time it hands to the Press Queue (`tick(now)`, press times) is on this clock. Outside a
  freeze it equals the uptime clock.
- **`freeze()`** — the Parent Gate opens its number challenge (K-20): the play clock stops; the current reveal,
  the queue (no ticks, no presses: keys go to the challenge) and the hints stop where they are; the creature's idle
  stops. Audio pauses its players (Audio & Voice's gate-freeze rule, AC-21). A **walking parade pauses** too: its walk clock `pt`, the
  walkers and its tune (E12, through Audio) stop, and while the Parade is Armed its rest time does not count (the
  leader's decision, Parade TASK-046). The scene is still drawn, frozen, under the gate.
- **`resume()`** — a wrong answer or a timeout: the clock runs again from where it stopped, so nothing jumps and no
  hold is shortened; the parade walks on from the same `pt`.
- **`settle()`** — a correct answer opens the panel (K-15, after the freeze), or the app goes to the background:
  the Press Queue clears its queue and marks the current reveal formed (its R8, R9); the Reveal Stage shows the
  creature fully formed at rest (no specks, no halo, idle from rest), sends `shown` if not yet sent (R4), and
  clears its own sparkles. The panel's dim and Audio's cuts are theirs. Closing the panel returns to Play with the
  settled creature and the hold passed.
- **Under the panel the play clock runs** (the panel is not a freeze; Scene R9 relies on this). Nothing waits on it
  there: the settle left the queue empty and the hold passed, no press or touch reaches Play, the tap cooldown and
  the `mashing` window simply age out, and the creature idles under the dim. Hint Letters freezes its own `hintTime`
  from the Parent Gate's panel signals (K-18), and a walking parade has already faded out (Parade R6).
- Background: settle, and the play clock does not count background time (Press Queue R9).

**R9. Reduce Motion** (K-16, K-20). Read at reveal start and locked with the timing set:
- the **reduced timing set** (MorphCore);
- the glyph **rises straight** with no scale overshoot (the one-shot's rise is already a straight, smoothstep
  lerp; under Reduce Motion it stays so, on the shorter `letter_in`);
- the creature appears **with no pop overshoot** (F3);
- the leaving creature **fades without sinking or shrinking** (F4);
- Cast Rendering softens the idle, the hop and the halo (its R5, R7, R8).
- **The tap and ignored-press sparkles stay unchanged** (leader's call, TASK-062; Accessibility A3's flag): they are
  short (0.6–1.0 s), they are the toy's "I heard you" answer (art bible §7: every press is answered), and they move
  small specks, not the scene.
- The flag is **Accessibility's `reduceMotion`** (its A1; never the OS API).

**R10. Layout, stage fit and draw order** (K-20).
- **Stage units:** the 1280×720 **safe stage**, y down. Glyph centre (640, 320), ~330 units tall; creature anchor
  (640, 600), `creature_scale` 1; keyboard anchor (640, 700); the ground line (the parade lane) y 558 (the
  one-shot's 478 + 80).
- **Keyboard row on** (art bible §7): the creature anchor, the ground line and the lane move up by
  `row_lift` (proposal: 110 units); the glyph centre stays; hints stay in the sky.
- **Stage fit (decided, K-20): contain, then extend.** The safe stage is scaled to fit the screen whole (F1) and
  centred; the Scene extends the sky and ground to fill the rest. No bars, nothing cropped. iPads (narrower than
  16:9) fit by width and gain sky and ground; wide Mac windows fit by height and gain hills to the sides. Hints,
  queue tokens and the parade meter stay inside the safe stage.
- The Reveal Stage **owns this transform** and publishes `stage_to_px` (physical px per stage unit) and the
  **visible rect** in stage units (it extends past 0…1280 or 0…720). Cast Rendering (its F1), the Scene, the
  Parade (its F3: `W` = the visible width, starting at the rect's left edge), Hint Letters and Input's hit testing
  use it. App Shell owns the window and the safe-area insets it hands over.
- It also publishes, in stage units and updated whenever they move (`row_lift`, a token-row change, a new
  creature): the **cast box** (the current creature's box at its anchor), the **glyph box** (the glyph's drawn
  box at full size), the **token circles** (the queue row), the **meter box** (the parade meter, x 846–1022, y 40–76
  with its glow; TASK-120) and, while it is on, the **keyboard row band** (`y ≥ 582`,
  published by the On-screen Keyboard Row, its R1) *(TASK-062)*. Hint Letters reads them for its clearances (its R5);
  the moon's rect comes from the Parent Gate.
- And two flags, for the Scene (its R3, R3a), on the play clock:
  - **`haloOn`**: true while the glyph's halo is on, through the Glow phase (R5: `letter_in < s ≤ glow`), false
    otherwise and while a reveal is settled or there is none;
  - **`mashing`**: true while the Press Queue snapshot's queue length is ≥ 1 (its R11), **or** an `ignored` outcome
    happened in the last `mash_window_s` (1 s, the Scene's knob); false otherwise. It stops changing under a
    freeze (play clock) and is false after a settle (the queue is empty).
- **Draw order** (back to front): Scene backdrop (sky, hills, ground, weather) → parade walkers → the leaving
  creature → the current creature → **the On-screen Keyboard Row** (while it is on) → the glyph or the specks → starlights and sparkles → hint letters → queue
  tokens and the parade meter (TASK-120) → the moon → the gate and panel. During a parade the stage creature stays where it is, in front of the
  walkers (Parade R5). The `zPosition` of each layer is ADR-0006 D1's table (the keyboard row at z 35: above the
  current creature at 30, below the glyph or specks at 40) *(TASK-085a; TASK-070)*; this line gives the order only,
  and D1's table is the one source for the numbers.

### States and Transitions

The Reveal Stage's own state follows the Press Queue's, plus freeze:

| State | Meaning | Leaves to |
|---|---|---|
| **Empty** | Play just entered: no creature (first launch into Play) | Revealing (a press starts) |
| **Revealing** | a reveal before `formedS` | Formed (at `formedS`, timeout or settle) |
| **Formed** | the creature is on stage (fading in or idling); taps allowed | Revealing (the next reveal starts; this creature leaves) |
| **Frozen** | the number challenge is open; the play clock stops | the state it was in (resume) or Formed (settle on a correct answer) |

### Interactions with Other Systems

| System | Direction | Interface |
|---|---|---|
| Input & Key Filter | in | press, `sparkle(point)`, `creatureTap(point)` (its R8); out: the creature hit shape (its R7 layer 4), the stage transform for hit tests |
| Press Queue | out / in | `press(p)` and `tick(now)` on the play clock; in: `startReveal(...)` → `{formedS, revealLen, hasWord}`; out: `formed(revealId)` once; reads the snapshot (R11 there); `settle` on panel and background |
| Hint Letters | out / in | `originFor(key)` before a hardware press; the outcome (consume / keep); freeze / resume for the gate challenge; the cast box, glyph box and token circles (R10). Hints also freeze while the **panel** is open (K-18): Hint Letters takes panel open / close from the Parent Gate & Grown-up Panel directly, not from the Reveal Stage |
| Key Table & Theme Data | in | `resolve(key)` at start; a peek for prefetch (no `lastShown` change); the fallbacks |
| MorphCore | in | the morph per reveal (glyph path, silhouette, spec, seed); `position(i, s)`, T, phase |
| Cast Rendering | out / in | `drawGlyph`, `drawDust`, `drawCast` each frame with the halo on/off, alphas, `idleTime`, `hop`; `willForm`, `isResident`, `prefetch`, `release` |
| Audio & Voice | out | E1–E3 from the outcome; E6–E10 at their times (R6); pause / resume on freeze; `hasWord` |
| Parade | out / in | out: `shown(revealId, key, castId, kind)`; the lane y; the visible rect; draw order; freeze / settle. In: the parade meter snapshot, which it draws (Parade R12; TASK-120) |
| Parent Gate & Grown-up Panel | in | `freeze` (challenge open), `resume` (wrong or timeout), `settle` (correct → panel) |
| App Shell & Title | in | enters Play; background → settle; the window size and safe area |
| Scene: Time of Day & Weather | out | the visible rect to fill (sky and ground extension), the ground line, the play clock and freeze / resume, the glyph box, `haloOn` and `mashing` (R8, R10) |
| Accessibility | in | Accessibility's `reduceMotion` (its A1; never the OS API), read at reveal start (R9) |

## Formulas

**F1. Stage fit.**
```
s_fit   = min(W_px / 1280, H_px / 720)                 stage_to_px
offset  = ((W_px − 1280·s_fit) / 2, (H_px − 720·s_fit) / 2)
visible = (x: −offset.x / s_fit, y: −offset.y / s_fit, w: W_px / s_fit, h: H_px / s_fit)   in stage units
```
| Screen (physical px) | s_fit | visible rect |
|---|---|---|
| 11" iPad landscape, 2388 × 1668 | 1.866 (by width) | x 0, y −87, 1280 × 894 |
| 13" iPad landscape, 2752 × 2064 | 2.150 (by width) | x 0, y −120, 1280 × 960 |
| 16:9 Mac window, 2560 × 1440 | 2.000 | 0, 0, 1280 × 720 |
| 21:9 Mac window, 3440 × 1440 | 2.000 (by height) | x −220, y 0, 1720 × 720 |

**F2. Glyph rise.** With `u = smoothstep(clamp(s / letter_in, 0, 1))`:
```
pos(s)   = origin + (centre − origin) · u          centre = (640, 320)
scale(s) = 0.25 + 0.75 · u
```
Example (normal, `letter_in` 0.45 s): from a hint at (300, 250), at s = 0.225 (u = 0.5) the glyph is at (470, 285)
at scale 0.625.

**F3. Creature fade-in and pop.** With `u = smoothstep(clamp((s − fadeStart) / form_s, 0, 1))`:
```
alpha    = u
pop(u)   = 0.92 + 0.08·u + 0.03·sin(π·u)         normal (as played)
pop(u)   = 0.92 + 0.08·u                          Reduce Motion (no overshoot)
```
`fadeStart = formedS` for the morph (later with late art); for the two fade-in fallbacks, whose `formedS` is the
fade-in's end (Press Queue R6): `fadeStart = formedS − form_s` for glyph missing (the set is valid). For an
invalid set, whose own `form_s` is not trusted, **`form_s` is replaced by `fallback_fade_s` in both places**: in
`fadeStart = formedS − fallback_fade_s` and as the fade's length in `u` *(TASK-088d)*. Example: u = 0.5 → pop 0.99 normal
(0.96 + 0.03), 0.96 reduced. The normal pop peaks just above 1 (≈ 1.002 near u = 0.8) and settles at 1.0; the
reduced one never exceeds 1.0.

**F4. Leaving creature.** With `v = clamp(t_leave / leave_s, 0, 1)`:
```
alpha = 1 − v;   y = anchor.y + 12·v;   scale = 1 − 0.08·v      normal (as played)
alpha = 1 − v;   y = anchor.y;          scale = 1               Reduce Motion
```

**F5. Fallback lengths** (R3).
```
glyph missing:      formedS = max(glow + form_s,  letter_len_max_s − word_offset_s)      (the fade-in starts at formedS − form_s)
invalid set:        formedS = max(fallback_glow_s + fallback_fade_s, letter_len_max_s − word_offset_s)
art missing:        formedS = glow + sparkle_out_s
revealLen = formedS in all three
```
The `max` keeps the word (E9 at `formedS + 0.25`) from starting before the longest letter line has ended
(`letter_len_max_s` 1.0 s, Audio A3), since the voice bus has one player.

| Case | Normal set | Reduced set |
|---|---|---|
| glyph missing | max(0.8 + 0.5, 0.75) = **1.30 s** | max(0.4 + 0.3, 0.75) = **0.75 s** |
| invalid set (fallback 0.8 + 0.5) | **1.30 s** | **1.30 s** (the set itself is not trusted) |
| art missing (`sparkle_out_s` 0.6) | 0.8 + 0.6 = **1.40 s** | 0.4 + 0.6 = **1.00 s** |

**F6. Tap cooldown.**
```
counts(tap at t) = (t − lastCountedTap ≥ tap_cooldown_s)      on the play clock
```
Example: taps at 10.0, 10.5 and 11.0 → the first and third count (0.5 < 0.9; 1.0 ≥ 0.9).

## Edge Cases

| Case | What happens |
|---|---|
| **A hardware key whose letter is on a hint** | The glyph rises from that hint; the hint is consumed if the press is accepted (R2, K-18). |
| **The same, but the queue is full** | `ignored`: a sparkle at the hint's centre, a ping, the hint stays (K-15). |
| **Two hints show the same key** | Not possible: Hint Letters never repeats a key on screen (K-18). |
| **A hint fades away while its press is queued** | Already consumed at the press; the queued reveal later rises from the stored origin (the queue keeps `origin`, Press Queue R2). |
| **Art not loaded at `formedS`** | Cast Rendering's late-art wait (R5); `formed` is not moved; sound plays on time. |
| **Glyph missing** | The creature fades in on F5's time; no stardust; letter voice, cast sound and word as usual. |
| **Art missing (`willForm` false)** | The glyph glows and sparkles out; `hasWord` false; no cast sound or word; `shown(glyphOnly)`. |
| **Timing set invalid** | No morph; the glyph glows until `fallback_glow_s`, then crossfades into the creature over `fallback_fade_s` (F5); E7 at `fallback_glow_s` *(TASK-088b)*; one log line. |
| **A tap during the fade-in** | Counts (the hit shape exists from `formedS`). |
| **A tap on the leaving creature or a walker** | A sparkle only (R7, K-17). |
| **Taps faster than the cooldown** | Only one per 0.9 s hops and sounds; the others sparkle (F6). |
| **The challenge opens mid-morph** | Everything freezes (R8); a wrong answer resumes the morph from the same `s`; a correct answer settles it to formed. |
| **The challenge opens while a key is queued** | The queue freezes with it; on resume the hold continues where it stopped (play clock). |
| **The challenge opens during a parade** | The parade pauses (its `pt` and tune); a wrong answer resumes it; a correct answer opens the panel and the Parade fades it out (Parade R6). |
| **Art never loads after `formedS`** | The specks sparkle out, but `shown(creature)` was already sent, so the Parade counts a creature the child did not see. Accepted: rare (art is prefetched, Cast Rendering R10), logged. |
| **The app goes to the background mid-reveal** | Settle (R8): the creature is formed on return, the queue is empty, the next press starts at once. |
| **The window is resized on the Mac** | F1 is recomputed; the safe stage keeps its layout; the visible rect and `stage_to_px` are republished; Cast Rendering may change tier (its edge case). |
| **The keyboard row is turned on or off** | Applied from the next reveal: the anchor, ground line and lane move by `row_lift`; the current creature stays where it is until it leaves. |
| **Reduce Motion changes mid-reveal** | The running reveal keeps its locked set and motion; the next one uses the new rules (R9). |
| **A theme change in the panel** | The settled creature stays; the next reveal uses the new theme (Key Table §4). |
| **A frame hitch** | `s` jumps with the clock; events already due (formed, sounds) fire on that frame, once. |

## Dependencies

- **Upstream (the Reveal Stage reads):**
  - Press Queue (`design/gdd/press-queue.md`): `press`, `tick`, `startReveal`, `formed`, the snapshot, settle (R3–R11
    there).
  - Cast Rendering (`design/gdd/cast-rendering.md`): every draw call, `willForm`, `isResident`, `prefetch`,
    `release`, late art (R9, R10, R12, F7).
  - MorphCore (`design/gdd/morphcore.md`): the morph, positions, T, the seed rule (Rules 3–6, 9).
  - Audio & Voice (`design/gdd/audio-voice.md`): E1–E12 and their times; ducking.
  - Key Table & Theme Data (`design/gdd/key-table-theme-data.md`): `resolve`, the fallbacks.
  - Input & Key Filter (`design/gdd/input-key-filter.md`): the press event, `sparkle`, `creatureTap`, hit layers.
  - Hint Letters (`design/gdd/hint-letters.md`): `originFor(key)`, consume / keep.
- **Downstream (each must name the Reveal Stage):** Parade (TASK-046: `shown`, the lane, the visible rect, draw
  order, taps, freeze and settle), Parent Gate & Grown-up Panel (freeze, resume, settle), App Shell & Title (enters
  Play, background, window), Scene (the visible rect), Accessibility (R9), Mash World (Full Vision).
- **Follow-ups for other GDDs (not edited here; the leader sends them as one task, TASK-050):**
  - Press Queue F1: take `hasWord` from `startReveal` (not only "the item has no word line").
  - Press Queue: under a freeze, all its times are the play clock (R8 here).
  - Input & Key Filter R8: a note that the Reveal Stage fills a hardware key's origin after Input (R2, K-18).
  - Key Table: a peek resolve for prefetch that does not change `lastShown` (R5).
  - Audio & Voice: pause and resume its players on `freeze` / `resume` (R8).
- **Decisions:** K-13, K-15, K-16, K-17, K-18, K-20.

## Tuning Knobs

All values are bundled data, checked at build.

| Knob | Value | Safe range | Source | Effect |
|---|---|---|---|---|
| glyph centre, size | (640, 320), 330 units | — | art bible §7, one-shot | where the letter glows |
| creature anchor, `creature_scale` | (640, 600), 1.0 | scale 0.6–1.3 | one-shot | where the creature stands |
| keyboard anchor | (640, 700) | — | one-shot | where a hardware letter rises from |
| ground line / lane y | 558 | — | one-shot (478 + 80) | the parade's walk |
| `row_lift` | 110 units | 80–160 | **proposal** | how far the ground moves up for the keyboard row |
| `form_s` | 0.5 s (reduced 0.3) | 0.1–1.5 | one-shot, MorphCore F5 | the creature's fade-in |
| `leave_s` | 0.45 s | 0.2–1.0 | one-shot | the previous creature's exit |
| `sparkle_out_s` | 0.6 s | 0.3–1.0 | proposal (one-shot burst life 0.6–1.0) | the art-missing glyph's exit |
| `fallback_rise_s`, `fallback_glow_s`, `fallback_fade_s` | 0.45, 0.8, 0.5 s | — | the normal set's values (`letter_in`, `glow`, `form_s`) | the invalid-set fallback: rise, glow end, crossfade *(TASK-088c)* |
| `tap_cooldown_s` | 0.9 s | 0.2–3 | one-shot | how often a tap hops and sounds |
| burst sizes | ignored 8, tap 6, cooldown tap 4 | 2–12 | one-shot | sparkle answers |
| token row | x 1214, step 66, y 58 | inside the safe stage | one-shot | where queued letters wait |

## Acceptance Criteria

Logic tests use an injected play clock and fakes for the Press Queue, Cast Rendering, MorphCore, Audio, Key Table
and Hint Letters. Screenshots are retained in `production/qa/evidence/`.

1. **AC-1 Lengths:** `startReveal` returns, for the normal set: morph (2.45, 2.95, true); glyph missing (1.30, 1.30,
   true); art missing (1.40, 1.40, false); invalid set (1.30, 1.30, true); and the F5 reduced values.
2. **AC-2 formed and shown once:** `formed(revealId)` and `shown(..., kind)` each fire exactly once, at the first
   frame with `s ≥ formedS`; `kind` is `glyphOnly` only for art missing; after a queue timeout or a settle,
   `shown` still fires once.
3. **AC-3 Origins:** a hint touch rises from its centre; a row key from its centre; a hardware key with a matching
   hint from that hint (consumed on started and queued, kept on ignored); a hardware key with no match from
   (640, 700).
4. **AC-4 Same callback:** for each outcome, Audio, Hint Letters and the starlight/sparkle are called inside the
   `press(p)` callback (a recording fake), never on a later frame.
5. **AC-5 Event times:** with `hasWord`, E6 at 0, E7 at 0.8, E8 at 2.45, E9 at 2.70 (±1 ms); for an item with `sfx`
   but no word line, E8 at 2.45 and no E9; for art missing, neither E8 nor E9 *(TASK-088b)*.
6. **AC-6 No jump at the swap:** the glyph's outline and the specks' start points, and the creature's outline and
   the specks' end points, overlay within 1 px (same transforms, R5).
7. **AC-7 Late art:** with Cast Rendering's seam delaying the art, `formed` fires at `formedS`, the fade-in starts
   when the art arrives within the F7 wait, and the idle starts at rest then.
8. **AC-8 Leaving:** when reveal 2 starts, reveal 1's creature fades over 0.45 s, sinking 12 units and shrinking 8%;
   with Reduce Motion it only fades.
9. **AC-9 Taps (F6):** taps at 10.0, 10.5, 11.0 → hop + E10 at 10.0 and 11.0, a sparkle only at 10.5; a tap on the
   leaving creature or a walker gives a sparkle only.
10. **AC-10 Freeze:** freeze at `s` = 1.0 for 20 s of uptime, then resume: the reveal continues from `s` = 1.0, the
    queue's hold is not shortened, and the cooldown is unchanged; freeze then a correct answer settles to formed.
11. **AC-11 Settle:** on panel open or background mid-morph, the creature is drawn formed at rest, the specks and
    halo are gone, the queue is cleared (Press Queue), and the next press after return starts at once.
12. **AC-12 Stage fit (F1, screenshots):** the four F1 rows give the listed `s_fit` and visible rect; retained
    screenshots on an 11" iPad, a 13" iPad and a 21:9 Mac window show no bars, nothing cropped, and hints and
    tokens inside the safe stage.
13. **AC-13 Draw order (screenshot):** during a parade with a creature on stage and a key queued, the walkers are
    behind the creature, the specks and glyph in front of it, the tokens and hints above.
14. **AC-14 Reduce Motion:** the glyph rise has no scale above 1, the pop never exceeds 1.0, the leaving creature
    does not move; the reduced set's times are used for E6–E9.
15. **AC-15 Prefetch:** a queued key's item is peeked without changing `lastShown`, prefetched, and released if the
    real resolve at start picks another.
16. **AC-16 Feel (device, NOT ASSESSED):** the reveal and its sounds on a real iPad (TASK-033 procedure).
17. **AC-17 Scene flags:** `haloOn` is true exactly for frames with `letter_in < s ≤ glow` of the current reveal;
    `mashing` turns true on a `queued` outcome, stays true while the queue is non-empty, and turns false 1 s after
    the last `ignored` outcome with an empty queue; under a freeze neither changes; after a settle both are false.

**NOT ASSESSED:** how the reveal and the stage fit feel and read on a real iPad and Mac; device frame time (Cast
Rendering's measurement plan).

## Open Questions

- None open for Luan.
- **Decided (Luan, K-20, 2026-11-18):** contain the safe stage and extend the sky and ground; the Reveal Stage owns
  the transform. Reduce Motion: straight rise without scale overshoot, no pop overshoot, the leaving creature fades
  without sinking.
- **Chosen by the author (proposals in Tuning Knobs):** `row_lift` 110 units, `sparkle_out_s` 0.6 s, the F5
  `max` with the letter line, the play clock for the freeze, and asking Audio to pause on freeze (the
  alternative, letting a word finish behind the gate, is the Audio GDD's call).
