# TASK-007 Android QC, round 10 (native Kotlin, build d8403dd)

**Overall r10 verdict: FAIL (one visual defect, B8).** Everything timed in AC32 passes: the finish hold lasts 1.5 s, a mash doesn't shorten it, and a resume gives ≥ 0.8 s of banner-up. The hint hands (AC12), the double-outline pop (AC15) and the full regression (3★ + medal, rolling lock, B7, small quiz) also pass.

**B8:** in the real flow the hero reaches Cờ near the right edge, so the partner re-enters from the left, which is the same side as the raised banner. **The banner cloth then covers the partner's head and face**, and the partner faces the hero, not the banner (AC32: "stands beside the hero facing the banner"). Dev's debug shot didn't show it because there the hero is mid-screen.

| Item | Value |
|---|---|
| Build | `d8403dd` (155 JVM tests per dev). APK sha256 `6f72822b2504e1919a06a975079b3771dd8bf8133a8768f10d85014dc136ee79`, re-hashed by QC and on the device. |
| Specs | docs/vn-history-game-plan @ 06f31b3 (r10 rules from 6a066f0: Rule 7c/AC32, Hints Rule 6/AC12, hud AC15) |
| Device | `emulator-5554` (mp17863), API 36, landscape, k ≈ 0.488. Fresh boot this round. |
| Input | Timing input streamed through one `cat` (`fastmt.py`); kernel `getevent -lt` lines in `input-timing.txt`. Durations come from screenrecord frames. Precise hold timings were done at `--ef slow 0.1`, where 10 s wall = 1 s game, so a ±16 ms frame error becomes ±1.6 ms. |
| Host load | 9–15 all round. No emulator crash. |

## 1. Training finish hold (Rule 7c, AC32)

| Check | Result | Measurement | Evidence |
|---|---|---|---|
| Pads and the special hint hide at the Cờ tap | **PASS** | Normal speed: the first frame after the tap (2.328 s) has no pads and no hand. Real flow: pads gone at 51.695 s. | `fh.mp4`, `tr.mp4` (scratchpad) |
| Banner rises ≈ 0.67 s, then holds | **PASS** | The cloth's top at x 300 goes from **y 328 to 288 (40 px)** with an ease-out: 2.328 → ≈ 2.86 s (last 2 px by ≈ 2.99). It then stays at 288. Slow 0.1: from 328 at 2.477 s to 288 at 7.928 s wall. | `fhp.py` traces |
| **Banner-up after the rise ≥ 0.8 s** | **PASS** | Normal speed: tap → end **1.499 s**, so banner-up ≈ **0.83 s**. Slow 0.1: tap → end 15.149 s wall = **1.515 s** game; the rise ends at 0.67 s, so banner-up ≈ **0.85 s**. (r9: 0.57 s total.) | `fh.mp4`, `fs-plain.mp4` |
| Partner re-enters beside the hero, staff upright | **PASS (debug path) / B8 (real flow)** | With the hero mid-screen (debug `stage special`), the partner walks in from the right during the rise and stands beside the hero, staff upright (`r10-04`). **Real flow: see B8.** | `r10-04-hold-banner-up-partner-staff.png`, `r10-08-realflow-hold-banner-up.png` |
| Cheer, 4th dot fill and walk start ≥ 1.5 s after the tap | **PASS** | Real flow: pads hide 51.695 → scene switch, cheer stars, 4 dots and walk pads at 53.211 = **1.516 s**. Debug: 1.499 / 1.515 s. | `tr.mp4`, `r10-07` |
| Raised banner below the bar | **PASS** | Top at y 288 ≥ 276 (bar bottom 268). | traces |

### 2. Mash during the hold (a tap every 0.2 s, alternating the Cờ and Attack spots)

**PASS.** Kernel: taps at 0, 0.200, 0.401, 0.601 … every 0.200 ± 0.002 s.
- Normal speed: tap → end 1.464 s from the first frame showing the tap. The recording has an 86 ms frame gap right at the tap, so the true value is in 1.46–1.55 s. The rise curve is identical to the plain run.
- **Slow 0.1, 85 taps:** tap → end **15.168 s wall = 1.517 s**, against 1.515 s without the mash. Nothing shortens the hold.
- After the hold: the cheer and the walk pads, and no attack or other action carried over from the mash.

Evidence: `r10-03-finish-mash-0.2`, `fs-mash.mp4`, `input-timing.txt`.

### 3. Pause in the hold

