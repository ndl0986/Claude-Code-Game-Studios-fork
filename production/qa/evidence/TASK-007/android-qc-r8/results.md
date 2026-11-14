# TASK-007 Android QC, round 8 (native Kotlin, build ea70edb)

**Overall r8 verdict: PASS.** The rolling lock now holds every story box and every dialogue line (all 9 Bình Than lines) for ≥ 1.5 s under a 0.35 s mash. A deliberate tap 0.6 s after the last press goes through, and the 0.45 s control doesn't. The quiz's small layout is correct, and Tiếp is inside 702. Story screens are clean: no play sprites and no top stack, with the 256/208 portraits and the "Phần n" label in place. The "!" and the gold arrow stay below the banner bar. Regression: the full read-everything run gives 3★ and the medal, B7 holds under a mash, and the skip warning, title card, VI/EN, contrast and logcat all pass. There are no new dev bugs. One asset gap (the ending still) and two observations are noted.

| Item | Value |
|---|---|
| Build | `ea70edb` (134 JVM tests per dev). APK sha256 `4c1b1bb9667ffee4dae95a11000a20736d52f0146a6678552aa45a4b478667e8`, re-hashed by QC and on the device (`base.apk`). ce119bf was uninstalled first. |
| Specs | docs/vn-history-game-plan @ 01c6a3d (r8 4495f7f, r8b 14cbc1c, r8c 01c6a3d) |
| Device | `emulator-5554` (mp17863), API 36, 1080x2400 at 420 dpi, landscape 90°. **k = 1.28055 / 2.625 ≈ 0.488** (world px → dp). This is the r8c "k 0.488" column, not 0.527, so the small layout is expected either way. |
| Input | All timing input is streamed through one `cat` (`fastmt.py`). Kernel `getevent -lt` lines are in `input-timing.txt`, and every interval is 0.350 ± 0.005 s. Holds are measured from screenrecord frames (≈ 60 fps). |
| Host load | 69 → 10 for the timing cases (`uptime` at install 69/131/90; the B7 case 11). **One emulator crash at 03:26** (load 192: "detected a hanging thread QEMU2 … 15 s", exit 139, the known host-load crash). It came after all the timing cases, during the add-on pop recording. The emulator was restarted, the build was still installed, and the pop capture was redone. |
| Date | 2026-11-15 |

## 1. Rolling lock (Input 13b, AC21/AC22; dialogue AC8; story AC11)

A real flow from the title (`pm clear`). Start, then a tap on the Tiếp/ask spot (1112, 628) every 0.35 s for 62 s, with ▶ pressed 2.8 s of every 3 s on a second finger (`r8-04-flow-mash`, `flow.mp4`). Times are video seconds at the first frame of each box or line.

| Screen | Box/line appears → next | Hold | Result |
|---|---|---|---|
| Intro (4 boxes) | 2.695 → 4.443 → 6.193 → 7.943 → play 9.710 | 1.75, 1.75, 1.75, 1.77 | **PASS**, none skipped |
| Beat card, Phần 1 (3 boxes) | 13.960 → 15.677 → 17.401 → play 19.143 | 1.72, 1.72, 1.74 | **PASS** |
| Bình Than dialogue (9 lines, Tiếp and "Xin vào!") | 27.843 → 29.659 → 31.410 → 33.159 → 34.910 → 36.660 → 38.414 → 40.148 → 41.894 → play 43.645 | 1.82, 1.75, 1.75, 1.75, 1.75, 1.75, 1.73, 1.75, 1.75 | **PASS**: every line ≥ 1.5 s, all 9 seen, so the hero's plea and the king's words can't be mashed past (r7 design question closed) |
| Beat card "Quả cam", Phần 3 (2 boxes) | 47.559 → 49.260 → play 51.010 | 1.70, 1.75 | **PASS** |
| Ending (2 boxes), reached by walking to the flag with Attack every 0.35 s (`r8-33`, `b7r8.mp4`) | 6.242 → 8.025 → quiz 9.776 | 1.78, 1.75 | **PASS** (B7 regression) |

The 1.75 s holds are as specified: the lock caps at 1.5 s, and the next 0.35 s press after that (+1.75 s) advances. No press queued: nothing extra advanced after a mash stopped.

**A deliberate tap goes through after a 0.6 s pause.** On a locked box, kernel taps at 0, 0.35 and 0.70, then one more:

| Case | Last tap | Result | Evidence |
|---|---|---|---|
| Dialogue (line 3 → 4 by the first tap, then the test on line 4) | @1.300 (0.60 after) | **advanced** to line 5 | `r8-05-dl-gap0.60*` |
| Dialogue control | @1.150 (0.45 after) | **stayed** on line 4 | `r8-05-dl-gap0.45*` |
| Beat card (box 1 → 2, then the test on box 2) | @1.300 (0.60 after) | **advanced** to box 3 | `r8-06-card-gap0.60*` |
| Beat card control | @1.150 (0.45 after) | **stayed** on box 2 | `r8-06-card-gap0.45*` |

