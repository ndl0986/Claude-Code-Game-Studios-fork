# TASK-006 evidence: iOS native vertical slice (developer screenshots)

These are the developer's own run-and-observe screenshots (`.claude/docs/run-and-observe.md`), not
QC's. game-qc-ios tests the frozen build separately and commits its own evidence.

- **Build:** `feat/TASK-006-ios-native` @ `b9c946b`, Debug, from a clean `xcodebuild`.
- **Device:** iPhone Duo Simulator, iOS 27.1 (`629C702F-FFE6-4040-8616-0513F1D44BAF`), landscape. Captured from the cover
  display with `xcrun simctl io <udid> screenshot --display=<cover UUID>`; the inner display is black while the phone is folded.
- **Content:** the real Trần Quốc Toản mission from `content/data/` (walk → hold-meter → training →
  reach-the-flag). Its claims are pending, so the debug build shows `UNSIGNED Cxx` badges in a strip at the
  top edge, off the text. A release build refuses this content (R12).
- **Reaching each screen:** debug launch arguments, the same names as Android:
  `-startScreen <screen> -beat N -stage card|blocks|encounter|telegraph|caption|wrong|right|skipwarning -q N -stars N -lang vi|en`.
- **Automated checks at this build:** GameCore 59/59 XCTest (`swift test`), app target 2/2 XCTest (`xcodebuild test`, iPhone Duo).

| # | Screen | Launch arguments | Files |
|---|---|---|---|
| 00 | Scaffold title (first run) | none | `00-scaffold-title-vi.png` |
| 01 | Title: VI\|EN switch, Start, controls legend, debug subtitle | none | `01-title-{vi,en}.png` |
| 02 | Intro story box: picture, one sentence, Next, Skip | `-startScreen intro` | `02-intro-{vi,en}.png` |
| 03 | Beat card before a non-fight beat (walk) | `-startScreen play -beat 1 -stage card` | `03-card-walk-{vi,en}.png` |
| 04 | Walk: move pads only, goal on the HUD | `-startScreen play -beat 1` | `04-play-walk-{vi,en}.png` |
| 05 | Hold-meter: only the Cờ/Flag pad, the hold hand | `-startScreen play -beat 2` | `05-play-hold-{vi,en}.png` |
| 06 | Training, blocks stage: dummies (hit), friendly partner, the stuck pulse on Đỡ/Defend | `-startScreen play -beat 3 -stage blocks` | `06-play-training-blocks-{vi,en}.png` |
| 07 | Reach-the-flag encounter: camera locked, enemy with a padded spear | `-startScreen play -beat 4 -stage encounter` | `07-play-reach-encounter-{vi,en}.png` |
| 08 | Ending: a calm picture, one line | `-startScreen ending` | `08-ending-{vi,en}.png` |
| 09 | Quiz: 3 picture cards (shuffled), question count | `-startScreen quiz -q 3` | `09-quiz-{vi,en}.png` |
| 10 | Quiz, wrong card: greyed, #9C8FB8 border, circular-arrow mark, "Try again" | `-startScreen quiz -q 3 -stage wrong` | `10-quiz-wrong-{vi,en}.png` |
| 11 | Quiz, right card: green, the `why` line, Next | `-startScreen quiz -q 3 -stage right` | `11-quiz-right-why-{vi,en}.png` |
| 12 | Results: 3 stars, the medal earned this run, "More heroes are coming" | `-startScreen results -stars 3 -stage newmedal` | `12-results-{vi,en}.png` |
| 13 | Skip warning (D-07): Keep reading / Skip anyway | `-startScreen intro -stage skipwarning` | `13-skip-warning-{vi,en}.png` |
| 14 | Pause: Keep playing, Home, sound, VI\|EN | `-startScreen pause -beat 4` | `14-pause-{vi,en}.png` |

Not covered by screenshots (not assessed here; QC's round on the device type): touch feel, multi-touch,
audio, the telegraph timing on screen, and the unlock screen (no second hero exists in `data/` yet).
