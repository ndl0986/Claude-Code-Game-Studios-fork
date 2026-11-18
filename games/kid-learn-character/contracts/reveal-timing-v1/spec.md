# reveal-timing-v1

**Owner GDDs:** `design/gdd/reveal-stage.md` (with TASK-088b/c/d) and the pure formulas of `design/gdd/cast-rendering.md`
(F1, F2, F4, F5, F7; TASK-080 Q4). **Layer:** KidCore. **ADR:** ADR-0004, ADR-0002 (D3).
**Cases:** hand-written by game-qc-android (TASK-086), reviewed by game-dev-ios (the author of both GDDs).

## What it covers

- **R3 / F5:** `startReveal` → `{case, formedS, revealLen, hasWord}` for the morph, glyph-missing, art-missing and
  invalid-set cases, in the normal and reduced sets. `hasWord` = the case forms a creature AND the active locale has
  the word line (TASK-088b).
- **R4:** `formed` and `shown` once, on the first frame with `s ≥ formedS`. `kind` comes from the case (`glyphOnly`
  for art missing), including on a settle (RT-Q5).
- **The invalid-set timeline** (TASK-088b/c/d): with a set whose own values differ, the glyph rises over
  `fallback_rise_s`, `haloOn` runs to `fallback_glow_s`, and the creature fades over `fallback_fade_s`, under Reduce
  Motion too.
- **R8:** the reveal's `s` stops under a freeze; a settle sends `shown` once. **R2:** the origin of a hardware press: a hint, else the leftmost
  matching row key, else the keyboard anchor (RT-Q3).
- **F1** stage fit (exact values, RT-Q6); **F2** glyph rise; **F3** creature alpha and pop (including the fade-in
  fallbacks' `fadeStart`); **F4** leaving; **F6** tap cooldown (≥).
- **R10:** `haloOn` (`letter_in < s ≤ glow`) and `mashing` (queue length ≥ 1, or an `ignored` with
  `now − t_i < mash_window_s`, strict, RT-Q4).
- **Cast Rendering:**
  - F1 detail kept by role;
  - F2 halo blur, with `t = s − letter_in` (RT-Q8);
  - F4 the stardust cap per channel;
  - F5 hop;
  - F7 the late-art wait table.

**Not covered here, and why:**
- **The E-times (E6–E9):** audio-plan-v1 owns them. This contract outputs `formedS`, `glow` and `hasWord` only.
- **The item pick, the morph seed and positions:** key-table-schema-v1 and morph-contract-v1.
- **Draw order and stage fit on screen (AC-12, AC-13), feel (AC-16):** screenshots and device checks.
- **Cast Rendering F3, F6, F8:** speck looks are per platform (R6). Texture memory depends on ADR-0009. F8 is
  scene-look-v1's.
- **The late-art timeline in a running reveal** (RT-Q7): v1 tests the F7 numbers only. **v2 scope** (agreed with
  game-dev-ios), with Cast Rendering's residency inputs:
  - a key queued after the shrunk bound has passed → the specks sparkle out at once (one log line);
  - art arriving inside the wait → the fade-in starts at its arrival;
  - no key waiting → the full 0.5 s.

## `given` fields

- `timingSet`, `reducedSet`: MorphCore's values as inputs (`letter_in`, `glow`, `T`, `form_s`, `valid`). Normal
  0.45 / 0.8 / 2.45 / 0.5; reduced 0.225 / 0.4 / 1.2 / 0.3.
- `knobs`: `sparkle_out_s` 0.6, `fallback_rise_s` 0.45, `fallback_glow_s` 0.8, `fallback_fade_s` 0.5,
  `letter_len_max_s` 1.0, `word_offset_s` 0.25.
- `accessibility {reduceMotion}`.
- `hintOrigins` (key → `originFor`); `keyboardRow {on, keys: [{key, centre}]}`.
- `formedCreature` (a formed creature is on stage, for taps).

## Events

| Event | Fields | Emits |
|---|---|---|
| `startReveal` | `revealId`, `key`, `source`, `origin`, `item {castId, hasGlyph, willForm, hasWordLine, sfx}` | `startResult` |
| `frame` | — | `formed`, `shown` when due. State: `s`, `haloOn` (for `invalidSet`: `fallback_rise_s < s ≤ fallback_glow_s`), `mashing` |
| `settle` | — | `shown`, if not yet sent |
| `freeze`, `resume` | — | — |
| `routePress` | `key`, `source` | `origin` |
| `stageFit` | `windowPx` | `stageFit {stageToPx, offsetPx, visible: [x, y, w, h]}` |
| `glyphAt` | `s`, `origin`, `case`? | `glyph {pos, scale}`: the rise lasts `letter_in` of the active set, or `fallback_rise_s` when `case` is `invalidSet` |
| `creatureAt` | `case`, `formedS`, `s` | `creature {alpha, pop}`: the fade lasts the active set's `form_s`, or `fallback_fade_s` for `invalidSet` (F3, TASK-088d) |
| `leavingAt` | `tLeave` | `leaving {alpha, y, scale}` (`leave_s` 0.45, anchor y 600) |
| `creatureTap` | `point` | `tap {counted}` (whether it counts; the sound is Audio's E10/E4) |
| `pressOutcome` | `outcome`, `queueLength` | state `mashing` |
| `queueSnapshot` | `queueLength` | state `mashing` |
| `keepDetail` | `sizeArtboard`, `role`, `roleHeight`, `stageToPx` | `keep {value, onScreenPx}` |
| `haloBlur` | `s` | `blur {value}` (`halo_blur_max` 60, `halo_hz` 2.2) |
| `dustCap` | `scene`, `cap`, `specks: [[alpha, colour]]` | `channel {value}` (one linear channel) |
| `hopAt` | `tau` | `hop {value}` (`hop_px` 26, `hop_s` 0.45) |
| `lateArtWait` | `holdEff`, `formedS`, `form_s`, `keyWaiting` | `wait {value}` |

**Field kinds:** times (`formedS`, `revealLen`, `s`, `wait`) are `time` (1e-9). Positions, scales, alphas, blur,
hop, channel values and px are `geometry` (1e-6). Cases that test an exact boundary (`haloOn`, `formed`) use dyadic
frame times, or r0 = 0, so the comparison is exact on every platform.

## Answers from the GDD author (RT-Q1–Q8, game-dev-ios; TASK-088b @ 7d16be9d, TASK-088c @ 34ab7951, TASK-088d @ 45809435)

The cases follow these answers:
- **Q1:** E8/E9 at formedS, with E8's and E9's conditions owned by audio-plan-v1.
- **Q2:** hasWord as above.
- **Q3:** the origin order.
- **Q4:** `mashing` is strict.
- **Q5:** `kind` from the case.
- **Q6:** exact F1 values.
- **Q7:** F7 measured from formedS.
- **Q8:** `t = s − letter_in`.
