# TASK-007 Android r5: developer evidence (game-dev-android)

Build **f02c0d6** on `setup/TASK-007-android-kotlin`. APK `production/qa/builds/TASK-007-f02c0d6.apk`,
sha256 `b5d008474fa227dd01c5cc8d531ac2dee24820f3cb839e585a9fb29e09d00283`. Unit tests: **107/107, 0 skipped**
(TraceTest replays trace-tqt.json 1.1). Release gate log: R12 fails, as it should (C01–C16 pending).
Device: my own AVD `devandroid002` (emulator-5556), API 36, 1080×2400 @ 420 dpi. Its safe rect is
width-limited (a 78 px left gesture inset), so k = 0.488 dp per world px, smaller than the QC
reference phone's 0.527. The pad_min corner is therefore wider here (to x ≈ 338), and the top stack
shifts right to stay clear of it (see the note below). **Not the QC device.**

| Shot | Checks |
|---|---|
| `r5-01-training-dummies-vi/en` | **W12:** dummies step shows only ◀ ▶ and Đánh; the hand points down at Đánh. **Top stack:** dots, goal plate (920, box 880), banner bar (920 × 112): VI 1 line, EN 2 lines; every body below the bar (AC9) |
| `r5-02-encounter-vi/en` | The same stack in reach-the-flag. Bodies at spec height (hero 180, enemies ≤ 170); the stack clear of pause/sound (AC11) |
| `r5-03-training-blocks-vi` / `r5-04-training-finish-vi` | **W12:** blocks + Đỡ; finish + Cờ (hand on Cờ) |
| `r5-05-telegraph-leader-en` (frozen) / `r5-11-windup-telegraph-over-bar-vi` | The "!" draws over the bar (z-order, §3.3) |
| `r5-12-pop-beside-head-strike-vi` | **AC12:** "Ối!" beside the hero's head at head height, away from the enemy, below the bar (a hurt-blink frame, so the hero isn't drawn); the spear out on the strike, reaching the hero (AC13) |
| `r5-10-15b-after-4s-right-vi` | **15b on device:** ▶ held 4.5 s from training start (input motionevent). The camera is capped, the hero is stopped at the right limit, all three dummies are still on screen, and the stall arrow points back at the first |
| `r5-06-quiz-vi` | Pause/sound at pad_min top-left; the counter beside the dots; the prompt below the corner |
| `r5-07-intro-corner-vi`, `r5-08-results-corner-vi` | **W7:** pause and sound top-left on story screens and results |
| `r5-09-title-sound-vi` | The title has sound only (top-left), and the VI\|EN chip top-right |

**Note for the spec (hud.md §3.3):** the band x 330–1250 holds for k ≥ ≈ 0.50. On a phone with a
smaller k (like this AVD), Android starts the 920-wide stack 8 px right of the actual pad_min
corner, with its centre clamped to 790–810.
