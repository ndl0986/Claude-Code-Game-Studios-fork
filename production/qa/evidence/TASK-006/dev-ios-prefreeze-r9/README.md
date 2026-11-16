# Developer pre-freeze pass for iOS r9 (not QC evidence)

game-dev-ios's run-and-observe check before freezing r9, on its own Simulator "iPhone 18 Pro – dev-ios"
(FB836E51-D39E-42C3-A60E-96159EE6516C, k ≈ 0.529, small quiz layout). QC's device was not used.
**Frozen build `9c12a4a`**: `production/qa/builds/TASK-006-ios-9c12a4a/`, run with its own `ios-touch-tests.sh`.
(`TASK-006-ios-73f8af5` is superseded: same app, but case D's mash cadence was too slow; see D below.) Shots are
XCUITest attachments from the run of the 73f8af5 folder, whose app is byte-identical in Release and differs in Debug
only by build path. The 9c12a4a run's results are below.

## r9 scope

- **Rule 7c finish hold** (8eeef44 core and app): the banner moment holds 1.5 s and drops taps; a resume restarts it to
  "rise done"; the partner's placement, linear walk-in and fade; trace 1.3; the hint hand's placement; camera catch-up.
- **The medal finding (iOS QC r8 open question)**: a debug jump (`-startScreen quiz`, in the skip-warning UI case) saved
  stars, completed, seen_open and the medal to UserDefaults, which gave the 3★ + medal on QC's fresh install. Fixed:
  a debug-jumped run never writes progress (`Game.debugJumped` → `DiscardStore`); VI|EN is still saved.
- **The QC r8 NOT ASSESSED items** as XCUITest cases A–D (QC's Device Hub can't be tapped), plus the iOS-R8-01 case made
  tolerant of tap latency.

## Shots

| Shot | Checks |
|---|---|
| 01 Cờ hint hand | Hints Rule 6: the hand sits left of the Flag pad and points right at it (hand box x 940–1064, y 378–434 world); it is clear of every visible pad's square |
| 02–05 (a) rise ×0.1 at 0.06 / 0.26 / 0.51 / 0.76 s | Facing right, hero at screen x 460: the banner rises behind the hero from low (ease-out); the partner walks in at the front spot (+110), semi-transparent at 0.06 s (the 0.2 s fade, start on screen), opaque after; banner up and partner in place facing it at 0.76 s |
| 06–07 (b) left edge facing left | Hero at screen x 70 facing left: the front spot is off screen, so the partner stands **beyond the banner** (banner 125 behind, on the right; partner right of the cloth), never over the cloth or the hero |
| 08–09 (c) right side facing right | Hero at screen x 807 (▶ held 9 s at ×0.25 stopped there): the front spot again. **The "start off screen, no fade" case was not reached** (the hero would have to be at the right cap, x ≈ 1060); covered by GameCore FinishHoldTests |
| 10 (d) just after a resume | Banner up, partner at full opacity (a resume restarts to rise done) |
| 11 camp "Oof!" | hud AC15: the cream pop outline on the camp's night sky with the ink ring outside it (double outline, 6 + 4 px) |
| 12 day-village "Ối!" | The ink outline on the light day sky (unchanged from r8) |
| 13–15 quiz pick ×0.1: fading / gliding / end | quiz §5.2: the wrong cards fade, then the right card glides from slot 3 to the left slot, then the why line and Tiếp |
| 16 quiz after the glide | End state at normal speed |
| 17 next question after a double Tiếp | Case B: one advance, no card picked, none marked wrong |
| 18 intro box 3 after the deliberate tap | Case C |
| 19 results after a mashed real run, 20 title after relaunch | Case D: medal earned and 3★; after a relaunch the title card shows 3★ + medal |
| 21 title after relaunch (skip-warning case) | After a debug-jumped quiz the title shows **0★, no medal** (the r9 fix) |

## Cases A–D (the QC r8 NOT ASSESSED items)

- **A, quiz fade/glide ≤ 720 during the motion**: the app samples every frame after the actions run (didFinishUpdate,
  debug only). Run on e0c9d48: 29 frames moving, 18 distinct glide positions (x 860 → 86 at y 278), max bottom
  **575.7 ≤ 720**. ×0.1: 298 frames, 180 positions, the same max bottom.
- **B, per-question lock (two quick Tiếp taps)**: one advance, no pick, no wrong mark. **Limit:** the band where Tiếp
  overlaps the next question's third card is only ≈ 1.4 world px tall on this phone. XCUITest's doubleTap also lands
  the second touch-down in the same event batch as the first release, before the next frame rebuilds the screen. So
  the second touch lands on the old Tiếp, which is gone at its release, and nothing fires. The touch log shows it
  (`touch:1050,567:next` twice, 0.067 s apart; one fire). The child-visible rule holds; the lock itself (a press on the new card inside 0.6 s) is proven by
  GameCore `EveryBoxLockTests`, not by this case.
- **C, the deliberate 0.6 s tap**: on intro box 1 (entry at +0): press +0.362 locked (lock end +0.600); press +0.865
  locked, 0.097 s before the end (end +0.962 → rolled to +1.465); press +1.562, 0.097 s after the end: advanced. Every
  press matched the rule replayed on the logged times.
- **D, the medal under a mash in a real run**: `-resetProgress YES -autoplay YES`, a real Start, no debug jumps. Real
  taps on Tiếp / ask / quiz cards; the skip warning never opened; results: medal earned, 3★; after a relaunch the title
  shows 3★ + medal. `-autoplay` (debug only) plays only the play beats with the GameCore bot. **Cadence fix
  (9c12a4a):** in e0c9d48/73f8af5 a fixed 0.35 s sleep on top of the state read and the tap gave Tiếp presses
  ≈ 0.73 s apart. That is outside the 0.6 s lock, so it proved only "fast taps keep the medal". The loop now sleeps
  only the remainder of 0.35 s, the note reports the press gaps, and the case asserts a median < 0.6 s: **median 0.390 s,
  min 0.375 s, 131 taps**, medal kept.

## Automated results

- **GameCore** `swift test`: **149/149**, including the new `DebugSaveTests` (mutation-checked: with
  `debugJumped = true` commented out, 6 assertions fail).
- **Full suite on e0c9d48** (own Simulator): **27/27 passed** (5 app + 22 UI), no skips, ≈ 10 min. The ~300 s XCTest
  teardown is gone (cases 6–105 s).
- **Frozen folder 73f8af5** (superseded): 22/22 UI cases passed.
- **Frozen folder 9c12a4a**: see "Frozen-build run" below.

## Release check (73f8af5; 9c12a4a identical)

Release built three times into one derived-data path: **A1**, **A2** (touch-and-rebuild control) and **B** (every
`#if DEBUG` block, 180 lines, stripped from `GameScene.swift`, `DaiDatAnhHungApp.swift`, `Flow.swift` and
`DebugBot.swift`). Each links, then stops at the R12 content gate (claims unsigned), as designed. The executable is
**byte-identical in A1, A2 and B** (sha256 `41c12614…c1af`), so no debug code path reaches Release. `strings` finds
none of `debugState`, `resetProgress`, `autoplay`, `timeScale`, `quiz_motion`, `quiz_overlap`, `debug_jumped`,
`lock_until`, `lock_context`, `sprites_visible`, `max_bottom` or the touch-log format; `nm` finds no `botInput`,
`didFinishUpdate`, `quizMotion`, `debugAutoplay`, `debugPublish` or `lockUntilForDebug`. That getter was the one
name left in the first Release build of e0c9d48; 73f8af5 puts it inside `#if DEBUG`. `Game.debugJumped` stays in
Release on purpose. It is the save guard, and in Release `debugStart` returns before setting it (`isDebug` is false).

9c12a4a changes only UI-test code. Its Release executable is the same bytes (sha256 `41c12614…c1af`), so the check
above holds for it.

## Frozen-build run (9c12a4a)

`tools/qa/ios-touch-tests.sh production/qa/builds/TASK-006-ios-9c12a4a` on FB836E51 (app uninstalled first):
**22/22 UI cases passed**, 0 failed, 0 skipped, cases 6.7–127 s. A: 18 glide positions, max bottom 575.7. B: one
advance, nothing picked (second touch on the old Tiếp, lock not reached; see B). C: +0.362 and +0.881 dropped, +1.601
(0.120 s after the end +1.481) advanced, all matching the rule. D: median press gap 0.401 s, min 0.379 s, medal and 3★
saved across the relaunch. iOS-R8-01: three ◀ presses at +445/+831/+1211 ms, all locked, no warning.

Frozen Debug executables: `DaiDatAnhHung` sha256 `d97a9302…1fae2`, `DaiDatAnhHung.debug.dylib` `4cc2e6a0…2a30c`.
