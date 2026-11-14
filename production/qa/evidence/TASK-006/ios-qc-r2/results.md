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
