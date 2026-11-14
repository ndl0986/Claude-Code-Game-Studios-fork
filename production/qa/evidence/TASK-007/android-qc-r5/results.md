# TASK-007 Android QC, round 5 (native Kotlin, build f02c0d6)

**Overall r5 verdict: PASS with findings.** Every new r5 feature works, and the full regression passes. Two findings:
- **B6 (Low):** the sound button overlaps the top-left corner of the story picture and the beat-card panel (intro, ending and cards).
- **AC13 concern:** in the strikes captured, the enemy's spear tip never shows touching the hero.

There are also two contrast observations: the "Ối!/Oof!" pop, and gold-on-red banner text.

| Item | Value |
|---|---|
| Build | `f02c0d6` (107 tests). APK `production/qa/builds/TASK-007-f02c0d6.apk`, sha256 `b5d008474fa227dd…`, matching QC's copy and the device. c00c5e0 was uninstalled first. |
| Device | `emulator-5554` (mp17863), API 36, 1080x2400, landscape 90°. Every adb command names the serial. |
| Input | Timing-sensitive input goes through `fastmt.py` (one streaming `cat`), and every case has a kernel `getevent -lt` line in `input-timing.txt`. |
| Date | 2026-11-14 |

## 1. Combat Rule 15b, the training camera cap (AC24)

**PASS.** After the training card closed I held ▶ for 5.0 s (kernel: down @0.000, up @4.999). In the 60 fps recording the camera scrolls smoothly, with **no jump**. The hero then **stops at the right limit** while **all three dummies stay on screen** (`r5-22-15b-hero-at-limit-dummies-on-screen.png`). Turning back to hit the dummies, blocking 3 times and tapping Cờ **completed training** (4th star, "Đi tiếp", `r5-23-15b-training-completed.png`). Evidence: `r5-20/21/22/23`, `cam.mp4`.

## 2. W12, pads per training step (MF 7c / AC27)

**PASS.** `stage teach` (dummies): only ◀ ▶ and **Đánh**. `stage blocks`: adds **Đỡ**. `stage special`: adds **Cờ**. The same holds in EN (Defend/Attack). Evidence: `r5-12-training-dummies-pads.png`, `r5-13-training-blocks-pads.png`, `r5-14-training-special-pads.png`, `r5-17-training-blocks-en.png`.

## 3. W7, pause and sound top-left (Input Rule 3)

| Check | Result | Evidence |
|---|---|---|
| Pause and sound top-left on play, intro, ending, quiz and results | **PASS** | `r5-02…05`, `r5-10…17` |
| Sound only on the title | **PASS.** The title shows only the speaker, and tapping it toggles mute. | `r5-01-title.png`, `r5-43/44` |
| Nothing on unlock | **PASS** | `r5-06-unlock.png` |
| Pause works from intro, ending and results, and resumes | **PASS.** Each opens "Paused" with Keep playing, Home and VI\|EN; Keep playing returns to results. | `r5-07-pause-from-{intro,ending,results}.png`, `r5-08-resume-results.png` |
| Pause and sound ≥ pad_min | **PASS.** Radius ≥ 68.5 world px, so ≥ 137 across. | code (`cornerSize`) and screens |
| **Nothing overlaps them** | **FAIL (B6)**, for story screens and cards only. On play beats AC11 passes: the goal plate clears the sound button by about 8 device px. | `r5-02-intro.png`, `r5-03-ending.png`, `r5-41-B1-card-f1-dbl.png` |

## 4. Banner and top stack (hud.md §3.3)

| AC | Result | Notes | Evidence |
|---|---|---|---|
| AC10, the goal plate in the same place on every beat | **PASS** | The walk (non-banner) plate sits at the same y and centre as on hold, training and reach. Walk_to segments have no plate, as designed. | `r5-56-walk-beat-goal-plate.png`, `r5-11`, `r5-13`, `r5-15` |
| AC9, the banner in the sky, 2 lines in EN and 1 in VI, never covering a body, same height | **PASS** | Pixel scan of the bar: **device rows 274–416 (143 px = 112 world) in both VI and EN**. The EN second line ("kindness") ends at row 406, **10 px inside the bar, not clipped**. *(The iOS overflow does not happen on Android.)* No head or body pixels under the bar in training or reach captures; only the hero's raised staff tip passes behind it (allowed). | `r5-16-flag-encounter-en.png`, `r5-17-training-blocks-en.png`, `r5-13-training-blocks-pads.png` (VI) |
| AC11, nothing overlaps pause/sound (play) | **PASS** | The dots, plate and banner all clear the two buttons. | `r5-13…17` |
| AC12, pops beside the head | **PASS** | "Ối!/Oof!" appears to the left of the hero's head at head height, clear of the banner bar. | `sp.mp4`, `sp1.mp4` frames |
| AC13, the enemy's weapon tip visibly reaches the hero | **Concern / NOT ASSESSED** | In two recorded leader strikes (frames 0.81 → 1.07 s and 1.06 → 1.18 s), the first strike frame already shows the hero **pushed back and blinking**. The padded tip lands at ground level where his feet were. **No frame shows the spear touching his body**, so a child sees the push without the contact. Frame drops under host load mean a single contact frame may be missing, so it isn't called FAIL. Suggestion: hold the contact pose for 1–2 frames before the push, and aim the thrust at chest height. The hero's 175 px swing reach wasn't frame-measured. | `sp.mp4`, `sp1.mp4` |

