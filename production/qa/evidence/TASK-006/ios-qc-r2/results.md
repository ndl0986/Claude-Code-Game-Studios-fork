# TASK-006 iOS QC, round 2 (part 1: non-touch re-checks)

- **Build:** frozen debug `.app` from `feat/TASK-006-ios-native` @ `0bb4826`, copied from game-dev-ios's
  `production/qa/builds/TASK-006-ios-0bb4826/` (`DaiDatAnhHung.debug.dylib` sha1 `bd71fda4…` matches the original).
  b9c946b was uninstalled first, then this build installed. Not rebuilt.
- **Reference:** the GDDs on `docs/vn-history-game-plan` @ `08497ed`; r1 results in `../ios-qc-r1/results.md`.
- **Date / tester:** 2026-11-14, game-qc-ios
- **Device:** Simulator "iPhone Duo" (iPhone19,4), iOS 27.1 (24A94425), cover display in landscape, captured with
  `simctl io screenshot --display=<cover UUID>`.
- **How:** debug launch arguments, `simctl` launch and terminate, Settings brought to the front to send the app to
  the background, UserDefaults read with `plutil`, and pixel colours sampled with a small AppKit script.

**Overall so far: NOT ASSESSED (touch still blocked).** macOS Accessibility reads still fail. The checks that need
no touch: all 3 r1 bugs are **fixed**, and the launch flash, the `-stage telegraph` jump and the "Ối!" placement are
**fixed**. **2 new low bugs** (R2-01 title, R2-02 grey frame) and 1 note. The touch cases follow once Luan toggles
Accessibility.

## Re-checks of r1 and the new items

| # | Check | Steps | Expected | Actual | Result | File |
|---|---|---|---|---|---|---|
| R1-01 | Skip warning z-order | `-startScreen intro -stage skipwarning`, VI and EN | Dialog above the dimmed story; nothing over it | The dialog is on top. The story sentence is now dimmed and passes **under** the dialog's bottom edge. The Tiếp and Bỏ qua buttons are dimmed | **PASS (fixed)** | k_skipwarning_vi.png, k_skipwarning_en.png |
| R1-02 | Font weight | Every screen | Not the thin ExtraLight | Text renders heavy (ExtraBold) on every screen; pads, "Bỏ qua" and the `why` line are clearly readable. Side effect: see R2-01 | **PASS (fixed)** | k_*_vi.png, k_*_en.png |
| R1-03 | Quiz `why` strip; debug badges | `-q 3 -stage right`, VI and EN | Strip below the cards; badges in one top strip | The strip sits below the cards with no overlap. The `UNSIGNED C06` badge is in the top strip. Note: in EN, "That's right!" and the 2-line `why` sit ~3 pt apart and "king." wraps alone (see notes) | **PASS (fixed)** | k_quiz-right_en.png, k_quiz-right_vi.png |
| L | Dark launch colour, no white flash | Cold launch, frames every 0.12–0.4 s | No white | The launch colour is the dark navy (#393153 at the centre sample) and there's no white. **But** on a launch right after an install, one frame is flat **grey** (#BFBFC1) between the launch colour and the title (2 of 2 fresh installs; not seen on a normal relaunch). See R2-02 | **PASS (white gone)**; new R2-02 | l1_launch-colour_fresh-install.png, l2_grey-frame_before-title_fresh-install.png, l3_grey-frame_first-run-1.png |
| T | `-stage telegraph` on a reach encounter | `-startScreen play -beat 4 -stage telegraph`, frames every 0.5 s | Enemy in windup with "!" | "!" over the enemy with the gold glow. The defend hand shows during the windup (HO AC3). One strike landed earlier in the series ("Ối!" with the hero flashing) | **PASS** | k_telegraph_t3.0s_vi.png, k_telegraph_oi-below-hud_t2.0s_vi.png |
| P | Pops kept below the HUD ("Ối!") | Same series | "Ối!" not over pause or sound | "Ối!" sits over the hero's head, below the HUD row, clear of pause and sound. The training case itself (r1's K item) still needs a training hit, i.e. touch | **PASS** (reach); training NOT ASSESSED | k_telegraph_oi-below-hud_t2.0s_vi.png |
| W | New skip-warning wording, no pronoun | Skip-warning jump | "Nếu bỏ qua, sẽ chưa nhận được huy hiệu của câu chuyện này nhé." | Exactly that text (VI). EN unchanged: "If you skip, you won't get this story's medal yet." | **PASS** | k_skipwarning_vi.png |
| W2 | `-startScreen skipwarn` alias | `-startScreen skipwarn` | Same as `intro -stage skipwarning` | Same screen | **PASS** | k_skipwarn-alias_vi.png, k_skipwarn-alias_en.png |
| BC | Beat card: title in the header, first box = first scene line | `-beat 1 -stage card` | Header "Phần 1 · …", body = scene line | Header "Phần 1 · Đến bến Bình Than" / "Part 1 · To the Bình Than riverbank"; body "Giặc Nguyên sắp sang xâm lược." / "The Nguyên army is coming." | **PASS** | k_card-walk_vi.png, k_card-walk_en.png |
| PR | Partner rest → windup cycle, encounter lock, hold hand when stuck, stuck arrow over the next dummy, separate flag hints (held vs tapped), last dummy → blocks in the same frame | — | — | Need play input (touch). Static frames show the partner in windup with "!" in training blocks and the hold hand at the hold-meter start | NOT ASSESSED (no touch) | k_training-blocks_*, k_play-hold_* |

