# Interaction Pattern Library

> **Status**: In Design
> **Author**: game-dev-android (TASK-112), from the GDDs (no new rules)
> **Last Updated**: 2026-11-18
> **Template**: Interaction Pattern Library

---

## Overview

The game has two audiences with different patterns. The **child** (2.5–3, cannot read) presses keys and taps the
stage: every press answers at once, nothing has to be read, found or learned (Input R2–R7; art bible §7). The
**grown-up** reaches settings through a deliberate gate (a moon hold or the Mac chord, then a four-digit challenge)
and uses a plain panel of standard controls (Parent Gate G1–G10). This library is **minimal and drawn from the
GDDs**: each pattern cites the rules that define it; anything the GDDs do not say is in Gaps or Open Questions, not
invented here. Platforms: iPadOS (touch, optional hardware keyboard) and macOS (keyboard, mouse or trackpad);
Android NOT ASSESSED.

---

## Pattern Catalog

| # | Pattern | Audience | One line |
|---|---------|----------|----------|
| P1 | Key press → reveal | child | any letter or digit key, hint tap or row key becomes a press; the Press Queue starts, queues or ignores it |
| P2 | "I heard you" answer | child | every press answers at its origin in the same callback: star + chime, or sparkle + ping |
| P3 | Any tap starts (Title) | child | any letter/digit key or any tap except the moon starts play |
| P4 | Moon hold → Parent Gate | grown-up | hold the moon 1.5 s (or ⌃⌥⌘Q on the Mac) to open the challenge |
| P5 | Gate digit entry | grown-up | enter four digits shown as words; one wrong digit closes; Cancel / Esc closes with no penalty |
| P6 | Panel controls | grown-up | standard ≥ 44 pt controls with On/Off text; slider previews while dragging |
| P7 | Hold to confirm | grown-up | destructive actions need a 1.5 s hold on a separate button |
| P8 | On-screen keyboard row | child | a short word's letters as keys along the bottom; a tap is a press |
| P9 | Reduce Motion variants | both | the same patterns, gentler motion, from the OS flag |

---

## Patterns

### P1. Key press → reveal

- **What it is:** the core loop. One input becomes one press, and the press becomes a reveal now, later, or not at
  all.
- **Inputs and how they resolve:**
  - **Hardware key** (Input R2): numpad digit first, then the base-level character folded to A–Z / 0–9, then the
    US-QWERTY position. Ctrl, Alt, Cmd and Fn disqualify a key; Shift, Caps Lock and Num Lock are ignored (R3).
    Only the first down counts; repeats and held keys are ignored (R4).
  - **Touch** (Input R7), by layer: 1 a hint (a press, even while fading), 2 a keyboard-row key (a press), 3 the
    moon (P4), 4 a creature tap (a hop), 5 the empty stage (a sparkle). Each pointer is classified on its own; on
    overlapping hints the nearest wins.
- **The press:** `{key, source, time, origin}` (Input R8). The origin for a hardware key is the matching hint's
  centre if one shows, else the matching row key's centre when the row is on, else the keyboard anchor (640, 700)
  (Reveal Stage R2).
- **The Press Queue decides** (Press Queue R3): start at once if nothing is showing, or if the current reveal is
  formed, the queue is empty and the hold has passed (`hold_s` 3.0 s, locked at start, F1); else queue if fewer
  than `queue_max` (3) wait (FIFO); else ignore. A queued press adds a token at the top right (Reveal Stage R6).
- **Answer:** P2, in the same callback, for every outcome.
- **Not a press:** on the Title a key gives `startPlay` (P3); in the gate challenge nothing reaches the queue
  (Input states; Press Queue R8a).

### P2. "I heard you" answer

- **What it is:** the rule that every press answers at once, so a press is never lost to the child (Pillar 1).
- **Behaviour** (Press Queue R4; Reveal Stage R6; Audio E1, E2):

  | Outcome | At the origin | Sound | A touched hint |
  |---|---|---|---|
  | `started` / `queued` | Starlight four-point star | chime E1 | consumed with a 10-spark burst (Hint Letters R8) |
  | `ignored` (queue full) | 8-speck sparkle burst | ping E2 | stays, holds still, restarts its life (Hint Letters R8) |

- **No colour or sound alone:** the star backs the chime; the sparkle backs the ping (Accessibility A6, A9).
- **A started reveal** also fires E6 at s = 0 (Reveal Stage R6).

### P3. Any tap starts (Title)

