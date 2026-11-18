# keyboard-row-v1

**Owner GDD:** `design/gdd/onscreen-keyboard-row.md` (with TASK-089a). **Layer:** KidCore. **ADR:** ADR-0004 (D2
stream `keyboard-row`), ADR-0002 (D3, D4). **Cases:** hand-written by game-qc-android (TASK-089), reviewed by
game-art-content (the GDD's author).

## What it covers

- **F1** layout for 2, 3, 4 and 8 letters; **R3** the hit test: closed rects, nearest centre, a tie to the left, the
  y edges 582 and 716, misses (KR-Q7).
- **F2** hit-rect size and `k`, including a synthetic screen with `k > 1`.
- **F3** the press light, normal and Reduce Motion. **R5** which keys light: a row tap lights that key only; a hardware
  or hint press lights every matching key (KR-Q6).
- **F4** the word draw (the GDD's fixture case and three more u values), with Key Table F1's rule.
- **R2** the word's life:
  - Due from any source and any outcome;
  - the quiet moment, checked every frame by the pointers' current positions (KR-Q5);
  - the change draws at its start (KR-Q3);
  - taps during the change go to the old keys for 0.3 s, then to the new ones;
  - the new pressed set starts at the new word's fade-in (KR-Q4).
- **`last`** is kept across a Title entry and a turn-off; the first draw after launch has none (KR-Q1).
- **R7** the background keeps the word and its pressed set; a Due word can't change during its fade-in (KR-Q9).
- **R8** turning on draws at panel close; turning off removes the hit rects and drops the pressed set (KR-Q2, Q10).
- **The gate freeze** holds the light and the fades (the play clock).
- **The fallback** (KR-Q11): FOSSIL from the cast names, else ABC. A pool of one never draws and never changes.

**Not covered here, and why:**
- **The look (AC-18):** screenshots.
- **Android insets (AC-19):** a later version, with an Android build.
- **Alpha values during the fades:** the fades are linear (KR-Q8), but v1 tests touchability and state only.
- **Theme switching:** the next draw uses the new pool. That is the same F4 function with a different pool, so it
  needs no extra case.
- **A pool of 2–7 words:** fails V17, so it is the fallback (key-table-schema-v1 owns V17).

## `given` fields

- `knobs`: `key_w` 128, `key_h` 118, `gap` 16, `hit_pad` 8, `key_top_y` 590, `key_flash_s` 0.35, `press_scale` 1.08,
  `row_fade_s` 0.3, `word_fade_s` 0.3, `hit_floor_mm` 18.
- `accessibility {reduceMotion}`; `keyboardRow` (the stored setting at the start).
- `rowWords` (the theme's pool; `null` for a v1 theme); `castNames` (the theme's cast names in canonical order, for
  the fallback).

## Events

| Event | Fields | Emits |
|---|---|---|
| `enterPlay`, `title` | — | `word {index, word}` when a word is drawn |
| `frame` | — | `word` when a change starts |
| `press` | `key`, `source` (`hardwareKey`, `hint(id)`), `outcome` | `light {indices}` (none if no key matches) |
| `rowTap` | `point` | `press {key, source: keyboardRow, origin}` and `light`, or nothing on a miss |
| `pointerDown`, `pointerMove`, `pointerUp` | `id`, `point` | — (the quiet moment reads current positions) |
| `queueState` | `quiet` (Empty, or `restingSince` set) | — |
| `gateOpen`, `gateResume`, `panelOpen`, `panelClose`, `setRow {on}` | — | `word` at a panel close that turns the row on |
| `background`, `returnFromBackground` | — | — |
| `lightQuery` | `index` | `lightValue {glow, scale}` |
| `layout`, `hitTest`, `size`, `lightAt`, `drawWord` | pure formula inputs | `layout`, `rowHit`, `size`, `light`, `word` |

**State (`expectState`):** `state` (Hidden, FadingIn, Showing, Changing, FadingOut, Frozen), `due`, `word`, `pressed`
(sorted letters). **Field kinds:** time `time` (1e-9); positions, mm and light values `geometry` (1e-6).
**Draws:** the `keyboard-row` stream, raw UInt64 strings (each u used here is dyadic, so it is exact).

## Answers from the GDD author (KR-Q1–Q11, game-art-content; TASK-089a @ 1525bd52, merged 8120a018)

The cases follow the merged GDD text, and sources.lock is cut on it.