## Regression sweep of the non-touch cases (same as r1)

| # | Case | Actual | Result | File |
|---|---|---|---|---|
| A1/A2 | VI default on a fresh install; EN; diacritics | VI title on a fresh install, EN via `-lang en`; diacritics unclipped in the heavier weight on all screens. `seen_open.tran-quoc-toan = true` saved | PASS | a1_title_vi.png, a1_title_fresh-install_vi.png, a2_title_en.png |
| C | Pads per beat | Walk ◀▶ only; hold Cờ/Flag only plus the hold hand; training ◀▶ Đỡ Đánh Cờ; reach encounter ◀▶ Đỡ Đánh, no flag pad in the fight | PASS (layout) | k_play-walk_*, k_play-hold_*, k_training-blocks_*, k_reach-encounter_* |
| F2 | Results medal / no medal | Gold "Nhận được huy hiệu!"; outline "Read it all for a medal", stars greyed, no red | PASS | k_results-newmedal_*, k_results-nomedal_* |
| G2 | Killed during beat 3 → relaunch | Title opens | PASS | g1_relaunch-after-kill-in-beat3_title.png |
| I | Background mid-fight for 10 s | Comes back on "Tạm dừng". The enemy had only reached the right edge during the ~0.3 s switch and was still there after 10 s; the hero hadn't moved | PASS | i1_walk-in_just-before-bg.png, i2_return-after-10s-bg.png |
| K4 | Quiz wrong card | Greyed card, lavender border, circular arrow. "Thử lại nhé!" is now a pale blush (#F8D8D0), not red | PASS | k_quiz-wrong_vi.png, k_quiz-wrong_en.png |
| — | Ending, pause, quiz, intro | Render in VI and EN with no overlap | PASS | k_ending_*, k_pause_*, k_quiz_*, k_intro_* |

## New bugs (bug-report format)

### iOS-R2-01: VI title runs into the side emblems in the new bold weight
- **Severity:** Low (S4). **Priority:** P3. **Platform:** iOS 0bb4826, iPhone Duo Sim iOS 27.1.
- **Steps:** launch with VI (default).
- **Expected:** a clear gap between "Dải Đất Anh Hùng" and both round emblems.
- **Actual:** with ExtraBold, the "D" touches the left emblem's outer ring and the "g" of "Hùng" crosses into the right
  one. EN "Land of Heroes" is shorter and clear.
- **Suggested fix (dev's call):** shrink the title to fit the space between the emblems, or use SemiBold/Bold for the title.
- **Evidence:** a1_title_vi.png, g1_relaunch-after-kill-in-beat3_title.png.

### iOS-R2-02: One flat grey frame between the launch colour and the title on the first launch after an install
- **Severity:** Low (S4). **Priority:** P3.
- **Steps:** `simctl uninstall`, `simctl install`, launch; capture every 0.12 s.
- **Expected:** launch colour → title, with no other colour.
- **Actual:** one full-screen grey frame (#BFBFC1, about 0.1–0.4 s) appears just before the title. Seen 2/2 on the
  first launch after an install, 0/1 on a normal relaunch. It looks like the SKView or window background showing
  before the first scene draws. A child might see it as a blink.
- **Suggested fix (dev's call):** set the view or window background to the launch colour, or present the scene before
  the view becomes visible.
- **Evidence:** l2_grey-frame_before-title_fresh-install.png, l3_grey-frame_first-run-1.png.

## Notes

- **EN quiz `why` line:** "That's right!" and the 2-line explanation sit ~3 pt apart, and "king." wraps onto its own
  line. Readable, but a little crowded (k_quiz-right_en.png).
- The Cờ/Flag pad still sits over the third dummy in training (r1 note, unchanged).
- Letterbox bars as before (TASK-013).

## Still to run once Accessibility works (r2 part 2, same build)

A3, B, C behaviour (with the parity switches PR), D timing and rules, E timing (stall hint, reset on resume, hold
hand when stuck, stuck arrow, flag hints), F flow plus medal, G save at quiz finish, H the 2nd landscape direction,
I resume, J, K2 (Ối! in training).

---

# Part 2: touch cases on the iPhone 18 Pro (iOS 27.0)

- **Device change (Luan's call, relayed by the leader):** iPhone 18 Pro Simulator, iOS 27.0
  (`E9F515E9-58F2-4A92-ABEF-C5CD59CE8183`), a Dynamic Island phone, so there is no foldable caveat. The Duo was shut down
  (not erased). The same frozen `0bb4826` copy was installed after an uninstall.
- **Input:** Device Hub window, driven by macOS mouse events posted to the simulator view (one pointer), plus `orca computer`.
  Real multi-touch isn't possible this way: **NOT ASSESSED**.
- **Captures:** `simctl io screenshot` (2622×1206), about 0.5–0.7 s per frame, so timings are ± one frame.
  There was no frame-step tool, so exact timings (1.1 s telegraph, the 0.25 s debounce, 5.0 s stall) are bounded, not measured.
- **Runs:** run A was a fresh install that skipped story (Skip → Keep reading → Skip → Skip anyway), with 3 quiz retries.
  Run B read every story box with Tiếp only and had 0 retries. Run C started a new run with the medal earned.

**Overall part 2: FAIL. 2 new bugs (1 S2 input, 1 S3 quiz timing) and 2 low ones.** The full mission plays
end to end, on both runs, and saving works.

| # | Case | Steps | Expected | Actual | Result | File |
|---|---|---|---|---|---|---|
| H1 | Safe area, island on the left | Rotate the device in Device Hub; title and training | Nothing under the island or the home indicator | The game is 16:9 (≈713×402 pt) inside the 874×402 pt screen, with ≈80 pt bars on both sides (island inset 62 pt). Pads sit ≥24 pt above the bottom edge (indicator inset 21 pt) | **PASS** | h1_frame_island-left_title.png, h1b_frame_island-left_training.png |
| H2 | Safe area, island on the right | Rotate 180° | Same | Same layout, mirrored device | **PASS** | h2_frame_island-right_training.png, h2_device_island-right_training.png |
| H3 | Pads ≥72 pt (18 Pro) | Measured on the device shots | ≥72 pt | ◀/▶ ≈89, Đỡ ≈88, Đánh ≈103, Cờ ≈90 pt | **PASS** | h2_device_island-right_training.png |
| A3 | VI\|EN kept after relaunch | Tap EN, kill, relaunch | EN kept | EN title after relaunch; `lang = en` in UserDefaults | **PASS** | a3a_after-tap-EN.png, a3b_relaunch_EN-kept.png |
| B | Story flow; double tap within 0.25 s advances once (MF AC9) | Two taps 0.15 s apart on Tiếp: card 1 box 1, ending box 1 | One box | Card 1: box 1 → box 2 only. Ending: box 1 → box 2 only. The intro has a single box, then the `walk_to` leg (correct per data). Each card is scene lines + the goal box (card 1: 4 boxes) | **PASS** | b2_card1-box1.png, b3_card1-after-double-tap.png, b4_ending_after-double-tap.png |
| C1 | Walk (card first, move pads only, 11.6 s) | Hold ▶ from rest | Ends ≈11.6 s | Still walking at 11.4 s, done (medal 1 lit, "Đi tiếp") at 12.0 s from the press, which includes ~0.1–0.3 s input latency. Only ◀▶ shown | **PASS** (±0.4 s) | c1_walk_t11.4s_still-walking.png, c1_walk_t12.0s_done_medal1.png |
| C2 | Hold-meter (Cờ only, 2.5 s, no drain) | Hold 1.2 s, release 2.5 s, hold 1.0 s, then 0.5 s | Meter keeps its level while released; ends at 2.5 s total | The ring stayed at the same fill while released, ≈88% after 2.2 s, and the beat ended on the next 0.5 s hold | **PASS** | c2_hold_after-1.2s.png, c2_hold_released-2.5s_no-drain.png, c2_hold_after-2.2s-total.png, c2_hold_done_medal2.png |
| C3 | Training: early flag tap does nothing; 3 dummies → blocks; blocks count only if held at the strike; flag | As named | As named | Early Cờ tap: nothing. 3 dummies hit, and the partner switched to blocks right after the last dummy. A defend press released mid-windup: hit with "Ối!", not counted. Defend held: "Đỡ được!" ×3, then the partner leaves and the flag tap ends the beat | **PASS** | c3_*.png |
| C4 | Parity: partner rest → windup cycle | Watch the partner | Rest, then windup | Rest ↔ windup with "!" each cycle | **PASS** | c3_partner-windup_defend-hand.png, i1_*.png |
| C5 | Reach-the-flag: 2 encounters lock the camera, then the flag; no flag pad in fights | Play both runs | Camera locks until enemies flee; flag ends the beat | The camera locks and unlocks after each encounter, and the flag ends the beat; no flag pad in fights. The known **G2 pinning** (fixed in later builds): the hero walks *through* the first enemy and gets pinned at the right screen edge with enemies behind him or half off-screen (the leader overlaps the hero). Both runs finished: run A in 154 s, run B in ~176 s (within the 3-min cap) | **PASS with the known G2 issue** | d1_*.png, d3_*.png, d6_hero-walks-through-enemy_pinning.png, d5_reached-flag_ending-box1_t154s.png |
| D1 | Telegraph 1.1 s | Idle in the encounter, frames every ~0.6 s | "!" ≈1.1 s, then strike | "!" in 2 consecutive frames (2.5–3.8 s), strike in the next (3.8–4.3 s): ≥0.65 s and ≤1.8 s, consistent with 1.1 s. Leader 1.32 s: not separately timed | Consistent; exact timing NOT ASSESSED | d7_*.png |
| D2 | Block rules, flee, no lives | Fights | Weapon dropped on flee; no lose screen | Two hits → enemy flees, weapon on the ground. Many hits taken, no lose screen or lives | **PASS** | d2_enemy-flee_weapon-dropped.png |
| D3 | Dropped attack while defending (SSC AC18) | — | — | Needs two simultaneous touches | NOT ASSESSED (single pointer) | — |
| E1 | First-use hands | Run start | Hand on ▶ until the first move; hand on Đánh in training until the first hit; hand on Đỡ during windup until the first block | All seen as specified | **PASS** | c0_walk-to-0_hand-on-right.png, c3_*.png |
| E2 | Hold hand to 25%; again when stuck | Hold 0.6 s (24%), then idle | Hand stays below 25%; returns when stuck | Hand still on at 24%; back with a pulse after ~6 s idle | **PASS** | e1_hold-hand-still-at-24pct.png, e1_hold-hand-back-when-stuck.png |
| E3 | Stuck hint ~5 s (arrow over the next dummy); reset on resume | Idle in training; pause/resume while the hint shows | Hint after 5 s; hidden on resume; back after another 5 s | Arrow over the next dummy plus the attack pulse after ≈5 s. After resume: hidden at 0.5 and 3.5 s, back by 6 s | **PASS** (±0.6 s) | e2_stuck-arrow-over-next-dummy.png, e3_*.png |
| E4 | Separate flag hints: held vs tapped | Hold-meter, then training after blocks | Different teach hints | Hold-meter: hand plus ring (hold). Training: hand on Cờ after the 3 blocks (tap), with a pulse when idle | **PASS** | e1_*.png, e4_flag-tap-teach-hand_after-blocks.png, c3_flag-pulse-after-blocks.png |
| F1 | D-07: first Skip → warning (Keep reading default); Keep reading → same box | Run A, intro | As named | Warning with "Đọc tiếp" highlighted; Keep reading returns to the same box | **PASS** | f1_run-A_skip-tapped_warning.png, f2_run-A_keep-reading_same-box.png |
| F2 | Warning returns after Keep reading; Skip anyway → silent for the run | Run A, card 1, then cards 2–4 | As named | The warning came back on card 1; "Vẫn bỏ qua" skipped the card. Skip on cards 2, 3 and 4 went straight to play with no warning | **PASS** | f3_run-A_skip-again_warning-returns.png, f4_run-A_after-skip-anyway.png |
| F3 | Medal gold only for a full read | Results of run A and run B | A: outline; B: gold | A: outline medal, "Read it all for a medal", no `medal` key. B: gold "Nhận được huy hiệu!", `medal.tran-quoc-toan = true` | **PASS** | g1_run-A_results_skipped.png, g3_run-B_results_full-read.png |
| F4 | No warning once the medal is earned; medal never lost | Run C: Start, Skip | No warning; medal stays | Straight into play; `medal` still true | **PASS** | f5_medal-earned_skip-no-warning.png |
| G1 | D-16: saved at quiz finish; kill on results → relaunch keeps it | Run A: finish quiz, kill on results, relaunch | Completed and stars kept | `completed = true`, `stars = 1` saved before the kill and kept after relaunch | **PASS** | g2_relaunch-after-kill-on-results_title.png |
| G2 | Best stars kept / improved | Run B with 0 retries | 3★ replaces 1★ | `stars = 3` | **PASS** | g3_run-B_results_full-read.png |
| G3 | Results → title ("More heroes are coming") | Tiếp on results | Title | Title | **PASS** | g4_results-next_title.png |
| Q1 | Quiz: greyed card, 2 wrong → third only; why; stars by retries | Run A Q1: 2 wrong, then right; Q3: 1 wrong | Rules per GDD | Greyed lavender cards with the circular arrow; third card only after 2 wrong; `why` shown; R=3 → 1★; R=0 → 3★ | **PASS** | k_quiz1_*.png, g1/g3 |
| Q2 | Next not visible before `feedback_time` (0.9 s) (QS AC5) | Timed capture after a right pick | No Tiếp before 0.9 s | **Tiếp already visible in the first frame, ≤0.73 s after the pick**, on Q1 and Q2 | **FAIL: iOS-R2-04** | bug_quiz2_tiep-visible-within-0.67s.png, k_quiz1_right_tiep-at-~0.3s.png |
| Q3 | Language switch mid-quiz (QS AC10) | Wrong pick, pause → EN → resume | Same card greyed, all EN | Same card greyed, all EN | **PASS** | k_quiz3_wrong_vi.png, k_quiz3_after-lang-EN_still-greyed.png |
| I1 | Resume restarts the telegraph (SSC AC19) | Training: pause mid-windup, resume, timed frames | No early strike; full windup after resume | The partner went back to rest (no "!") for ~1.3 s, then a full new windup, strike at 2.3–2.8 s. No early strike | **PASS** (the partner re-enters rest first; enemy case not separately timed) | i1_resume-*.png |
| I2 | Pause screen during the quiz | Pause on Q3 | Pause over the quiz | The pause overlay shows the **last battle scene** (camp, hero) behind it, not the quiz | **Note: iOS-R2-06 (low)** | i_pause_from-quiz.png |
| J | Sound path | Mute toggle | Icon toggles | Speaker ↔ muted icon. Hearing: NOT ASSESSED in the Simulator | Icon PASS; audio NOT ASSESSED | j1_sound-toggled.png |
| K2 | "Ối!" in training clear of pause | Hits in training | Below the HUD | "Ối!" sits above the hero, below the HUD row, in training and reach | **PASS** | c3_early-release-not-blocked_oi-below-hud.png |
| M | Multi-touch (hold ◀/▶ and attack) | — | — | Single pointer only | NOT ASSESSED | — |

## New bugs, part 2 (bug-report format)

### iOS-R2-03: A pad stays "held" after release if the touch reported movement while held (stuck input)
- **Severity:** High (S2): the hero keeps walking, or keeps defending (can't attack), after the child lifts the finger.
  **Priority:** P1. **Confidence:** PLAUSIBLE on a real device (seen with Simulator mouse input; needs one device check).
- **Steps (Simulator):** in play, press ▶ (or Đỡ) and keep it down for ≥0.1 s while the pointer reports move events at the
  same spot (a mouse drag with no movement), then release.
- **Expected:** the pad releases; the hero stops.
- **Actual:** the pad stays lit and the action continues (▶: the hero keeps walking ~2 s+ after release; Đỡ: the shield
  stays up). A separate short tap anywhere on a pad clears it. **Control:** the same hold with *no* move events releases
  correctly. A real finger nearly always reports small `touchesMoved` while held, so this likely reproduces on devices;
  `touchesEnded` for a moved touch may be matched against a different pad/ID. The same thing made a training flag tap with a
  move event not count.
- **Evidence:** bug_right-stuck-2s-after-release.png, bug_defend-stuck-1s-after-release.png,
  bug_control_left-held-no-move-events_released-ok.png.

### iOS-R2-04: The quiz "Tiếp" appears before `feedback_time` (0.9 s) after a right answer
- **Severity:** Medium (S3), QS AC5. **Priority:** P2.
- **Steps:** in the quiz, pick the right card and capture continuously.
- **Expected:** no Tiếp until 0.9 s (`tuning.feedback_time`).
- **Actual:** Tiếp is in the first capture, taken 0.0–0.67 s after the release (≤0.73 s after touch-down), on Q1 and Q2.
  A child can skip the `why` line instantly.
- **Evidence:** bug_quiz2_tiep-visible-within-0.67s.png (with timing log), k_quiz1_right_tiep-at-~0.3s.png.

### iOS-R2-05 (update to R2-02): grey screen after a fresh install lasts several seconds on the 18 Pro
- **Severity:** Low (S4).
- **Actual:** on the 18 Pro, a capture ~8 s after the first launch post-install was still flat grey; the app then showed
  (taps during the grey period started the run). The Duo showed a single grey frame. Same likely cause as R2-02.
- **Evidence:** l4_grey-after-fresh-install_18pro_t8s.png.

### iOS-R2-06: The pause overlay during the quiz shows the last battle scene behind it
- **Severity:** Low (S4).
- **Steps:** in the quiz, tap pause.
- **Expected:** pause over the dimmed quiz.
- **Actual:** the dimmed camp scene with the hero is behind "Tạm dừng"; on resume the quiz returns correctly.
- **Evidence:** i_pause_from-quiz.png.

## Notes, part 2

- **Known G2 pinning** (reach-the-flag): the hero walks through enemies and is pinned at the right edge; the leader overlaps the
  hero, and enemies are drawn half off-screen. Both runs still finished in under 3 min. Also in training the hero is pushed to
  the left edge and partly clipped by each partner strike.
- The quiz question's 2nd line sits close to the card tops on Q2 and Q4/Q5 EN (no overlap).
- The quiz order was the same in both runs (deterministic shuffle).
- Early files `b1_double-tap_after-1..7.png`, `f1_skip-warning-first-play.png` and `f2_after-keep-reading_box1.png` are from my first
  attempt, before I knew the intro has one box: they show one Tiếp tap going from intro box 1 to the `walk_to` leg (correct).
- Input caveat: occasionally the first click after bringing Device Hub to the front was swallowed by macOS; repeated where needed.
