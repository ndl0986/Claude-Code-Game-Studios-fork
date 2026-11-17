# Hints & Onboarding

> **Status**: Approved (peer review: game-dev-ios, 2026-11-14)
> **Author**: game-art-content (Luan decides)
> **Last Updated**: 2026-11-14
> **Last Verified**: 2026-11-14
> **Implements Pillar**: Nhỏ chơi được (Small hands can do it), Sống lại câu chuyện (Live the story)
> **Task**: TASK-008 · Tier: standard (Player Fantasy and Tuning Knobs skipped by tier)

## Summary

The game teaches itself without words. A cartoon hand points at each button the first time a
beat needs it, until the child uses it. If a child gets stuck, a pulse or an arrow shows what to
do next after a few seconds. There is no tutorial level, no text to read, and no hint ever
blocks play.

> **Quick reference** — Layer: `Feature` · Priority: `Vertical Slice` · Key deps: `Mission flow & beat types, Side-scroll movement & combat, Input & touch controls, Audio & voice-over`

## Overview

Many players are 6 years old and can't read yet, so onboarding is visual (and voiced, once
voice-over exists). It is built into the story beats, not added before them. The first beat
that needs a button teaches it (Mission flow Core Rule 5).

This system owns two kinds of help:
- **Teach hints:** a pointing hand on a new button until it is used once.
- **Stuck hints:** a pulse or arrow after `hint_delay` seconds without progress.

It reads events from Mission flow and Combat and draws over the HUD. It never changes rules,
timers or difficulty.

Source: the TASK-003 prototype (`203d73e`, `index.html` `hand()`, `arrowDown()`, the `tut`
flags, `stall`/`idle`), plan reviews 1–2, and QC O2 (hints count from the caption closing).

## Detailed Design

### Core Rules

1. **No words.** Hints are drawn shapes: a cartoon hand, a pad pulse, a bouncing arrow. No hint
   has text. **Post-slice**, once voice-over exists, a short voice prompt per hint is added
   (Audio GDD).
2. **Teach hints** show the first time, in a mission run, that a beat needs a button:

| Teach | Shows when | Where | Ends when |
|---|---|---|---|
| move | Slice: during `walk_to[0]` (walking to beat 1) while the hero hasn't moved right yet. Later: the first beat with `move` | Hand on ▶ + ▶ pulses | The hero moves right once |
| attack | The first enemy or dummy is on screen and no hit has landed yet | Hand on attack | The first hit lands |
| defend | An enemy or practice partner is in `windup` and the child hasn't blocked yet in this run | Hand on defend, only while a windup is showing | The first block |
| special (tap) | Training's finish step starts and special hasn't been tapped yet (no special in combat, D-10) | Hand on special | The first tap |
| special (hold) | A `hold-meter` beat starts | Hand pressing and holding on special, with the meter ring glowing | The meter passes 25% |

3. **One teach hint at a time.** Priority: move, then attack, then defend, then special. A
   lower one waits until no higher one is showing. In the prototype, the defend hand shows only
   while an enemy is winding up, so it never covers the attack hand. **In a training beat, teach
   hints follow the step order** (dummies → blocks → flag): the flag hand shows only once the
   finish step is current, never at training start (QC r2 B3).
4. **Stuck hints** show after `hint_delay` (5 s) without progress:

| Situation | "Progress" means | Hint |
|---|---|---|
| walk, and walking between beats | Any movement, left or right (prototype: `if (mv) idle = 0`) | ▶ pulses |
| fight, encounter | A hit landed | An arrow over the nearest non-fleeing enemy + attack pulses |
| training | The current step advanced (dummy hit, block, special tap) | Pulse on the pad for the current step |
| hold-meter | The meter rose | Hand on special again |
| reach-the-flag (path clear, no encounter active) | Any movement, left or right | An arrow over the flag, if it is on screen; otherwise ▶ pulses |
| dialogue (ask button showing, Mission flow Rule 7d) | An ask tap or "Tiếp" | Hand on the ask button (the button also pulses) |
| map: first view (Map Rule 8) | The open pin is tapped | Hand on the only open pin, shown at once on the first map view (not after `hint_delay`) and kept until that tap |

The stuck arrow (ASSET-034) is gold with an ink outline, never red. On banner beats it never enters
the motto bar's band; where it can't bounce above its target below the bar, it points from the side
(`design/ux/hud.md` §3.3).

5. **This system owns the no-progress timer** (`progress_timer`, called `stall`/`idle` in the
   prototype) and `hint_delay`. Mission flow and Combat only send events. **Timers reset** on progress, when a caption or beat card closes (QC O2: hints count from the
   caption closing, not from behind it), and when the game resumes from pause. **The reset on
   resume is new versus the prototype**, which froze the timers across a pause. Both apps add it on
   purpose: a child coming back from pause gets a fresh `hint_delay`.
