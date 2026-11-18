# On-screen Keyboard Row

> **Status**: Approved (independent read by game-dev-android, merged 2026-11-18)
> **Author**: game-art-content for Luan (TASK-060); plan reviewed by game-dev-android
> **Last Updated**: 2026-11-18
> **Last Verified**: 2026-11-18
> **Implements Pillar**: Pillar 1 (Every Press Answers); serves Pillar 4 (Things the Child Loves) and Pillar 5 (Safe by Design)

## Summary

When a grown-up turns it on in the panel, a row of big letter keys sits along the bottom of the stage. It spells
one short, common word, such as **REX**, **NEST** or **MOON**, picked at random from the theme's word pool. A
touch-only child can then press letters they choose instead of only the three hints in the sky (art bible §7,
conflict 2). When the child has pressed every letter of the word, a new word fades in at the next quiet moment.
A row press is an ordinary press: the key lights at once, and the letter rises from that key. The row is off by
default, hidden on the Title, and kept at a safe touch size of 18 mm or more, which is why a word has at most 8
letters.

> **Quick reference** — Layer: `UI` · Priority: `Vertical Slice` · Key deps: `Input & Key Filter`, `Press Queue`,
> `Settings Store` (also reads Key Table's `rowWords` and pick function, the Reveal Stage's layout, play clock and
> press notifications)

## Overview

A child who can't use a hardware keyboard sees R E X along the bottom. Pressing X lights the X key at once, and a
glowing X rises from it and turns into the Xenoceratops. Once the child has pressed R, E and X, at least once each
and in any order, from the row, a hint or the keyboard, the row waits until the stage is calm. Then REX fades out
and, say, M O O N fades in. Mashing is answered like any other press: the key lights, and when three keys are
already waiting the press sparkles and pings (Press Queue).

This GDD owns: which word the row shows and when it changes (R2), the layout and touch size (R3, F1, F2), the look
(R4), the press feedback (R5), how the row sits beside hints, tokens and the stage (R6), its states (R7), turning
it on and off (R8), and Mac and hardware keyboards (R9).

It does **not** own: what a press does (Input R7–R8, Press Queue R3–R4, Reveal Stage), the ground lift
(`row_lift`, Reveal Stage R10), the stored switch (Settings Store `keyboardRow`), the panel switch (Parent Gate &
Grown-up Panel), the sounds (Audio & Voice E1/E2), or the word pool's contents (Key Table `rowWords`).

## Player Fantasy

**"I can press the letters myself."** The row gives a touch-only child the choice the keyboard gives an older
child. It always spells something short and familiar, so it doubles as a first word to look at. It changes once
the child has tried all its letters, which quietly invites the next ones. The grown-up turns it on for a child
who wants to pick their own letters, and nothing ever moves under the child's finger.

## Detailed Design

### Core Rules

**R1. Ownership and interfaces.**
- The row draws its keys and publishes, in stage units: each key's **hit rect** (Input R7 layer 2: below hints,
  above the moon), each key's **centre** (the press `origin`, Input R8), and the **row band** (the area
  `y ≥ 582`, the top of the hit rects), published next to the Reveal Stage's cast, glyph and token boxes (Reveal
  Stage R10), for Hint Letters to use as a clearance box (follow-up).
- A row press is an ordinary press, `source = keyboardRow` (Input R8). The Press Queue treats every source the same
  (its R12).
- The row receives **every press notification** with its key, source and outcome from the Play router, the same
  place that calls Hint Letters' `originFor` (Reveal Stage R2). It uses them for the light (R5) and the change rule
  (R2c).

