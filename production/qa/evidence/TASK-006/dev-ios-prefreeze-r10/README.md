# Developer pre-freeze pass for iOS r10 (not QC evidence)

game-dev-ios's run-and-observe check before freezing r10, on its own Simulator "iPhone 18 Pro – dev-ios"
(FB836E51-D39E-42C3-A60E-96159EE6516C). QC's device was not used.
**Frozen build `2af9b85`**: `production/qa/builds/TASK-006-ios-2af9b85/`, run with its own `ios-touch-tests.sh`.

## r10 scope

- **N1 (QC r9):** the banner moment after a resume measured 0.800 s (QC) / 0.812 s (mine) instead of 0.833 s.
  The app's fixed-step accumulator credited the first frame's dt and the remainder carried from before the press.
  GameCore `FrameClock` now owns the steps (1/60, dt clamped to [0, 0.25], 0 on the first frame, debug scale
  before the accumulator). The frame on which the screen leaves pause credits no time and drops the remainder.
  The rules are the same as Android r13 `FrameClock` (reviewed by game-dev-android).
- **Skin parity:** `C.skin` #F5C9A0 → #F1C9A0 (look-sheet-d18: one skin for everyone), shared by the hero, the
  follower/partner (its look now uses `C.skin` instead of an inline copy), the enemies' faces and hands, and the
  "child" picture icon. (Commit 2af9b85's message says "the hint hand, the cheer crowd and the title figure": that
  list is wrong. The hint hand is a white glove and doesn't use it. The code change is as described here.)

## Shots and logs

| File | Checks |
|---|---|
| 01 hint hand | The Cờ hint hand as in r9 (unchanged placement) |
| 02 banner up, partner in place | Hero and follower now share one skin. The hero's face samples #F5D3AF here, #F8D3AF at the same pixel in r9 (shading and colour conversion on top of #F1C9A0 / #F5C9A0) |
| 03 paused in the hold | The pause screen opened 0.3 s into the banner moment |
| 04 just after a resume | Banner up, partner at full opacity (r9 rule kept) |
| 05 resume log + banner-up | The resume case's log; banner-up after the press **0.849 s** in the frozen run |
| 06 results after a mashed real run | Results screen after case D (the medal and 3★ kept) |

## Automated results

- **GameCore** `swift test`: **155/155** (149 + 6 new `FrameClockTests`: first frame, 60 Hz and clamps, debug
  scale, the resume frame, a 240-frame jittered "sim never ahead of wall time" check, and the hold driven through
  `Game`: 50 frames after the resume frame for carried remainders 0 / 0.5 / 0.9 step).
  **Mutation check:** with the resume reset removed, 3 tests fail, and the Game-driven hold ends after
  **48–49 frames**, which reproduces QC's 0.800 s and my 0.812 s.
- **UI case** `test_a_resume_restarts_the_hold_to_rise_done` now asserts ≥ 0.828 s after the press (it was ≥ 0.75).
  Repeat runs on 2eb923c: **0.840 / 0.833 / 0.831 s**. Frozen run: **0.849 s**. Expected 0.833 ≤ t ≤ 0.850, plus the
  touch-to-log jitter. Never short by more than the 5 ms tolerance, and r9's 0.812 would fail it.
- **Full suite** before the freeze (both commits in the tree): **27/27** (5 app + 22 UI), 526 s.
- **Frozen folder 2af9b85** (app uninstalled first): **22/22 UI cases passed**, 0 failed, 0 skipped.

## Release check (2af9b85)

Release was built three times into one derived-data path: **A1**, **A2** (every source touched, then rebuilt) and
**B** (every `#if DEBUG` block stripped, 182 lines, from `GameScene.swift`, `DaiDatAnhHungApp.swift`, `Flow.swift`
and `DebugBot.swift`; B recompiled and relinked). Each stops at the R12 content gate (C01–C16 unsigned), as
designed. The executable is **byte-identical in A1, A2 and B**: sha256 `fced6233…6a61` (r9: `41c12614…c1af`; the
FrameClock code changed it). `strings` finds none of the debug-state keys or the touch-log format, and `nm` finds
none of the debug symbols (`botInput`, `didFinishUpdate`, `quizMotion`, `debugAutoplay`, `debugPublish`,
`lockUntilForDebug`). `FrameClock` is present, as expected.

Frozen Debug executables: `DaiDatAnhHung` sha256 `990cd334…e10d`, `DaiDatAnhHung.debug.dylib` `0a1f0bac…21f7`.
