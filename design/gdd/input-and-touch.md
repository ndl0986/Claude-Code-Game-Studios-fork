# Input & Touch Controls

> **Status**: Approved (peer review: game-dev-android, 2026-11-14)
> **Author**: game-art-content (Luan decides)
> **Last Updated**: 2026-11-14
> **Last Verified**: 2026-11-14
> **Implements Pillar**: Nhỏ chơi được (Small hands can do it), An toàn cho trẻ (Safe for kids)
> **Task**: TASK-019 · Tier: standard (Player Fantasy and Tuning Knobs skipped by tier)

## Summary

Every touch goes through one set of rules. Big thumb pads sit in the safe corners of a landscape
phone. Each finger owns one pad. Play pads act the moment they're pressed; menus act when the
finger lifts inside them. Nothing ever stays stuck, and a double tap never skips a line. These
rules write down what both apps already do and QC has verified.

> **Quick reference** — Layer: `Foundation` · Priority: `Vertical Slice` · Key deps: `None` · Used by: `Combat, Mission flow, Quiz & stars, Hints, Map & timeline, Audio`

## Overview

Children of 6–10 use phones with small, imprecise, often multi-finger touches. This system
owns:
- where the pads sit (safe areas and gesture zones), and how big they are;
- how touches map to pads and buttons (press vs release, multiple fingers, sliding);
- when held input is cleared;
- the debounce and the drop rules that stop double taps and queued taps.

It does not own what a pad does (Combat, Mission flow), which pads a beat shows (Mission flow
R13), or the sounds (Audio).

Sources: P-01 (press vs release), P-04 (parity), TASK-013 (full-screen layout), and the QC
rounds: TASK-003 r3 O5/O6, TASK-007 r2 B1/B4, and the TASK-006 iOS rounds.

## Detailed Design

### Core Rules

**Layout (TASK-013 full screen)**

1. **World and screen.** Gameplay is the 1280×720 world, fitted to the screen at scale k
   (aspect kept). The backdrop and HUD extend to the real screen edges, so there are no
   letterbox bars on 20:9 phones.
2. **Safe anchoring.** Pads and HUD buttons anchor to the **true safe rect**: the screen minus
   the notch or Dynamic Island, the rounded corners, **and** the system gesture inset: on
   Android the **mandatory** system gesture insets (the bottom swipe zone), not the full
   system-gesture insets with the side back zones; on iOS the home-indicator inset. They don't
   anchor to the 1280×720 box
   (QC r3 O5: pads clear of the gesture zone).
3. **Positions.** ◀ ▶ sit bottom-left. Defend and attack sit bottom-right, with the flag pad
   above attack (only on hold-meter and training, D-10). Pause and sound sit top-left. The
   VI|EN chip is on the title and pause screens only (P-04). Story and dialogue buttons ("Tiếp",
   "Bỏ qua", ask) sit bottom-right and bottom-left as their GDDs set.
4. **Sizes and gaps.** Every pad and button is ≥ `pad_min` (72 pt/dp) across (F1), with a
   minimum gap of `pad_gap` between neighbouring pads, so a small thumb can't press two at once.

**Touch model**

5. **Per-pointer ownership.** Each pointer (finger) owns **at most one** pad at a time, so
   multi-touch works: hold ▶ with one thumb and tap attack with the other.
5b. **Track pointers by identity, never by position** (iOS QC r2, iOS-R2-03). Each pad
    remembers the **id** of the pointer that owns it. That pointer's release or cancel **always**
    releases its pad, wherever the pointer has moved (inside the pad, onto another, or off every
    pad). A pad is never released or kept held by hit-testing the release position.
6. **Tie-break.** If two pointers land on the **same** pad, the **first** one owns it. The
   second is **ignored until it lifts**. It never takes over the pad, and it doesn't activate
   another pad by sliding onto it (play pads fire only on press, Rule 7).
7. **Play pads fire on press** (P-01): move, attack, defend and flag act on pointer-down
   inside the pad.
8. **Menus fire on release inside** (P-01): "Tiếp", "Bỏ qua", the skip-warning buttons, quiz
   cards, the dialogue ask button, results, pause-menu items, the VI|EN chip and map pins act
   when the pointer lifts **inside** the same button it went down on. Lifting outside cancels.
