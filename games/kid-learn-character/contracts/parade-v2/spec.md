# parade-v2

**Owner GDD:** `design/gdd/parade.md` after TASK-120 (K-45 start without a rest; K-44 meter R12 and F4; K-46 the
1.5 s beat and the meter light R12a). **Layer:** KidCore. **ADR:** ADR-0004, ADR-0002 (D3 play clock).
**Cases:** hand-written by game-qc-android (TASK-122), reviewed by game-art-content (the GDD's author).

## What changed from v1 (TASK-122)

v2 supersedes parade-v1 (K-40). parade-v1 started the parade through the Press Queue's `restingSince`. Since K-45 the
start is `armedAt + parade_delay_s`, with no rest, so the 21 v1 cases that drove the start through `rest` are
retired and rewritten here.
- **The 9 unchanged v1 cases** are kept with their steps and expectations as they were: `AC1-distinct-keys`,
  `AC2-glyph-only-does-not-count`, the six `AC6-walk-*` cases and `AC11-per-theme`. Their `given` gains the meter
  knobs and `queue_max`.
- **The `rest` event is gone.** The Parade no longer reads `restingSince`, `formedS` or `revealLen` (Precise rules).
- **New:** the meter (R12, F4) and its light (R12a), through `meterQuery`, and the cross-knob check.

## What it covers

- **R2 / F2 start:**
  - `armedAt` = the 6th `shown`; the start at `armedAt + 1.5`, inclusive. The normal (9.95) and reduced (8.7) sets,
    and an exact dyadic boundary (AC-3).
  - A press while Armed doesn't delay it (AC-4); a key every 3.0 s with the queue never empty gives a parade per 6
    keys (AC-20).
- **R2.4 / R2.5:** its own clock and Ended at 11 (AC-7). A next batch filled mid-walk is Armed at Ended with
  `armedAt = fullAt = Ended`, and starts 1.5 s later (AC-8).
- **R6:**
  - panel open ends the walk at once, with release after the 0.6 s fade (AC-9); background drops it (AC-10);
  - while Armed, the panel or background hold the start, and `armedAt` is re-set at the close or return. Background
    time doesn't count (AC-21).
- **R8:**
  - prefetch at Armed; 2 missing → walk at the 0.5 s wait's end with 4 at their indices; 4 missing → skip;
  - the retry only after the next formed reveal (AC-12, AC-16); 3 ready walks; art arriving in the wait walks on that
    tick.
- **R7** the bob amplitude (AC-13). **R6a:** a walk frozen 20 s ends 31 s after its start, and Armed with 0.5 s of
  the beat left starts 0.5 s after the resume (AC-19). **No cap** (AC-17).
- **R12 / F4 meter:**
  - fill: `litAt = launch + 0.75`, a 0.4 s ease-out, 0.8125 at +0.2; repeats and glyph-only send nothing (AC-22);
  - full: `fullAt`, and the glow 0.215 at +0.2 and 0.45 at +0.5; Waiting at `armedAt + 1.5` (AC-23);
  - the handover drain of cells and glow over 0.6 s, with a held key's cell staying lit (AC-24);
  - the gate and panel: a fill in progress completes, the glow holds at ramp · 0.40, and nothing replays (AC-25);
  - per theme, with no fill animation after a switch (AC-26);
  - Reduce Motion: no light, `litAt` = the shown, a steady 0.40 glow (AC-27).
- **R12a the light:**
  - the path: (640, 300) → (866.5, 58), with (696.625, 118.5) at u 0.5 and the fade over the last 0.15 s (AC-31);
  - Reduce Motion turned on mid-flight (AC-32); removed at the gate, the panel or the background, with the cell lit at
    once (AC-33);
  - a held key sends none (AC-34); during a walk it goes to the next batch's cell (AC-35).
- **The cross-knob constraint** `meter_fly_s − meter_land_s + meter_step_s ≤ parade_delay_s`, inclusive, through
  `knobCheck`.

**Not covered here, and why:**
- **AC-14 taps on walkers and AC-28 meter taps:** Input's routing (input-filter-v2).
- **AC-15 the debug start:** debug builds only.
- **AC-18 and AC-30 looks:** screenshots.
- **AC-29 flash data:** ADR-0013's build gates.
- **AC-34's 60 s mash:** a per-platform session test. The one-light rule is pinned by the held-key case and the
  1.2 s ≥ `meter_fly_s` bound.
- **Where `knobCheck` runs:** the parade knobs are bundled data checked at build (ADR-0003). This contract pins the
  rule as a pure function; wiring it into the data validator is a follow-up for its owner.

## `given` fields

- `knobs`: `parade_count` 6, `parade_s` 11, `parade_delay_s` 1.5, `gap` 150, `fade_s` 0.6, `art_wait_s` 0.5,
  `skip_fraction` 0.5, `meter_empty_alpha` 0.25, `meter_step_s` 0.4, `meter_glow_g0` 0.40, `meter_glow_g1` 0.05,
  `meter_pulse_hz` 0.5, `meter_fly_s` 0.9, `meter_land_s` 0.15.
- `theme`, `resident` (castIds whose parade art is resident), `queue_max` (3: `meter_cx` 934, cell `i` at
  866.5 + 27i), `accessibility {reduceMotion}`.

## Events

| Event | Fields | Emits |
|---|---|---|
| `shown` | `key`, `castId`, `kind`, `from`? (the cast box's top centre, for the light's path) | `prefetch {castIds}` when it arms the Parade and art is missing |
| `tick` | — | `E12 {op: play}`, `paradeWalking {on}`, `walkers [...]`; `skip {ready}`; `paradeWalking {on: false}`, `release` |
| `resident` | `castId` | — |
| `themeChanged` | `theme` | — |
| `freeze`, `resume` | — | `E12 {op: pause/resume}` while Walking |
| `panelOpen`, `panelClose`, `background`, `foreground` | — | the Walking end outputs |
| `reduceMotion` | `value` | — (`bobAmp` changes on the next tick) |
| `meterQuery` | — | `meter {filled, alpha[6], glow, flight: {cell, pos, alpha} | null}` |
| `walkAt` | `n`, `W`, `minX`, `pt` | `walk {speed, x, alpha, drawn}` |
| `knobCheck` | `knobs` | `knobsValid {value}` |

**State (`expectState`):** `state`, `batch`, `held`, `pt`, `bobAmp`, `armedAt`, `fullAt` (play clock).
**Field kinds:** times `time` (1e-9); alphas, glow, positions, speed `geometry` (1e-6). Start boundaries use
dyadic times; the GDD's 2.45/1.2 sets tick just after the due time.

## Source

Parade R2, R6, R6a, R8, R12, R12a, F2–F4 and the Precise rules as merged by TASK-120 (7815770d). The cases follow
that text, and sources.lock is cut on it.
