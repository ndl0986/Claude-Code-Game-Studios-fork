# TASK-007 Android QC, round 3 (native Kotlin, build 77c862c)

**Overall r3 verdict: FAIL.** **B1 is still open** on every story Next path except the quiz and results: the intro boxes, beat cards and dialogue "Xin vào!" all fail. **B3 is fixed in logic but the hand is drawn on the Defend pad.** There is one new text-layout bug, B5. Everything else passes: B4, G1–G4, the new Bình Than walk and dialogue, the leader's 1.32 s, the stall hint and its reset, the windup restart on resume, skip/medal, saving, logcat and the release gate.

| Item | Value |
|---|---|
| Build | `77c862c` on `setup/TASK-007-android-kotlin`. APK `production/qa/builds/TASK-007-77c862c.apk`. sha256 `0b61b4736a9fee5d…`, matching QC's copy and the device. Clean install after `pm clear`. |
| Device | Emulator `mp17863` (`emulator-5554`), API 36, 1080x2400 at 420 dpi, landscape 90°, `-gpu host`. Pinned with `ANDROID_SERIAL`. |
| Method | Real kernel multi-touch via `sendevent`. A beat-aware touch autoplay with pixel probes (`run3.py`, `quiz2.py`). 60 fps `screenrecord`, with each frame timed by a Swift AVAssetReader tool. Debug stages from the build's README. `run-as` to read the prefs. logcat. The interference watcher (host adb, monkey and input processes with their parent chains) ran for the whole round. |
| Date | 2026-11-14 |

## 1. r2 bug re-tests

| Bug | Result | Notes | Evidence |
|---|---|---|---|
| **B1** two taps within 0.25 s, one advance | **FAIL** on the intro, beat cards and dialogue. **PASS** on the quiz Tiếp and results. | **Intro:** box 1 → **box 3** at gaps of 0.06, 0.11, 0.12 and 0.20 s (4 of 4); a single tap goes box 1 → box 2 (control). The skipped box was "Năm ấy, quân Mông–Nguyên chuẩn bị sang xâm lược Đại Việt." **Beat card f1:** line 1 → the goal box, skipping "Cậu vội đến bến Bình Than…". **Dialogue "Xin vào!":** line 2 → **line 4**, skipping the hero's plea "Xin cho tôi gặp nhà vua!" (AC23, "two ask taps within advance_debounce advance only once"). **Quiz Tiếp:** Q1 → Q2 only (PASS). **Results Tiếp:** goes to the title only (PASS). | `r3-03-B1-*`, `r3-06-B1-card-f1-double-tap.png`, `r3-10-B1-ask-double-tap.png`, `r3R-05-q2-after-double-tap-on-q1-next.png`, `r3-35-results-double-tap-to-title.png` |
| **B3** training starts with the attack hand | **Logic PASS. Visual FAIL** (B3b). | The hint state is now ATTACK. But to avoid pointing at the flag, the hand is drawn at world x 1028, left of the attack pad. That puts it **on top of the Defend pad** (Defend spans x 870–1030), finger pointing right, so a child reads "press Đỡ". | `r3-17-B3-training-start-hand.png` |
| **B4** taps during the shake are ignored | **PASS** | A wrong card, then a second card tapped 0.25 s later (one sendevent script). In the 60 fps frames the first card turns lavender at 1.447 s and **the second stays cream** after the shake. Q1 retries = 1 (only the real wrong pick), so stars are unchanged. | `r3-31-B4-after-tap-during-shake.png`, `q3.mp4` |

## 2. G items

