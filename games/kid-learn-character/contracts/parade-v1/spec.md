# parade-v1

**Owner GDD:** `design/gdd/parade.md` (with "Precise rules for the contract", TASK-101a). **Layer:** KidCore.
**ADR:** ADR-0004, ADR-0002 (D3 play clock). **Cases:** hand-written by game-qc-android (TASK-101), reviewed by
game-art-content (the GDD's author).

## What it covers

- **R1 / F1:** distinct keys, a repeat counting once; glyph-only not counting; Armed at the sixth (AC-1, AC-2).
- **R2 / F2 start:**
  - inclusive, on the play clock: an exact dyadic boundary, then the normal (4.45) and reduced (3.0) sets;
  - a press while Armed waits for the next rest (AC-3, AC-4).
- **Walking entry** in order: E12, `paradeWalking` on, the walkers (key, castId, index). The batch empties and the
  next one starts as the held list; a key in the full batch isn't held, and a held key is held once (PA-Q3, PA-Q4).
- **R3 order and castIds** across a theme switch (AC-5).
- **F3 walk** as a pure function: speed, `x_i`, alpha clamped, and the inclusive draw test at 1280 and on a wide Mac
  rect (AC-6).
- **R2.4 its own clock;** Ended at `pt ≥ 11`, inclusive (AC-7). **R2.5** a next batch filling during the walk is
  Armed only at Ended (AC-8).
- **R6:**
  - panel open: Ended at once, `paradeWalking` off at once, figures released when the 0.6 s fade is done, no replay
    (AC-9);
  - background: dropped (AC-10);
  - panel while Armed keeps the batch.
- **R1 per theme** (AC-11).
- **R8 art:**
  - 2 missing → walk at 0.5 s with 4 at their own indices;
  - 4 missing → skip, Armed, and a retry only on a new rest;
  - 3 ready walks; art arriving mid-wait walks on that tick (AC-12, AC-16).
- **R7:** the bob amplitude 5 → 2.5 from the next tick (AC-13).
- **R6a freeze:** walking holds `pt` and pauses or resumes E12; Armed with 0.5 s of rest left starts 0.5 s after the
  resume; the art wait holds; the panel while Waiting → Armed (AC-19, PA-Q9).
- **No cap:** three batches, the third repeating keys (AC-17).

**Not covered here, and why:**
- **The tune itself:** audio-plan-v1. **The look (AC-18), taps on walkers (AC-14):** screenshots and Input's routing.
- **The debug start (AC-15):** debug builds only.

## `given` fields

- `knobs`: `parade_count` 6, `parade_s` 11, `parade_delay_s` 1.5, `gap` 150, `fade_s` 0.6, `art_wait_s` 0.5,
  `skip_fraction` 0.5.
- `theme`: the current theme at the start.
- `resident`: the castIds whose parade art is resident at the start.
- `accessibility {reduceMotion}`.

## Events

| Event | Fields | Emits |
|---|---|---|
| `shown` | `key`, `castId`, `kind` (`creature`, `glyphOnly`) | — |
| `rest` | `restingSince`, `formedS`, `revealLen` (null = no rest; the Press Queue's inputs) | — |
| `tick` | — | `prefetch {castIds}`; `E12 {op: play}`, `paradeWalking {on: true}`, `walkers [{key, castId, i}]`; `skip {ready}`; `paradeWalking {on: false}`, `release` |
| `resident` | `castId` | — |
| `themeChanged` | `theme` | — |
| `freeze`, `resume` | — | `E12 {op: pause/resume}` while Walking |
| `panelOpen`, `panelClose`, `background`, `foreground` | — | `paradeWalking {on: false}` (+ `release` on background) when Walking |
| `reduceMotion` | `value` | — (`bobAmp` changes on the next tick) |
| `walkAt` | `n`, `W`, `minX`, `pt` | `walk {speed, x, alpha, drawn}` |

**State (`expectState`):** `state` (Counting, Armed, Waiting, Walking), `batch`, `held` (keys, in order), `pt`,
`bobAmp`. **Field kinds:** times `time` (1e-9); positions, speed and alpha `geometry` (1e-6). The start boundary uses
dyadic stand-ins; the GDD's 2.45/2.95 cases tick just after the due time.

## Answers from the GDD author (PA-Q1–Q9, game-art-content; TASK-101a @ 752e6b8f, merged 5f8ef144)

The cases follow the merged text, and sources.lock is cut on it.
