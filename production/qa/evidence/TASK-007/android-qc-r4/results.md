# TASK-007 Android QC, round 4 (native Kotlin, build c00c5e0)

**Overall r4 verdict: PASS.** Every in-scope item passed and no new bugs were found. One QC process correction (the erratum below) withdraws the B1 and B4 failures reported in r2 and r3.

| Item | Value |
|---|---|
| Build | `c00c5e0` on `setup/TASK-007-android-kotlin` (101 tests). APK `production/qa/builds/TASK-007-c00c5e0.apk`, sha256 `107c882d97097f4c…`, matching QC's copy and the device. 77c862c was uninstalled first, then a fresh install. |
| Device | `emulator-5554` (mp17863), API 36, 1080x2400 at 420 dpi, landscape 90°. Every adb command names `-s emulator-5554` (via `ANDROID_SERIAL`). |
| Input method | **New this round:** timing-sensitive input goes through `fastmt.py`, which streams raw `input_event` structs through one device-side `cat > /dev/input/event1`, with timing kept on the host. Every timing-sensitive case is verified with `getevent -lt`, and the kernel down/up times are in **`input-timing.txt`** in this folder. Holds and play use `sendevent` as before. Screen-side timing comes from 60 fps `screenrecord` frames. |
| Date | 2026-11-14 |

## Erratum for r2 and r3 (QC tool artefact)

In r2 and r3, QC reported **B1** (a double tap advances two story boxes, lines or asks) and, in r2, **B4** (a tap during the wrong-card shake is queued and applied at +0.502 s). Both were based on "double taps" injected with one `sendevent` process per event. In r4, `getevent -lt` showed what that method really produced: for a script of "0.04 s hold, 0.10 s gap", **a 0.198 s hold and a 0.35 s gap, so 0.55 s from down to down.** Spawning a process per event on the loaded emulator stretches every step. The second tap therefore landed **after** the 0.25 s debounce (and after the 0.5 s shake), and two advances (or a second wrong pick) was correct behaviour.

- **r2 B1 and r3 B1 (FAIL):** withdrawn as unproven. With kernel-verified double taps of 0.06–0.20 s, B1 passes on every path in r4 (below).
- **r2 B4 ("queued during the shake"):** withdrawn. The "+0.502 s" second wrong pick was most likely a second tap that really arrived about 0.5 s later. In r4, B4 passes with a kernel-verified tap 0.20 s into the shake.
- **r1 B1 (bfe3890):** stands. That build had no debounce at all.
- **Unaffected:** all screen-timed results (telegraph 1.10/1.32 s, the stall hint, the windup restart, the 0.9 s Tiếp delay, the AC6 frame analysis of what the screen did), and every non-timing result. Hold-based tests were right in substance, though the holds lasted longer than scripted.

## 1. B1, double taps (`advance_debounce` 0.25 s)

All taps go through `fastmt.py`, and every row has a kernel timing line in `input-timing.txt`.

| Path | Kernel timing (down → down) | Result | Evidence |
|---|---|---|---|
| Intro box 1 | 0.129 s | **PASS:** box 1 → box 2 only | `r4-03-B1-intro-box1-dbl.png` |
| Intro box 2 | 0.196 s | **PASS:** box 2 → box 3 only | `r4-04-B1-intro-box2-dbl-0p20.png` |
| Intro box 3 | 0.060 s | **PASS:** box 3 → box 4 only | `r4-05-B1-intro-box3-dbl-0p06.png` |
| Card f1, line 1 | 0.139 s | **PASS:** line 1 → line 2 ("Cậu vội đến bến Bình Than…") | `r4-07-B1-card-f1-dbl.png` |
| Dialogue Tiếp, line 1 | 0.144 s | **PASS:** line 1 → line 2 | `r4-09-B1-dialogue-tiep-dbl-line1.png` |
| **"Xin vào!", line 2** | 0.139 s | **PASS:** line 2 → **line 3, and the plea "Xin cho tôi gặp nhà vua!" shows** (AC23) | `r4-10-B1-ask-dbl-line2-to-3-plea.png` |
| Ending box 1 (EN) | 0.141 s | **PASS:** box 1 → box 2 only | `r4-21-B1-ending-box1-dbl.png` |
| Caption | — | **N/A.** This mission has no fight beats, so there are no captions (`startScreen caption --ei beat 1` just shows play). | — |

