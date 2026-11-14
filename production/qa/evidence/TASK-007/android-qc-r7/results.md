# TASK-007 Android QC, round 7 (native Kotlin, build ce119bf)

**Overall r7 verdict: PASS.** B7 is fixed by the rolling screen-entry lock on every path tested, including the r6 medal-loss case. The small-k quiz, the skip-warning card and the full regression pass. There are no new bugs. One design question is noted for the dialogue (lines 2–9 under continuous mashing).

| Item | Value |
|---|---|
| Build | `ce119bf` (117 tests). APK sha256 `658826b8559d13e3…`, matching QC's copy and the device. 7790ee9 was uninstalled first. |
| Device | `emulator-5554` (mp17863), API 36, 1080x2400, landscape 90°. |
| Input | All timing input goes through `fastmt.py`. Kernel `getevent -lt` lines, **with the host load average at each B7 case**, are in `input-timing.txt` (load 60–70 for the B7 cases, 224 at install). |
| Date | 2026-11-15 |

## 1. B7, the ending (Input Rule 13b, story AC11)

| Case | Result | Measurement | Evidence |
|---|---|---|---|
| Attack/Next every 0.35 s from the end of reach-the-flag | **PASS** | Continuous gesture (▶ held, Attack taps every 0.35 s). Ending box 1 appears at 34.793 s, **box 2 at 36.627 s (+1.83)** and **the next screen at 38.393 s (+3.60)**. Each box holds ≥ 1.5 s (1.83 s, 1.77 s) while taps keep landing. Expected +1.75 and +3.50, so it's within one tap interval. Nothing queued: no extra advance after the taps stop. | `r7c1.mp4`, `input-timing.txt` (load 60) |
| The mash stops, then the next tap 0.65 s later advances | **PASS** (box 2) | Kernel: taps at 0, 0.35 and 0.70, then **1.40 (0.65 after the last)**, which advanced. **Control:** the same mash, then a tap 0.45 s after the last, did **not** advance. Note: the first box of a `--es startScreen ending` debug jump has no entry lock (a debug path only; the real-flow ending is locked, see the row above). | `r7-11-*`, `r7-12-*-control`, `input-timing.txt` |
| A thumb held on Attack when the ending appears, released over Tiếp | **PASS** | Finger 1 down on Attack at touch time 33.26 s. The ending appears at about 33.5 s. Released at 49.26 s over Tiếp. Ending **box 1 stays** for the rest of the recording, and nothing fires. | `r7-19-held-attack-released-over-Tiep.png`, `hold.mp4`, `ge_hold` |

## 2. B7, card entry (the r6 medal-loss case)

**PASS.** A full read-everything run after `pm clear`, with the r6 training cycle that taps ◀ (140, 610) and Attack throughout, as cards appear. **No skip warning in the whole run.** A perfect quiz gave **3★ and the gold medal** ("Nhận được huy hiệu!"). In r6 the same pattern hit Bỏ qua and cost the medal. Evidence: `r7R*`, `r7-20-results-read-all-medal.png`, prefs `stars=3, medal=true`.

## 3. B7, other screens

| Screen | Result | Measurement | Evidence |
|---|---|---|---|
| Dialogue line 1 (entered from the walk) | **PASS** (AC8) | Walking in with taps on the Tiếp spot every 0.35 s (kernel median 0.350): line 1 appears at 7.359 s and holds until 9.143 s (**1.78 s**, the 1.5 s cap). Lines then advance one per tap, and none is skipped. | `dl.mp4`, `ge_dl` |
| Quiz entry | **PASS** | Kernel: Tiếp (ending box 2) @0, then the right card tapped @0.35, which was **dropped** (the card stayed cream). A later tap was accepted (green). | `r7-13-*`, `r7-14-*` |
| Results entry | **PASS** | Kernel: Q5's Tiếp @0, then results Tiếp @0.35, which was **dropped** (results stay). A later tap goes to the title. | `r7-15-*`, `r7-16-*` |
| Box to box elsewhere | **PASS** | The normal 0.25 s debounce: B1 double taps advance one (§7). | `r7-40/41/42` |
| Pause inside the lock | **PASS** | Kernel: Tiếp into the quiz @0, then pause @0.30, which **opened "Tạm dừng"**. | `r7-17-B7-pause-inside-quiz-entry-lock.png` |
| **Design question** | — | Per dialogue.md the lock covers **line 1 only** ("the debounce covers line-to-line"). Under continued mashing, lines 2–9 (including the hero's plea and the king's words) then advance every 0.35 s, so each is on screen for about 0.35 s. That meets AC8 as written (no line skipped), but a mashing child won't read them, unlike the ending, where every box locks. Worth a design decision. | `dl.mp4` frames 9.14–11.94 s |