Captions: TQT has no caption beat (`startScreen caption` on TQT goes to play). The story-screen lock code is shared, and the beat cards and intro pass. Pause and sound inside the lock: passed in r7 (pause opened 0.30 s into a lock), not re-run in r8.

## 2. Quiz, small layout (r8c; quiz AC7–AC9)

| Check | Result | Measurement | Evidence |
|---|---|---|---|
| Small layout on mp17863 | **PASS** | Choosing: 3 cards 380 × 290 with no Tiếp. After the right pick, the right card is in the left slot (x 41–418, y 287–582), the why line is to its right (x 454–1235, y ≈ 295–425), and Tiếp is on the bottom row. | `r8-10/11/12-*-vi/en` |
| **Tiếp ≤ 702 / 720** (the r7 clip) | **PASS (fixed)** | Tiếp **x 811–1262 (450 wide), y 554–702** (white rim to 702.0). Spec at k 0.488: x 812–1262, y 554.5–702. Only its 4 px drop shadow reaches 706 (≤ 720). | live scan, `r8-12-quiz-q1-right-en` |
| Corner block / prompt | **PASS** | Corner block bottom 166 (spec 165.5). The prompt starts below it. | — |
| "Đúng rồi! / That's right!" pill | **PASS** | Over the top of the picture, not clipped, no "…", in VI and EN on all 5 questions. Text ink #1A120C on green, 5.77:1. | `r8-12`, `r8-15-quiz-q2..5-right-vi/en` |
| Wrong cards fade, right card glides, Tiếp last (AC8) | **PASS** | Frame-stepped (`pick.mp4`): the pick at ≈ 2.70 s; wrong cards dimmed at 2.71 and **gone by 2.86**; the right card glides 2.86–3.16; the why line at 3.16; **Tiếp first at ≈ 3.6 s** (+0.9 s). | `pick.mp4` frames |
| Taps where the wrong cards were | **PASS** | Kernel taps at +0.35, +0.66, +1.01, +1.36 and +1.71 on the old slots 1/2 did nothing. | `r8-13`, `input-timing.txt` |
| No Tiếp while a card can be picked | **PASS** | No Tiếp in the choosing or wrong states (5 questions × VI/EN for the right state; Q1 and Q5 for choosing, Q1 for wrong). | `r8-10`, `r8-11`, `r8-16` |
| Per-question lock (small layout, AC9) | **PASS** | On Q1 after the right pick, Tiếp at (1037, 565) at kernel 0 and again at **0.300**. The second tap lands on Q2's third card slot, and **Q2 shows with no card picked**. | `r8-14-quiz-tiep-double-tap-0.3` |

Note: Q5's 2-line card label ("Quân Mông–Nguyên" / "The Mông–Nguyên army") has its second line partly under the debug-only **UNSIGNED C09** badge (`r8-16`). It isn't clipped by the card. The badge won't ship (R12), so this is not a defect.

## 3. Story and dialogue screens (story AC12/AC13; dialogue AC9; hud §5)

| Check | Result | Measurement | Evidence |
|---|---|---|---|
| No hero, enemy, partner, dummy, flag prop, fx or pops on the intro, beat cards (b1, b3, b4, b5), ending and dialogue | **PASS** | None in VI or EN. The beat-5 card's small red flags on the hills are the camp background, which play shows the same. The r7 ending had the hero's head over the panel; r8 has none. | `r8-20-*-vi/en`, `r8-30-b5-*` |
| No beat dots, goal plate or banner bar; only pause/sound | **PASS** | On all of the above. | `r8-20-*` |
| Intro placeholder 256 | **PASS** | Ring y 45–300, x 512–767, centred on 640. | live scan |
| Beat-card placeholder 208 | **PASS** | y 25–232, x 536–743. Bottom ≤ 233, and 40 px above the label. | live scan |
| "Phần n / Part n" | **PASS** | Only on beat cards (Phần/Part 1, 3, 4, 5 = the beat's 1-based index; TQT's beat 2 is the dialogue, which has no label). Not on the intro, ending, dialogue or quiz. Label ink box **y 272–298** with panel top ≈ 308 (spec: panel top −38 … −10). Gold #FFC531 fill with an ink #3A2A20 outline ≈ 2.3 px. Ink vs sky #A9CFC3 is 8.09:1; bare gold would be 1.07:1, so the outline carries it. | `r8-20-card-*`, `bbox.py` |
| Dialogue dimmed, portraits only, no "Phần" | **PASS** | Dim scene, medallions, panel, bottom row, pause/sound. | `r8-03-card-mash-entry`, `r8-05-*` |
| Ending still (ASSET-016) | **NOT ASSESSED (asset gap)** | AC12 wants ASSET-016 (banner cloth, warm light) on the ending, and "no story screen shows only background". ASSET-016 is still **"Needed"** in `asset-manifest.md`, and the code draws no placeholder on the ending by design (`Renderer.kt:208`). So **the ending shows background only** today, in r7 too. It's for art/content, not a dev bug in this build. | `r8-20-ending-vi/en` |

