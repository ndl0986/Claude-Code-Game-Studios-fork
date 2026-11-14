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

1. **World and screen.** Gameplay is the 1280×720 world, fitted to the safe rect (aspect kept).
   The fit has two names, defined once in F1: **`k`** (pt/dp per world px, for touch sizes) and
   **`k_px`** (screen px per world px, for drawing and text). Every GDD uses these two names. The backdrop and HUD extend to the real screen edges, so there are no
   letterbox bars on 20:9 phones.
2. **Safe anchoring.** Pads and HUD buttons anchor to the **true safe rect**: the screen minus
   the notch or Dynamic Island, the rounded corners, **and** the system gesture inset: on
   Android the **mandatory** system gesture insets (the bottom swipe zone), not the full
   system-gesture insets with the side back zones; on iOS the home-indicator inset. They don't
   anchor to the 1280×720 box
   (QC r3 O5: pads clear of the gesture zone).
3. **Positions.** ◀ ▶ sit bottom-left. Defend and attack sit bottom-right, with the special pad
   above attack (only on hold-meter and training, D-10). **Pause and sound sit top-left on every
   screen that has them**, so a child always looks in one place (TASK-020 W7). The VI|EN chip
   sits top-right on the title and the map, and inside the pause menu; nowhere else (P-04).

   | Screen | Pause + sound | VI\|EN chip | Other corners |
   |---|---|---|---|
   | Mission HUD (play, `walk_to`) | top-left | — | progress dots and goal top-centre; pads bottom |
   | Story screens and dialogue | top-left | — | "Tiếp" / ask bottom-right, "Bỏ qua" bottom-left |
   | Quiz and results | top-left | — | the "Câu n/N" counter top-centre; "Tiếp" bottom-right |
   | Map (Alpha) | top-left | top-right | the timeline column as Map Rule 1 sets |
   | Title | sound top-left (no pause) | top-right | Start centre |
   | Pause menu | — (it is the menu) | inside the menu | — |
   | Unlock | none | — | one button bottom-centre |
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
7. **Play pads fire on press** (P-01): move, attack, defend and special act on pointer-down
   inside the pad.
8. **Menus fire on release inside** (P-01): "Tiếp", "Bỏ qua", the skip-warning buttons, quiz
   cards, the dialogue ask button, results, pause-menu items, the VI|EN chip and map pins act
   when the pointer lifts **inside** the same button it went down on. Lifting outside cancels.
9. **A pointer keeps its pad from down to up (or cancel).** The only change while it's down is
   the **◀ ↔ ▶ slide**: sliding from ◀ to ▶ (or back) switches the move direction as it crosses.
   Sliding off a pad, or ◀/▶ drifting into empty space, does **not** release it, because thumb
   drift is forgiven. Release comes only from up or cancel (Rule 5b) or clear-all (Rule 11).
10. **Hold.** Defend and special (on hold-meter) act for as long as their pointer stays down
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
13b. **Screen-entry lock, rolling** (QC r6 **B7**). After one of these screens is **entered
    from a different screen**, every press on it is **dropped, not queued**, until the child has
    stopped pressing for **`screen_enter_lock`** (default **0.6 s**, range 0.3–1.0), and never
    longer than **`screen_enter_lock_max`** (default **1.5 s**, range 1.0–3.0) from entry. The
    screens: a story screen (intro, beat card,
    caption, ending), a dialogue beat, the skip-warning card, the quiz, results, unlock and the
    title. **Play-phase changes inside a mission count as entering:** a beat card, a caption and a
    dialogue's first line each start the lock. Examples: play → beat card, play → caption or
    ending, walk → dialogue line 1, ending → quiz, quiz → results, results → unlock or title. The
    lock starts on the entered screen's first frame.
    - **Rolling window:** at entry, `lock_end = t_enter + screen_enter_lock`. A press at
      `t_press < lock_end` is dropped and **restarts** the window:
      `lock_end = min(t_press + screen_enter_lock, t_enter + screen_enter_lock_max)`. A press at
      `t_press ≥ lock_end` is accepted (then `advance_debounce` applies as usual). So a continuous
      mash holds the first box until the mash pauses for 0.6 s, or 1.5 s pass; a deliberate tap
      after a pause works at once; a child tapping because "nothing happens" is never held past
      1.5 s.
    - **The entry time is stamped on the press clock** (the platform's touch-event timestamps), the
      same clock as `advance_debounce` (F3). Never compare a touch timestamp with a frame or wall
      clock.
    - Its buttons (Tiếp, Bỏ qua, ask, cards) **show at once** but take no input during the lock (an
      optional subtle fade-in over the lock is allowed; nothing else changes).
    - **What it guarantees:** the first box is on screen ≥ `screen_enter_lock`, and until the child
      has stopped pressing for `screen_enter_lock` (at most `screen_enter_lock_max`); later boxes
      ≥ `advance_debounce`, one per press, nothing skipped silently.
    - **Why:** the story bottom row sits where the play pads were (Tiếp over Attack, Bỏ qua over
      ◀). In r6 a child mashing Attack every ≈ 0.35 s as reach-the-flag ended skipped both
      ending boxes; "Trần Quốc Toản đã hy sinh…" was on screen for 0.26 s, and the run landed in
      the quiz.
    - **Every story box and every dialogue line takes the rolling lock** (QC r7, for r8): each box
      of the intro, a beat card, a caption and the ending, and each dialogue line, starts the lock
      as if entered, with the same keys (no new key). Under a continued mash each one holds
      ≥ `screen_enter_lock_max` (1.5 s), so the hero's plea, the king's words and "…đã hy sinh…"
      can't be mashed past. A child of 6–10 can't read a box in under 0.6 s, so a deliberate
      reader is unaffected: one tap per box after a 0.6 s pause. `advance_debounce` still applies.
      An ask tap ("Xin vào!") is a line advance too, so two quick ask taps advance one line.
    - **The quiz keeps its own rules:** the next quiz question takes no lock (only the debounce),
      except on small phones (below).
    - **One exception, small phones only:** in the quiz's small layout (`quiz-and-results.md`
      §5.2: the reference cards' bottom would pass Tiếp's top, k < ≈ 0.533, which includes both reference phones) Tiếp lies over
      the third card slot, so a second tap on Tiếp could pick a card on the next
      question. There, each new question takes the lock too. The lock follows the layout's own
      flag, never a separate k test.
    - **Pause and sound are exempt** (top-left, nowhere near the play pads; a child must always be
      able to pause), and so is the pause menu.