## 5. Small-k quiz (`--ef padScale 1.22`, effective k ≈ 0.40)

**PASS.** The flag applies on 5554: the corner buttons grow and the cards shift down. **No Tiếp while choosing.** After the right pick, the wrong cards fade (about 1.0 s), the right card glides left (1.2–1.4 s), then the why line (1.4 s) and **Tiếp** (about 1.8 s). Taps where the wrong cards were (kernel @0 and @0.666) **did nothing**. Cosmetic: a sparkle star overlaps the "Đúng rồi!" label. Evidence: `r7-03`, `r7-05`, `r7-06`, `sk.mp4`.

## 6. Skip-warning card

**PASS.** "Đọc tiếp" and "Vẫn bỏ qua" are inside the card. A pixel scan of "Đọc tiếp" gives about **150 world px tall** (rows 459 to about 610, above the card's gold border at about 622–629), which is ≥ pad_min (147.6). Evidence: `r7-02-skipwarn-card.png`.

## 7. Regression

| Item | Result | Notes | Evidence |
|---|---|---|---|
| Full read-everything run | **PASS** | 3★ and the medal (§2). | `r7R*`, `r7-20` |
| B1, 3 of 3 | **PASS** | Intro 1→2 (0.140 s down to down, after the real title → intro entry lock), card 1→2 (0.141 s), "Xin vào!" 2→3 (0.140 s). | `r7-40/41/42` |
| B4 | **PASS** | A second card tapped 0.20 s after the wrong pick's lift is ignored. | `r7-43` |
| G2 | **PASS** | The continuous gesture reached the ending at about 33.5 s (touch time) in the B7 runs. | `hold.mp4`, `r7c1.mp4` |
| 15b | **PASS** | 5.0 s held ▶ (kernel): the hero is at the limit with all dummies on screen. | `r7-47` |
| W12 | **PASS** | Dummies, blocks and special each show the correct pads. | `r7-44/45/46` |
| Title card states | **PASS** | Fresh: outline stars and medal (`r7-01`). After the read-everything perfect run: 3★ and gold (`r7-48`). (The 4c lower-replay case was verified in r6 and not re-run.) | `r7-01`, `r7-48` |
| Save after a kill | **PASS** | 3★ and the medal survive a kill and relaunch. | `r7-48` |
| Mute | **PASS** | `sound=false` persists after a kill and relaunch, with the muted icon. Toggled back afterwards. | `r7-48` |
| logcat | **PASS** | 26 app processes: 0 FATAL/AndroidRuntime, 0 ANR, 0 `DaiDat` warnings. | `logcat-r7` (scratchpad) |
| Network | **PASS** | No permissions, and no network use in logcat. | — |
| Release gate | **PASS** (still refuses) | Log `commit ce119bf…`: `:app:contentGate FAILED`, "R12 … C01 … C16", then `BUILD FAILED`. | game-dev-002 log |

## Observations carried

- The red stall arrow still sits over the red banner's left edge in training (r6), so it's hard to see. `r7-47`.
- The intro and ending panels still cover the hero below the neck (r6, art/composition).

## Environment

- The host load average was 224 at install (game-dev-iOS xcodebuild) and **60–70 during all B7 timing cases** (logged in `input-timing.txt`). No emulator crash this round.
- **Watcher:** 627 samples, with no foreign input on 5554.
- This build has not been seen on a real low-end phone, and nobody has listened to the sound.