| Item | Result | Notes | Evidence |
|---|---|---|---|
| G1 wording | **PASS** | "Giữ chặt nút lá cờ!" and the pad is labelled "Cờ". (The meter ring is still around the orange, not the pad; minor.) | `r3-14-holdmeter-G1.png`, `r3-15-*` |
| G2 reach-the-flag ≤ 60 s by touch | **PASS (borderline)** | Simple child strategy (hold ▶ 0.95 s with 2 attack taps, repeated): **62.3 s** wall clock from closing the card to the ending, in both runs (R and S). That includes about 0.4 s of adb latency per cycle with ▶ released, plus the beat-end cheer and screen detection, so the in-game time with ▶ held is under 60 s. Never stuck: the run finished the same way twice, where r2 took 280–410 s. | `r3R.log`, `r3S.log` |
| G3 dummies spring back | **PASS** | A hit dummy wobbles and stays upright, then fades once done. None lie flat. | `r3-18-training-after-dummies.png`, `dum.mp4` |
| G4 Q1 flags | **PASS** | Terracotta (Lê), a blue pennant (Lý) and gold (Trần): no red flag, nothing gives the answer away, and no red on the wrong-pick screen. | `r3-30-quiz-q1-G4-flags.png`, `r3-31-*` |

## 3. New Bình Than scene

| Item | Result | Notes | Evidence |
|---|---|---|---|
| Walk is 1 screen | **PASS** | walk_to, then card f1, then a 1-screen walk, then the dialogue. 1st star. | `r3-05-*`, `r3-07-*` |
| Dialogue: 9 lines in order | **PASS** | Lines 1–9 match `mission.json`. Line 3 was checked separately with `stage line --ei line 3`. | `r3-07`, `r3-08`, `r3-19`, `r3-10`, `r3-11-dialogue-line5…9` |
| Portraits | **PASS** (to the GDD) | Narrator lines have no portrait and a centred box. **The hero is on the left** (lines 3, 6, 7) and the guard and king are on the right, which is mission-flow 7d: "the hero's portrait sits left and others right". (The brief said "portraits on the right side"; the GDD rule is followed.) | `r3-19-dialogue-line3-hero-pleading.png`, `r3-11-dialogue-line6/8.png` |
| "Xin vào!" on lines 2–3, "Tiếp" from line 4 | **PASS** (single taps) | Line 1 shows Tiếp, lines 2 and 3 show the red ask button, and line 4 onward shows Tiếp. (The double-tap case is B1.) | `r3-08`, `r3-19`, `r3-10` |
| Hint hand on "Xin vào!" after about 5 s | **PASS** | Idle on line 2: the hand is over the ask button at about 6 s. | `r3-09-dialogue-line2-hint-hand-after-6s.png` |
| Skip on dialogue lines and the warning | **PASS** | `stage skip --ei line 4` with no medal gives the D-07 warning. In Run S, Skip on the dialogue ended only the dialogue (on to the next walk_to). | `r3-20-dialogue-skip-line4-warning.png`, `r3S.log` |
| No pads during dialogue | **PASS** | Only pause and mute are shown, plus Tiếp/ask and Skip. | `r3-07…11` |
| EN dialogue | **PASS** | "You are too young to join the meeting." with "Let me in!" and "Skip". | `r3-21-dialogue-line2-en.png` |
| Then the orange beat | **PASS** | Card f2, then the hold-meter (2nd beat star after the dialogue). | `r3-13`, `r3-14` |

## 4. Text

| Item | Result | Notes | Evidence |
|---|---|---|---|
| Body ≥ 37, readable | **PASS** | Body text on story boxes, dialogue and quiz is large and readable. | screens above |
| Headings 44 | **FAIL** (B5) | The 44 px card heading "Khi các vương hầu họp bàn ở Bình Than" **runs over both star medallions** on the card panel and touches the UNSIGNED badge. | `r3-05-card-f1-line1.png` |
| Why ≤ 3 lines | **PASS** | The why lines checked (Q1, Q3) fit on one line, with "Đúng rồi!" above Tiếp. | `r3R-04-q1-right-why-and-next.png`, `r3Sq-04-*` |
| Nothing clipped in VI/EN | **PASS**, with observations | No clipping, but on two-line intro boxes the second line nearly touches the Tiếp button (about 5 px at 900 view) and the first line sits on the picture frame's edge. | `r3-04-intro-box2-text-near-button.png` |
| Sky gradient (themes.json) | **PASS** (as seen) | Light blue sky band on the title, story pictures and play. | screens |

