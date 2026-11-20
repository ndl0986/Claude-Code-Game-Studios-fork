# Press Queue

> **Status**: Approved (independent re-review by game-dev-ios, merged 2026-11-18)
> **Author**: game-dev-android for Luan (TASK-043); plan reviewed by game-dev-ios
> **Last Updated**: 2026-11-18 (TASK-082 nits)
> **Last Verified**: 2026-11-18, against Input & Key Filter R8, MorphCore F5/F6, Audio & Voice F6/E1/E2, Key Table
> R3 and `voiceDurations` (V15), Settings Store, K-06, K-13, K-15, the one-shot `pressLetter` / `holdTime`
> **Implements Pillar**: Pillar 1 (Every Press Answers); serves Pillar 3 (Calm Magic)

## Summary

The Press Queue decides what every press becomes: a reveal that starts now, a key that waits its turn, or (when
three keys are already waiting) a press that only sparkles and pings. It owns the hold, the time a creature stays
on stage while keys wait, and it starts the next reveal when that hold has passed. It answers every press in the
same event callback, so Audio, the Reveal Stage and Hint Letters respond without a frame of delay. It has no
visuals or sound of its own.

> **Quick reference** — Layer: `Core` · Priority: `MVP` · Key deps: `Input & Key Filter` (press events); works with
> `Reveal Stage` (starts reveals, receives "formed"), `Audio & Voice` (F6 word end), `Key Table & Theme Data`
> (`voiceDurations`, item at start)

## Overview

A 2.5-year-old presses keys fast and often all at once. The toy must answer every press (Pillar 1) without
turning into a strobe of half-finished morphs (Pillar 3). The mash rule (K-06) does both: at most 3 keys wait,
each reveal holds about 3 s while keys wait, and extra presses only sparkle. The Press Queue is that rule as a
small, UI-free state machine driven by an injected clock: Input hands it each press (Input R8), it returns the
outcome at once, and once per frame it checks whether the next waiting key may start. The Reveal Stage draws and
reports when each creature has formed; the timing is decided here (systems index, Press Queue ↔ Reveal Stage
resolution).

## Player Fantasy

For the child: "every press does something". A single press always starts a letter at once if nothing is
happening; a flurry of presses fills a little row of waiting tokens that play in turn; when the row is full, the
press still sparkles and pings, so nothing is ever dead. A creature always finishes forming and its word is
always heard whole before the next letter takes its place.

For the grown-up: the toy never runs away. Mashing ten keys gives at most four creatures in a calm sequence, not
ten overlapping explosions, and when the grown-up opens the panel or the app goes away, the waiting keys are
forgotten and the stage is quiet when they return.

## Detailed Design

### Core Rules

**R1. Ownership.**

| Concern | Owner |
|---|---|
| Accept, queue or ignore a press; the hold; when the next reveal starts; clearing the queue | **Press Queue** |
| Drawing the reveal, its no-morph fallbacks, the tokens, the sparkles; reporting `formed` | Reveal Stage |
| Particle positions, T | MorphCore (it has no hold, its Rule 7) |
| When the word ends (F6 constraint), chime and ping | Audio & Voice |
| Which item a key shows; `voiceDurations` | Key Table & Theme Data (resolved when the reveal starts, its §4) |
| Turning presses into events; held keys and repeats | Input & Key Filter (it never drops a press, its R8) |
| When the parade starts and whether a press ends it | Parade (reads `restingSince`, R10) |

**R2. State.**

- `current`: the reveal on stage, or none. It holds `revealId`, `key`, `source`, `origin`, `r0` (start time),
  `formedS` and `revealLen` (from the Reveal Stage, R6), `holdEff` (F1, **locked at start**), `formed`
  (boolean) and `formedAt` (time, once formed).
- `queue`: a FIFO list of at most `queue_max` (3) waiting presses, each `{key, source, origin, time}`. A queued
  press has **no revealId** until it starts.
