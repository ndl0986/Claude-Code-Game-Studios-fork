# TASK-007 Android QC, round 11 (native Kotlin, build 742a230)

**Overall r11 verdict: PASS.** **B8 is fixed in the real flow.** The partner now enters from the front, stands in front of the hero facing the banner, and touches neither the cloth nor the hero in any frame. Case (d) puts the partner beyond the banner, 12 px clear. Every resume (N = 1, 2, 3) gives ≥ 0.8 s of banner-up. No dummy or prop is drawn on the night camp (AC34). Regression: everything passes (hold, mash, hands, camp pop, rolling lock, 3★ + medal, quiz, ending, VI/EN).

| Item | Value |
|---|---|
| Build | `742a230` (157 JVM tests per dev). APK sha256 `2e112eb99dc5b93d458ae06795c77d5bb85b00cbe387de3954df5102652692e9`, re-hashed by QC and on the device. |
| Specs | docs/vn-history-game-plan @ 4a0dd64 (Rule 7c Placement, AC32–34 from a092a89) |
| Device | `emulator-5554` (mp17863), landscape, k ≈ 0.488 |
| Input | Timing input streamed through one `cat` (`fastmt.py`); kernel `getevent -lt` lines in `input-timing.txt`. Hold/pause timings measured at `--ef slow 0.1` (10 s wall = 1 s game). |
| Host load | 9–18 all round. No emulator crash. |

## 1. B8 retest, real flow (the same autoplay as r10)

**PASS.** Autoplay through the training beat (`tr11.mp4`). The hero taps Cờ near the right edge facing right, as in r10.

| Check | Result | Measurement |
|---|---|---|
| Partner placement | **PASS** | The banner is behind the hero (left), and the **partner stands in front (right)**, facing left toward the hero and the banner (`r11-01-realflow-hold-partner-front.png`). |
| No overlap, any frame | **PASS** | Tracked every frame from the tap to the end. The partner only moves left toward its final spot; at the end its leftmost pixel (head) is ≈ 40 world px clear of the hero's rightmost (arm/staff). The cloth is far to the left of the hero. |
| Walk-in, linear, ≈ 0.67 s | **PASS** | It first shows at the right edge at 67.907 s (it starts off screen, so **no fade**, correct). It then moves 4–5 px per frame at a constant rate (x 1276 → 1127) and **stops at 68.473 s, 0.683 s after the banner first appears** (67.790). |
| Faces the banner at the end | **PASS** | Faces left (from the front, that's also toward the hero). |
| Hold | **PASS** | Pads hide 67.790 → night background 69.308 = **1.518 s**. |

## 2. Case (d) `finishleft` and `finishright` (slow 0.1)

| Case | Result | Measurement |
|---|---|---|
| `finishleft` (hero ≈ x 100, facing left; banner on his right) | **PASS** | The partner **fades in on screen** (semi-transparent in the first frames), walks left, and stops **beyond the banner**, facing left toward it. Row scans of the hold frame: cloth right edge **x 301**, partner's leftmost pixel (staff/face) **x ≈ 313**, so **≈ 12 px clear (≥ 8)**. No overlap with the hero. `r11-10-finishleft-hold.png`, `finishleft.mp4`. |
| `finishright` | **PASS** | Partner in front (right) of the hero, fading in on screen, facing left, ≈ 40 px clear of the hero; the cloth is behind the hero. `r11-10-finishright-hold.png`. |

## 3. Pause (AC32, slow 0.1; first pause during the rise at +0.29 s game)

| N | Last resume → cheer/next beat | Result |
|---|---|---|
| 1 | 8.392 → 16.592 s wall = **0.820 s** | **PASS** |
| 2 (second pause 0.41 s after the first resume) | 15.526 → 23.795 = **0.827 s** | **PASS** (r10: 0.41 s) |
| 3 | 23.558 → 31.808 = **0.825 s** | **PASS** |

Every resume shows the banner straight at its raised position. **A resume during the rise puts the partner at its spot at full opacity on the first frame** (`r11-20-pause-during-rise-before-after-resume-final.png`: paused mid-rise | first frame after resume | final frame are the same pose). It never gets stuck.

## 4. AC34: training props gone on the next theme

**PASS.** Real flow, frame-stepped across the switch (`r11-02-realflow-first-night-f_069224…069490.png`). The last day frame is 69.290 s; **the first night-camp frame (69.308 s) has no dummy, no partner and no prop**, and neither does any later frame. (r10: faded dummies on the camp for about 1 s.)

Observation: in that **first night frame only**, the hero is still drawn at his old screen position (right side, under the "Đi tiếp" arrow), then jumps to the camp start position in the next frame (69.324 s). It lasts one frame (≈ 16 ms) and is barely visible; noted for dev.

## 5. Regression

| Item | Result | Notes | Evidence |
|---|---|---|---|
| Hold timing | **PASS** | Real flow 1.518 s; slow-0.1 plain hold within the pause runs. | §1 |
| Mash during the hold (0.2 s, Cờ/Attack spots, 85 taps, slow 0.1) | **PASS** | Tap → end 15.153 s wall = **1.515 s**. Nothing carried over. | `r11-31-*`, `m11.mp4` |
| Hint hands ≥ 276 | **PASS** | Cờ hand x 961–1037, y 376–427 (left of Cờ, pointing right). The attack/Đỡ hands are unchanged from r10 (dev change limited to placement). | `r11-30-special-teach-hand.png` |
| Camp double pop outline | **PASS** | Cream inside, ink outside, over the mint hill and the navy sky. | `r11-32-oof-camp.png` |
| Rolling lock, real flow (0.35 s mash) | **PASS** | Intro 1.72 / 1.75 / 1.75 / 1.75. Card 1.70 / 1.73 / 1.75. **Dialogue 9 lines: 1.80, 1.75, 1.75, 1.73, 1.75, 1.77, 1.75, 1.75, 1.75.** "Quả cam" 1.72 / 1.73. | `r11-40-flow-mash`, `flow11.mp4` |
| Full run, 3★ + medal | **PASS** | `pm clear`, 0 skip warnings, every story screen; perfect quiz with 0 retries; prefs `stars=3, completed=true, medal=true`; title 3★ and gold. | `r11R-*`, `r11R-results`, `r11-50-title-after-run` |
| Small quiz ≤ 720 | **PASS** | Settled: Tiếp x 820–1260 at y 640 (rim from 819.6), **y 554–702.0** (rim), shadow to 706. **Observation:** Tiếp's idle pulse periodically scales it, so the rim bottom reaches **≈ 705.9** and the shadow ≈ 710. That is within 720, but ≈ 4 px past the 702 line in quiz AC7. Probably the same in earlier rounds, which sampled only at ≈ 2.5 s. | `r11-41-quiz-right-vi/en` |
| Ending still | **PASS** | Full-bleed scene, VI/EN. | `r11-42-ending-vi/en` |
| VI/EN | **PASS** | Quiz and ending. | — |
| logcat | **PASS** | 16 app starts: 0 FATAL, 0 ANR, 0 `DaiDat` warnings. | `logcat-r11.txt` (scratchpad) | |

## Environment

- Watcher: 154 samples. All input was QC's own; **no foreign input on 5554**.
- No emulator crash.
- Not assessed, as before: the sound, and a real low-end phone.