**R2. Which word, and when it changes** (K-29).
- **a. The pool:** the theme's `rowWords` (Key Table schema 2, V17): at least 8 unique words, each 2–8 letters
  A–Z. Dinosaurs: REX, EGG, NEST, ROAR, DINO, BABY, MOM, DAD, SUN, MOON, STAR, CAT, DOG, BALL, HAT, BUS (Luan,
  K-29; no people's given names). **Fallback:** for a v1 theme without `rowWords`, or a pool that fails V17 at
  load, the row uses the first cast `name` of 2–8 letters in canonical order (Dinosaurs: FOSSIL), else "ABC"; one
  debug log line (Key Table Edge Cases). *(KR-Q11)* "Canonical order" is the Key Table key order (A–Z, then 0–9),
  each key's items in data order. A `name` is upper-cased and **skipped if it then holds anything but A–Z**
  (a space, a hyphen, a digit: "T-Rex", "three baby dinosaurs"); the first one of 2–8 letters wins. With the fallback the word never changes (a pool of one).
- **b. The pick** (TASK-059 rule): one injectable 64-bit **`rowSeed`** per launch, its own random stream (separate
  from the morph, hint and item streams), logged in debug builds. Each draw uses **the same uniform no-repeat function
  as Key Table F1** (every weight 1, `last` = the current word's index), driven by an injected `RandomSource`. Test
  fixtures feed draws, not seeds (F4).
  - *(KR-Q1)* `last` is **the last word shown in this run**, kept across a Title entry and a turn-off; the very first
    draw after launch has none. F1's draw rule applies as is: no draw for a pool of one, nor for a pool of two with
    `last` set (Key Table F1, |C| ≥ 2).
- **c. When it changes** (K-29):
  - **Trigger:** the word becomes **due** when **every distinct letter of it has been pressed at least once** since
    it appeared. "Pressed" means **any press event of that key, from any source** (row, hardware key or hint),
    **with any outcome** (started, queued or ignored). For a repeated letter (EGG) each distinct letter needs one
    press: E and G.
  - **Also on each entry to Play** (from the Title, including after a long background, K-22): a new word is drawn,
    and it fades in with the row.
  - **The pressed set** *(KR-Q4)* starts empty **when a newly drawn word's keys start to fade in** (a change, a Play
    entry or a turn-on), and only presses from then on count for it. A short-background return keeps the same word
    **and its pressed set** (R7, AC-14). A press before that, including a tap on an old key during its fade-out, counts only for the
    old word, which is already being replaced.
  - **Only at a quiet moment** *(KR-Q5: checked every frame; the change starts on the first frame where the word
    is Due and the moment is quiet; a word fading in is not yet Due-checkable, see KR-Q9)*: a due word changes only
    when (1) **no pointer is down whose current position is** on any row key's hit rect (a pointer that started on
    a key and moved off no longer blocks; one that started elsewhere and moved onto a key does),
    and (2) **the stage is quiet**: the Press Queue has no current reveal (Empty), or `restingSince ≠ none`
    (current formed, queue empty, its R10). Not under the gate freeze, the panel or the background.
  - **The change:** the **new word is drawn at the start of the change** (the quiet moment; KR-Q3), the old keys fade
    out over `word_fade_s` (0.3 s), then the new ones fade in over 0.3 s. Every row and word fade is **linear in
    alpha** (KR-Q8). A word **fading in cannot start a change**: a word that is already Due (for example after a
    background return, KR-Q9) waits until its fade-in has finished (Showing), then for the next quiet moment. The old
    keys stay touchable until their fade-out ends; the new ones are touchable from the start of their fade-in. A
    key never changes letter under a finger.
  - **Clock:** the due state, the quiet-moment check and both fades run on the **play clock** (Reveal Stage R8), so
    they hold under the gate freeze.
- **d. Repeated letters:** a word shows its letters in order, including repeats (EGG has three keys, so it reads as
  the word). Each key is a press of its letter.