9. **A pointer keeps its pad from down to up (or cancel).** The only change while it's down is
   the **◀ ↔ ▶ slide**: sliding from ◀ to ▶ (or back) switches the move direction as it crosses.
   Sliding off a pad, or ◀/▶ drifting into empty space, does **not** release it, because thumb
   drift is forgiven. Release comes only from up or cancel (Rule 5b) or clear-all (Rule 11).
10. **Hold.** Defend and the flag (on hold-meter) act for as long as their pointer stays down
    on them.
11. **Clear-all.** Every held pad is released, and every pressed menu cancelled, on any of:
    - a pointer cancel;
    - window or focus loss;
    - pause;
    - backgrounding;
    - an audio route change or interruption (Audio Rule 16).

    On resume nothing is held until the child presses again (Mission flow Rule 11; QC r3: "no
    input held after the lift").

**Debounce and dropped input**

12. **Press-time debounce on every advance button.** Intro, beat card, caption, ending,
    dialogue "Tiếp" and ask, quiz "Tiếp" and results all ignore a second activation within
    `advance_debounce` (0.25 s) of the last **press** that advanced (F3). This fixes QC r2 **B1**,
    where two taps 0.17 s apart skipped a beat-card line.
13. **Locked UI drops input, never queues it.** While a UI state is locked, taps are **dropped**,
    never stored for later. Locked states include the quiz card shake (0.5 s), the skip warning
    opening, the map's arrival sequence and screen transitions. This fixes QC r2 **B4**, where a
    card tapped during the shake turned lavender 0.5 s later.

**Visibility and feedback**

14. **Pads per beat.** Only the pads in the beat's `buttons` are shown (R13). Others are
    **hidden**, not greyed (Mission flow Rule 4). `walk_to` shows move only; story and dialogue
    screens show no pads.
15. **Press feedback.** Every pad and button shows a pressed state (a 4% squash) on the next
    frame. Menu presses play exactly one tone; play pads play no tap tone, only their action
    sounds (O6, Audio Rule 6).
16. **Tap vs drag** (map, timeline column): a pointer that moves more than `drag_threshold`
    (~10 pt) is a drag and never activates (Map & timeline Rule 5).
17. **Haptics** (optional, where the platform has them): a light tap on a hit, a block and the
    meter marks. Haptics follow the device's own setting, not the game's sound toggle.

### States and Transitions

Per pointer: `idle` → `down(pad or button)` → (`sliding` between ◀ ▶) → `up` or `cancelled`.
Per pad: `released` ⇄ `held(by pointer id)`.
Global: `accepting` ⇄ `locked` (Rule 13: dropped, not queued).
Clear-all (Rule 11) forces every pad to `released` and every pointer to `cancelled`.

### Interactions with Other Systems

| System | In | Out | Owner |
|---|---|---|---|
| Side-scroll movement & combat | (none) | press, hold and release of move, attack, defend (frame step 1) | Combat GDD (frame order) |
| Mission flow & beat types | the beat's `buttons`; the phase (story or play) | the visible pad set; advance taps | Mission flow GDD |
| Quiz & stars | locked during the shake | card taps (on release) | Quiz GDD |
| Hints & onboarding | (none) | pad positions for the hand | Hints GDD |
| Map & timeline | (none) | taps and drags | Map GDD |
| Audio & voice-over | (none) | menu press (one tone) | Audio GDD |
| Content data | `tuning.json` `pad_min`, `pad_gap`, `advance_debounce`, `drag_threshold` | (none) | Content contract |

## Formulas

The F1 (pad size in world px) formula is defined as:

`pad_world = pad_min / k`; `gap_world = pad_gap / k`, where k is the fitted points (dp) per world px.

**Variables:**
| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| pad_min | float (pt/dp) | 44–120 | data file (`tuning.json`, 72) | Minimum touch size |
| pad_gap | float (pt/dp) | 8–24 | data file (proposed key, 12) | Minimum gap between pads |
| k | float (pt per world px) | device | calculated (fit scale) | Device scale |

**Output Range:** ≈ 106 world px at k ≈ 0.68 (a 20:9 phone). The same formula sizes the map
pins (Map F2).
**Example:** `pad_min` 72, k 0.68 → `pad_world` ≈ 105.9; `pad_gap` 12 → ≈ 17.6 world px.

The F2 (safe-anchored position) formula is defined as:

`screen_pos = safe_edge ± (margin + pad_px / 2)`, then `world_pos = (screen_pos − world_origin_screen) / k_px`, where `pad_px = pad_min` converted to screen px.

**Variables:**
| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| safe_edge | screen px | device | platform (safe-area plus gesture insets) | The edge a pad anchors to |
| margin | pt/dp | 8–24 | UX constant ⟨/ux-design⟩ | Breathing room from the edge |
| world_origin_screen | screen px | device | calculated | Where world (0,0) lands on screen |
| k_px | float | device | calculated | Screen px per world px |

**Output Range:** a pad is always fully inside the safe rect, and never under a gesture zone.
**Example:** QC r3 O5: on 1080×2400 @ 420 dpi in full screen, the gesture zone starts at device
y 996, and pad bottoms land at 957–977: clear.

The F3 (debounce) formula is defined as:

`accept(t) = t − t_last_advance ≥ advance_debounce`, where t is the press time of the new activation.

**Variables:**
| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| t, t_last_advance | float (s) | — | clock (press time) | Times of presses that advanced |
| advance_debounce | float (s) | 0.1–0.5 | data file (`tuning.json`, 0.25) | Debounce window |

**Output Range:** boolean. At exactly 0.25 s the press is accepted (≥).
**Example:** taps at 0.00 and 0.17 s → the second is ignored (B1). Taps at 0.00 and 0.30 s →
both advance.

## Edge Cases

- **If a third finger lands while two pads are held**: it owns whatever free pad it's on, or
  nothing. Held pads are unaffected.
- **If a pointer goes down outside any pad and slides onto one**: play pads don't activate (they
  fire on press, Rule 7). Only the ◀ ▶ slide between move pads counts.
