# TASK-006 iOS QC, round 1 (partial: touch input blocked)

- **Build:** frozen debug `.app` from `feat/TASK-006-ios-native` @ `b9c946b`. I copied it from game-dev-ios's
  `production/qa/builds/TASK-006-ios-b9c946b/` (`DaiDatAnhHung.debug.dylib` sha1 `de67b5b3…` matches the original),
  then installed it after an uninstall. It was not rebuilt.
- **Reference:** the GDDs on `docs/vn-history-game-plan` @ `08497ed`: mission-flow, side-scroll-combat,
  hints-and-onboarding, quiz-and-stars and hero-progression.
- **Date / tester:** 2026-11-14, game-qc-ios
- **Device:** Simulator "iPhone Duo" (iPhone19,4, foldable), iOS 27.1 (24A94425), cover display (2034×1398 px in
  landscape), captured with `simctl io screenshot --display=<cover UUID>`. It is the only device iOS 27.1 runs.
- **How:** debug launch arguments (`-startScreen`, `-beat`, `-stage`, `-q`, `-stars`, `-lang`), `simctl`
  launch and terminate, Settings brought to the front to send the app to the background, and the app's
  UserDefaults read with `plutil`.

**Overall: NOT ASSESSED (partial).** macOS Accessibility reads failed for every app (Device Hub and Finder
alike), so `orca computer` could not tap, hold, drag or rotate. `orca computer permissions` still reports
"granted". I asked the leader for Luan to toggle Orca Computer Use off and on. Every case that needs touch is
NOT ASSESSED and will run in r1b once input works. Of the cases observed: **3 bugs** (one is the thin font) and
several notes. Nothing observed blocks a later run.

## Results