6. **Hints never block.** A hint never pauses play, covers a pad's touch area, or stops the child
   doing something else. The hand is drawn above the pad and doesn't take touches.
   - **On banner beats every hint stays below the bar** (r9, leader's call; the same rule as the
     "!" and the stuck arrow, `hud.md` §3.3): every pixel of a hand, pulse or arrow is at
     **y ≥ 276** (bar bottom + 8). There's no exemption for a hand beside its pad: the hand
     draws above the bar, so it would cover the motto, and for a child who can't read the hand
     is the instruction.
   - **Placement:** the hand sits **above its pad** when its whole shape fits there at y ≥ 276.
     Otherwise (e.g. the special pad "Cờ" stacked above attack at small k) it sits **beside the
     pad, on the side away from the screen edge** (left of a right-hand pad), at the pad's
     mid-height, pointing sideways at it, as the stuck arrow's side fallback does.
   - Either way the hand **never covers any pad's visible square** (`pad_min` diameter; the
     touch slop is excluded), its own pad included. The hand takes no touches.
7. **Per run, not saved.** Teach flags are kept for one mission run, so a replay shows the hand
   again briefly until each button is used once. Hints saves nothing; the saved keys are listed
   in Save & progress Rule 1.
8. **No hints on story screens, with two named exceptions.** Story boxes, the quiz and results
   use their own "Tiếp" pulse (Mission flow, Quiz). This system covers play, plus exactly two
   non-play rows of Rule 4: the **dialogue ask button** (an action the child must take to move
   the story on) and the **map's first view** (Map & timeline Rule 8). A dialogue line showing
   "Tiếp" gets no hint. The map's locked-pin arrow is tap feedback owned by Map (Map Rule 3),
   not a hint.

### States and Transitions

Per teach hint: `pending` → `showing` (its "shows when" holds and no higher-priority hint is
showing) → `done` (its "ends when" happened). `done` lasts for the rest of the run.

Per stuck hint: `quiet` → `showing` (progress timer > `hint_delay`) → `quiet` (progress, a
caption or card closing, or resume).

### Interactions with Other Systems

| System | In | Out | Owner |
|---|---|---|---|
| Mission flow & beat types | beat started (type, buttons, which are new), card or caption closed, meter value, training step | (none) | Mission flow GDD |
| Side-scroll movement & combat | events `hit`, `block`, `pushed`, `windup_started`, `flee`, hero moved | (none) | Combat GDD |
| Input & touch controls | pad positions and sizes | (none) | Input GDD |
| Audio & voice-over | (none) | hint shown (post-slice: voice prompt id) | Audio GDD |
| Map & timeline | "first map view", the open pin's position; pin tapped | (none) | Map GDD |
| Content data | `tuning.json` `hint_delay` | (none) | Content contract |

## Formulas

The F1 (stuck hint trigger) formula is defined as:

`show_stuck = progress_timer > hint_delay`, where `progress_timer += dt` each play frame and resets to 0 on progress, on a card or caption closing, and on resume.

**Variables:**
| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| progress_timer | float (s) | 0–∞ | calculated | Time since the last progress (Rule 4) |
| hint_delay | float (s) | 2–15 | data file (`tuning.json` `hint_delay`, 5) | Wait before a stuck hint |
| dt | float (s) | 1/60 | engine (fixed step) | Frame step |

**Output Range:** boolean. At 2 s, hints nag a child who is just watching an enemy walk in. At
15 s, a stuck 6-year-old gives up first. 5 s is the prototype value, played through QC r3.
**Example:** in a fight with no hit, at dt 1/60 the hint first shows at step 301 (5.0167 s), the arrow and attack pulse show. A hit at 6 s
hides them, and the timer restarts.

## Edge Cases

- **If a beat's first enemy is still walking in when the fight starts**: the progress timer runs,
  but at 5 s the arrow only shows if a non-fleeing enemy is on screen. Otherwise nothing shows.
- **If the child is defending the whole time** (no hit): the stuck hint shows the arrow and
  attack pulse after 5 s. Defending is not "progress".
- **If the child is pushed repeatedly without blocking**: the defend teach hint keeps showing
  during each windup until the first block. No extra hint, and nothing is shamed.
- **If two teach hints qualify at once** (an enemy winds up before the first hit): attack shows
  first (Rule 3). The defend hand waits for the next windup after the first hit.
- **If a beat doesn't list a button** (Mission flow Rule 4: hidden pads): no hint ever points to
  a hidden pad.
- **If the game is paused while a hint shows**: the hint hides, and the timers freeze and then
  reset on resume (Rule 5).
- **If the language changes**: nothing changes, because hints have no text.
- **If a training beat has `blocks` 0**: no defend teach hint in that beat.
- **If the child uses a button before its hint shows**: the hint is `done` without ever showing.

## Dependencies

| System | Direction | Hard/Soft | Interface |
|---|---|---|---|
| Mission flow & beat types | this depends on it | Hard | Beat start, new buttons, card or caption closed |
| Side-scroll movement & combat | this depends on it | Hard | Combat events |
| Input & touch controls | this depends on it | Hard | Pad positions |
| Audio & voice-over | this depends on it (post-slice voice prompts) | Soft | Prompt ids |
| Map & timeline | this depends on it | Soft | First map view, open-pin position (map row of Rule 4) |
| Content data | this depends on it | Hard | `hint_delay` |