"With the host busy": every run in this round was on the shared, heavily loaded Mac (other sessions' VM, the iOS Simulator and a second emulator).

## 2–4. r3 fixes

| Item | Result | Notes | Evidence |
|---|---|---|---|
| **B3b**, the training attack hand | **PASS** | `stage teach`: the hand sits at the upper-left of Đánh, pointing diagonally at it, clear of Đỡ (below left) and Cờ (above). It overlaps only the banner's debug UNSIGNED badge. | `r4-11-B3b-training-teach-attack-hand.png` |
| **B5**, card heading | **PASS** | No medallions beside the heading. "Khi các vương hầu họp bàn ở Bình Than" fits on one line inside the panel. | `r4-06-card-f1-line1-B5-heading.png` |
| Two-line story text clear of Tiếp | **PASS** | Intro box 4 and ending box 2 (two lines): clear space above Tiếp. | `r4-05-*`, `r4-21-*` |
| "Xin vào!" label white | **PASS** | White on red (217,52,43): **4.69:1** (it was about 2.9:1 with the dark ink). | `r4-10-*` |

## 5. New items

| Item | Result | Notes | Evidence |
|---|---|---|---|
| A second pointer on a held pad is ignored (AC3) | **PASS** | Kernel: A down on Đỡ @0.000, **B down on Đỡ @0.608**, **A up @1.408**, B up @3.030. While A holds, the hero defends (shield up). After A lifts, **defend releases** with B still on Đỡ (two frames after 1.408 s, both without the shield). | `r4-12-AC3-a-held.png`, `r4-12-AC3-b-*.png`, `r4-12-AC3-c-a-lifted-b-still-on.png`, `input-timing.txt` |
| Unlock has a single "Về bản đồ" | **PASS** | "Mở khoá anh hùng tiếp theo!", then the hero → ? medallion, then "(Bản đồ sắp ra mắt)" and one "Về bản đồ" button. | `r4-13-unlock-single-button.png` |
| The title shows the map stub, no legend | **PASS** | "(Bản đồ sắp ra mắt)" / "(Map coming soon)" in place of the controls legend. | `r4-01-title-map-stub.png`, `r4-25-*` |
| Wrong card #E6E1F0, lavender border, arrow | **PASS** | The fill pixel is **(230,225,240) = #E6E1F0**, with a lavender border and a circular-arrow icon. | `r4-14-quiz-wrong-card-colour.png` |
| Tick and arrow have ink outlines | **PASS** | The green tick and the retry arrow are both drawn with a dark ink outline. | `r4-15-quiz-right-tick.png`, `r4-14-*` |
| Mute survives force-stop and relaunch | **PASS** | M on the title writes `sound=false`. After force-stop and relaunch the prefs still say `sound=false`, and the play HUD shows the muted speaker. (Toggled back afterwards.) | `r4-16-mute-persisted-play-icon.png` |

## 6. Regression

| Item | Result | Notes | Evidence |
|---|---|---|---|
| Full run (EN, read everything) | **PASS** | After `pm clear`, EN was set on the title. Intro, then walk, dialogue, hold-meter, training, reach-the-flag, the ending (EN), the quiz (5 wrong picks → **1★**) and **"You earned the medal!"**. 294 s from Start to the ending. | `r4-20…25`, `r4R.log`, `r4q.log` |
| Skip and medal | **PASS** | With the medal earned, Skip on a dialogue line skips with **no warning**. After `pm clear`, the same skip **shows the warning**. (The full skip flow was covered in r3.) | `r4-27-*`, `r4-28-*` |
| Save after a kill | **PASS** | Killing the app on results and relaunching keeps `stars=1`, `completed` and `medal`. | `r4-25-title-after-kill-on-results.png` |
| EN | **PASS** | The title, dialogue, ending, quiz and results are all in EN ("Map coming soon", "Next", "You earned the medal!"). | `r4-20`, `r4-21`, `r4-24` |
| B4, a tap during the shake | **PASS** | Kernel: the wrong pick, then a second card tapped **0.202 s** later (inside the 0.5 s shake). In 60 fps frames the first card turns lavender and **the second stays cream throughout**. | `r4-23-B4-tap-during-shake.png`, `input-timing.txt`, `b4r4.mp4` |
| G2, reach-the-flag ≤ 60 s | **PASS** | One continuous gesture (▶ held, attack tapped every 0.35 s) from `play --ei beat 5`: the ending screen at **about 41 s** (poll resolution about 2 s). The bot run with adb gaps took 72 s, which reflects tool overhead, not the game. | `r4-26-G2-after-flag.png` |
| logcat | **PASS** | 15 app processes: 0 FATAL/AndroidRuntime, 0 ANR, 0 `DaiDat` content warnings. App-side E lines are emulator codec noise only (`MediaCodec: Media Quality Service not found`, `ashmem`). | `logcat-r4` (scratchpad) |
| No network | **PASS** | The APK has no permissions, and logcat shows no network use by the app. | — |
| Release gate | **PASS** (still refuses) | `TASK-007-release-gate.log`, `commit c00c5e0…`: `:app:contentGate FAILED`, "R12 hero tran-quoc-toan: claims not approved: C01 … C16", then `BUILD FAILED`. | game-dev-002 log |

## Known, not reported this round (per the brief)

The training camera can strand dummies, pause sits top-right on story and quiz screens, and training shows all pads.

## Observations

- On the quiz the wrong card's picture now stays at full colour on the #E6E1F0 card. It reads well, and the arrow and border carry the "try again" meaning.
- The ending and pause dim screens look slightly lighter than in r3. That's cosmetic and not a regression.
- **Environment:** the watcher took 264 samples this round and saw no foreign adb input on 5554. The Mac stayed heavily loaded. This build has not been seen on a real low-end phone, and nobody has listened to the sound.