## 5. r2 carry-overs

| Item | Result | Notes | Evidence |
|---|---|---|---|
| Leader telegraph 1.32 s | **PASS** | `stage leader`, 60 fps frames: the first "!" frame is at 5.331 s (none at 5.278 s) and the first strike ("Ối!") frame at 6.610 s (still winding up at 6.571 s). So the windup lasts **1.24–1.33 s** (frames were dropped under host load). That is consistent with 1.32 s and rules out the spear's 1.10 s. | `ldr.mp4` |
| Stall hint at about 5 s, and reset on resume | **PASS** | The arrow over the enemy first appears **about 4.7–5.0 s** after play starts. Pause at 9.35 s, resume at 11.35 s: the arrow is gone and comes back at **16.34 s (+5.0 s)**. (Sampling about 0.33 s.) | `st.mp4` |
| The windup restarts its telegraph on resume | **PASS** | Paused about 0.64 s into the leader's windup, then resumed. The strike came **about 1.36 s after resume** (1.17–1.53 s with frame drops). Without a restart it would be about 0.68 s. | `f2.mp4` |
| Tiếp only after 0.9 s (quiz AC5) | **PASS** on Q2; Q1 inconclusive | Q2: green between 1.345 and 1.397 s, Tiếp between 2.261 and 2.280 s, so **0.86–0.94 s**. Q1 measured 0.66–0.80 s, probably a probe or animation artefact on the right-most card. Re-measure if in doubt. It never auto-advances (still on Q1 after 4 s). | `tp.mp4`, `tp2.mp4` |

## 6. Regression

| Item | Result | Notes | Evidence |
|---|---|---|---|
| Full playthrough (read everything) | **PASS** | 267 s from Start to the quiz (F1 target 3–5 min): 4 intro boxes, then walk, dialogue, hold-meter, training, reach-the-flag, the ending, the quiz (4 retries, 1★) and "Nhận được huy hiệu!" (gold medal). | `r3R-*`, `r3-32-results.png` |
| D-07 skip and medal | **PASS** | Run S after `pm clear`: Skip, then the warning, then "Đọc tiếp", then Skip again and **the warning shows again**. After "Vẫn bỏ qua", 5 cards, the dialogue and the ending were skipped silently. Results show **no medal** ("Đọc hết câu chuyện để nhận huy hiệu nhé"), with no `medal` key in the prefs (mission-flow AC25). 2 retries gave 2★. | `r3S-*`, `r3-34-results-skipped-run-no-medal.png` |
| D-16 save on kill | **PASS** | Killing the app on Run R's results screen and relaunching keeps `stars=1`, `completed` and `medal`. | `r3-33-title-after-kill-on-results.png` |
| logcat | **PASS** | No app FATAL, AndroidRuntime or ANR lines across 17 app processes (the `AndroidRuntime` lines in the log are the system zygote restarting after the emulator crash, see Environment). 0 `DaiDat` content warnings. App-side E lines are emulator codec noise (`MediaCodec: Media Quality Service not found`, `ashmem`) plus one `SurfaceSyncGroup` timeout under host load. | `logcat-r3` (scratchpad) |
| Offline | **PASS** | The APK requests no permissions (no INTERNET), and logcat shows no network use by the app. | — |
| Release gate | **PASS** | `production/qa/builds/TASK-007-release-gate.log`, `commit: 77c862c…`: `:app:contentGate FAILED`, "R12 hero tran-quoc-toan: claims not approved: C01 … C16", then `BUILD FAILED`. | game-dev-002 log |

## Bugs (`/bug-report` format)