## 5. Placeholders at spec height

**PASS.** The hero is noticeably smaller than in r4 (about 245 world px tall). Proportions to dummies, partner, spear soldiers, the leader and the pads read correctly. Nothing is clipped or reads wrong. The figures still sit on the ground line, and the pop and goal stack stay clear.

## 6. Regression

| Item | Result | Notes | Evidence |
|---|---|---|---|
| Full run (read everything) | **PASS** | After `pm clear`: intro, walk, dialogue, hold, training, reach, ending, the quiz (4 retries → **1★**) and the medal earned. It ran in 3 segments because the emulator crashed under host load (see Environment) and my screen detector needed two fixes for the camp's navy sky. Each segment resumed from the same run state. | `r5R-*`, `r5R3-*`, `r5-52-results.png` |
| B1 spot-checks, 3 of 3 | **PASS** | Intro 1→2 (0.139 s down to down), card f1 line 1→2 (0.139 s), "Xin vào!" line 2→3 with the plea shown (0.170 s). One advance each. | `r5-40/41/42`, `input-timing.txt` |
| B4 | **PASS** | A second card tapped 0.199 s after the wrong pick's lift (kernel), inside the shake, was ignored. It stays unchanged in every frame. | `r5-51-B4-tap-during-shake.png`, `b4r5.mp4` |
| G2, reach-the-flag | **PASS** | 57 s by the bot, including adb overhead (r4 continuous-gesture method: about 41 s). | `r5R3.log` |
| Skip and medal | **PASS** | With the medal earned, Skip on a dialogue line goes straight through. After `pm clear`, the D-07 warning shows. | `r5-54`, `r5-55` |
| Save after a kill | **PASS** | Killing the app on results keeps `stars=1`, `completed` and `medal`. | `r5-53-title-after-kill.png` |
| Mute persistence | **PASS** | The title's sound button sets `sound=false`. After force-stop and relaunch it is still false, with the muted icon shown. Toggled back afterwards. | `r5-43`, `r5-44` |
| logcat | **PASS** | 31 app processes: 0 FATAL/AndroidRuntime, 0 ANR, 0 `DaiDat` content warnings. E lines are only emulator codec noise and one `SurfaceSyncGroup` timeout under load. | `logcat-r5` (scratchpad) |
| Network | **PASS** | No permissions, and no network use in logcat. | — |
| Release gate | **PASS** (still refuses) | Log `commit f02c0d6…`: `:app:contentGate FAILED`, "R12 … claims not approved: C01 … C16", then `BUILD FAILED`. | game-dev-002 log |

## Bug

### B6: the sound button overlaps the story picture and the card panel corner (Input Rule 3 / "nothing overlaps pause/sound")
- **Severity:** Low (S4), P3. A cosmetic overlap, but the button is semi-transparent, so the frame corner shows through it.
- **Build / device:** f02c0d6, emulator-5554.
- **Steps:** Open intro box 1, the ending, or a beat card (for example card f1).
- **Expected:** Pause and sound sit clear of every other element.
- **Actual:** The sound button (at world x about 223–360, y 18–155) covers the **top-left corner of the story picture frame** on the intro and ending, and the **top-left corner of the beat-card panel**. Play beats are fine.
- **Suggestion:** Push the story picture and card panel down or right by about one button height on screens that have the corner icons, or keep a safe zone for them.
- **Evidence:** `r5-02-intro.png`, `r5-03-ending.png`, `r5-41-B1-card-f1-dbl.png`.

## Observations (contrast)

- **"Ối!/Oof!" pop:** red (228,84,60) with no outline. Measured contrast: **1.95:1** on the camp's lower navy sky (76,84,128), 3.3:1 on the darkest navy (47,50,87), and **2.5:1** on the mint mountains it often overlaps. That's under 3:1 on most backgrounds. Suggestion: a white or ink outline, or white text with a red outline.
- **Banner text:** gold (242,182,50) on the red bar (217,52,43) is about 2.6:1. It's the "six golden words" look, so it's a design choice, but it's low for 6–10-year-olds. An ink outline on the gold would keep the look and help legibility.

## Environment

- **The emulator crashed again** at 22:19 under host load: QEMU's main and CPU threads hung for 15 s, then SIGSEGV (139), with no shutdown request. QC relaunched it (QC owns the lifecycle). The regression run was restarted from `pm clear`, and the evidence from the interrupted run was deleted.
- **Watcher:** 614 samples in r5. The only extra adb client was the emulator's own startup broadcast (`am broadcast … multidisplay.START`, parent `qemu-system-aarch64`, from QC's relaunch). No foreign input on 5554.
- This build has not been seen on a real low-end phone, and nobody has listened to the sound.