**R3. Layout and touch size** (F1, F2; K-20).
- **Inside the safe stage**, like hints and tokens: one row centred on x 640. Each key is drawn **128 × 118** units
  with a **16** unit gap (the first prototype's DINOSAUR row). The key top is at **y 590** with a 12-unit bottom
  margin, so centres sit at y 649.
- **Hit rect:** the drawn key plus **8** units on every side, so 144 × 134 units (art bible §7 conflict 1: a little
  larger than drawn). Keys are 16 apart, so neighbouring hit rects share an edge at the gap's centre and never
  overlap. **A touch on a shared edge goes to the key whose centre is nearest**; at an exact tie (the edge itself),
  the left key wins. This is the same nearest-centre rule Input R7 uses for overlapping hints. *(KR-Q7)* The hit
  rects are **closed**, `[cx − 72, cx + 72] × [582, 716]`, so a touch at exactly y 582.0 is on the key. A touch in
  no hit rect is not a row press; it falls through to Input R7's lower layers (the moon, the creature, a sparkle).
- **Width:** n keys take `144·n − 16` units. The word is capped at **8 letters** (V17), so the row is at most 1136
  units wide, which leaves 72 units on each side of the safe stage. At 9 letters the hit rects would reach −8 and
  1288, outside the safe stage and into Android's back-gesture insets.
- **The 18 mm floor applies to the hit rect** (Hint Letters F5 method; F2). The smallest MVP case, the
  960 × 540 pt Mac window at 2× and 254 ppi, gives 21.6 × 20.1 mm; every MVP device gives k = 1, so keys are never
  scaled up.
- **Android:** the row's hit rects must stay outside the system gesture insets, read live (Hint Letters R11). At
  n ≤ 8, 72 units is ample; **NOT ASSESSED** until an Android build exists.
- The visible rect beyond the safe stage (K-20) is the Scene's ground. The row does not stretch on a wide Mac or
  move down on a 4:3 iPad.

**R4. The look** (art bible §3, §4, §7).
- Each key is a rounded square of highlight cream `#f8efdc` (L 0.87, under the frame cap), corner radius 36% (the
  hint bubble's), with a soft ground shadow. The letter is in Letter Gold ink `#b9631c`, in the bundled rounded font,
  about **80** units tall (the hint letter size). There are no labels and no icons.
- No outline (art bible §5: UI glows, the cast has ink outlines).

**R5. Press feedback** (Pillar 1; art bible §7 UX: every press is answered).
- **Any press of a row key**, with any outcome, **lights that key at once**, and only that key (with EGG, a tap on
  the second G lights that G alone; KR-Q6): a warm glow around it
  (`rgba(255, 214, 110, 0.5)`, the halo's colour family) and a scale to `press_scale` (1.08), both fading back over
  `key_flash_s` (0.35 s, as played; F3). The outcome adds its usual answer: a starlight, a token, or the sparkle
  burst plus ping for an ignored press (Reveal Stage R4; Audio & Voice E1/E2).
- **A hardware press** of a letter in the word **lights every matching key** (K-29), light only; the glyph rises as
  Input and K-18 say (from a matching hint if one is on screen, else from the **leftmost** matching row key).
- **A hint press** of a letter in the word lights the matching keys as well, which keeps "pressed" visible.
- The glyph of a row press rises from **that key's centre**, the press origin (Reveal Stage R2).

**R6. Beside the hints, tokens and stage.**
- **Bands:** hints live in the sky band (y 150–420, Hint Letters R5); tokens sit at the top right (y 58, Reveal Stage
  R10); the row is at y ≥ 582. They never overlap. Input's layer order puts hints above the row anyway.
- **The stage moves up:** with the row on, the Reveal Stage lifts the creature anchor, the ground line and the parade
  lane by `row_lift` (110), from the next reveal (its R10). The creature stands at y 490, 100 units above the row.
- **The parade lane and the hints (accepted, noted):** with the lane at y 448, walkers (about 85 units tall) occupy
  y 363–448 and visually cross the bottom hint slots (y 410). Touch is unaffected (hints are layer 1), and K-26
  already dims hints and holds them still during a parade. There is no new clearance box; a one-line note for Hint
  Letters is a follow-up.

**R7. States and situations.**
- **Title:** hidden (K-29); it fades in over `row_fade_s` (0.3 s) when Play starts, with a newly drawn word (R2c).
- **Play:** active.
- **Gate challenge** (K-20): drawn as it is, **frozen** (lights and fades hold on the play clock). Input sends
  nothing to play during the challenge, so a touch on the row reaches the challenge only.
- **Grown-up panel:** drawn under the panel's 55% navy dim, not touchable (Input: panel state).
- **Background:** not drawn; the word and its pressed letters are **kept** in memory. A return to Play within App
  Shell's window fades the row back in (0.3 s) with the **same** word. Only a Title entry, including the Title after
  a long absence (K-22), draws a new word.
- **Parade Walking:** **fully visible and active**, not dimmed (K-29).
- **Reduce Motion** (K-16, K-29): no `press_scale` (the key lights without growing); the light and the word fades are
  kept, since they are fades, not motion. A mid-session toggle applies on the next frame (K-29: ambient UI).
- **Mac child lock** (Child Lock-in): unchanged; a mouse click on a key is a press (Input R7).

**R8. Turning it on and off** (Settings Store `keyboardRow`, default off; Parent Gate panel row).
- **On:** the row fades in over `row_fade_s` once the panel closes (it is set under the dim). Its hit rects are live
  from the start of the fade-in, and a word is drawn **at that moment, the panel's close** (not when the switch
  flips; KR-Q2), with `last` = the last word shown this run. The play clock runs under the panel (only the gate
  challenge stops it, Reveal Stage R8), but nothing about the row happens there while it is untouchable. The ground lift applies from the next reveal
  (Reveal Stage R10), so nothing on stage jumps mid-reveal.
- **Off:** the hit rects go at once, and the row fades out over `row_fade_s`; the lift is removed from the next
  reveal. The pressed set is dropped, and the word is kept only as `last` for the next draw (KR-Q10).
- The current word and its pressed letters are **in memory only** (Settings Store R2: nothing else is stored).

**R9. Mac and hardware keyboards** (K-29). The row shows **whenever the grown-up turned it on**, even with a hardware
keyboard (every Mac, an iPad with a keyboard). Detecting a keyboard is unreliable, and the choice is the grown-up's.

### States and Transitions

| State | Entered when | Touchable | Left when |
|---|---|---|---|
| **Hidden** | `keyboardRow` off; the Title; background | no | turned on in Play, or a Title → Play entry → Fading in with a **new** word; a return from a short background (App Shell's window, K-22) → Fading in with the **same** word and its pressed letters |
| **Fading in** | Play entry or turned on (a new word is drawn); return from a short background (the word is kept) | yes | 0.3 s → Showing (or Due, if the kept word was Due) |
| **Showing** | — | yes | every letter pressed → Due; off → Fading out; Title or background → Hidden (background **keeps** the word and its pressed letters) |
| **Due** | the word's letters have all been pressed | yes | a quiet moment → Changing; off → Fading out |
| **Changing** | quiet moment | the old keys until their fade-out ends, then the new ones | 0.6 s → Showing (new word) |
| **Fading out** | turned off | no | 0.3 s → Hidden |
| **Frozen** | gate challenge (play clock stopped) | no (Input sends to the challenge) | `resume()` → the state it froze in; correct answer → Under the panel |
| **Under the panel** | panel open | no | panel closed → the state it was in, or Fading in / out if the switch changed |

### Interactions with Other Systems

| System | Direction | What passes |
|---|---|---|
| Settings Store | in | `keyboardRow` and its change notification |
| Input & Key Filter | out / in | out: the key hit rects (layer 2); in: row presses become press events, `source = keyboardRow`, `origin` = key centre (R7, R8) |
| Press Queue | in | Empty / `restingSince` for the quiet moment (R10, R2c); outcomes through the Play router |
| Reveal Stage | in / out | in: `row_lift` and the layout (R10), the play clock and freeze (R8), press notifications (R2); out: the row band and key rects next to its boxes |
| Key Table & Theme Data | in | `rowWords` (V17) and the fallback; the F1 pick function |
| Hint Letters | out | the row band, for its F4 clearance boxes (follow-up); press notifications include hint presses (R5) |
| Audio & Voice | none directly | E1/E2 come from the outcome |
| App Shell & Title | in | Title vs Play entry; background and return |
| Parent Gate & Grown-up Panel | in | the panel switch writes `keyboardRow`; panel open/close (dim) |
| Parade | none | the lane moves with `row_lift` (Reveal Stage); the row is not dimmed |
| Accessibility | in | Accessibility's `reduceMotion` (its A1; never the OS API), applied on the next frame (R7) |
| Child Lock-in | none | the row works the same in a locked Mac |

## Formulas

**F1. Layout for a word of n letters** (stage units; n = 2…8).
```
pitch    = key_w + gap = 128 + 16 = 144
total    = pitch · n − gap = 144·n − 16
x0       = 640 − total / 2                    left edge of the first key
centre_i = (x0 + key_w/2 + pitch·i, 649)      i = 0 … n−1
hit_i    = [centre_i.x − 72, centre_i.x + 72] × [582, 716]
```
| n | word | total | x0 | centres x | hit rect x span |
|---|---|---|---|---|---|
| 2 | — | 272 | 504 | 568, 712 | 496 … 784 |
| 3 | REX | 416 | 432 | 496, 640, 784 | 424 … 856 |
| 4 | NEST | 560 | 360 | 424, 568, 712, 856 | 352 … 928 |
| 8 | (cap) | 1136 | 72 | 136 … 1144 (step 144) | 64 … 1216 |

At n = 9 the span would be −8 … 1288, outside the safe stage (hence V17's cap of 8).

**F2. Physical size and the floor** (Hint Letters F5 method, on the **hit rect**).
```
mm_per_u  = stage_to_px / ppi × 25.4
hit_mm    = (144 × mm_per_u, 134 × mm_per_u)
k         = max(1, 18 / min(hit_mm))                 hit_floor_mm = 18
```
| Device | stage_to_px | ppi | mm per unit | hit rect | drawn key | k |
|---|---|---|---|---|---|---|
| 11" iPad (2388 × 1668) | 1.866 | 264 | 0.180 | 25.9 × 24.1 mm | 23.0 × 21.2 | 1 |
| 13" iPad (2752 × 2064) | 2.150 | 264 | 0.207 | 29.8 × 27.7 mm | 26.5 × 24.4 | 1 |
| Mac, 1280-pt window, 2× 254 ppi | 2.0 | 254 | 0.200 | 28.8 × 26.8 mm | 25.6 × 23.6 | 1 |
| Mac, smallest window 960 × 540 pt, 2× 254 ppi | 1.5 | 254 | 0.150 | **21.6 × 20.1 mm** | 19.2 × 17.7 | 1 |
| Mac, smallest window, 1× ~109 ppi display | 0.75 | 109 | 0.175 | 25.2 × 23.4 mm | 22.4 × 20.6 | 1 |
| 10" Android tablet | by formula | `xdpi` | — | — | — | NOT ASSESSED |

`k > 1` cannot occur on the MVP devices. If it did (a future smaller screen), the keys, gaps and hit rects would scale
by k, and the cap on n would drop to what fits inside the safe stage.

**F3. The press light** (play clock `τ` since the press).
```
glow(τ)  = 0.5 · (1 − smoothstep(clamp(τ / key_flash_s, 0, 1)))      alpha of the glow
scale(τ) = 1 + (press_scale − 1) · (1 − smoothstep(clamp(τ / key_flash_s, 0, 1)))   1 under Reduce Motion
```
A new press of the same key restarts `τ` at 0 (so mashing a key keeps it lit, never brighter: the brightness ceiling,
art bible §2).

**F4. The word draw.**
```
index = KeyTable.F1(n = |rowWords|, weights = 1, last = currentIndex or none, u = RandomSource.nextUnit())
```
With a pool of 16 and `last` set, each other word has probability 1/15. Fixture case (for key-table-schema-v1, TASK-059,
unless it lists a separate keyboard-row-v1): pool of 4, `last` = 1, injected `u` = 0.40 → candidates {0, 2, 3}, target
1.2 → index 2.

## Edge Cases

| Case | What happens |
|---|---|
| **A finger rests on the row for minutes** | The word stays (no quiet moment); harmless, accepted (no cap). |
| **The queue never empties (steady mashing)** | The word stays Due until the queue empties and `restingSince` is set; accepted. |
| **Play entry with nothing on stage** | Empty counts as quiet: the new word fades in with the row at once. |
| **EGG** | Three keys E, G, G; pressing E and either G (or G on the keyboard) makes it Due. |
| **A hardware press of G with EGG showing** | Both G keys light; the glyph rises from the leftmost G (or from a G hint, K-18). |
| **A press of a letter not in the word** | No light; counts toward nothing. |
| **An ignored row press (queue full)** | The key lights, sparkle burst and ping (R5); it still counts as pressed for R2c. |
| **The word becomes Due during a reveal** | It waits for the rest (`restingSince`), then changes. |
| **A tap lands on an old key during its fade-out** | It is a press of that old letter (the old keys are touchable until their fade-out ends). |
| **The panel opens while Due** | Nothing changes under the dim; after close, the next quiet moment changes it. |
| **The gate challenge opens mid-change** | The fades freeze; on resume they continue (play clock). |
| **Turned on while a reveal is mid-morph** | The row fades in after the panel closes; the ground lifts from the next reveal. |
| **Turned off while Due** | The row fades out; on the next turn-on a new word is drawn. |
| **A v1 theme or a broken pool** | The fallback word (FOSSIL in Dinosaurs, else ABC), no changes; one debug line. |
| **Theme switched in the panel** | The next word is drawn from the new theme's pool when the panel closes. |
| **Two fingers on two keys at once** | Two presses, in Input's sorted order (Input R7); both keys light. |
| **Reduce Motion toggled mid-session** | `press_scale` stops or starts on the next frame. |
| **A parade with the row on** | Walkers on the lifted lane (y 363–448) pass behind the bottom hint slots; the row is not dimmed (R6, R7). |

## Dependencies

**Upstream (the row reads):**
- **Settings Store** (`design/gdd/settings-store.md`): `keyboardRow`.
- **Input & Key Filter** (`design/gdd/input-key-filter.md`): R7 layer 2, R8 press event and origin.
- **Press Queue** (`design/gdd/press-queue.md`): Empty / `restingSince` (R10), outcomes (R4), sources equal (R12).
- **Reveal Stage** (`design/gdd/reveal-stage.md`): `row_lift`, the layout and boxes (R10), the play clock and freeze
  (R8), the press notifications and origins (R2). **Follow-up:** list the row band next to its boxes.
- **Key Table & Theme Data** (`design/gdd/key-table-theme-data.md`): `rowWords`, V17, schema 2, the fallback, and the
  F1 pick function (edited in this task).
- **Accessibility:** the Reduce Motion flag.

**Downstream / peers:**
- **Hint Letters** (`design/gdd/hint-letters.md`): **follow-ups**: read the row band in F4 as a clearance box, and a
  one-line note on the parade lane crossing the bottom slots with the row on (R6).
- **Parent Gate & Grown-up Panel:** its "Keyboard" row is live now that #16 is written.
- **TASK-059 (fixtures):** the F4 row set in key-table-schema-v1 (or a keyboard-row-v1).

**Normative:** art bible §3, §4, §5, §7 (conflicts 1 and 2); K-10, K-15, K-16, K-18, K-20, K-22, K-26, K-29.

## Tuning Knobs

| Knob | Value | Safe range | Source | Effect |
|---|---|---|---|---|
| `key_w` × `key_h` | 128 × 118 u | ≥ 120 wide at the 18 mm floor | first prototype; F2 | key size |
| `gap` | 16 u | 12–24 | first prototype | spacing; hit rects touch at its centre |
| `hit_pad` | 8 u | 4–8 (≤ gap/2) | art bible §7 conflict 1 | the touch margin around a key |
| key top y / bottom margin | 590 / 12 u | must stay inside the safe stage | this GDD | row height |
| max word length | 8 | ≤ 8 at 128 u | F1 (V17) | longest word |
| `key_flash_s` | 0.35 s | 0.2–0.6 | one-shot | light length |
| `press_scale` | 1.08 | 1–1.12 (1 under Reduce Motion) | proposed | press bounce |
| `row_fade_s` / `word_fade_s` | 0.3 / 0.3 s | 0.2–0.6 | K-29 (word), proposed (row) | fades |
| letter size | 80 u | 70–90 | art bible §7 (hint size) | legibility |

`row_lift` (110) is the Reveal Stage's knob; the pool is Key Table data.

## Visual/Audio Requirements

- Cream keys, gold letters, a soft shadow, a warm glow on press (R4, R5). Under the frame cap (art bible §2, §4).
- No sound of its own: E1 chime or E2 ping come with the outcome (Audio & Voice).

## UI Requirements

The row **is** UI, for the child: no text labels, no icons. The grown-up's switch is in the panel (Parent Gate &
Grown-up Panel), stored as `keyboardRow`.

## Cross-References

- `design/art/art-bible.md` §7 (the decided row, conflicts 1–2), §3, §4, §5.
- `design/gdd/input-key-filter.md` R7, R8; `design/gdd/press-queue.md` R4, R10, R12;
  `design/gdd/reveal-stage.md` R2, R8, R10; `design/gdd/hint-letters.md` R5, R11, F4, F5;
  `design/gdd/key-table-theme-data.md` `rowWords`, V17, F1; `design/gdd/settings-store.md` R1;
  `design/gdd/parent-gate-panel.md` (panel row); `design/gdd/app-shell-title.md`.
- `production/team/decisions.md`: K-26, K-29.
- First prototype `1c10352` (`KEY_W` 128, `KEY_H` 118, `KEY_GAP` 16, DINOSAUR).

## Acceptance Criteria

Logic criteria use an injected play clock, `RandomSource`, settings and press notifications; screenshots are
retained in `production/qa/evidence/`.

1. **AC-1 Off by default.** With `keyboardRow` false, no key is drawn and Input's layer 2 has no rects.
2. **AC-2 Layout.** For REX, NEST and an 8-letter test word, the key centres and hit spans equal F1's table; every hit
   rect lies inside x 64 … 1216 and y 582 … 716.
3. **AC-3 Size (F2).** The hit rect is 144 × 134 units; on the smallest Mac window (stage_to_px 1.5, 254 ppi) it is
   ≥ 18 mm on both sides (21.6 × 20.1).
4. **AC-4 Origin.** A row tap on X in REX produces one press, `source = keyboardRow`, `origin` = (784, 649).
   **Boundary:** with REX, a touch at x 711.9 presses E, at 712.1 presses X, and at exactly 712.0 (the shared edge)
   presses E (the left key).
5. **AC-5 Light.** Any press of a row key, with any outcome, sets its glow to 0.5 on the same frame and back to 0
   after 0.35 s; with Reduce Motion the scale stays 1.
6. **AC-6 Ignored.** With the queue full, a row press lights the key, shows the sparkle burst and requests E2.
7. **AC-7 Hardware lights.** With EGG showing, a hardware G lights both G keys; the glyph rises from the leftmost G
   unless a G hint is on screen.
8. **AC-8 Due.** With REX showing, presses of R (hint), E (hardware, ignored) and X (row) make it Due; pressing R
   twice and E does not.
9. **AC-9 Quiet moment.** A Due word does not change while a pointer is down on a row key, or while the queue holds a
   key, or before `restingSince`; it changes within one frame of the first quiet moment.
10. **AC-10 Change.** The old keys fade out over 0.3 s, then the new ones fade in over 0.3 s; a tap at 0.2 s presses
    the old letter, a tap at 0.4 s the new one.
11. **AC-11 No repeat.** With a fixed injected draw sequence, 1,000 changes never repeat a word twice in a row, and
    the F4 fixture case gives index 2.
12. **AC-12 Play entry.** Each Title → Play entry draws a new word (no repeat of the last one) and fades the row in.
13. **AC-13 Freeze.** Under the gate freeze, a running light and a running word fade hold their values; after
    `resume()` they continue.
14. **AC-14 Panel and states.** Under the panel the row is drawn under the dim and a touch on it is not a press; on
    the Title it is hidden; during a parade it is drawn at full alpha and is touchable. **Background:** with REX
    showing and R pressed, a short background and return shows REX again with R still counted; a Title entry
    draws a new word.
15. **AC-15 On and off.** Turning it on in the panel shows the row with a 0.3 s fade after close and lifts the ground
    from the next reveal; turning it off removes the hit rects at once.
16. **AC-16 Fallback.** With a v1 test theme (no `rowWords`), the row shows FOSSIL (or ABC when no name fits), never
    changes, and logs one debug line.
17. **AC-17 Band.** The row band (y ≥ 582) and key rects are published while the row is on, and withdrawn when off.
18. **AC-18 Look (screenshots).** On the 11" iPad and the 21:9 Mac rect, with REX and an 8-letter word, the keys are
    centred in the safe stage, cream with gold letters, and do not overlap hints or tokens.
19. **AC-19 Android insets (NOT ASSESSED).** On an Android build, no hit rect crosses the system gesture insets.

## Open Questions

None for Luan; K-29 answered them. Follow-ups (queued by the leader):
- **Hint Letters:** the row band in F4; the parade-lane note.
- **Reveal Stage:** list the row band next to its boxes.
- **TASK-059:** the row fixture set.

**Resolved (Luan, K-29, 2026-11-18):** the row shows a short common word from a per-theme pool (Dinosaurs' 16, no given
names), drawn at random with no immediate repeat; it changes once every letter has been pressed and on each Play entry,
only at a quiet moment, with 0.3 s fades; it shows even with a hardware keyboard; it stays active during a parade; it
is hidden on the Title; a hardware press lights the row key. **Leader calls:** starvation accepted with no cap; the
parade-lane overlap noted, with no new clearance box. **Reviewer (game-dev-android):** the 8-letter cap, the floor on
the hit rect, the R2c definitions, the TASK-059 seed rule, Key Table schema 2, the published band.