**Visibility and feedback**

14. **Pads per beat.** Only the pads in the beat's `buttons` are shown (R13). Others are
    **hidden**, not greyed (Mission flow Rule 4). `walk_to` shows move only; story and dialogue
    screens show no pads; training shows the pads of its current step (Mission flow Rule 7c).
    **Hiding is not releasing.** A hidden pad produces no input, but a pointer that owns it keeps
    it (Rule 9). If that pointer is still down when the pad shows again, the hold continues.
    Release comes only from up, cancel (Rule 5b) or a Rule 11 trigger. A phase change is not a
    Rule 11 trigger.
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
| Content data | `tuning.json` `pad_min`, `pad_gap`, `advance_debounce`, `drag_threshold`, `screen_enter_lock` | (none) | Content contract |

## Formulas

The F1 (pad size in world px) formula is defined as:

`k_px = min(safe_w / 1280, safe_h / 720)`; `k = k_px / density`; `pad_world = pad_min / k`; `gap_world = pad_gap / k`.

This is the **one definition** of the fit scale. `k` is pt (iOS) or dp (Android) per world px;
`k_px` is screen px per world px; `density` is screen px per pt/dp (Android dpi / 160, iOS the
screen scale). Language Rule 6 and Map F2 use these names.

**Variables:**
| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| pad_min | float (pt/dp) | 44–120 | data file (`tuning.json`, 72) | Minimum touch size |
| pad_gap | float (pt/dp) | 8–24 | data file (proposed key, 12) | Minimum gap between pads |
| safe_w, safe_h | screen px | device | platform (safe rect, Rule 2) | Safe rect size |
| density | float | device | platform | Screen px per pt/dp |
| k_px | float (screen px per world px) | device | calculated | Drawing scale |
| k | float (pt/dp per world px) | device | calculated | Touch scale |

**Reference phones** (the test devices; "the reference phones" in any AC means these, r8e):
- **Android: the QC and dev AVDs** (pixel_7, devandroid002 and mp17863), 1080×2400 @ 2.625,
  measured **k ≈ 0.488** (confirmed by game-dev-android, r8): `pad_min` 72 → ≈ **148** world px.
- **Geometry example (k 0.527, no test device):** the same 1080×2400 @ 420 dpi (density 2.625)
  panel with only the mandatory gesture inset, safe height 996 px (F2): k_px = 996 / 720 =
  **1.383**; k = 1.383 / 2.625 = **0.527 dp per world px**. Worked numbers labelled "k 0.527"
  across the GDDs and UX specs use it; they are geometry, not a device. No Android test device
  runs at 0.527.
- **iOS: a 6.1" Dynamic Island iPhone**, 852×393 pt landscape (scale 3), safe rect ≈ 734 × 372
  pt after the side and home-indicator insets. k = min(734/1280, 372/720) = **0.517 pt per
  world px**; k_px = 1.55. Re-checked: the iOS QC iPhone 18 Pro measures **k 0.517**; the
  dev-ios phone **0.529**.

**Output Range:** `pad_world` ≈ 136–148 world px on the reference phones (148 Android, 139
iOS QC, 136 dev-ios). A smaller k (a smaller
phone) makes pads bigger in world px. The same formula sizes the map pins (Map F2).
**Example** (the geometry example, k 0.527): `pad_min` 72 → `pad_world` = 72 / 0.527 ≈ **137** (what Android's
`ScreenFit` draws); `pad_gap` 12 → ≈ **23** world px. Two pads plus a gap take ≈ 297 of the
720 world px height. Android AVDs (k 0.488): 72 / 0.488 ≈ 148; 12 / 0.488 ≈ 25. iOS QC: 72 / 0.517 ≈ 139; 12 / 0.517 ≈ 23.

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
  line; the screen-entry lock (Rule 13b) also drops it.
