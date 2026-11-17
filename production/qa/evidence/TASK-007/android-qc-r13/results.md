# TASK-007 Android QC, round 13 (native Kotlin, build 3183874)

**Overall r13 verdict: PASS.**
1. **FrameClock:** after a mid-hold pause, the hold ends inside the leader's window of **0.833–0.850 s** after the resume frame, at every N and at both speeds. At real speed every run is **exactly 51 frames** (the resume frame + 50 sim frames). Resume and Home-from-pause show **no jump and no speed-up**.
2. **Skin:** every drawn skin is **`#F1C9A0`** (hero, partner, enemy), and **0 px of the old `#F5C9A0`** is left anywhere. The hint hand is a white glove with a red cuff and draws no skin, so there is nothing to change there (§2).
3. **The full r12 suite passes again.**

| Item | Value |
|---|---|
| Build | `3183874` (JVM 171 per dev). Diff against r12's `1ae1560`: `FrameClock.kt` (new), `GameView.kt` (uses it; `drainInput()` sits between `wasPaused` and the `resumed()` check, so the branch can fire), `Draw.kt` (`SKIN` = `#F1C9A0`), `FrameClockTest`. |
| APK | sha256 `c87774112f6dfabc00ed27317a6fb1adc647a5e97c122fa3da3ec2728157cbc7`; QC re-hashed it on the Mac and on the device, and both match the leader's hash. Clean uninstall and install. |
| Device | `emulator-5554` (mp17863), landscape, k ≈ 0.488. Measured frame period **16.665 ms** (60 Hz). |
| Host load | The 1-min load is noted per item. Two runs went over 20 (iOS build, load 112 / 90) and one first-N=3 run had a 1011 ms host stall. All three are marked **invalid** and rerun at loads under 12. Every counted timing ran at a load of 4.4–12.3. |
| Specs | docs `0f90158` + the leader's r13 window (0.833 ≤ t ≤ 0.850 s from the resume frame; under 0.833 is a FAIL). |

## 1. FrameClock (pause / resume / home)

Measured from the **resume frame** (the first undimmed frame) to the **first night-camp frame** (end of the finish hold), in `finishright`.

**Slow 0.1** (10 s wall = 1 s game; frame resolution ≈ 1.7 ms game):

| Run | Load | Resume frame → night | Game s | Result |
|---|---|---|---|---|
| N=1 (`s1`) | 4.4 | 6.606 → 14.990 = 8.384 s | **0.8384** | PASS |
| N=2 (`s2`) | 5.2 | 12.010 → 20.392 = 8.382 s | **0.8382** | PASS |
| N=3 (`s3d`) | 10.9 | 17.257 → 25.623 = 8.366 s | **0.8366** | PASS |
| N=3 (`s3`), **invalid** | 5.6 at start | 0.8874 | — | The video has 15 frame gaps over 60 ms, one of them **1011 ms**: a host stall during the run. A stall over FrameClock's 0.25 s clamp drops sim time, so the hold runs long. Rerun as `s3d`, which has no gap over 60 ms. |
| N=3 (`s3b`, `s3c`), **invalid** | 112 / 90 | 0.8370 / 0.8382 | — | Both in range, but over the load rule. |

**Real speed** (pause 0.32 s after tapping Cờ, then resume 1 s later; N=2 adds a second pause 0.42 s later):

| Runs | Load | Resume frame → night | Frames at 16.665 ms | Result |
|---|---|---|---|---|
| N=1 × 5 (`r1a`–`r1e`) | 8.4–12.3 | 0.850, 0.852, 0.851, 0.850, 0.850 s | **51.0, 51.1, 51.1, 51.0, 51.0** | PASS |
| N=2 × 3 (`r2a`–`r2c`) | 7.5–8.5 | 0.848, 0.849, 0.850 s | **50.9, 50.9, 51.0** | PASS |

Every run is **51 frames = 0.8499 s**: the resume frame (0 steps) plus 50 sim frames, which is the "up to one frame late" end of the window. The video timestamps are whole milliseconds, so 0.848–0.852 is ±2 ms of rounding around 0.8499; none is a 50- or 52-frame result. None is under 0.833.

**No jump or speed-up** (`r13-21-pause-resume-home`, `ph.mp4`, load 7.3; frames `r13-22…24`):
- **Resume:** the hint hand moves left about 0.8 world px per frame. The last frame before the pause dim (4.143 s) has the hand at x **978.1**. The **resume frame (6.743 s) has it at 978.1**, the same place; the next frame is unchanged (the 0-step resume frame); after that it carries on at about 0.8 px per frame. There is no catch-up step.
- **Home from pause** ("Màn hình chính"): on the first title frame (10.409 s) and the next one, the Start button is at the same width, 413.9 (the 0-step frame). After that its pulse grows smoothly by about 1.6 px per frame, with no jump.

## 2. Skin `#F1C9A0` (lossless screencaps)