Mission flow (Interactions table), Combat (Interactions table) and Map & timeline (Dependencies)
all list Hints as a dependent.

## Visual/Audio Requirements

- **Hand:** a cartoon hand in the art bible's rounded style (§3), ink-brown outline (§4), with a
  1 s bob toward the pad. For a hold, it presses and stays.
- **Pulse:** the pad scales 1.0 → 1.08 → 1.0 every 0.8 s with a gold rim (§4 "interactive /
  reward"). No flashing faster than 3 Hz (accessibility).
- **Arrow:** a gold bouncing arrow above the target, readable at thumbnail size.
- **Audio:** none in the slice. Post-slice: one short voice prompt per teach hint, e.g. "Bấm vào
  đây để đi! / Tap here to walk!" (Audio GDD, with `vo` ids).

## UI Requirements

- Hints draw above the HUD, never inside another pad's touch area, and never over the
  goal line.
- 📌 **UX Flag — Hints & Onboarding**: include the hint overlays in the mission HUD `/ux-design`.

## Cross-References

| This doc references | Where | What |
|---|---|---|
| Mission flow | `design/gdd/mission-flow.md` Core Rules 2, 4, 5 | New buttons per beat; cards and captions |
| Combat | `design/gdd/side-scroll-combat.md` frame order, Interactions | Events only; this system owns the no-progress timer and its resets |
| Content | `content/data/tuning.json` `hint_delay` | 5 s |
| Prototype | `203d73e` `index.html` (`hand`, `arrowDown`, `tut`, `stall`, `idle`) | Behaviour |
| QC | `qa/TASK-003-android` (O2) | Hints count from the caption closing |
| Decisions | `production/team/decisions.md` P-04 (6) | The stall hint resets on a hit or a caption closing |

## Acceptance Criteria

Criteria 1–7 and 10 are logic and need unit tests (hint state from events). Criteria 8–9 and 11
need a screenshot per platform.

1. **GIVEN** the slice mission at `walk_to[0]` (later: the first beat with `move`), **WHEN** play
   starts, **THEN** the hand shows on ▶ until the hero first moves right, and never again in
   that run.
2. **GIVEN** a fight with no hit yet, **WHEN** the first enemy is on screen, **THEN** the hand is
   on attack. **WHEN** the first hit lands, **THEN** it hides for the rest of the run.
3. **GIVEN** the first hit has landed and no block yet, **WHEN** an enemy is in `windup`,
   **THEN** the hand is on defend only during that windup, until the first block.
4. **GIVEN** a fight at dt = 1/60 with `hint_delay` 5, **WHEN** no hit lands for 300 steps
   (5.0 s, compared strictly: `progress_timer > hint_delay`), **THEN** no stuck hint shows. **WHEN**
   none lands for 301 steps (5.0167 s: within one step after 5.0 s), **THEN** an arrow is over the nearest non-fleeing enemy and attack
   pulses (F1 boundary).
5. **GIVEN** a stuck hint showing, **WHEN** a hit lands, a caption closes, or play resumes from
   pause, **THEN** it hides and the timer restarts from 0.
6. **GIVEN** a `hold-meter` beat, **WHEN** it starts, **THEN** the hold hand shows until the
   meter passes 25%.
7. **GIVEN** a beat whose `buttons` doesn't include defend, **WHEN** any situation happens,
   **THEN** no hint points to defend.
8. **GIVEN** any hint showing, **WHEN** a screenshot is taken in VI and EN, **THEN** no hint
   contains text, and the screenshots are identical apart from the HUD text.
9. **GIVEN** a hint over a pad, **WHEN** the child taps the pad through the hand, **THEN** the
   pad fires (the hand takes no touches).
10. **GIVEN** a dialogue beat with the ask button showing, **WHEN** no ask tap comes for 301
    steps at dt = 1/60, **THEN** the hand points at the ask button; **WHEN** the ask is tapped,
    **THEN** it hides and the timer restarts. On a line showing "Tiếp", no hint ever shows.
11. **GIVEN** the first map view, **WHEN** it opens, **THEN** the hand is on the only open pin
    until that pin is tapped.
12. **GIVEN** the training beat's finish step (a banner beat) at k 0.40, 0.488 and 0.517, in VI and EN, **WHEN** the special-pad teach hand and, separately, the stuck pulse show, **THEN** every hint pixel is at y ≥ 276; where the hand doesn't fit above Cờ it sits left of Cờ at Cờ's mid-height, pointing at it; and no hint pixel lies inside any pad's visible square.

## Open Questions

| # | Question | Owner | By |
|---|---|---|---|
| — | Voice prompts for hints (post-slice): add a `vo` id per hint once Audio & voice-over is designed | game-art-content + audio-director | Audio GDD |
| — | Should a child who needs the stuck hint 3+ times in a fight get slower enemies? Recommendation: **no**. Difficulty never changes behind the child's back; the stars already measure mastery | Luan | After the slice playtest |
