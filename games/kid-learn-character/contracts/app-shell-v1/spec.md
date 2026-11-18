# app-shell-v1

**Owner GDD:** `design/gdd/app-shell-title.md` (with TASK-095: R3, R6, R7, F4). **Layer:** KidCore. **ADR:**
ADR-0004, ADR-0002 (D3 `AwayClock`). **Cases:** hand-written by game-qc-android (TASK-094), reviewed by game-dev-ios
(the GDD's author).

## What it covers

- **The state machine:** Launching → Title → Play, Gate, Panel, Background.
- **R1 / F1 `ready`** (Mac only, AC-3): once, at the last of first frame, chord installed and window covers display,
  in any order. iPadOS has no `ready`.
- **R3 starts** (AC-5, AC-7):
  - a key or a non-moon touch **down** starts play; a move or up doesn't;
  - with the theme ready: E5 (`titleChime`), then the four ordered Play-entry notifications (R4);
  - with it loading: one pending start, with the chime at once and Play at `themeReady`, further starts absorbed;
  - a start in Play does nothing; nothing before the first frame (AC-10's launch-screen row).
- **R5 the gate:** Gate and Panel return to the origin (Play or the Title).
- **R6 / F3 the return:**
  - F3 is strict: exactly 1800 → Play, 1800.5 → Title; an 8 h device sleep (away only) → Title (AC-8);
  - from the Title → Title;
  - from the Gate or Panel → the origin, then F3;
  - a pending start is dropped on background.
- **R7 overlays** (AC-14; Parent Gate AC-38): `statusBarHidden {true}` once and `edgeDeferral {on}` at the first frame
  (iPadOS); `edgeDeferral` off on entering the Gate, on again on return to the stage. The Mac has neither.
- **R8 / F4 memory** (AC-11): inclusive 30 s; "previous" is the preceding warning of either level; on uptime;
  background warnings count.

**Not covered here, and why:**
- **Window shapes (AC-10, AC-14's swipes), the first-frame look (AC-2), scans (AC-12), device times (AC-13), cold
  launch (AC-9):** screenshots, scans and device checks.
- **The held set carrying into Play (AC-6) and the moon exclusion:** input-filter-v1. **The queue fake's state:**
  press-queue-v1.
- **What each shed level frees:** Cast Rendering and Parade. This contract checks the level only.
- **AC-4 (K-21 relaunch):** settings-record-v2 and Child Lock-in.

## `given` fields

`platform` (`iPadOS` or `macOS`); `knobs`: `title_after_s` 1800, `memory_escalate_s` 30.

## Events

Every step has `t.uptime`. `t.away` (AwayClock) is given at `background` and `returnFromBackground`.

| Event | Fields | Emits |
|---|---|---|
| `launch` | — | — |
| `firstFrame`, `chordInstalled`, `windowCoversDisplay` | — | `statusBarHidden`, `edgeDeferral` (iPad, first frame); `ready` (Mac) |
| `themeReady` | — | the Play entry, if a start is pending |
| `startPlay`; `titleTouch` | `phase`, `point` | `titleChime`, then `enterPlay {notify}` × 4 (Input, PressQueue, RevealStage, HintLetters) |
| `gateOpen`, `gateCorrect`, `gateClosed {reason}`, `panelClosed {reason}` | — (the Parent Gate's `gateOverlayShown` transitions) | `edgeDeferral {on}` on a change |
| `background`, `returnFromBackground` | — | `return {to}`, then `edgeDeferral` if it changed |
| `memoryWarning` | — | `shed {level}` |

**State (`expectState`):** `state`. **Field kinds:** none timed beyond the event times.

## Answers from the GDD author (AS-Q1–Q10, game-dev-ios; TASK-095 @ 114796ff and 1ff47f0e)

The cases follow the merged GDD text, and sources.lock is cut on it.