| Case | Result | Measurement (slow 0.1) |
|---|---|---|
| Pause at +0.29 s (game), resume after ≈ 3 s wall | **PASS** | On resume the banner shows straight at its raised position (288). **Resume → end 8.234 s wall = 0.823 s ≥ 0.8** (dev's 0.833 is within one frame). |
| Pause twice (+0.29 s; then 0.41 s after the first resume) | **PASS (ends, never stuck)** | The first resume restarts the hold, as above. The second resume does **not** restart it: the beat ends **0.414 s** after the second resume (4.137 s wall). This is dev's "restart once" guard. **Note for design:** after a second pause the child sees only ≈ 0.4 s of the banner. AC32's wording covers a single pause. |

Evidence: `fs-pause1.mp4`, `fs-pause2.mp4` (scratchpad), `input-timing.txt` (`fs-pause1/2`).

## B8. Real flow: the raised banner covers the partner's face (AC32 placement)

**FAIL.** I played the training beat through (autoplay, `tr.mp4`), so the hero reaches Cờ near the right edge (hero x ≈ 1000–1090 world).
- The partner re-enters **from the left** (the side away from the nearer edge, as specified), and the raised banner is also on the hero's left.
- The partner ends up **under the banner cloth**: its head and face are covered by the red cloth down to the eyes (`r10-08`, crop: only the eyes and mouth show below the cloth).
- The partner faces the hero (right), not the banner. AC32 requires "stands beside the hero facing the banner".
- With the hero mid-screen (dev's debug shot, QC `r10-04`) the partner comes from the right and nothing overlaps. So the bug depends on where the hero stands, and real play puts him near the right edge.

Suggested direction (dev/design): when the partner has to come from the banner's side, place it beyond the banner, or put the banner on the hero's other side.

## 4. Hint hands on banner beats (Hints Rule 6, AC12)

| Hand | Result | Measurement |
|---|---|---|
| Cờ teach hand | **PASS** | Hand x ≈ 955–1047 (white 970–1047, red cuff to the left), **y 376–427**: left of Cờ at its mid-height (Cờ centre y ≈ 400), pointing right. Every pixel ≥ 276. ≈ 27 px clear of Cờ's pad square (x ≥ 1074). (r9: the hand was at y 226–307, in the bar.) |
| Attack teach hand (dummies step) | **PASS** | Above Đánh, pointing down, bobbing **y 388–487**. Đánh's visual top is ≈ 501 and its pad square starts ≈ 516. Below the bar. |
| Đỡ teach hand (blocks step, frozen windup) | **PASS** | Above Đỡ, **y 447–524** (cuff ≈ 435). Đỡ's pad square starts ≈ 551. |

Evidence: `r10-01-special-teach-hand.png`, `r10-05-hand-teach-*`, `r10-06-hand-blocks-frozen.png`.

## 5. Pop outline (hud AC15)

**PASS.** On the sample hero's camp beat (slow 0.3), the "Ối!" has a **double outline: cream inside, ink outside**. It reads clearly over the mint hill and the navy sky (it straddles both in the capture). The bamboo sky keeps the **ink-only** outline. Evidence: `r10-14-oof-camp.png`, `r10-12-oof-bamboo.png`.

## 6. Observations (not fails)

- **Partner's staff tip in the bar band:** the upright staff's tip reaches **y ≈ 263**, right at the bar's bottom edge, with the shaft faintly visible through the translucent bar. It reads acceptably, as a staff passing behind the bar (`r10-04` crop).
- **Background switch with faded dummies still on screen: yes.** In the real flow, at the hold's end the background jumps straight to the night camp (beat 5 theme), with the cheer and the walk pads. **The faded training dummies are still drawn in the camp scene** for about a second (`r10-07-realflow-hold-end-camp-bg-with-faded-dummies.png`). Straw dummies in an enemy camp read oddly.
- The debug jump `--es stage special` goes from the hold straight to beat 5 without the walk or the Phần 5 card; in the real flow the walk and the Phần 5 card follow. This is debug-only, as in r9.

## 7. Regression

| Item | Result | Notes | Evidence |
|---|---|---|---|
| Rolling lock, real flow (0.35 s mash, 50 s) | **PASS** | Intro 1.75 / 1.75 / 1.74. Card 1 1.67 / 1.75 / 1.75. **Dialogue 9 lines: 1.82, 1.73, 1.77, 1.73, 1.75, 1.75, 1.77, 1.73, 1.77.** "Quả cam" 1.68 / 1.73. | `r10-20-flow-mash`, `flow10.mp4` |
| B7 ending under an Attack mash | **PASS** | Box 1 5.727 → box 2 7.377 (**1.65 s**) → quiz 9.127 (**1.75 s**). | `r10-32-*`, `b7r10.mp4` |
| Full read-everything run, 3★ + medal | **PASS** | `pm clear`, 0 skip warnings. Every story screen in the real flow, including the new ending scene. Perfect quiz with 0 retries. Prefs `stars=3, medal=true`. Title after: 3★ and gold. | `r10R-*`, `r10R-results`, `r10-40-title-after-run` |
| Small quiz ≤ 720 | **PASS** | Tiếp y 554–701 plus a 4 px shadow to 705. Right card in the left slot, why line to its right, pill fine in VI/EN. | `r10-33-quiz-right-vi/en` |
| Per-question lock | **PASS** | Tiếp at kernel 0 and 0.300; Q2 shows with no card picked. | `r10-34` |
| Story screens / ending still | **PASS** | No play layer; the ending shows the full-bleed scene. | `r10R-01..09` |
| Flag below the bar | **PASS** | Cloth y 300–369 at x 1050; the arrow points from the far side. | `r10-30`, `r10-31` |
| VI/EN | **PASS** | Quiz; the story screens are unchanged since r9. | — |
| logcat | **PASS** | 19 app starts: 0 FATAL, 0 ANR, 0 `DaiDat` warnings. | `logcat-r10.txt` (scratchpad) |

## Environment

- Watcher: 170 samples. All input was QC's own; **no foreign input on 5554**.
- Not assessed, as before: the sound (including whether the cheer is heard at the hold's end), and a real low-end phone.
