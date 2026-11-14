# TASK-007 Android QC, round 2 (native Kotlin, full structure, build 00f402d). CLOSED

**Overall r2 verdict: FAIL.** B1 (beat-card double tap) is still open, plus new bugs B4 (quiz taps during the shake are queued) and B3 (training hint order). The full structure, skip/medal, saving, pause and the release gate all pass. **Carried to r3:** the leader 1.32 s (needs the new `stage leader`), A6 (the stall hint at 5 s and its reset on resume), F2 (the windup restart on resume), A5 (tones) and the 0.9 s Tiếp frame timing. The contaminated Run B was redone cleanly (Run B2 after `pm clear`) with the interference watcher on, and it showed no foreign input on 5554.

| Item | Value |
|---|---|
| Build | `00f402d` on `setup/TASK-007-android-kotlin`. APK `production/qa/builds/TASK-007-00f402d.apk`. sha256 `776454af8b97df06…`, matching on the device and in QC's own copy. versionName 0.1.0. The APK requests no permissions. |
| Device | Emulator `mp17863` (`emulator-5554`), API 36, 1080x2400 at 420 dpi, gesture navigation, display cutout on the left in landscape 90°, `-gpu host`. A second emulator (`emulator-5556`, game-dev-android's `devandroid002`) is attached to the same adb server. QC pins every command with `ANDROID_SERIAL=emulator-5554`. |
| Method | Real kernel multi-touch via `sendevent` (world 1280x720 to screen px). Beat-aware touch autoplay with pixel-probe screen detection. 60 fps `screenrecord`, with each frame read and timestamped by a Swift AVAssetReader tool. `run-as` to read the prefs. logcat. |
| Date | 2026-11-14 |

## Results

| Item | Result | Notes | Evidence |
|---|---|---|---|
| **A1** Full playthrough to results | **PASS** (Run A) | Title, the intro (1 box in 00f402d's data), then walk_to and card, then walk, hold-meter, training and reach-the-flag, then the ending (2 boxes), the quiz (5 questions) and results. Run B (read everything) also reached the quiz. | `rA-*.png`, `rB-01…07` |
| A2 Leader telegraph 1.32 s | **NOT ASSESSED** on the device. Moves to r3 (leader). | In the slice the leader only appears in encounter 2 of reach-the-flag, behind spear soldiers. In three recordings (about 105 s) the front spear did every windup, and the one leader windup seen was cut short by a hit. The debug `telegraph` stage only applies to `fight` beats, and this mission has none. The value is covered by the unit tests. Suggestion: a debug stage that puts the leader in windup. | `flag`/`lead` recordings (scratchpad) |
| A3 Flee | **PASS** | Spear soldiers drop their weapon (it stays on the ground) and leave. | `r2-c14-after-flag-beat.png` area, encounter frames |
| A4 No lives | **PASS** | While pinned at the camera edge (see G2) the hero was hit dozens of times in a row. There was no life counter, no lose screen and no restart. | `lead` recording |
| A5 One tone per menu press | **NOT ASSESSED** | The native build has no hook to count `SoundPool` plays, and nobody can listen. | — |
| A6 Stall hint after 5 s (step 301) and reset on resume | **not run** (moves to r3) | The stall arrow and attack pulse were seen in play (r1 and r2 recordings), but the 5.0 s boundary and the reset on resume weren't frame-measured. | |
| A7 Sound signal path | **Signal present.** NOT ASSESSED for hearing. | The app opens audio playback on UI and combat events: system `AppOps` entries for the app on each burst of sound, and a `c2.android.raw.decoder` (SoundPool) on start. Nobody has listened. | logcat |
| A8 logcat errors | **PASS** (no app errors) | Across 7 app processes: **0** `FATAL`/`AndroidRuntime` lines, **0** ANRs, **0** lines with the app's `DaiDat` tag (no content warnings), and **0** network activity. The only `E`/`W` lines are platform noise from the emulator's codec and graphics (`MediaCodec: Media Quality Service not found`, `Codec2Client … param skipped`, `ashmem pinning deprecated`, `HWUI` config fallbacks) and a system `AppOps: attributionTag not declared in manifest`, which is harmless. | `logcat-r2` (scratchpad) |
| A9 Release-gate log (read only) | **PASS** (with a caveat) | `production/qa/builds/TASK-007-release-gate.log` (game-dev-android, 19:52): `> Task :app:contentGate FAILED`, then "Content gate failed (release builds need signed-off content): R12 hero tran-quoc-toan: claims not approved: C01 … C12", then `BUILD FAILED`. A release build is refused while claims are pending, as designed. **Caveat:** the log doesn't name the commit, and its first line says `app/build.gradle.kts` had changed, so it may come from a working tree newer than 00f402d. Read only; QC didn't build. | game-dev-002 `production/qa/builds/TASK-007-release-gate.log` |
| **B** B1 re-check: two taps within 0.25 s on every Next | **FAIL** on beat cards. **PASS** on quiz Tiếp and results Next. | **Beat cards: 2 of 2 skipped a line.** On card 1, a double tap 0.17 s apart went from line 1 to line 3. On card 2, a double tap 0.14 s apart skipped the "Truyện kể rằng… quả cam" line straight to the goal box. **Quiz Tiếp:** a double tap 0.15 s apart moved Q1 to Q2 only (PASS). **The intro** has only 1 box in this build, so it can't be tested there. **Results Next:** a double tap 0.15 s apart lands on the title, and nothing more fires (`rB2-21`). → **B1 stays open** (see the bug below). | `r2-b1-FAIL-card1-…`, `r2-b1-FAIL-card2-…`, `rA-05-q2-after-double-tap-on-q1-next.png` |
| **C1** Walk | **PASS** | It follows the GDD state table: walk_to, then the card, then walk (3 screens). Only ◀ ▶ (plus pause and mute) show. The hand is on ▶ at the start. A held ▶ for about 12 s ended the beat, the 1st star lit, and **no caption** followed. | `r2-c01…c03` |
| **C2** Hold-meter | **PASS** | Only the flag pad (special) shows. Holding 1.2 s and releasing left the meter partly filled, and it **did not drain** after 3 s. A further 1.0 + 0.5 s finished the beat (2nd star), so 2.5–2.7 s in total. The hand is on the flag at the start. | `r2-c05`, `r2-c06-*` |
| **C3** Training | **PASS** for the rules, with two findings (B3 below and G3) | Tapping the flag **early did nothing**. The 3 dummies were knocked down by attacks. The partner (blue tunic, red headband) then winds up. A **press-and-release of defend during the windup did not count** (the hero took the hit). **Held blocks counted** ("Đỡ được!" at 6.0, 9.0 and 12.0 s). After 3 blocks the partner leaves and the **flag pad pulses**, and tapping it ends the beat (3rd star). | `r2-c09`, `r2-c10`, `r2-c11a/b/c`, `r2-c12` |
| **C4** Reach-the-flag | **PASS**, with UX finding G2 | Encounter 1 (2 spears) and encounter 2 (spear, leader, spear) each **lock the camera** until every enemy has left. The flag is reached at the end, followed by the ending. The banner/flag pad is never shown during encounters (only ◀ ▶, Defend and Attack). | `r2-c13`, `r2-c14`, recordings |
| C5 Non-fight beats show a card and no caption | **PASS** | Every beat in this mission is non-fight. Both runs showed 4 cards and 0 captions. | run logs |
| **D1** Skip on every story box | **PASS** | "Bỏ qua" is on the intro box, every beat card and the ending boxes. | `rA-01…09` |
| D2 The warning returns after "Keep reading" | **PASS** | Skip, then the warning, then "Đọc tiếp" (back to the box), then Skip again, and **the warning shows again**. | `rA-02-skip-warning-1.png`, `rA-04-skip-warning-2.png` |
| D3 "Skip anyway" means the rest of the run skips silently | **PASS** | After "Vẫn bỏ qua", 4 cards and the ending were skipped with **no further warning**. | `rA.log` (warned 2, both on the intro) |
| D4 Skip ends only that section | **PASS** | Skipping a card went to its play, never past the play. Skipping the ending went to the quiz. | `rA.log` |
| D5 Medal gold only if the run read everything | **PASS** | Run A (skipped): **not earned**, with "Đọc hết câu chuyện để nhận huy hiệu nhé" and no `medal` in the prefs. Run B2 (after `pm clear`, every box read, no Skip): **"You earned the medal!"** in gold, and `medal=true` saved at quiz finish. | `rA-21-results-1star-no-medal.png`, `rB2-20-results-read-all.png` |
| D6 No warning once the medal is earned; saved, never lost | **PASS** | Run C (medal already earned, Skip tapped on every box): **no warning at all** (warned 0). The run was finished with 5 retries, and the results still show the gold medal. The prefs keep `medal=true`, and the best stars stay 1. The medal also survived a kill and relaunch after Run B2. | `rC-*.png`, `rC.log`, `rB2-22-title-after-relaunch.png` |
| **E1** Progress saved at quiz finish | **PASS** | On Run A's results screen the prefs held `stars=1`, `completed=true` and `seen_open`. **Killing the app on results and relaunching** kept all three, and the title screen opens. | `rA-21`, `rA-22`, prefs dump |
| E2 Results → title, "More heroes are coming" | **PASS** | "Còn nhiều anh hùng nữa sắp đến" / "More heroes are coming" is shown. Next goes to the title (with next_hero null, there is no unlock screen). | `rA-21`, `rB2-20`, `rB2-21` |
| **F1** Focus loss pauses play and the quiz | **PASS** | Pressing Home on quiz Q1 and returning gives "Tạm dừng", with "Chơi tiếp", "Màn hình chính" and VI\|EN. Play paused on background in r1 (bfe3890). **Quiz AC10:** after a wrong pick, pause, switch to EN and resume, the same card is still greyed and all text is EN ("Try again!"). | `rB2-08-F1-quiz-after-home-and-return.png`, `rB2-09-quiz-AC10-en-after-wrong-pick.png` |
| F2 A windup restarts its telegraph from 0 on resume | **not run** (moves to r3) | | |
| Quiz rules (extra) | **FAIL** on AC6 (B4). The rest PASS. | A wrong card turns **lavender with a circular-arrow icon**, plus "Thử lại nhé!". A re-tap on a greyed card is ignored. The right card turns green and shows its why line. **Tiếp waits and never auto-advances** (still on Q1 4 s later). Stars: R=5 gave 1★ (Run A). The **0.9 s Tiếp delay** is not yet frame-measured. **AC6: a tap during the shake is not ignored** (B4). | `rA-02`, `rA-04`, `rB-08`, `rB-09` |

## Bugs (`/bug-report` format)

### B1 (still open): two quick taps on "Tiếp" skip a beat-card line
- **Severity:** Medium (S3). A child misses story text; in one case the skipped line was the "Truyện kể rằng" legend line. **Priority:** P2.
- **Build / device:** 00f402d, mp17863, API 36.
- **Steps:** 1. Reach a beat card with 2 or more lines (card 1 or card 2). 2. Tap "Tiếp" twice, 0.14–0.17 s apart.
- **Expected:** One line advances (mission-flow AC9: two taps within 0.25 s, one box).
- **Actual:** Two lines advance, 2 of 2 times: card 1 went from line 1 to line 3, and card 2 went from line 1 to the goal box, skipping "Truyện kể rằng cậu tức quá, bóp nát quả cam…". Quiz Tiếp is debounced correctly (Q1 → Q2 only), so the fix in a317f58 seems to miss the beat-card and caption Next path.
- **Evidence:** `r2-b1-FAIL-card1-double-tap-0p17s-line1-to-line3.png`, `r2-b1-FAIL-card2-double-tap-0p14s-skipped-orange-line.png`.

### B4: a tap on another quiz card during the wrong-card shake is queued, not ignored (quiz AC6)
- **Severity:** Medium (S3). A child who taps quickly gets an extra wrong pick counted, which can cost a star. **Priority:** P2.
- **Build / device:** 00f402d, mp17863, API 36.
- **Steps:** 1. On a quiz question, tap a wrong card. 2. 0.25 s later (during the 0.5 s shake), tap a second card.
- **Expected:** The second tap is ignored (AC6), and the second card stays cream and selectable.
- **Actual:** The second card turns lavender as a wrong pick **exactly when the shake ends**. In the 60 fps recording the first card is lavender at 1.328 s and the second at **1.830 s (+0.502 s)**, with no touch in between. The tap was held and applied after the shake, adding a retry.
- **Evidence:** `rB-08-q1-tap-during-shake.png`, `rB-09-q1-second-card-lavender-at-shake-end-1830ms.png`, recording `quiz.mp4` (scratchpad).

### B3: at training start the hint hand points at the flag pad, which does nothing yet (hints GDD rule table)
- **Severity:** Low–Medium (S3). The first thing a child is told to press does nothing, and attack has never been taught in this mission (there are no fight beats before training). **Priority:** P3.
- **Steps:** Play to beat 3 (training) and close the card.
- **Expected:** Hints GDD: the special (tap) hand appears only when training's **finish step** starts. One teach hint at a time, with priority move > attack > defend > special, so the attack hand should show at the first dummy.
- **Actual:** The hand bobs on the flag pad from the start of training, before any dummy is hit. A tap there does nothing (correctly). The defend hand does show correctly during the partner's windup.
- **Evidence:** `r2-c08-B3-training-start-hand-on-flag-pad.png`, `r2-c09-training-early-banner-tap-nothing.png`.

## Wording and UX observations for a 6–10-year-old (G)

- **G1, the hold-meter goal "Giữ nút đặc biệt! / Hold the special button!"** No button is called "special": the child sees a flag icon. Suggestion: "Giữ nút lá cờ!" / "Hold the flag button!". The meter is a small ring around the orange bubble near the hero, while the art direction in mission-flow §visuals puts it **around the special pad**, where the finger and eyes are.
- **G2, reach-the-flag can trap a child who holds ▶.** With the camera locked, the hero walks through the enemies and ends up pinned at the right edge, facing away, while spears and the leader strike from behind. The beat never fails, but by touch with a simple "hold ▶ + tap attack" strategy, reach-the-flag took **280 s and 410 s** in two runs. The GDD estimate is 90 s, and combat AC14 says a fight should end within 2 min. A child is likely to play exactly like this. Suggestions: stop the hero at the encounter's far edge, turn the hero automatically toward the nearest enemy when the attack pad is pressed with nothing in front, or point the stall arrow behind the hero.
- **G3, training dummies stay lying flat once hit.** Mission-flow §visuals says they "wobble and spring back. They never break apart". Here they fall and stay on the ground. The art direction (and combat AC13's "no figure lying down") suggests springing back.
- **G4, the quiz Q1 pictures:** the right answer, "Nhà Trần", is a **red** flag, the same red as the hero's headband and banner, which may give the answer away. Red is also on screen during a wrong pick, while quiz AC9 says "no red anywhere on screen". These are placeholder pictures, but worth flagging for the art pass.
- **G5, the title screen shows no progress.** After finishing (1★, completed) the title looks the same as on a fresh install. Expected for the slice (no map), but a child gets no "you did it" on return.
- The skip-warning text "Nếu bỏ qua, bạn sẽ chưa nhận được huy hiệu của câu chuyện này nhé." with "Đọc tiếp" / "Vẫn bỏ qua" is clear and kind. The UNSIGNED badges now sit at the picture corner and no longer cover story text (r1 observation fixed).

## Environment

- **Outside interference, 19:37:49 to about 19:39:40.** While QC sent no input, the app on emulator-5554 played UI sounds continuously (system AppOps entries every few seconds). Run B's quiz (left at Q1) was finished, `medal.tran-quoc-toan=true` was written, and a new run was started and left at the beat-1 card. There was no crash or restart (same pid 7408). At that moment a shell was running under game-dev-android's session process. The leader has set a rule that devs use `-s emulator-5556` only, with a guard refusing 5554. **Results that depend on this window are discarded** (Run B's quiz, results and medal), and **they were redone** as Run B2 and Run C. Its screenshots are kept as `env-interference-1939-*.png`.
- The second emulator on the same adb server means a plain `adb` fails ("more than one device"). QC uses `ANDROID_SERIAL=emulator-5554` throughout.
- This build has not been seen on a real low-end phone, and nobody has listened to the sound.
- **Interference watcher** (from 19:43): every 2 s it records host processes with adb, monkey or input in their command line, with their parent chain (`intwatch-ps.txt`), alongside a live `logcat -b events`. During Run B2 and Run C the only adb clients were QC's own and game-dev-android's `-s emulator-5556` (install, `am start`, screencap), with **no foreign input on 5554**. The 19:37 interference stays unexplained.
