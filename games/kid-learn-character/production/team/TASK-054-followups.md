# TASK-054 follow-up batch (queued by game-leader, 2026-11-18)

Small edits to Approved GDDs, collected while the last MVP GDDs were written. Send as one task once
TASK-048, TASK-051 and TASK-052 are merged. Each GDD gets a dated "no re-review" log entry with a receipt.

## Settings Store
- S1: R10 sends one change notification for a run-only OFF of the Mac child lock (no write, or a write
  that keeps `childLock: true`). Child Lock-in needs it to disengage. (game-qc-ios)
- S2: define the run value explicitly as `childLockActive` (= stored `childLock` at launch; OFF changes only
  the run value, K-21). Parent Gate and Child Lock-in use this name. (leader call)

## Input & Key Filter
- I1 (safety): R6 "no other key held" must not trust a held set that lost a key-up while ⌘ was held:
  read the OS key state at the Q down (e.g. CGEventSource keyState), or clear ⌘-pressed keys on the ⌘
  flagsChanged release. A stale key must never block the kiosk way out. (game-qc-ios)
- I2: Layer 3 emits `gateTouch(ended)` when the pointer leaves the moon region + 20 pt of slop. (game-qc-ios)
- I3 (safety): while `childLockActive`, ⌘-combinations are swallowed in every state, Gate challenge and
  Panel open included (⌘Q must not skip Quit's 1.5 s hold). (game-qc-ios, game-dev-android TASK-052)
- I4: a wrong answer or timeout returns to the state the gate opened from (Title or Play); the chord works
  on Title and is ignored in Panel open. (game-qc-ios)

## Cast Rendering
- C1: per-look glyph and creature changes keyed by the Scene's `look` + `lookBlend`: amber 6 px outline and
  saturated halo in Morning/Day; at Night the palest stop dropped, halo at 70%, creature 15% dim; blends
  with lookBlend (art bible §2). (game-dev-ios takes it)
- C2: add the Scene's worst case (snow 60 + windy) to the R11 device measurement run.

## Hint Letters
- H1: F5's "Mac 700-pt window, k 1.10" row cannot occur (App Shell minimum 960×540 pt → stage_to_px 1.5,
  22.5 mm, k = 1); correct the row and AC-7's k values. (game-dev-android)

## Parent Gate & Panel
- P1: the moon is the sky's only moon; it takes the Scene's `look`; daytime moon at 70% in Morning/Day.
  (TASK-053 Scene)

## Privacy & Kids Compliance
- V1: the continuous clock used by App Shell R6 (ContinuousClock / mach_continuous_time) — check whether
  it needs a privacy-manifest required-reason entry (PKC-09 / system boot time API). (game-dev-ios)
- V2: L-07 (OS crash logs) stays Luan's call; App Shell cites it.