- **What it is:** the Title's single affordance; the play button is a visual cue, not the only target.
- **Behaviour** (App Shell R3): any letter or digit key, or any tap except the moon, starts play; the E5 chime plays
  and the play button lights at once. Other keys do nothing (system keys pass, Input R5). A moon touch goes to P4.
- **The start is not reveal 1:** Play opens on an empty stage; the key that started play makes no press until it
  goes up and down again (App Shell R3; Press Queue AC-17).
- **While the theme loads:** one pending start; Play enters when the theme is ready; extra starts are absorbed;
  going to the background drops it (App Shell R3).
- **No touch floor** for the play button (Accessibility A7).

### P4. Moon hold → Parent Gate

- **What it is:** the grown-up's deliberate way in, hard for a toddler to trigger by accident.
- **Target:** a circle of 50 stage px around the crescent, ≥ 44 pt across, with 20 pt slop (`moon_slop_pt`)
  (Parent Gate G1; Input layer 3).
- **Hold:** `gate_hold_s` 1.5 s opens the challenge (at 1.50 s, not 1.49 s; G1 B2). A Starlight ring fills as
  `t_held / 1.5` and never pulses (G1 F1). Lifting, a cancel, or leaving the slop resets it and empties the ring.
  A second pointer on the moon is ignored; a pointer that was on the moon when the challenge closed must lift
  before a new hold starts (G1 B4). Play continues during the hold; the freeze starts when the challenge opens.
- **Mac alternative:** ⌃⌥⌘Q, exactly (Shift and Caps Lock ignored, Fn disqualifies), on the Title and in Play, kiosk
  on or off; no chord on iPadOS (Parent Gate G2; Input R6; K-26).
- **Sleep:** after a wrong answer or a timeout the moon and chord sleep 10 s (`moon_sleep_s`), invisibly; Cancel,
  Esc and the background start no sleep (G1 B3, G2).
- **VoiceOver:** one element, "Grown-ups", hint "Double-tap and hold to open settings" (Parent Gate Edge Cases;
  Accessibility A8).

### P5. Gate digit entry

- **What it is:** a challenge a grown-up reads and a toddler cannot.
- **Shown** (Parent Gate G3): a new four-digit code each time, written in words ("Enter four · one · seven · two"),
  never numerals and never spoken; a keypad 1 2 3 / 4 5 6 / 7 8 9 / 0 with keys ≥ 60 pt and gaps ≥ 12 pt; four
  dot slots; a Cancel button apart from the keypad. Deliberately dull: no sound, animation, shake or red.
- **Entering:** a digit enters on touch down or accessibility activation. Hardware digits (main row and numpad)
  arrive as `gateDigit`, and their release as `gateDigitUp`; a key held from before the challenge is ignored until
  released (Input R8; G3). Any new digit input while another is still down is wrong, including a keypad touch while
  a digit key is down (G13 B7); two keypad pointers are wrong unless the first lifts within 0.15 s of the second's
  down (`overlap_grace_s`, G3 B6).
- **Outcomes:** the first wrong digit closes at once and starts the sleep (G3, G4); the fourth right digit opens the
  panel (G6); Cancel or Esc (`gateCancel`) closes with no sleep (G3, G4); a 20 s timeout from the last accepted
  digit closes with sleep (`challenge_timeout_s`; G3 B5). The closing touch never reaches Play (G4).
- **While shown:** play is frozen (G5; Reveal Stage R8).
- **VoiceOver:** the code reads "Enter four, one, seven, two"; focus lands on it; entered digits read "dot"
  (Parent Gate Edge Cases).

### P6. Panel controls

- **What it is:** the grown-up panel, a centred card over the dimmed stage, in the same window (App Shell R7).
- **Controls** (Parent Gate G7): volume slider (11 steps; a preview gain while dragging, the write on release,
  Settings Store R4), mute, the silent-mode note (iPadOS), theme (hidden in the MVP), weather + windy (once the Scene
  ships), keyboard row, child lock + Quit (macOS; Quit only while the kiosk mode is on), Guided Access text and
  state (iPadOS), the privacy page, "Start over", "Back to play".
- **Targets and text:** every target ≥ 44 pt, Dusk Blue `#46558f`, 15–22 pt regular; switches show On/Off text as
  well as colour (G7; Accessibility A6, A7). Dynamic Type: the card scrolls (AC-32).
- **Closing** (G9): "Back to play", Esc, the 60 s idle auto-close (`panel_idle_s`, reset by a control touch, scroll
  or key down; hard cap 300 s; G10), or the background. No tap-outside close. The dim fades out over 0.3 s and the
  next press starts at once.