- **If a thumb holding ◀ or ▶ drifts into empty space**: the move stays held, in the same
  direction, until the thumb lifts (Rule 9). Drifting onto the other move pad switches the
  direction.
- **If a menu button is pressed and the screen changes before release** (e.g. the arrival
  animation ends): the press is cancelled; nothing fires.
- **If the child rests a palm on the screen** (many pointers at once on the bottom edge): each
  pointer follows Rule 5; extra pointers on the same pad are ignored (Rule 6). Nothing breaks.
- **If the app is backgrounded with defend held**: clear-all (Rule 11). On return defend is up,
  and the windup restarts its telegraph (Combat edge case).
- **If two advance taps straddle a screen change** (the last caption line, then the next beat):
  the debounce applies across the change, so the second tap never skips the new screen's first
  line.
- **If the device has no gesture insets or notch**: the safe rect is the screen; same rules.
- **If haptics are unavailable**: no haptics; nothing else changes.

## Dependencies

| System | Direction | Hard/Soft | Interface |
|---|---|---|---|
| Content data & claims | this depends on it | Hard | `tuning.json` keys |
| Side-scroll movement & combat | depends on this | Hard | Pad events |
| Mission flow & beat types | both ways | Hard | Visible pads; advance taps |
| Quiz & stars | depends on this | Hard | Card taps, lock |
| Hints & onboarding | depends on this | Hard | Pad positions |
| Map & timeline | depends on this | Hard | Tap vs drag |
| Audio & voice-over | depends on this | Soft | One tone per menu press |

Combat, Mission flow and Hints already list Input as a dependency.

## Visual/Audio Requirements

- Pads and buttons are specced in `design/assets/specs/mission-hud-assets.md` (ASSET-024–035)
  and `mission-flow-assets.md` (ASSET-323, 331): a plain shape with one motif accent each (Luan's
  rule 4), and a distinct outer shape plus icon per pad (colour-blind backup).
- Pressed state: a 4% squash, no colour-only change.

## UI Requirements

- 📌 **UX Flag — Input**: the pad layout per aspect ratio, the safe margins and `pad_gap` go into
  the mission HUD `/ux-design`.

## Cross-References

