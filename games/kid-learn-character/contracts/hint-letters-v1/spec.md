# hint-letters-v1

**Owner GDD:** `design/gdd/hint-letters.md` (with TASK-089b, R13). **Layer:** KidCore. **ADR:** ADR-0004 (D2 stream
`hints`), ADR-0002 (D3, D4). **Cases:** hand-written by game-qc-android (TASK-089), reviewed by game-dev-android (the
GDD's author).

## What it covers

- **R13 draw order, exactly** (AC-23):
  - key (F1) → lazy slot pick (L1…R4) → up to 5 jittered tries, then zero jitter → life → phase;
  - the draw count per attempt, enforced by draw exhaustion and leftovers.
- **Spawning:**
  - the 0 / 0.7 / 1.4 s sequence on frames (AC-1);
  - the inclusive gap from the last attempt, spawned or not (AC-2);
  - no attempt in a frame with a removal, from a consume or an expiry (R8, R13);
  - expiry at age ≥ life.
- **F1 exclusions** (AC-3, single cases): the current key and the queued keys skipped, including the last key of the
  pool.
- **R5 / F4:**
  - a jitter redraw near the moon; five failed jitters, then zero; an inner slot blocked by the widest creature,
    then the next pick; an inner slot saved by a jitter (AC-6);
  - every slot blocked, then the next attempt 0.7 s later.
- **F4 checks, inclusive with the exact values:**
  - the moon, the token, the creature box, the glyph box, the row band on and off, the stage edge, hint spacing;
  - `k = 1.2` (the moon's 50 and the tokens' 40 are not scaled).
- **R8 outcomes:** a touch with started or queued consumes the hint; an ignored touch keeps it still, at age
  `fade_in_s`; a hardware or row key consumes on started or queued, and an ignored one leaves the hint unchanged
  (AC-10).
- **`originFor`** gives the drawn centre, the frozen one, or none after a consume (AC-11). A fading hint still counts
  (AC-12).
- **R9 freezes:**
  - the gate challenge (AC-14) and the panel (AC-15);
  - the parade dim and hold, a touch on a dimmed hint, a dim reversal mid-fade (AC-18b);
  - Frozen → Dimmed; the background and its return, with ids continuing (AC-16).
- **R7 pulse** per Play entry (AC-13). **R10 Reduce Motion** from the start and mid-life (AC-18).
- **F2** alpha and scale; **F3** drift; **F5** size and `k` (AC-19). The title: no hints (AC-17).

- **Boundaries pinned exactly** (game-dev-android's review): the inclusive gap at a dyadic `hint_gap_s` 0.75; expiry
  at exactly age = life; the moon's 50 and the tokens' 40 unscaled at `k = 1.2`; the exact 147.8 / 137.8, not the
  rounded 148 / 138. Each one fails if the rule is flipped in the model (mutation-checked).

**Not covered here, and why:**
- **F1's `|pool| = 1` (no draw) and `|pool| = 0` (no spawn):** unreachable in play (at most 7 keys are excluded of 36),
  so no case reaches them; R13 states them.
- **The box and hint-spacing inclusivity:** their thresholds (97.8, 185.6) are not dyadic, so those cases sit near
  the threshold rather than on it. The moon and token boundaries are pinned on the exact values instead.
- **AC-7's 10,000-minute simulation and AC-4's 100,000 spawns:** per-platform unit tests, too large for a case file
  (ADR-0004 D2). AC-3's frequency check over 10,000 spawns is the same kind of test; the cases pin the mapping.
- **Android insets (AC-20):** a later version. **The look (AC-22):** screenshots.
- **The pulse's p(t) values:** a pure sine of `hintTime`. v1 tests whether it runs, not its amplitude.

## `given` fields

- `knobs`: `hint_count` 3 (1 in the single-hint cases), `hint_life_s` 6, `hint_gap_s` 0.7, `fade_in_s` 0.6,
  `fade_out_s` 0.8, `hint_jitter` 10, `hit_radius` 75, `drift_max` 12.8, `parade_hint_alpha` 0.5,
  `parade_hint_fade_s` 0.6, `consume_fade_s` 0.3, `hit_floor_mm` 18.
- `layout`:
  - the 8 slots and their base order;
  - the stage, 1280 × 720;
  - the moon (centre, radius) and the 3 tokens (centres, radius);
  - the glyph box and the row band top (582).
- `k`; `castBox` (`[x0, y0, x1, y1]` or null); `keyboardRowOn`; `accessibility {reduceMotion}`.

## Events

| Event | Fields | Emits |
|---|---|---|
| `enterPlay`, `returnFromBackground` | — | an attempt at once: `spawn {id, key, slot, centre, life, phi}` or `skip {reason}` |
| `frame` | — | the tick: `expire {id}`…, then `spawn` / `skip` |
| `press` | `key`, `source` (`hint(id)`, `hardwareKey`, `keyboardRow`), `outcome` | `consume {id, style: burst/fade}` or `keep {id}` |
| `originFor` | `key` | `origin {point}` (null when no hint shows the key) |
| `hintQuery` | `id` | `hint {id, age, alpha (F2 × dim), scale, pos, still}` |
| `queueSnapshot` | `current`, `queued` | — |
| `castBox` | `box` | — |
| `gateOpen`, `gateFailed`, `gateTimeout`, `gateCorrect`, `panelOpen`, `panelClose`, `paradeWalking {value}`, `background`, `title`, `reduceMotion {value}` | — | — |
| `visualAt`, `driftAt`, `validAt`, `sizeAt` | pure formula inputs | `visual`, `drift`, `valid`, `size` |

**State (`expectState`):** `count`, `hintTime`, `pulsing`, `mode` (Off, Running, Frozen, Dimmed), `dim`.
**Field kinds:** times (`hintTime`, `age`, `life`) are `time` (1e-9). Positions, alphas, scales, `phi`, mm and `dim`
are `geometry` (1e-6). Frame times are dyadic, so the gap and expiry boundaries compare exactly.
**Draws:** the `hints` stream, raw UInt64 strings (each u used is dyadic, so `(2u − 1) × 10` and the index floors are
exact).

## Answers from the GDD author (HL-Q1–Q12, game-dev-android; written as R13 by TASK-089b @ 0dd33c3a)

The cases follow R13, and sources.lock is cut on the merged text.
