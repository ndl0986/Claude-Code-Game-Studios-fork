# TASK-007 Android QC, round 6 (native Kotlin, build 7790ee9)

**Overall r6 verdict: FAIL, on one new bug.** **B7 (Medium–High):** the new story bottom row overlaps the play pads, so a child's ongoing Attack or ◀ taps click through or skip story text as soon as a beat ends. The leader has already routed it to both apps as a 0.6 s entry lock for r7. Every r6 change passes:
- the D-27 title and hero card (AC4, 4b, 4c, 4d, 4e);
- full-bleed story screens with B6 fixed;
- the dialogue title inside the panel;
- pop and banner contrast;
- AC13 contact;
- the 1.35 em line pitch.

The full regression also passes.

| Item | Value |
|---|---|
| Build | `7790ee9` (107 tests). APK sha256 `2fed0ba265dd8ee5…`, matching QC's copy and the device. f02c0d6 was uninstalled first. |
| Device | `emulator-5554` (mp17863), API 36, 1080x2400, landscape 90°. |
| Input | Timing-sensitive input goes through `fastmt.py`. Kernel `getevent -lt` lines are in `input-timing.txt`. |
| Date | 2026-11-14/15 |

## 1. Title (D-27, title.md §5.2–5.5)

| AC | Result | Notes | Evidence |
|---|---|---|---|
| One-line title, no emblems, no standing hero | **PASS** | "Dải Đất Anh Hùng" / "Land of Heroes" on one line, with no drum emblems and no standing hero. | `r6-01-title-fresh-vi.png`, `r6-22-title-en.png` |
| 4b, fresh install | **PASS** | The card shows the portrait and name, 3 outline stars and an outline medal. The only badge is the debug `UNSIGNED` one. | `r6-01` |
| 4, 2★ with no medal | **PASS** | After Run A (story skipped, 2 retries): 2 filled stars, 1 outline star and an outline medal. Prefs `stars=2`, no `medal`. | `r6-21-title-card-2stars-no-medal-AC4.png` |
| Best stars, and the gold medal once earned | **PASS** | Run B gave 3★ but **no medal**, because the story was skipped (B7b below), so the card showed 3★ with an outline medal. Run C read everything and answered perfectly: **3★ and the gold medal**. | `r6-61`, `r6-63-title-3stars-gold-medal.png` |
| 4c, a worse replay doesn't lower it | **PASS** | Run D replayed with 5 retries, 1★ on results. The card still shows **3★ and the gold medal**, and the prefs stay `stars=3, medal=true`, also after a kill and relaunch. | `r6-64`, `r6-65-title-after-1star-replay-AC4c.png`, `r6-66` |
| 4e, a card tap does nothing | **PASS** | A tap on the card (kernel: down @0 / up @0.053) leaves the title unchanged. The no-tone part can't be heard. | `r6-23-title-card-tap-nothing.png` |
| 4d, sizes and overlaps (VI and EN) | **PASS** | Start, sound and the VI\|EN chip are ≥ pad_min. Nothing overlaps among sound, chip, title row, card, Start, map stub and debug line in either language. (The map stub is a 38 px label; title.md doesn't require it to be pad_min.) | `r6-01`, `r6-22` |

## 2. Story screens (story-screens.md §5.2)

| Item | Result | Notes | Evidence |
|---|---|---|---|
| Full-bleed pictures, text panel bottom-anchored above Tiếp | **PASS** | Intro and ending pictures fill the screen, and the text panel sits just above the bottom row. | `r6-02`, `r6-06`, `r6-33…35` |
| B6, nothing under the corner buttons (AC9) | **PASS** | Only the picture's sky/background is under pause and sound. No frame, panel or card edge is there any more, on intro, ending or cards. | `r6-02`, `r6-03`, `r6-06` |
| AC10, Tiếp and Bỏ qua ≥ pad_min on one row | **PASS** | Both are about 148 world px tall (pad_min at k 1.28), with matching top and bottom: Bỏ qua at x 18–318, Tiếp at x 962–1262. | same |
| **Observation:** subject hidden | — | On intro box 1/2 and the ending, the bottom panel covers the hero figure up to his neck, so only his head shows above it. With full-bleed art, the story subject should sit above the panel (composition or art direction). | `r6-02`, `r6-06` |

## 3. Dialogue (dialogue.md §5.2, AC6)

**PASS.** On line 1 the title "Xin gặp vua" sits **inside** the panel. The panel's top and bottom are the same on lines 1, 2 and 8 (VI and EN). Evidence: `r6-04`, `r6-05`, `r6-36`.

## 4. Contrast (measured as in r5)

| Item | Result | Numbers | Evidence |
|---|---|---|---|
| "Ối!" pop with an outline, ≥ 3:1 on every sky | **PASS** | The red glyph (224,80,56) now has a **cream outline** (248,248,232). Glyph vs its outline: **3.64:1**. Outline vs camp navy (72,80,120) **7.27:1**, vs dark navy **11.4:1**. (Outline vs light mint or day sky is 1.4:1, but there the red glyph inside its cream ring carries the 3.6:1.) | `c1.mp4`, `popz` crop |
| Banner gold text with an ink outline | **PASS** | The gold text on the red bar now has a dark ink outline. | `r6-31`, banner crop |
| **Observation:** stall arrow | — | The stall hint arrow is now **red** and sits over the red banner's left end in training, so it's hard to see. | `r6-53-15b-hold-right-5s.png` |
| **Observation:** leader "!" | — | The leader's windup "!" marker straddles the banner bar's bottom edge, and the windup glow shows faintly through the bar. His body is clear of the bar (AC9 still holds). | `r6-30-leader-windup-marker-vs-banner.png` |

## 5. AC13, spear contact

**PASS (with a note).** Leader strike, frames at about 37 fps: at **1.023 s** the padded tip overlaps the hero's right foot while he is still at his pre-strike x (same as 0.961 s). At 1.050 s he has been pushed. So contact is visible **before the push**. The recording rate can't prove "≥ 2 game frames". The thrust is aimed at foot level, not the chest. Evidence: `c1.mp4`, `c2.mp4`.

## 6. Line pitch 1.35 em

**PASS.** The 2-line story texts (intro boxes 1, 2 and 4, ending box 2, in VI and EN), dialogue line 8 (VI and EN) and the EN banner all fit inside their boxes. Pixel scan of the EN banner: the bar is at device rows 274–416 and the text ends at **403** (training) or 391 (reach), so it isn't clipped. Evidence: `r6-31…36`, `r6-02`.

## 7. Regression

| Item | Result | Notes | Evidence |
|---|---|---|---|
| Full runs | **PASS** | Four runs: A (skip with warnings, 2★), B (read-attempt, 3★), C (read everything, perfect quiz, 3★ and the medal) and D (skip with the medal earned, 1★). | `r6A*`, `r6B*`, `r6C*`, `r6D*` |
| B1 spot-checks, 3 of 3 | **PASS** | Intro 1→2 (0.143 s down to down), card 1→2 (0.150 s), "Xin vào!" 2→3 (0.129 s). | `r6-40/41/42`, `input-timing.txt` |
| B4 | **PASS** | A second card tapped 0.192 s after the wrong pick's lift is ignored, and only card 1 turns lavender. | `r6-55-B4-tap-during-shake.png` |
| G2 | **PASS** | One continuous "hold ▶ + tap attack" gesture: the ending's Tiếp appeared at **≤ 37 s**. | `r6-56` |
| 15b | **PASS** | 5.0 s held ▶ (kernel): the hero stops at the limit with all dummies on screen. | `r6-53` |
| W12 | **PASS** | Dummies show ◀▶ + Đánh, blocks add Đỡ, and the special step adds Cờ. The hint hand points at the correct pad. | `r6-50/51/52` |
| Skip and medal | **PASS** | Run A: the warning, "Đọc tiếp", the warning again, then "Vẫn bỏ qua" and the rest of the story is skipped silently, giving 2★ with no medal. Run D (medal already earned): skipping gives no warning and the medal is kept. | `r6A-02/04`, `r6D*` |
| Save after a kill | **PASS** | 3★ and the medal survive a kill on the title after the replay. | `r6-66` |
| Mute | **PASS** | The title's sound button sets `sound=false`, which persists after a kill and relaunch. Toggled back afterwards. | `r6-67` |
| logcat | **PASS** | 33 app processes: 0 FATAL/AndroidRuntime, 0 ANR, 0 `DaiDat` warnings. E lines are emulator codec noise only. | `logcat-r6` (scratchpad) |
| Network | **PASS** | No permissions, and no network use in logcat. | — |
| Release gate | **PASS** (still refuses) | Log `commit 7790ee9…`: `:app:contentGate FAILED`, "R12 … C01 … C16", then `BUILD FAILED`. | game-dev-002 log |

## Bug

### B7: the story bottom row sits on the play pads, so a child's ongoing taps click through or skip the story
- **Severity:** Medium–High (S2), P1. Story text, including the ending's "Trần Quốc Toản đã hy sinh…", is skipped without being read, and a ◀ press can open the skip warning or skip the story and lose the medal.
- **Build / device:** 7790ee9, emulator-5554.
- **Cause:** Tiếp sits at world x 962–1262, y 554–702, and the **Attack pad** is centred at (1150, 590), inside it. Bỏ qua sits at x 18–318, and the **◀ pad** is at (140, 610). Story screens accept new presses the moment they appear.
- **Repro 1 (Tiếp):** In reach-the-flag, hold ▶ and tap Attack every 0.35 s (kernel: 0.30–0.43 s, median 0.35 s). When the beat ends, **ending box 1 is on screen for 0.16 s** (35.529–35.653 s), **box 2 for 0.26 s**, and the **quiz appears at 36.060 s**. Evidence: `r6-58-B7-ending-box1-at-35.529s.png`, `r6-58-B7-ending-box2-at-35.689s.png`, `r6-58-B7-quiz-at-36.060s.png`, `b7.mp4`, `ge_b7`.
- **Repro 2 (Bỏ qua):** In Run B, the training card appeared while the touch bot was in a ◀/attack cycle. Its ◀ tap at (140, 610) landed on **Bỏ qua**, which raised the D-07 warning (and the bot confirmed "Vẫn bỏ qua"). The run ended **3★ with no medal**. Evidence: `r6-59-B7b-left-pad-tap-hit-Bo-qua-on-card.png`, `r6B.log`.
- **Expected:** A story screen doesn't act on presses that are really carry-over from play.
- **Suggested fix (routed by the leader):** a 0.6 s entry lock on story screens, and/or keep Tiếp and Bỏ qua clear of the pad positions.

## Environment

- **The emulator crashed 3 times this round** (QEMU hang, then SIGSEGV, with no shutdown requests) at host load averages of **350–400**. QC relaunched it each time. The interrupted runs were redone, and the partial evidence was committed early (f18feb4). The leader is raising the host load with Luan.
- **Watcher:** 908 samples. The only extra adb clients were the emulator's own startup commands (`cmd overlay …`, `am broadcast …`, parent `qemu-system-aarch64`). No foreign input on 5554.
- This build has not been seen on a real low-end phone, and nobody has listened to the sound.