| This doc references | Where | What |
|---|---|---|
| Decisions | `production/team/decisions.md` P-01, P-04; board TASK-013 | Press vs release; parity; full-screen layout |
| Combat | `design/gdd/side-scroll-combat.md` frame order step 1, Rule 4 | Input read; defend drops attack |
| Mission flow | `design/gdd/mission-flow.md` Rules 4, 11, 15, 7d | Visible pads; pause clear; Skip; ask |
| Quiz & stars | `design/gdd/quiz-and-stars.md` Rule 4, AC6 | Shake lock |
| Map & timeline | `design/gdd/map-and-timeline.md` Rule 5, F2 | Drag threshold; pin size |
| Audio | `design/gdd/audio-and-voice-over.md` Rules 6, 16 | One tone; interruptions |
| QC | TASK-003 r3 (O5, O6); TASK-007 r2 (B1, B4) | Gesture zone; tones; debounce; drop |

## Acceptance Criteria

Criteria 1–9 and 13–14 are logic (unit tests on the input layer); 10–12 need QC on devices.

1. **GIVEN** ▶ held by pointer A, **WHEN** pointer B taps attack, **THEN** the hero keeps moving
   and a swing starts (multi-touch).
2. **GIVEN** pointer A on ◀, **WHEN** it slides onto ▶ without lifting, **THEN** the move direction
   switches at the crossing and no other pad fires.
3. **GIVEN** pointer A holds defend, **WHEN** pointer B lands on defend too, **THEN** nothing
   changes. **WHEN** A lifts, **THEN** defend releases, even though B is still down (Rule 6).
4. **GIVEN** a pointer down on "Tiếp", **WHEN** it lifts outside the button, **THEN** nothing
   advances (release-inside).
5. **GIVEN** a beat card on line 1, **WHEN** "Tiếp" is tapped twice 0.17 s apart, **THEN** only line
   2 shows (B1). **WHEN** the taps are 0.30 s apart, **THEN** line 3 shows.
6. **GIVEN** a quiz card shaking, **WHEN** another card is tapped during the 0.5 s, **THEN** the tap
   is dropped and no card turns lavender after the shake (B4).
7. **GIVEN** defend held, **WHEN** the app is backgrounded and resumed, **THEN** no pad is held.
8. **GIVEN** a `walk` beat (`buttons: [move]`), **WHEN** in play, **THEN** only ◀ ▶ (plus pause and
   sound) exist on screen.
9. **GIVEN** any menu button, **WHEN** pressed and released inside, **THEN** exactly one tone plays.
   **GIVEN** a play pad, **THEN** no tap tone plays (O6).
10. **GIVEN** a 20:9 Android phone in full screen, **WHEN** the mission HUD is captured, **THEN** every
    pad is fully above the gesture zone and inside the safe rect (O5). The same holds on a Dynamic
    Island iPhone in both landscape orientations.
11. **GIVEN** each pad, **WHEN** measured on the smallest supported phone, **THEN** it's ≥ 72 pt/dp
    across, with ≥ `pad_gap` to its neighbours.
12. **GIVEN** a child-sized thumb test (QC), **WHEN** pressing each pad 20 times, **THEN** no press
    activates a neighbouring pad.
13. **GIVEN** a pointer pressed on defend, **WHEN** it sends a few small move events (inside or
    outside the pad) and then releases anywhere, **THEN** no pad is held within one frame of the
    release (identity tracking, iOS-R2-03; unit test).
14. **GIVEN** the training finish step, **WHEN** the flag pad is pressed, **THEN** it counts at
    the press and the banner rises. Moving afterwards, or releasing outside the pad, doesn't
    undo it (Rule 7).

## Open Questions

| # | Question | Owner | By |
|---|---|---|---|
| — | New tuning keys (data follow-up by game-dev-android): see the list below | game-dev-android | Data follow-up |
| — | Haptics in the slice, or later? (Rule 17) | Luan | Optional |

**New tuning keys** (for `content/data/tuning.json`):

| Key | Value | Range | Unit | Used by |
|---|---|---|---|---|
| `pad_gap` | 12 | 8–24 | pt_dp | F1: minimum gap between neighbouring pads (Rule 4) |
| `drag_threshold` | 10 | 6–20 | pt_dp | Rule 16 (map, timeline) |