- `nextRevealId`: one counter from launch. The first reveal after launch has `revealId = 1`, the next 2, and so
  on. It is the **same number as MorphCore's press count** for the seed (MorphCore Rule 5, K-11: "reveals started
  since launch"); the Reveal Stage passes it on as that count. Presses that are queued but cleared (R8, R9) or
  ignored never take a number, so the count advances only when a reveal starts.

**R3. A press arrives** (`press(p)`, called synchronously from Input's event callback, in delivery order; `p` is
Input's R8 event `{key, source, time, origin}`). The decision uses `p.time`, **converted to play-clock time on
arrival (R8a)**, and compares it with play-clock times only:

1. **Start at once** if there is no `current`, **or** the queue is empty **and** `current.formed` **and**
   `p.time ≥ current.r0 + current.holdEff`. The reveal starts with `r0 = p.time` (R6). Outcome:
   `started(revealId, r0, item)`.
2. Otherwise, **queue it** if `|queue| < queue_max`: append it. Outcome: `queued(index)`, where `index` is its
   0-based place in the queue.
3. Otherwise **ignore it** (overflow). Outcome: `ignored`.

- A press can **never jump a queued key**: while anything waits, rule 1 cannot apply.
- The same key may be queued more than once, and may be queued while it is on stage (as in the one-shot).
- A `p.time` earlier than `current.r0` (an out-of-order stamp, Input R8) is simply "before the hold has passed":
  it never starts a reveal early.
- In the Title state no press reaches the queue: `startPlay` is not a press (Input & Key Filter Title state, Audio
  E5). Play begins with an empty queue and no `current`, so the first press in Play starts at once.

**R4. The outcome is returned at once.** `press(p)` returns `started(revealId, r0, item) | queued(index) |
ignored` before Input's callback ends. In the same callback:

- **Audio & Voice** plays the chime for `started` and `queued` (E1), the softer ping for `ignored` (E2, K-13).
- **Reveal Stage** draws the starlight at `origin` for an accepted press, a sparkle at `origin` (or the keyboard
  anchor for a hardware key) for `ignored`, and starts the reveal for `started`.
- **Hint Letters** consumes the touched hint for `started` and `queued`; for `ignored` **the hint stays** on
  screen (Luan, K-15).

No consumer waits a frame. The outcomes come out in press order, one per press.

**R5. Once per frame: `tick(now)`.** The frame driver calls `tick(now)` once per frame, **before drawing**, with
the frame time (Apple: the display link's `targetTimestamp`, which shares mach uptime with `event.timestamp`;
Android: `SystemClock.uptimeMillis() / 1000`, the clock of `getEventTime()`). In order:

1. **Formed timeout:** if `current` is not formed and `now ≥ r0 + revealLen + formed_timeout_s` (1 s), mark it
   formed at `now`, write one debug log line. A real `formed` that arrives later is ignored (R7).
2. **Advance:** if the queue is not empty, `current.formed`, and `now ≥ r0 + holdEff`, pop the front press and
   start it with `r0 = now` (R6). At most **one** reveal starts per tick.

- **Both comparisons are inclusive** (`≥`): the formed timeout fires at exactly `r0 + revealLen + formed_timeout_s`,
  and the advance happens at exactly `r0 + holdEff` *(TASK-082, PQ-Q4)*.
- **Order with presses** *(TASK-082, PQ-Q2)*: presses and ticks are handled **in delivery order**; `tick(now)` is one
  more event in that order, with no fixed place before or after a frame's input callbacks. A press can never jump a
  queued key either way (R3), so the order changes at most its queue index. Example: with a key waiting, a press at
  exactly `r0 + holdEff` in the same frame as the tick: tick first, the head starts and the press queues at index
  0; press first, it queues at index 1 and the tick then starts the head. With an empty queue, a press at exactly
  `r0 + holdEff` starts at once (R3.1, `≥`).

**R6. Starting a reveal.** The queue calls the Reveal Stage's `startReveal(revealId, key, source, origin, r0)`:

- Key Table resolves the item **now**, with the theme active now (its §4); `item` is returned in the outcome.
- The Reveal Stage returns `{formedS, revealLen, hasWord}` for this reveal, **including its no-morph fallbacks**.
  `hasWord` is false when no word will play (no word line, or Cast Rendering's `willForm` is false):

  | Case | formedS | revealLen |
  |---|---|---|
  | Morph | `T` of the active timing set | `T + form_s / morph_speed` (MorphCore F5) |
  | Glyph missing → the creature fades in | the fade-in's end | the same |
  | Silhouette or art missing → the glyph glows and sparkles out | the sparkle-out's end | the same |
  | Invalid timing set → the creature fades in | the fade-in's end | the same |

  The queue never reads MorphCore or the timing data directly for these: the Reveal Stage's answer is the truth
  for the reveal it is drawing.
- The queue computes `holdEff` (F1) **once, at start**, and locks it together with the timing set. A Reduce Motion
  change during a reveal changes only the next one (MorphCore's edge case).
- The `revealId` counter advances by one.

**R7. `formed(revealId)`.** The Reveal Stage reports `formed` **exactly once per reveal**, at `s ≥ formedS`
(for a morph `s ≥ T`, MorphCore F6 "Formed"; the creature's `form_s` fade-in is still running, which is why
`holdEff ≥ revealLen`). The fallbacks report it at the end of their own length.

- `formed` for a `revealId` that is not `current` (a reveal already replaced, or cleared) is ignored.
- A second `formed` for the same reveal, or one after the R5 timeout, is ignored.
- On `formed`, the queue sets `current.formed = true` and `formedAt = now` (the tick or callback time it arrives).

**R8. Grown-up panel.** When the panel opens (Parent Gate & Grown-up Panel, chord or moon hold), **the queue is
cleared** (Luan, K-15), and the current reveal **settles at once to formed**: the queue marks it formed and the
Reveal Stage shows the formed creature under the dim, not a morph frozen half-way. The settled reveal's `formedAt` is the **play-clock time of the settle**, so `restingSince = formedAt` from that
moment (R10) and it **is published while the panel is open** (the play clock does not stop under the panel, Reveal
Stage R8; whether the Parade may start then is the Parade's rule, its R6) *(TASK-082, PQ-Q3)*. The hold of the
settled creature counts as passed, so after the panel closes the next press starts at once (same rule as R9; author's
choice, consistent with K-15). A theme can only be changed in the panel, so the queue is already empty when a new
theme takes effect; the next reveal uses it (Key Table §4). The theme change itself never clears anything.

**R8a. Parent-gate challenge: freeze and resume** (K-20; TASK-050). While the gate's number challenge shows (after
the moon hold or the Mac chord), the queue **freezes**: no tick advances it, the hold and the formed timeout do not
run, and nothing is cleared. Input sends no presses during the challenge (Input R6). On a **wrong answer or a
timeout**, the queue **resumes** exactly where it stopped. Only a **correct answer** opens the panel, and R8's
clear and settle apply then (K-15, K-20).
- **The play clock.** All the queue's times (`now` in `tick`, `r0`, `formedAt`, `restingSince`, the hold and the
  formed timeout) run on the **play clock = uptime − total frozen or background time** (as in Reveal Stage R8:
  `freeze()` / `resume()`, and background).
  While frozen the play clock stands still, so the frozen time never counts and nothing sees a gap. A press's
  `p.time` (uptime, Input R8) is turned into play-clock time when it arrives; no press arrives while frozen.
  With no freeze since launch the play clock equals uptime, so every other rule reads the same.

**R9. App to background** (Input & Key Filter: Inactive). The queue is cleared and the current reveal settles to
formed with its hold passed (Luan, K-15), with `formedAt` the play-clock time of the settle, as in R8. On return, the formed creature is on stage and the next press starts at
once. Time spent in the background never counts towards anything.

**R10. Resting signal for the Parade.** The queue publishes `restingSince`: when the queue is empty and
`current` is formed, `restingSince = current.formedAt`; otherwise none. The Parade starts when its own rule
holds: `restingSince ≠ none` and `now ≥ restingSince + (revealLen − formedS) + parade_delay_s` (Parade F2; the
delay and what a press during the parade does are the Parade GDD's).

**R11. Snapshot for drawing.** Each frame after `tick`, the Reveal Stage reads a snapshot: `current` (revealId,
key, origin, r0, formed) and the queue's keys in order (for the tokens, art bible §3). The snapshot is read-only.

**R12. Sources are equal.** A hardware key, a hint (`hint(id)`) and a keyboard-row key follow exactly the same
rules. Only `origin` differs, and it is passed through to the Reveal Stage (the glyph rises from it, art bible §7).

**R13. Data, not code.** `hold_s`, `queue_max` and `formed_timeout_s` live in a bundled data file (the queue
data), validated at build time (F-ranges in Tuning Knobs): a value missing, not a number or out of range fails
the build. `word_offset_s` and `hold_ext_max_s` are Audio & Voice's values, read from its data. No timing is
hard-coded.

### States and Transitions

| State | Meaning | Leaves to |
|---|---|---|
| **Empty** | no `current` (first launch into Play) | Revealing (a press starts at once) |
| **Revealing** | `current` not yet formed | Holding (on `formed` or the timeout) |
| **Holding** | `current` formed, `now < r0 + holdEff` | Revealing (queue non-empty and hold passed → advance) or Resting (hold passes with an empty queue) |
| **Resting** | `current` formed, hold passed, queue empty | Revealing (a press starts at once) |
| **Frozen** | the gate challenge shows (R8a, K-20): no tick, no press | `resume()` returns to the state it froze in; a correct answer opens the panel (R8: clear + settle → Resting) |

The queue's contents are independent of these states except that rule R3.1 can only apply in Empty and Resting.
Panel open and background (R8, R9) move to Resting with an empty queue.

### Interactions with Other Systems

| System | Direction | Interface |
|---|---|---|
| Input & Key Filter | in | `press(p)` (R8 event) in its callback; Title `startPlay` never reaches the queue |
| Reveal Stage | out / in | `startReveal(...) → {formedS, revealLen, hasWord}`; outcomes (R4); snapshot (R11); in: `formed(revealId)`, `settle` on panel/background |
| Audio & Voice | out | outcomes for E1/E2 (R4); reads its `word_offset_s` and `hold_ext_max_s` (F1) |
| Key Table & Theme Data | in | the item at start (R6); `voiceDurations` for the word line (F1) |
| Hint Letters | out | outcomes: consume on accepted, keep on ignored (R4, K-15) |
| On-screen Keyboard Row | in (via Input) | its presses are ordinary presses (R12) |
| Parent Gate & Grown-up Panel | in | challenge shown → freeze; wrong answer or timeout → resume (R8a); panel open (correct answer) → clear + settle (R8) |
| App Shell & Title | in | Play entered with an empty queue (R3); background → clear + settle (R9) |
| Parade | out | `restingSince` (R10) |
| Accessibility | in (via Reveal Stage) | the timing set at start; the hold stays 3 s (K-15) |
| Settings Store | none | nothing of the queue is stored (Settings Store R2) |

## Formulas

**F1. Effective hold, fixed when the reveal starts.**

```
word_end = formedS + word_offset_s + word_len          (Audio & Voice F6, with formedS = T for a morph)
holdEff  = max( hold_s, revealLen, min( word_end, hold_s + hold_ext_max_s ) )
```

| Variable | Meaning | Value / range | Source |
|---|---|---|---|
| `hold_s` | the base hold while keys wait | 3.0 s (1.0–6.0); the same with Reduce Motion (K-15) | queue data |
| `revealLen` | the visible reveal length from the Reveal Stage | 2.95 s normal, 1.5 s reduced (MorphCore F5) | R6 |
| `formedS` | when `formed` is reported | T: 2.45 s normal, 1.2 s reduced | R6 |
| `word_offset_s` | gap between the cast sound and the word | 0.25 s | Audio & Voice |
| `word_len` | the word line's duration | ≤ `word_len_max_s`, 1.5 s (Key Table V15; K-53) | `voiceDurations[locale][word line]` |
| `hold_ext_max_s` | the longest a word may extend the hold | 1.5 s | Audio & Voice |
| `holdEff` | the hold of this reveal | 3.0–4.5 s with shipped values | — |

- If `startReveal` returns `hasWord` false (no word line, or the creature will not form so no word plays), the
  term `min(word_end, …)` is dropped.
- If its `voiceDurations` entry is missing at run time (despite V15), `word_end = formedS + word_offset_s +
  word_len_max_s` = **`formedS + 1.75`** (Audio F6 bound; K-53, was `+ 1.5` with the 1.25 s limit), one debug log
  line.
- The base hold is not measured from the press: it starts at `r0`.

| Case | word_end | holdEff |
|---|---|---|
| "nest" 0.5 s, normal | 2.45 + 0.25 + 0.5 = 3.20 | max(3.0, 2.95, min(3.20, 4.5)) = **3.20** |
| "triceratops" 0.904 s, normal | 3.604 | **3.604** |
| "quetzalcoatlus" 1.15 s, normal | 3.85 | **3.85** |
| "five baby dinosaurs" 1.47 s, normal | 4.17 | **4.17** |
| no `voiceDurations` entry, normal | 2.45 + 1.75 = 4.20 | **4.20** |
| any word ≤ 1.5 s, reduced (T 1.2) | ≤ 2.95 | **3.0** |
| hold_s set to 1.0 (tuning test), "nest", normal | 3.20 | max(1.0, 2.95, min(3.20, 2.5)) = **2.95** (the cap would cut the word; the build check below forbids this) |

**Build checks** on the shipped data, for both timing sets:

1. **The cap never cuts a word:** `hold_s + hold_ext_max_s ≥ formedS_max + word_offset_s + word_len_max_s`, i.e.
   `hold_s ≥ 2.45 + 0.25 + 1.5 − 1.5 = 2.70` (normal set; reduced needs 1.45; K-53, was 2.45 with the 1.25 s
   limit). The shipped 3.0 passes.
2. **The base hold covers the visible reveal** (MorphCore's constraint "normal hold ≥ T + form_s"): `hold_s ≥
   revealLen = 2.95` (normal; reduced 1.5). `holdEff ≥ revealLen` holds anyway through the `max`, but this keeps
   the 3 s rhythm from silently depending on the morph's length.

With `hold_s = 3.0` both pass. The tuning-build row above (`hold_s` 1.0) fails check 1: its word would be cut.

**F2. The accept decision** (R3), as a predicate on a press at time `t`:

```
startNow(t) = current == none
           OR ( queue.isEmpty AND current.formed AND t ≥ current.r0 + current.holdEff )
outcome     = startNow(t) ? started : ( |queue| < queue_max ? queued : ignored )
```

**F3. Mash cap.** In any burst before the next advance, at most `1 + queue_max` presses are accepted when the
stage is resting, or `queue_max` when a reveal is holding.

| Burst | Outcomes |
|---|---|
| 10 keys at once, stage resting | 1 started, 3 queued, 6 ignored (Audio & Voice's edge case: 4 chimes, 6 pings) |
| 10 keys during a hold, queue empty | 3 queued, 7 ignored |
| `queue_max = 0` (tuning test) | 1 started at rest; during a hold every press is ignored |

**F4. Waiting time.** The `k`-th queued press (k = 1…queue_max) starts at

```
start_k = (current.r0 + current.holdEff) + Σ_{j=1}^{k−1} holdEff_j     (plus at most one frame each)
```

where `holdEff_j` is the hold of the j-th reveal ahead of it. Worst case, three long words queued during the first
instant of a reveal: `3.85 + 3.85 + 3.85 = 11.55 s` until the third waiting key starts (about 2.6 s more than the
plain `3 × 3.0 = 9 s`, Audio's accepted cost, K-13). Typical: 9.0–10.5 s.

**F5. Reduce Motion.** The timing set (normal or reduced) is read when the reveal starts and locked with it. Only
`formedS` and `revealLen` change (1.2 s and 1.5 s); `hold_s` stays 3.0 s (K-15), so with Reduce Motion a creature
rests longer on stage and the pace of the queue is unchanged.

## Edge Cases

- **Nothing on stage, one press:** starts at once (R3.1).
- **A press while a creature holds, queue empty:** queued; it starts at `r0 + holdEff` (not at once), so a second
  press never cuts the first creature short.
- **A press after the hold has passed, queue empty:** starts at once; the previous creature leaves (Reveal Stage).
- **Ten keys at once:** 1 started, 3 queued, 6 ignored with pings (F3).
- **Two presses in the same callback batch:** handled in delivery order; each gets its own outcome (R3, Input R8).
- **Out-of-order timestamps:** no reordering; a stamp before `r0` counts as during the hold (R3).
- **The same key three times:** three reveals of that key, each resolving its item at its own start (Key Table
  pick rule: no immediate repeat of the item).
- **The word line has no duration entry:** the bound `formedS + 1.75` is used, one log line (F1; K-53).
- **Art, glyph or timing data missing:** the Reveal Stage's fallback gives its own `formedS`/`revealLen` and reports
  `formed` at its end (R6, R7); the queue runs unchanged.
- **`formed` never arrives** (a bug): after `revealLen + 1 s` the queue marks the reveal formed and logs; a late
  `formed` is ignored (R5, R7).
- **`formed` for an old reveal:** ignored (R7).
- **Reduce Motion toggled mid-reveal:** this reveal keeps its locked hold and timing; the next uses the new set
  (R6).
- **Panel opened with 3 keys waiting:** all three are dropped silently (no ping, no sparkle); the creature
  settles; after close the next press starts at once (R8).
- **Gate challenge shown with 2 keys waiting, then a wrong answer:** nothing is dropped; the reveal and its hold
  continue from where they froze, and the 2 keys play in turn (R8a).
- **Gate challenge, then the correct answer:** the panel opens and R8 clears and settles as usual.
- **Theme changed in the panel:** the queue is already empty; the next reveal uses the new theme (R8, Key Table §4).
- **App backgrounded mid-morph:** the queue is cleared, the creature is formed on return, the next press starts at
  once (R9).
- **A frame hitch of 200 ms:** the advance happens on the next tick; `r0` of the advanced reveal is that tick's time
  (R5), so its hold is counted from when it is actually shown.
- **A started-at-once `r0` earlier than the last tick's time** (Apple's `targetTimestamp` is the coming frame's
  time, while `p.time` is the past event time): allowed; the Reveal Stage draws `s = now − r0`, which is a few ms
  into the reveal on its first frame. Both clocks are the same uptime clock, so `s` is never negative.
- **Title screen key:** `startPlay`, not a press; the queue is empty when Play begins (R3).
- **A hint touched while the queue is full:** `ignored`, sparkle and ping, the hint stays (R4, K-15).

## Dependencies

- **Upstream:**
  - Input & Key Filter (`design/gdd/input-key-filter.md`): the press event and its delivery order (R8 there);
    the Title and Inactive states. Its Interactions already name the Press Queue.
  - Key Table & Theme Data (`design/gdd/key-table-theme-data.md`): the item at start (R3) and `voiceDurations`
    (V15). Its Interactions already name the Press Queue; this GDD answers its open line "whether a theme change
    clears the queue": it does not, and the panel has already cleared it (R8).
  - Audio & Voice (`design/gdd/audio-voice.md`): F6, `word_offset_s`, `hold_ext_max_s`; consumes the outcomes for
    E1/E2. Its F6 and Interactions already name the Press Queue.
  - MorphCore (`design/gdd/morphcore.md`): T and F5 through the Reveal Stage; its "hold ≥ T + form_s" constraint is
    F1's `revealLen` term.
- **Downstream / peers (each names the Press Queue; all written except the On-screen Keyboard Row and
  Accessibility, TASK-056 W-9):**
  - Reveal Stage: `startReveal → {formedS, revealLen}`, `formed(revealId)` exactly once, the fallbacks' lengths,
    `settle`, the snapshot (R6, R7, R11). This is the Press Queue ↔ Reveal Stage contract from the systems index.
  - Hint Letters: consume / keep by outcome (R4).
  - Parade: `restingSince` (R10).
  - Parent Gate & Grown-up Panel, App Shell & Title: clear + settle (R8, R9).
  - On-screen Keyboard Row: its presses are ordinary (R12).
  - Accessibility: the timing set picked at start (F5).
- **Decisions:** K-06 (queue of 3, ~3 s per reveal while keys wait, extras only sparkle), K-11 (reveal count for
  the seed), K-13 (word not cut, ping on overflow), K-15 (panel and background clear the queue, Reduce Motion
  keeps 3 s, ignored hint stays).

## Tuning Knobs

| Knob | Value | Safe range | Source | Effect |
|---|---|---|---|---|
| `hold_s` | 3.0 s | 2.95–6.0 (F1 build checks 1 and 2); lower values only in tuning builds | K-06, one-shot `hold_s` | how long a creature stays while keys wait; longer = calmer and slower mash |
| `queue_max` | 3 | 0–5 | K-06, one-shot `queue_max` | how many keys may wait; more = longer waits (F4), fewer = more pings |
| `formed_timeout_s` | 1.0 s | 0.5–2.0 | this GDD | how long past `revealLen` the queue waits for a missing `formed` |
| `word_offset_s`, `hold_ext_max_s` | 0.25, 1.5 | Audio & Voice | Audio & Voice | lengthen the hold for long words (F1) |

**Interactions:** raising `spread_s` or `flow_s` (MorphCore) or `form_s` (Reveal Stage) raises `revealLen` and
can push `holdEff` above `hold_s`; the F1 build check reports it. Raising `queue_max` raises the worst wait in F4
by one `holdEff` per step.

## Acceptance Criteria

Unit tests use an **injected clock** (`press` times and `tick(now)` values set by the test), a fake Reveal Stage
(returns `{formedS, revealLen}` and lets the test send `formed`) and fixed `voiceDurations`. No wall clock, no
frames, no randomness.

- **AC-1 Start at once:** GIVEN no current, WHEN D is pressed at t = 10.0, THEN `started(1, 10.0, item)` and one
  `startReveal(1, "D", …, r0 = 10.0)`.
- **AC-2 Queue during the hold:** GIVEN D started at 10.0 (holdEff 3.2), WHEN B is pressed at 11.0, THEN
  `queued(0)`; WHEN tick(13.199) after formed, THEN nothing starts; WHEN tick(13.2), THEN B starts with r0 = 13.2.
- **AC-3 Formed guard:** GIVEN B queued and D not formed, WHEN tick(13.5) (past the hold), THEN nothing starts;
  WHEN formed(1) arrives and tick(13.6), THEN B starts.
- **AC-4 Ignore when full:** GIVEN a holding reveal and 3 queued, WHEN a 4th press, THEN `ignored`, the queue is
  unchanged, and no revealId is used.
- **AC-5 Rest, then start at once:** GIVEN D formed and its hold passed with an empty queue, WHEN B is pressed,
  THEN `started` with r0 = B's time (not the next tick).
- **AC-6 No jumping:** GIVEN B queued and the hold passed but no tick yet, WHEN C is pressed, THEN `queued(1)`;
  the next tick starts B, not C.
- **AC-7 F1 table:** for each F1 row (with a fake Reveal Stage giving the normal or reduced lengths and the given
  `voiceDurations`), holdEff equals the table within 1e-9; a missing entry gives `formedS + 1.75` and one log line.
- **AC-8 Mash (F3):** GIVEN rest, WHEN 10 presses arrive in one batch, THEN outcomes 1 started, 3 queued, 6
  ignored, in press order.
- **AC-9 Outcome in the callback:** `press(p)` returns its outcome synchronously; the outcomes of N presses are N
  values in press order (checked with a recording fake for Audio, Reveal Stage and Hint Letters).
- **AC-10 revealId:** across a run with starts, queued presses, ignored presses and a panel clear, the started
  reveals get 1, 2, 3… with no gaps, and each revealId equals the press count handed to the seed.
- **AC-11 formed rules:** a `formed` for a non-current id is ignored; a second `formed` is ignored; with no
  `formed`, the reveal is marked formed at `r0 + revealLen + 1.0` with one log line, and a later real `formed` is
  ignored.
- **AC-12 Fallback lengths:** GIVEN the fake Reveal Stage returns a fallback's `{formedS, revealLen}`, THEN holdEff
  uses those, and the queue advances after `formed` at that time.
- **AC-13 Locked at start:** GIVEN a reveal started with the normal set, WHEN Reduce Motion turns on mid-reveal,
  THEN its holdEff is unchanged and the next reveal uses the reduced lengths with `hold_s` 3.0.
- **AC-14 Panel:** GIVEN a reveal mid-morph and 3 queued, WHEN the panel opens, THEN the queue is empty, the
  current reveal is formed (settle sent once), no outcome or sound is produced for the dropped presses, and the
  next press after close starts at once.
- **AC-15 Background:** the same as AC-14 for the app going to the background and returning.
- **AC-16 Theme:** GIVEN theme A active, WHEN the panel switches to theme B and closes, THEN the next started item
  comes from B.
- **AC-17 Title:** GIVEN Play just entered from the title by a key (`startPlay`), WHEN the first press arrives,
  THEN it starts at once with revealId 1.
- **AC-18 Sources equal:** the same sequence of presses from `hardwareKey`, `hint(id)` and `keyboardRow` gives the
  same outcomes and timings; only `origin` differs in `startReveal`.
- **AC-19 Hint on overflow (integration, with Hint Letters):** GIVEN a full queue, WHEN a hint is touched, THEN it
  sparkles and pings and the hint is still on screen (retained screenshot).
- **AC-20 Resting signal:** `restingSince` is none while a reveal is unformed or anything is queued, and equals
  `formedAt` once formed with an empty queue.
- **AC-21 Data:** the build fails when `hold_s`, `queue_max` or `formed_timeout_s` is missing, not a number or out
  of range, and when the F1 build check fails; no timing literal appears in the queue's code (code review).
- **AC-22 One advance per tick:** GIVEN two queued presses and a tick far past both holds, THEN only one starts on
  that tick.
- **AC-23 Gate freeze (TASK-050):** GIVEN a reveal at s = 1.0 with 2 keys queued, WHEN the gate challenge shows for
  20 s and then times out, THEN the queue still holds 2 keys, the play clock advanced 0 s during the challenge,
  and the first queued key starts at play time `r0 + holdEff` (20 s of uptime later than without the challenge). WHEN instead the answer is correct, THEN the queue
  is cleared and the reveal settles (R8).
- **AC-24 hasWord (TASK-050):** GIVEN `startReveal` returns `hasWord` false for an item that has a word line
  (`willForm` false), THEN `holdEff = max(hold_s, revealLen)`.

**NOT ASSESSED:** how the 3 s hold and the 9–11.5 s worst wait feel to a 2.5-year-old on a real device (playtest).

## Open Questions

- None open.
- **Decided (Luan, K-15, 2026-11-18):** panel open clears the queue (R8); background clears it and the creature
  is formed on return (R9); Reduce Motion keeps the 3 s hold (F5); an ignored hint stays (R4).
- **Chosen by the author:** after the panel closes, the settled creature's hold counts as passed (R8, consistent
  with R9); a theme change never clears the queue by itself (the panel already has); `formed` = `s ≥ T` for a
  morph (MorphCore F6), with `holdEff ≥ revealLen = T + form_s` covering the fade-in (F1).