### B1 (still open, third round): a double tap on Tiếp or "Xin vào!" skips story text
- **Severity:** Medium (S3), P2. A child who taps twice misses story lines, including the hero's own plea in the new Bình Than dialogue and a "Truyện kể rằng" style line in r2.
- **Build / device:** 77c862c, mp17863, API 36.
- **Steps:** 1. On intro box 1, or a beat card with 2+ lines, or dialogue line 2 ("Xin vào!"), tap the button twice, 0.06–0.20 s apart (each touch 0.04 s, one sendevent script).
- **Expected:** One box, line or ask advances (mission-flow AC9, AC23: `advance_debounce` 0.25 s).
- **Actual:** Two advance: intro box 1 → 3 (4 of 4), card f1 line 1 → the goal box, dialogue line 2 → line 4. A single tap advances one (control). Quiz Tiếp and results Tiếp are debounced correctly.
- **Note (from reading 77c862c, not verified):** `Game.next()` and `ask()` compare `clock - lastAdvance` with the debounce, and `clock` advances only in `step()`. The quiz path works, so the story paths may reach `advance()` through a route that doesn't set `lastAdvance`, or the press-time check `pressAllowed` may not be applied to `next` on story screens. A unit test with two `next()` calls 0.15 s apart on the intro would show it.
- **Evidence:** `r3-03-B1-intro-double-tap*.png`, `r3-03-B1-intro-single-tap-control.png`, `r3-06-B1-card-f1-double-tap.png`, `r3-10-B1-ask-double-tap.png`, `b1.mp4`.

### B3b: the training attack hint is drawn on top of the Defend pad
- **Severity:** Low–Medium (S3), P3. The first instruction a child sees in training points at Đỡ.
- **Steps:** Play to training and close its card.
- **Expected:** The hand clearly marks Attack (Đánh).
- **Actual:** The hand is drawn at world (1028, 590), between Defend (centre 950, r 80) and Attack (centre 1150, r 92), so it overlaps Defend's right edge, pointing right. Suggestion: draw it below or to the right of the attack pad, or above it with the flag pad moved.
- **Evidence:** `r3-17-B3-training-start-hand.png`.

### B5: card headings at 44 px overlap the panel's star medallions
- **Severity:** Low (S4), P3. Text over decoration; readability drops on long titles.
- **Steps:** Reach card f1 "Khi các vương hầu họp bàn ở Bình Than" (VI).
- **Expected:** The heading fits between the medallions (Language Rule 6: nothing overlapped or clipped). Wrap, or shrink to fit the field width.
- **Actual:** The first and last words run over both medallions, and the UNSIGNED badge sits on the right one.
- **Evidence:** `r3-05-card-f1-line1.png`, `r3-06-B1-card-f1-double-tap.png`.

## Observations (G)

- **"Xin vào!" in red:** in this game wrong answers are lavender, never red, so a red button is unlikely to read as "wrong". With the hero's red headband and banner it reads as the hero's urgent plea, which fits. **But its label contrast is low:** the dark ink text (58,42,31) on red (217,52,43) is about **2.9:1**, under the 3:1 minimum even for large bold text. White text would give about 4.7:1.
- **Dialogue text contrast:** white text on the dark translucent box is high contrast and reads well. The scene (the hero figure) shows faintly through the box behind the text, which is a little busy but fine.
- **Two-line story text** nearly touches the Tiếp button (intro box 2, `r3-04`) and sits on the picture frame's lower edge. A few px more spacing would help.
- The hero's "determined" portrait has closed-line eyes that can read as sleepy (lines 6–7).
- G5 (the title shows no progress) is unchanged, as agreed.

## Environment

- **Emulator crash at about 21:05:** QEMU's main loop and CPU threads hung for 15 s under host load (`detected a hanging thread … No response for 15034 ms`), then the emulator exited with SIGSEGV (139). It was not stopped by another session (the log has no shutdown request). QC relaunched it (QC owns the lifecycle). The run in progress was discarded and redone from `pm clear`.
- **Interference watcher:** about 1,050 samples during r3. The only adb clients were QC's own and game-dev-android's `-s emulator-5556`, with **no foreign input on 5554**.
- Host load drops recording frames (25–60 fps), so the timing results above are given as bounds.
- This build has not been seen on a real low-end phone, and nobody has listened to the sound.