- **If a pointer is already down on a play pad when the screen changes** (a thumb held on Attack
  as the beat ends): it **never activates a menu button**. A menu button fires only for a pointer
  that went down on it after the screen appeared and after the lock (Rules 8, 13b). The held
  pointer is ignored by every menu button until it lifts.
- **If a child mashes Attack through a beat end** (≈ 0.35 s apart): every press restarts the
  rolling lock, so the caption's or ending's first box holds until `screen_enter_lock_max`
  (1.5 s); after that, presses advance one box per press under `advance_debounce`, and nothing
  is skipped silently. **Every later story box and dialogue line holds the same way** (each takes
  the lock). A child who stops for 0.6 s and then taps advances at once.
- **If the device has no gesture insets or notch**: the safe rect is the screen; same rules.
- **If haptics are unavailable**: no haptics; nothing else changes.
- **If a thumb stays on a pad while a story or dialogue screen hides it** (e.g. ▶ through the
  Bình Than dialogue): the pad gives no input while hidden. When `walk_to` shows it again and the
  same pointer is still down, the hold continues and the hero walks on (Rule 14). Thumb drift is
  forgiven, so this is intended. It is released only by up, cancel or Rule 11.
- **If a training step reveals a new pad under a thumb that's already down**: the pad does not
  fire. Play pads fire on press (Rule 7), so the child must press it.

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

Criteria 1–9, 13–15 and 17–22 are logic (unit tests on the input layer); 10–12 and 16 need QC on devices.

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
14. **GIVEN** the training finish step, **WHEN** the special pad is pressed, **THEN** it counts at
    the press and the banner rises. Moving afterwards, or releasing outside the pad, doesn't
    undo it (Rule 7).
15. **GIVEN** ▶ held by pointer A when a dialogue screen opens, **WHEN** A stays down through the
    dialogue and the next `walk_to` starts, **THEN** no move input happens while the dialogue
    shows, and the hero moves right as soon as ▶ is visible again, with no new press (Rule 14).
16. **GIVEN** the reference phones, **WHEN** each screen in the Rule 3 table is captured, **THEN**
    pause and sound are top-left on every screen that has them, and the VI|EN chip shows only on
    the title, the map and in pause.
17. **GIVEN** the TQT reach-the-flag beat ending with Attack pressed every 0.35 s for 3 s through the
    beat end (a scripted trace, on both apps), **WHEN** the ending shows (entry t = 0), **THEN** the
    presses at 0.35, 0.70, 1.05 and 1.40 s are dropped (not queued); box 1 holds until 1.5 s
    (`screen_enter_lock_max`); the press at 1.75 s shows box 2, which takes its own lock (AC21); and
    the quiz starts only after each ending box has been advanced once.
18. **GIVEN** a thumb held down on Attack as a caption appears, **WHEN** it slides onto Tiếp and
    lifts, **THEN** nothing advances (a pointer that went down before the screen never fires a
    menu button).
19. **GIVEN** a caption that appeared 0.2 s ago, **WHEN** pause is tapped, **THEN** the game pauses at
    once (pause and sound are exempt from the lock); **GIVEN** no press since entry, **WHEN** a press
    comes at 0.59 s (touch timestamp vs the entry stamp), **THEN** it is dropped (and the window
    moves to 1.19 s); **GIVEN** no press since entry, **WHEN** the first press comes at 0.60 s,
    **THEN** it is accepted (same press clock as F3).
20. **GIVEN** a caption entered at t = 0, **WHEN** presses come every 0.3 s from 0.3 s, **THEN** the press
    at 1.49 s is dropped and the press at 1.50 s is accepted (the `screen_enter_lock_max` cap);
    **GIVEN** a single press at 0.2 s, **WHEN** the next press comes at 0.79 s, **THEN** it is dropped,
    and **WHEN** it comes at 0.80 s instead, **THEN** it is accepted (the rolling window,
    `lock_end` = 0.2 + 0.6).
21. **GIVEN** the ending (2 boxes) and Next pressed every 0.35 s from its entry, **WHEN** the presses run
    on, **THEN** presses at +0.35 … +1.40 are dropped and +1.75 shows box 2; presses at +2.10 … +3.15
    are dropped and +3.50 starts the quiz. Each box is on screen ≥ `screen_enter_lock_max` (1.5 s), and
    every dropped press is dropped, not queued.
22. **GIVEN** the Bình Than dialogue (9 lines) and a press every 0.35 s on the button's spot from its
    entry, **WHEN** the presses run on, **THEN** each line holds ≥ 1.5 s (the press at +1.75 s after a
    line appears advances it), no line is skipped, and a deliberate tap 0.6 s after the previous
    press advances at once.

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
| `screen_enter_lock` | 0.6 | 0.3–1.0 | s | Rule 13b: the rolling quiet window after a story, dialogue, quiz, results, unlock or title screen is entered (QC r6 B7; TASK-005p) |
| `screen_enter_lock_max` | 1.5 | 1.0–3.0 | s | Rule 13b: the cap on the rolling lock from entry (TASK-005q) |

