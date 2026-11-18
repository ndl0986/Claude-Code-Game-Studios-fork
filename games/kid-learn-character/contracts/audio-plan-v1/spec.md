# audio-plan-v1

**Owner GDD:** `design/gdd/audio-voice.md` (with TASK-088a). **Layer:** KidCore (the audio *plan*; the engine is
ADR-0010's). **ADR:** ADR-0004, ADR-0002 (D3, D6 `AudioOutput`).
**Cases:** hand-written by game-qc-android (TASK-086), reviewed by game-art-content (the GDD's author).

## What it covers

- **R1:** the reveal schedule per case. It **owns E6–E9 and E11**:
  - E6 at 0;
  - E7 at `glow` (morph and art missing), at `fallback_glow_s` (invalid set), and not at all with the glyph missing;
  - E8 (E11 for a digit) at formedS, when a creature forms and an sfx exists;
  - E9 at formedS + `word_offset_s` when `hasWord`.
- **Press-time sounds:** E1–E3, E5. **F3** mash factor: one window for E1/E2/E3, (t − w, t] in delivery order, and
  a one-batch mash giving n = 0…9.
- **F1** gain chain (trims as knobs, AU-Q6); **F2** ducking, linear in dB at fixed rates from the current dB.
- **R2:** player use. A sound frees its player at start + length; a free player is used first (lowest number); the
  oldest is stolen, a tie the lowest number. E6 cuts the voice and cast players. Cast sounds replace each other.
- **R6:** the gate freeze. Players pause; a due event fires at its play time after `resume()`.

**Not covered here, and why:**
- **No click (AC-9), interruptions (AC-15), latency (AC-16), silent mode (AC-20):** the audio engine and the device
  (ADR-0010; device checks M-14, P-1, P-7–P-9).
- **Loudness (AC-12) and line lengths (AC-6):** build tools on the rendered files.
- **Voice lengths:** stubbed as `length` inputs. No case depends on which TTS voice is chosen (K-33).
- **formedS, glow and hasWord themselves:** reveal-timing-v1 (they are inputs here).

## `given` fields

`knobs`: `word_offset_s` 0.25, `fallback_glow_s` 0.8, `mash_k` 0.5, `mash_floor` 0.35, `chime_window_s` 1.0,
`duck_db` −9, `duck_attack_s` 0.05, `duck_release_s` 0.25, `head_db` −3, `bus_db` {voice 0, cast −4, ui −10,
music −8}, `ping_db` −6.

## Events

| Event | Fields | Emits |
|---|---|---|
| `revealSchedule` | `case`, `formedS`, `glow`, `hasWord`, `sfx`, `isDigit` | `schedule {event, s}`, in schedule order |
| `frame` | — | `fire {event, s}` for each scheduled event now due, on the play clock |
| `freeze`, `resume` | — | `pause`, `resume` |
| `pressOutcome` | `outcome` (`started`, `queued`, `ignored`) | `play {event, mash}` |
| `sparkle`, `startPlay` | — | `play {event, mash}` (E3 is mash-scaled; E5 is not) |
| `revealEvent` | `event` | `play {event, mash}` (E7 is not mash-scaled) |
| `gain` | `v`, `bus`, `event`, `mash`, `duck` | `gain {value}` |
| `voiceStart`, `voiceEnd` | — | — (they drive the duck) |
| `duckQuery` | — | `duck {value}` |
| `start` | `event`, `length` | for E6, `cut` on the voice then the cast player first if they're busy; a `cut` when stealing; then `player {bus, index}` |

**Field kinds:** `s` is `time` (1e-9); `mash`, `gain` and `duck` are `gain` (1e-9).

## Answers from the GDD author (AU-Q1–Q8, game-art-content; TASK-088a @ 82f24b2b)

The cases follow these answers:
- **Q1:** formedS; E8 follows willForm and sfx; E9 follows hasWord.
- **Q2:** the E7 rules.
- **Q3:** the window (t − w, t] in delivery order.
- **Q4:** freeing and stealing.
- **Q5:** the dB-linear duck from the current level.
- **Q6:** trims as knobs.
- **Q7:** E11 for digits.
- **Q8:** freeze carry-over.
