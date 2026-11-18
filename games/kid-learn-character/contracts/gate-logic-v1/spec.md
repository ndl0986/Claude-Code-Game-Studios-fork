# gate-logic-v1

**Owner GDD:** `design/gdd/parent-gate-panel.md` (G1–G10, and **G13 B1–B13** from TASK-096). **Layer:** KidCore.
**ADR:** ADR-0004 (D2 stream `gate-code`), ADR-0002 (D3 clocks, D4). **Cases:** hand-written by game-qc-android
(TASK-094), reviewed by game-qc-ios (the GDD's author).

## What it covers

- **B1 code:** one `gate-code` draw per digit, d1–d4 in order, `floor(u · 10)`; the exact text
  `Enter four · one · seven · two`; a new code at every opening; all ten words.
- **B2 hold** (AC-01, AC-02):
  - 1.49 no, 1.50 yes; a lift resets;
  - a second moon pointer is ignored and doesn't take over;
  - a hold started during sleep counts from wake;
  - a device sleep between the close and the hold.
- **B3 sleep** (AC-10, AC-37): strict; the chord at 9.9375 does nothing and at 10.0 opens; Cancel and Esc start
  none; it runs across a background.
- **B4 lift before refill** (AC-12): after a Cancel and after the panel's close.
- **B5 timeout** (AC-09): open at 19.9375, closed at 20.0; 35.0 after a right digit at 15; outside touches don't
  reset it. AC-08: the first wrong digit closes it.
- **Keypad and hardware digits** (AC-07):
  - B6 grace: 0.10 and 0.149 accepted; a lift at exactly 0.15 is wrong; a palm is wrong at 0.15; three pointers
    are wrong at once; a pending second lifting first is cancelled (AC-06, AC-36);
  - B7 mixed input: a hardware digit while a keypad pointer is down is wrong; two digit keys are wrong.
- **B11 background** (AC-22): the challenge closes as Cancel with no sleep, and the flags clear; the panel closes.
- **B13 the chord:** ignored in the challenge and the panel; Esc and Cancel return to the origin, Title or Play
  (AC-25, AC-31).
- **B8 confirm** (AC-17): 1.49 nothing, 1.50 confirms; a second trigger tap does nothing; it hides 5 s after the
  later of the reveal and the last lift, never while a hold is in progress.
- **B9 / B10 auto-close** (AC-18, AC-29):
  - idle 60 s, reset by control touches and key downs, never by the empty area;
  - the third down of a burst doesn't reset it; the window is half-open;
  - a non-resetting burst down still counts toward a later burst;
  - the cap at 300 s, which waits for a slider drag or a confirm hold (the action, then the close, in one step).
- **`gateOverlayShown`** (B12): true at the challenge's open, false at every close. App Shell's `edgeDeferral` and
  `statusBarHidden` are app-shell-v1's.

**Not covered here, and why:**
- **AC-04's statistics:** a per-platform seeded unit test (ADR-0004 D2). The cases pin the draw-to-digit mapping.
- **The chord's exactness, Fn, stale keys (AC-03, AC-27):** input-filter-v1.
- **AC-11's consumed closing touch:** Input's routing.
- **UI, VoiceOver, Dynamic Type, Reduce Motion fades, the Quit row, Guided Access text:** screenshots and device
  checks.
- **The panel's writes (AC-15):** settings-record-v2. **K-15's freeze, settle and clear (AC-13, AC-14):**
  press-queue-v1 and reveal-timing-v1.

## `given` fields

- `knobs`: `gate_hold_s` 1.5, `moon_sleep_s` 10, `challenge_timeout_s` 20, `overlap_grace_s` 0.15, `confirm_hold_s`
  1.5, `panel_idle_s` 60, `panel_max_s` 300, `burst_count` 3, `burst_window_s` 1.
- `origin`: `Play` or `Title`, the state the gate opens from.

## Events

Every step gives both `t.uptime` and `t.away` (the continuous clock); they differ only after a device sleep. Every
timer is on the away clock (G13).

| Event | Fields | Emits |
|---|---|---|
| `gateTouch` | `phase` (`began`/`ended`), `pointerId` | — |
| `tick` | — | the challenge, a timeout or grace close, a confirm, a panel close, when due |
| `openPanel` | — (Input's chord) | `challenge {code, text}`, `gateOverlayShown {true}` |
| `keypadDown`, `keypadUp` | `pointerId`, `digit` | `dot {n}`, `panel`, or `close` |
| `gateDigit` | `digit`, `anotherKeyHeld` | `dot`, `panel`, or `close` |
| `cancel` | `how`? (`esc`, `back`) | `close {reason: cancel}` in the challenge, `panelClose` in the panel |
| `cardTouch` | `on`: `outside` (challenge), `control`, `empty`, `scroll`, `slider`, `confirmTrigger` (+ `action`), `confirm` | `confirm {state: shown}` |
| `confirmUp`, `sliderEnd`, `keyDown` | — | `sliderWrite` at a drag's end |
| `background`, `foreground` | — | `close {reason: background}` or `panelClose` |

**Outputs:** `close {reason, sleep, to}` and `panelClose {reason, to}` are each followed by
`gateOverlayShown {false}`. `confirm {state: shown/hidden/done, action}`.
**State (`expectState`):** `mode` (Idle, Challenge, Panel), `asleep`.
**Draws:** the `gate-code` stream as raw UInt64 strings. Each u is k/64 just above d/10, so `floor(u · 10)` is
exact. Boundary times are chosen so their differences are exact in binary (for example the grace cases start at 0).

## Answers from the GDD author (GL-Q1–Q12, game-qc-ios; written as G13 by TASK-096 @ 5c207fcb)

The cases follow G13, and sources.lock is cut on the merged text.
