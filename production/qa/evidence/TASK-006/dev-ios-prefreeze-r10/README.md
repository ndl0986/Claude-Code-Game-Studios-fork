# Developer pre-freeze pass for iOS r10 (not QC evidence)

game-dev-ios's run-and-observe check before freezing r10, on its own Simulator "iPhone 18 Pro – dev-ios"
(FB836E51-D39E-42C3-A60E-96159EE6516C). QC's device was not used.

**Frozen build `760a5b2`**: `production/qa/builds/TASK-006-ios-760a5b2/`, run with its own `ios-touch-tests.sh`.
Two earlier folders are superseded:
- `TASK-006-ios-2af9b85`: before the hint-hand colours.
- `TASK-006-ios-baeb0f7`: the same app as 760a5b2, but its case C failed on a slow tap (see below).

## r10 scope

- **N1 (QC r9): the resume timing.**
  - The problem: the banner moment after a resume measured 0.800 s (QC) and 0.812 s (mine) instead of 0.833 s.
    The app's fixed-step accumulator credited the first frame's dt and the remainder carried from before the press.
  - The fix: GameCore `FrameClock` now owns the steps: 1/60, dt clamped to [0, 0.25], 0 on the first frame, and the
    debug scale applied before the accumulator. The frame on which the screen leaves pause credits no time and drops
    the remainder.
  - The rules are the same as Android r13 `FrameClock`, and game-dev-android reviewed them.
- **Skin parity:** `C.skin` #F5C9A0 → #F1C9A0 (look-sheet-d18 l.72: one skin for everyone).
  - It is shared by the hero, the follower/partner, the enemies' faces and hands, the "child" picture icon and,
    from baeb0f7, the hint hand.
  - The follower look now uses `C.skin` instead of an inline copy.
  - Commit 2af9b85's message lists "the hint hand, the cheer crowd and the title figure". That list was wrong at
    that commit.
- **Hint hand (ASSET-033, mission-hud-assets.md; look-sheet-d18 l.72), baeb0f7:**
  - Before: a white glove with a red cuff.
  - Now: palm, fingers and thumb in `C.skin`, a cream `C.cream` #FFF6E3 cuff, and an ink outline on every part,
    including the cuff, which had none.
  - The shape, bob and placement are unchanged.
  - Android r14 (a5e8c37) has the same change.
- **Case C test fix (760a5b2, test code only):**
  - In the baeb0f7 frozen run, tap latency was 0.287 s, so tap 3 landed at +1.475 s, just before the 1.5 s cap.
  - The app rightly dropped it, and every press matched the replayed rule, but the case asserted an advance anyway.
  - Such an attempt now counts as a miss and retries, up to 4 launches, as near misses already did.

## Shots and logs

| File | Checks |
|---|---|
| 01 hint hand | The Cờ hint hand in place, left of the Flag pad and pointing at it (placement unchanged from r9) |
| 07 hint hand close-up ×3 | Pixel samples (simulator screenshot, sRGB): palm **#F5D3AF**, finger **#F5D3AF**, thumb **#F5D3AF**, cuff **#FFF8E8**, outline **#4B3829**. The hero's face in shot 02 samples **#F5D3AF** too, so the hand and the hero share one skin. The screenshot pipeline shifts every drawn colour the same way: #F1C9A0 → #F5D3AF, #FFF6E3 → #FFF8E8, and ink #3A2A1F appears as #4B3829 on the anti-aliased outline. r9's white glove sampled white |
| 02 banner up, partner in place | The hero and the follower share one skin. The hero's face samples #F5D3AF here and #F8D3AF at the same pixel in r9 (#F5C9A0) |
| 03 paused in the hold | The pause screen opened 0.3 s into the banner moment |
| 04 just after a resume | Banner up, partner at full opacity (r9 rule kept) |
| 05 resume log + banner-up | The resume case's log and its banner-up time after the press |
| 06 results after a mash | Results after case D: medal and 3★ kept |

Shots 01 and 07 come from the baeb0f7 run, whose app is the same source as 760a5b2. The others come from the 2af9b85
run, which had the same FrameClock and skin.

## Automated results

- **GameCore** `swift test`: **155/155**, which is 149 plus 6 new `FrameClockTests`:
  - first frame;
  - 60 Hz and the clamps;
  - the debug scale;
  - the resume frame;
  - a 240-frame jittered "sim never ahead of wall time" check;
  - the hold driven through `Game`, ending 50 frames after the resume frame for carried remainders of 0, 0.5 and
    0.9 step.

  **Mutation check:** with the resume reset removed, 3 tests fail. The Game-driven hold then ends after
  **48–49 frames**, which reproduces QC's 0.800 s and my 0.812 s.
- **UI case** `test_a_resume_restarts_the_hold_to_rise_done` now asserts ≥ 0.828 s after the press (it was ≥ 0.75).
  - Measured: 0.840, 0.833 and 0.831 s on 2eb923c; 0.849 s in the 2af9b85 frozen run; 0.830 s for baeb0f7 and
    **0.831 s** for 760a5b2.
  - Expected: 0.833 ≤ t ≤ 0.850, plus about ±3 ms of touch-to-log jitter.
  - r9's 0.812 would fail it.
- **Full suite** on 2af9b85's tree: **27/27** (5 app + 22 UI).
- **Frozen folder 760a5b2** (app uninstalled first): **22/22 UI cases passed**, 0 failed, 0 skipped.
  - Case C: +0.364 and +0.881 s dropped; +1.585 s, 0.104 s after the end at +1.481 s, advanced. All three match
    the rule.

## Release check (baeb0f7; 760a5b2 changes only UI-test code)

- Release was built three times into one derived-data path:
  - **A1**;
  - **A2**, with every source touched, then rebuilt;
  - **B**, with every `#if DEBUG` block stripped: 182 lines from `GameScene.swift`, `DaiDatAnhHungApp.swift`,
    `Flow.swift` and `DebugBot.swift`. B recompiled and relinked.
- Each stops at the R12 content gate (C01–C16 unsigned), as designed.
- The executable is **byte-identical in A1, A2 and B**: sha256 `78ddc3fb…6491`. For comparison: 2af9b85
  `fced6233…6a61`, r9 `41c12614…c1af`.
- `strings` finds none of the debug-state keys or the touch-log format. `nm` finds none of the debug symbols
  (`botInput`, `didFinishUpdate`, `quizMotion`, `debugAutoplay`, `debugPublish`, `lockUntilForDebug`).

Frozen Debug executables (760a5b2): `DaiDatAnhHung` sha256 `a4176f96…d935`, `DaiDatAnhHung.debug.dylib`
`70b95b90…9fbd`.