- **Mac notice:** closing with the lock off shows "Child lock is OFF" at the top right for 3 s; touches pass
  through it (G9).

### P7. Hold to confirm

- **What it is:** protection for actions that lose state or release the lock.
- **Behaviour** (Parent Gate G8): "Start over", "Quit" and turning the child lock **off** show a separate "Hold to
  confirm" button on the opposite side, held 1.5 s; it hides after 5 s unused. Turning the lock on needs no
  confirm. "Start over" leaves the panel open (G7).

### P8. On-screen keyboard row

- **What it is:** an optional row of big letter keys for a child without a hardware keyboard (K-29).
- **Shown** (Keyboard Row R7–R9): off by default; when on, hidden on the Title, fades in over 0.3 s on entering Play,
  shown even with a hardware keyboard, fully visible and active during a parade, under the dim and not touchable
  in the panel.
- **The word** (R2a–R2c; K-29): a short common word from the theme's `rowWords` (Dinosaurs: REX … BUS), random with
  no immediate repeat; a new word once every letter has been pressed (any source, any outcome) and on each Play
  entry, only at a quiet moment, with 0.3 s fades out then in.
- **Keys** (R3, R4): drawn 128 × 118 units with 16 units between; hit rect 144 × 134 units (meets the 18 mm floor,
  F2); cream keys, Letter Gold letters; at most 8 letters.
- **A tap** (R5): a P1 press (`source = keyboardRow`, origin = the key centre); the key lights with a glow and
  scale 1.08, fading over 0.35 s. A hardware or hint press of a letter in the word lights every matching key; a
  hardware glyph rises from the leftmost match.

### P9. Reduce Motion variants

- **What it is:** the same patterns under the OS Reduce Motion setting, read through Accessibility's one flag
  (Accessibility A1), never an in-app switch.
- **Timing:** reveal-locked parts change from the next reveal; ambient parts on the next frame (A2; K-29).

  | Pattern | Under Reduce Motion | Source |
  |---|---|---|
  | P1 | reduced timing set, locked at reveal start; glyph rises with no overshoot; creature pops with no overshoot; leaving creature fades, no sink; `hold_s` stays 3.0 s | Reveal Stage R9; Press Queue F5 |
  | P2 | sparkles unchanged; a consumed hint fades over 0.3 s instead of the burst | Reveal Stage R9; Hint Letters R10 |
  | P3 | the play button breathes at half amplitude | App Shell R2, F2 |
  | P4 | the ring fills with no pulse | Parent Gate UI Requirements |
  | P5, P6, P7 | challenge and panel appear and leave with no fade; the dim is instant; the confirm ring fills the same way; the lock notice disappears with no fade | Parent Gate G4, G9, UI Requirements |
  | P8 | no `press_scale`; the glow and fades remain | Keyboard Row R7 |

---

## Gaps & Patterns Needed

- **Moon ring geometry** (size, stroke, placement beyond "Starlight ring") is not stated (Parent Gate UI
  Requirements); needed by the Title and Play UX specs.
- **Chord feedback:** no visual answer is defined for the ⌃⌥⌘Q chord, nor for a chord ignored during sleep.
- **Panel layout:** G7 lists the rows but no order, grouping, or per-row text size within 15–22 pt; no wireframe.
- **Cancel and keypad visual states:** only a "pressed state" is mentioned (G3).
- **Row keys and hints for VoiceOver:** no label or hint is stated (the child side is not designed for VoiceOver,
  Accessibility A8; what VoiceOver does there is NOT ASSESSED, its Q4).
- **The "I heard you" duration:** the star's and chime's timings are not stated beyond Audio E1 / E2 and the
  sparkle's 0.6–1.0 s life.
- **Keyboard row during its word change:** a touch on an old key during its fade-out presses the old letter
  (R2c, AC-10); stated, but a pattern note may be wanted.
- **Android:** every pattern's Android form is NOT ASSESSED (its ADR).

---

## Open Questions

| # | Question | Owner |
|---|---|---|
| OQ-1 | Moon ring geometry and look (size, stroke width, position relative to the crescent) | Parent Gate owner / art |
| OQ-2 | Should the Mac chord have a visual answer (and an ignored-chord answer during sleep)? | Parent Gate owner |
| OQ-3 | Panel row order, grouping and text sizes | Parent Gate owner (for its UX spec) |
| OQ-4 | VoiceOver labels for the child's hints and row keys, or a stated decision that they have none | Accessibility / Parent Gate owners |
| OQ-5 | Player journey map not yet created (`design/player-journey.md`); author it from `.claude/docs/templates/player-journey.md` | producer / UX |