Captions (sample hero) were captured by dev (r8-05/06). QC did not re-capture them, because TQT has no captions.

## 4. Banner beats: "!" and the stuck arrow (hud AC17)

Bar bottom measured at **y 268** (red to 267.1), so the rule is everything at y ≥ 276.

| Case | Result | Measurement | Evidence |
|---|---|---|---|
| "!" on the leader's windup (beat 5, frozen) | **PASS** | Beside the head, on the side away from the hero, tail pointing at the helmet. The bubble top is ≈ 30 px below the bar. | `r8-30-b5-leader` (+ crop) |
| "!" on the partner's windup (training) | **PASS** | Beside the head, away from the hero, below the bar. | `r8-30-b4-blocks` |
| "!" on the enemy (encounter) | **PASS** | Beside the head, away from the hero. | encounter idle frames (scratchpad) |
| Arrow, dummy stall | **PASS** | Rotated, on the side away from the hero, pointing at the dummy. Gold #FFC531, ink outline ≈ 6 px. **y 358–422**. | `r8-31-b4-stall-dummy-arrow*` |
| Arrow, enemy stall | **PASS** | Beside the enemy, away from the hero, pointing back at him, below the bar. | encounter idle frames |
| **Arrow, flag stall** (dev didn't capture it) | **PASS** | After clearing the encounter live: the flag is near the right edge, so the arrow uses **the hero's side, pointing inward** (the edge fallback). Gold with an ink outline, **y 318–381**. | `r8-32-b5-flag-stall-arrow*` |
| Never red | **PASS** | All arrows are gold with an ink outline. The r6/r7 red-arrow-on-red-banner observation is closed. | — |

Observation (outside the rule): on the reach-the-flag beat, **the flag cloth itself overlaps the right end of the red banner bar** (flag #CB342F from y 171 at x 1240, bar to 1264). It's red on red, the same family as the r6 arrow note. The r8 rule covers only the "!" and the arrow. Design to decide (`r8-32`).

## 4b. "Ối! / Oof!" pop outline on a light sky (leader add-on, from iOS QC r7 / r5 N1)

**PASS.** On Android TQT the only camp sky is the dark one (beat 5). There is no day camp sky, so the light-sky case is the training village sky. Recorded at `--ef slow 0.3` (the partner's strike, not defended): the "Ối!" outline samples **#392A21 ≈ ink #3A2A20** (compressed video) against sky **#A7CFC1**, about 8:1. It is not cream. The fill is red #D8342A. On the dark camp sky (beat 5 encounter, `r8-30`/encounter frames) the pop is drawn too, as before. Evidence: `r8-34-oof-pop-village-sky-slow.png` (a full-res 2400×1080 frame at 4.21 s of `oof3.mp4`).

## 5. Regression

| Item | Result | Notes | Evidence |
|---|---|---|---|
| D-27 title card, fresh | **PASS** | Outline stars and medal. | `r8-01-title-fresh` |
| Full read-everything run, 3★ + medal | **PASS** | `pm clear`, autoplay reading every box and line (no skip, 0 skip warnings), then a perfect quiz (0 retries): "Giỏi lắm!", 3★, "Nhận được huy hiệu!". Prefs `stars=3, completed=true, medal=true`. Title card after: 3★ and the gold medal. | `r8R-*`, `r8R-11-results-read-all`, `r8-40-title-after-3star-medal` |
| B7 ending under mash | **PASS** | §1 (1.78 / 1.75 s, then the quiz). | `b7r8.mp4`, `r8-33` |
| Skip warning → Keep reading | **PASS** | On fresh data: the card shows "Đọc tiếp" / "Vẫn bỏ qua". "Đọc tiếp" returns to intro box 1. With the medal already earned, skip shows no warning (nothing to lose). | `r8-41`, `r8-42` |
| VI/EN | **PASS** | Every story screen and quiz state captured in both. | `r8-20`, `r8-10..16` |
| Contrast | **PASS** | Label/arrow ink outline 8.09:1 on the sky; pill text 5.77:1; gold vs ink 8.67:1. | — |
| AC13 contact | **not re-run** | Passed in r6/r7. The r8 combat-spec change is only the bar rule (§4). The strikes seen in this round's fight frames connect. | — |
| Banner in the sky band | **PASS** | Bar y 156–267, above the figures. | `r8-30-*` |
| logcat | **PASS** | 54 app starts since install: 0 FATAL/AndroidRuntime, 0 ANR, 0 `DaiDat` warnings. | `logcat-r8.txt` (scratchpad) |
| Network | **PASS** | No permissions (runtime or install). | `dumpsys package` |
| Release gate | per dev log | Leader/dev report it fails on R12 only. QC didn't re-run the build. | — |

## Environment

- The emulator crash is described in the table above (`emu-stop-evidence-r8-0326.txt`, scratchpad).

- Watcher (`intwatch.sh`): 650 samples since install. Every sendevent seen is QC's own `mt.py` (autoplay). **No foreign input on 5554.**
- Not assessed this round, as before: the sound, and a real low-end phone.