| # | Case | Steps | Expected | Actual | Result | File |
|---|---|---|---|---|---|---|
| A1 | VI default on a fresh install; diacritics | Uninstall, install, launch | Title in VI, diacritics unclipped | Title in VI ("Dải Đất Anh Hùng", "Bắt đầu", "Đi / Đánh / Đỡ"). Diacritics unclipped on every screen captured (Ặ, ẫ, ỏ, ữ…). After the first launch, UserDefaults holds `seen_open.tran-quoc-toan = true` (progression AC12) | PASS | a1_title_fresh-install_vi.png |
| A2 | EN text | `-lang en` | Every screen in EN | Title and all 15 screens below render in EN with the same layout | PASS | a2_title_en.png, k_*_en.png |
| A3 | VI\|EN switch kept after relaunch | Tap EN, kill, relaunch | EN kept | Needs a tap (`-lang` is a launch override, so it can't prove saving) | NOT ASSESSED (no touch) | — |
| B | Story flow; two taps within 0.25 s advance once (MF AC9) | — | — | Needs two fast taps | NOT ASSESSED (no touch) | k_intro_vi.png (layout only) |
| C | Full structure: walk, hold-meter, training, reach-the-flag | Debug jumps to each beat | Pads per beat | Layout per beat as specified: walk has ◀ ▶ only (MF AC3). Hold-meter has only the Cờ/Flag pad, plus the hold hand. Training has ◀ ▶, Đỡ, Đánh and Cờ, with 3 dummies and a partner showing "!". Reach-the-flag encounter has ◀ ▶, Đỡ and Đánh, with **no flag pad in the fight**. Beat card shows before walk (MF AC1). Playing each beat (2.5 s hold, no drain, block counting, early flag tap, camera lock): needs touch | Layout PASS; behaviour NOT ASSESSED (no touch) | k_card-walk_*, k_play-walk_*, k_play-hold_*, k_training-blocks_*, k_reach-encounter_* |
| D | Combat: 1.1 s telegraph, blocks, dropped attack, flee, no lives | Encounter jump, left idle | "!" before each strike; knock-back, no lose state | "!" shown over the spear enemy in windup, with a gold glow. The hero, not defending, was pushed back with "Ối!" and no lose screen. Not done: timing (no frame-step tool), block rules, the dropped attack, flee | Partial (telegraph on screen, no lives); rest NOT ASSESSED | i4_encounter_t6s_just-before-bg.png, i5_return-after-10s-bg_paused.png |
| D2 | `-stage telegraph` debug jump | `-startScreen play -beat 4 -stage telegraph`, 6 shots over 4 s | Enemy in windup | No enemy on screen; the hero stands at the beat start. A debug-only gap (not in game-dev-ios's README table) | Note | k_telegraph_vi.png |
| E | Hints | Debug jumps | Hand on first use | Hand on Cờ in hold-meter and on Đỡ in training blocks, with no text in the hints (VI and EN identical apart from the HUD). Stall hint at ~5 s and the reset on resume: needs touch | Partial PASS (hands seen); timing NOT ASSESSED | k_play-hold_*, k_training-blocks_* |
| F | D-07 skip warning and medal | `-startScreen intro -stage skipwarning` | Warning with Keep reading as default | Warning shows "Đọc tiếp / Keep reading" highlighted as the default and "Vẫn bỏ qua / Skip anyway". **Bug iOS-R1-01:** the story sentence is drawn on top of the dialog. Keep reading → returns, Skip anyway → silent, and medal rules: need touch | **FAIL** (iOS-R1-01); flow NOT ASSESSED | k_skipwarning_vi.png, k_skipwarning_en.png |
| F2 | Medal on results | `-startScreen results -stars 3 -stage newmedal` / `-stars 1 -stage nomedal` | Gold medal plus "earned"; outline plus `ui.medal.missing`, no red | Gold medal "Nhận được huy hiệu!"; outline medal "Read it all for a medal", stars greyed, no red | PASS (screens) | k_results-newmedal_*, k_results-nomedal_* |
| G | D-16: saved at quiz finish; results → title | — | — | Finishing the quiz needs taps (the results jump doesn't save, as expected: UserDefaults unchanged) | NOT ASSESSED (no touch) | k_results-* (layout) |
| G2 | Killed during beat 3 → relaunch (MF AC13) | `-startScreen play -beat 3`, terminate, plain launch | Title opens | Title opens | PASS | g1_relaunch-after-kill-in-beat3_title.png |
| H | Safe area; pads ≥72 pt; both landscape directions | Measured on the screenshots | Pads ≥72 pt, clear of camera and home indicator | Measured in px on the 2034 px-wide capture, read as pt at an assumed @3x: ◀/▶ ≈ 88 pt, Đỡ ≈ 86 pt, Đánh ≈ 99 pt, Cờ ≈ 86 pt. The game draws at 16:9 inside the cover display, with black bars at the top and bottom (the TASK-013 letterbox), so every pad sits ≥ 80 pt from the side edges. Only the app's orientation was seen (landscape); the other direction needs Device Hub's rotate button | Partial PASS (sizes, one direction); 2nd direction NOT ASSESSED | k_play-walk_vi.png, k_training-blocks_vi.png |
| I | Background mid-fight → paused, nothing acts (MF AC10) | Encounter jump; shot; Settings to the front for 10 s; back to the app | Pause screen; no enemy progress | Comes back on "Tạm dừng" with Chơi tiếp / Màn hình chính. The enemy had just entered at the right edge and was still there after 10 s (only ≈0.3 s of drift during the app switch); the hero hadn't moved. Run twice. The hold-meter variant and "resume restarts the telegraph" need touch | PASS (auto-pause, no action while backgrounded); resume NOT ASSESSED | i6_walk-in_just-before-bg.png, i2_backgrounded_settings-in-front.png, i7_return-after-10s-bg.png, i1/i3 |
| J | Sound / multi-touch | — | — | Hearing NOT ASSESSED on the Simulator; multi-touch can't be done in the Simulator | NOT ASSESSED | — |
| K1 | Font weight | Font inspection plus screenshots | Readable for a 6-year-old, matching Android | **Bug iOS-R1-02:** text renders in Nunito **ExtraLight (weight 200)**. Thin strokes on the cream pads and dark story panel are hard to read (pad labels, "Bỏ qua", the quiz `why` line) | **FAIL** (iOS-R1-02) | k_intro_vi.png, k_quiz-right_en.png, k_play-hold_en.png |
| K2 | "Ối!" over the pause button in training | — | — | Needs a training hit (touch). Seen once elsewhere: after the background test, "Ối!" sits right under the sound button on the pause screen | NOT ASSESSED (training); see note | i5_return-after-10s-bg_paused.png |
| K3 | Other overlaps | All captures | No overlap | **Bug iOS-R1-03:** on a right quiz answer, the `why` strip covers the bottom ~20 pt of all three cards. Debug only: the `UNSIGNED C06` badge sits on the middle card instead of the top strip. Notes below | **FAIL** (iOS-R1-03, low) | k_quiz-right_en.png, k_quiz-right_vi.png |
| K4 | Quiz wrong card | `-q 3 -stage wrong` | Lavender-grey, circular arrow, no red | Greyed card, #9C8FB8-looking border, circular-arrow mark, "Thử lại nhé!", no red (QS AC9) | PASS | k_quiz-wrong_vi.png, k_quiz-wrong_en.png |

## Bugs (bug-report format)

### iOS-R1-01: Skip warning: the story sentence is drawn on top of the dialog
- **Severity:** Medium (S3). Child-facing, and text crosses the primary button. **Priority:** P2. **Platform:** iOS
  (b9c946b), iPhone Duo Sim iOS 27.1. **Also in** game-dev-ios's own `13-skip-warning-vi.png`.
- **Steps:** 1. `xcrun simctl launch <udid> com.galaxyandsun.daidatanhhung -startScreen intro -stage skipwarning`
  (VI or EN). In play: tap Bỏ qua on the first story box.
- **Expected:** the dialog sits above the dimmed story box; nothing draws over it.
- **Actual:** the story sentence ("Ngày xưa, thời nhà Trần…" / "Long ago, in the time of…") is drawn at full
  brightness over the dialog's bottom edge and through the lower half of "Đọc tiếp / Keep reading". The Tiếp
  and Bỏ qua buttons behind it are dimmed, but the sentence isn't.
- **Likely cause:** the story text node's zPosition is above the warning overlay, or it isn't put under the dim layer.
- **Evidence:** k_skipwarning_vi.png, k_skipwarning_en.png.

### iOS-R1-02: All text renders in Nunito ExtraLight (weight 200), much thinner than Android
- **Severity:** Medium (S3), readability for the 6–8 age group and a platform-parity gap. **Priority:** P2.
- **Steps:** launch any screen; compare with Android's captures.
- **Expected:** the Nunito weight the art bible and UI spec name (Android's renders as Regular or heavier).
- **Actual:** `data/fonts/nunito.ttf` is the variable Nunito (wght axis 200–1000, **default 200**). `Draw.swift:82-83`
  takes `descs.first`'s name, which is `Nunito-ExtraLight`, and `SKLabelNode(fontNamed:)` draws every label at
  weight 200.
- **Suggested fix (dev's call):** use a named instance such as `Nunito-Regular`, `Nunito-SemiBold` or
  `Nunito-Bold` (all are in the file), or set the `wght` variation. Then re-check the text budgets.
- **Evidence:** every `k_*` capture; font axes read with CoreText from the shipped `.app`.

### iOS-R1-03: Quiz right answer: the `why` strip overlaps the bottom of the answer cards
- **Severity:** Low (S4). **Priority:** P3.
- **Steps:** `-startScreen quiz -q 3 -stage right -lang en` (also VI).
- **Expected:** the `why` line and Next sit below the cards with a gap.
- **Actual:** the dark strip holding "That's right! The story says…" and Next covers the bottom ~20 pt of all
  three cards, including the green one's border. Debug only: the `UNSIGNED C06` badge for the `why` line is drawn
  on the middle card, not in the top strip.
- **Evidence:** k_quiz-right_en.png, k_quiz-right_vi.png.

## Notes (not bugs; for the leader)

- **White launch flash:** `UILaunchScreen` is an empty dict, so the first ~1 s after a cold launch is plain white
  before the cream title (note_white-launch-flash_t0.7s.png, 0.7 s after launch). A launch screen in the title's
  background colour would avoid the flash.
- **Letterbox:** black bars above and below the 16:9 game on the cover display, already tracked as TASK-013.
- **Training layout:** the Cờ/Flag pad sits on top of the third dummy (k_training-blocks_*). Worth checking that
  the child can still see it get hit.
- **Results:** "Giỏi lắm!" and "Còn nhiều anh hùng nữa sắp đến" are drawn across the decorative ring lines. They
  stay readable; this is cosmetic.
- Settings (com.apple.Preferences) was used only to send the app to the background, and was terminated afterwards.

## To finish in r1b (once Accessibility works again)

A3, B, C behaviour, D timing and rules, E timing, F flow plus medal, G, H second direction, I resume, K2. Same
build, same branch.