| Figure | `#F1C9A0` px | `#F5C9A0` px | Evidence |
|---|---|---|---|
| Hero face (`finishright` hold) | 1300 (the dominant face colour) | 0 | `r13-30-finishright-hold-skin.png` |
| Partner face | 721 (dominant) | 0 | same |
| Enemy face (reach-the-flag) | ≈ 970 (right of the hero) | 0 | `r13-32-enemy-skin.png`, `r13-33-oi-camp*.png` |
| Whole screen, three screens | 3299 / 2421 / 2421 | **0 on every screen** | — |
| Hint hand | **0** | **0** | `r13-31-special-hand-skin.png` |

**The hint hand has no skin to check.** `Figures.hand()` draws it as a **white glove (`C.WHITE`) with an ink outline and a red cuff**, with no `C.SKIN`. That is unchanged from r12 and drawn correctly. The r13 commit message lists "hint hand" among the skin users, which is a wording slip. If iOS draws a skin-coloured hand, the two apps differ there, but on Android there is nothing to change.

## 3. Regression (r12 suite)

| Item | Result | Measurement / notes |
|---|---|---|
| Debug jumps write no progress | **PASS** | Fresh install. Jumps: results (newmedal, 3★) + Next ×3; quiz q5 right + past the end; unlock (3★); ending + 6 taps; play beat 4 finish; title (lang en). Each left **no save file**; the title jump saved only `lang`. A normal launch has `seen_open` + `lang` only, and the title shows **0★ and no medal** (`r13-43`, `r13-save-prefs-after-debug-jumps.xml`). |
| Medal and stars | **PASS** | A real EN autoplay afterwards (0 skip warnings, quiz 5/5, 0 retries) saved `stars=3, completed=true, medal=true` (`r13-save-prefs-real-run.xml`). Results 3★ + "You earned the medal!" (`r13-44`); **relaunch: title 3★ + gold medal** (`r13-45`). |
| B8 real flow (`tr13.mp4`, load 5–7) | **PASS** | Partner in front, facing the banner. Positions are identical to r12 (partner's left edge at device x 1923, so ≈ 54 world px clear). Walk-in from off screen with no fade, linear, stops **0.684 s** after the banner. **Hold 1.518 s** (pads hide 52.575 → night 54.093). `r13-01*`. |
| Partner 0.62 × hero | **PASS** | 143 / 230 px = **0.622**. |
| Camera cut + AC34 | **PASS** | The last day frame is 54.076; the **first night frame (54.093) has the hero at the camp start** (legs x 443.9–474.4) and stays there; no props (`r13-02/03`). |
| `finishleft` (d) | **PASS** | Fades in; cloth right edge 301.0, partner's left 323.7, **21.9 px clear** (`r13-60/61`). |
| Mash during the hold (slow 0.1, 85 taps) | **PASS** | Pads hide 2.740 → night 17.907 = **1.517 s** game (load 6.2–8.3). |
| Rolling lock, 0.35 s mash | **PASS** | **Intro (real flow, load 6.0):** "Long ago" was accepted at the first press after ≈ 1 s (allowed); then **1.737 / 1.748 / 1.750 s**. **Dialogue (load 8.5):** lines 2–9 held **1.734, 1.751, 1.749, 1.749, 1.751, 1.750, 1.749, 1.751 s** (≥ 1.5). **"Quả cam" (load 9.1):** box 2 held **1.749 s**. |
| Deliberate taps (load 8.7–9.2) | **PASS** | After box 2 enters: taps at +0.35/+0.70 and then a **0.45 s gap** → still on box 2; with a **0.62 s gap** → box 3 (`r13-53-*`). |
| Hints AC12 (visible square) | **PASS** | 28 frames in VI and EN, 78 hand blobs: 0 overlaps, every hint pixel at y ≥ 276; hand x ≤ 1049.9, outside Cờ's pad_min square (1075–1223). |
| Camp double pop | **PASS** | "Ối!": cream inner outline, ink outer outline, over the mint hill and the navy sky (`r13-33-oi-camp-zoom.png`). |
| Quiz AC7 | **PASS** | VI and EN, 30 frames each: gold fill bottom 695.8 at rest (≈ 702 with the rim); every pixel incl. shadow **≤ 710.6** (≤ 720). |
| Story AC10 | **PASS** | Bỏ qua rim 552.9–702.8 (≈ 150 tall); Tiếp at rest 553.7–702.0 (matches); pulse ≤ 705.9. |
| Ending + corner block | **PASS** | VI and EN, pole x **501–515** (> 416), top y 121 (`r13-64-*`). |
| Release gate | **PASS** | `release-gate-3183874.log`: contentGate fails on R12 (C01–C16) only. |
| logcat | **PASS** | 45 app starts: 0 FATAL, 0 ANR, 0 `DaiDat` W/E. |

## Environment

- No emulator stop. The input watcher saw only QC's own sendevent signature (`3 57 101012`): **0 foreign input on 5554**.
- Not assessed, as before: the sound, and a real low-end phone.
