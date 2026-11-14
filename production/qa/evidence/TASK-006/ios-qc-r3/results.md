# TASK-006 iOS QC, round 3

- **Build:** frozen debug `.app` from `feat/TASK-006-ios-native` @ `9b0470a`. Fingerprint
  `find production/qa/builds/TASK-006-ios-9b0470a/DaiDatAnhHung.app -type f -exec shasum -a 256 {} + | sort -k2 | shasum -a 256`
  run from the game-dev-001 root = `544279664aaa…984daa` (**matches**). Note: the hash depends on the path form, so the
  same command run on the absolute path gives a different value. My scratch copy matches the original file by file.
  0bb4826 was uninstalled first. Not rebuilt.
- **Device:** iPhone 18 Pro Simulator, iOS 27.0, `E9F515E9-58F2-4A92-ABEF-C5CD59CE8183` (Dynamic Island).
- **Base / branch:** `qa/TASK-006-ios-r3` from `bb343e2`.
- **Input / capture:** as in r2. macOS mouse events go to Device Hub, one pointer at a time. Holds are sent either *with*
  move events every 50 ms (`press2`, which can also slide off the pad) or *without* (`press`). `simctl io screenshot`
  takes ≈0.5–0.6 s per frame. There's no frame-step tool.
- **Date / tester:** 2026-11-14, game-qc-ios

**Overall: FAIL.** R2-03 (stuck pad) **still reproduces**. Fixed: R2-04, R2-05, R2-06, G2 and R2-01 (title).
The dialogue beat works. The 005h text-size change caused **new layout regressions** (quiz question clipped, intro text
on Tiếp, card title over emblems, HUD overlaps), the intro pictures are empty, and the camp sky makes the goal text
hard to read.

## Priority retests

| # | Case | Steps | Expected | Actual | Result | File |
|---|---|---|---|---|---|---|
| 1 | **R2-03** stuck pad, with move events | Training: ◀ ▶ Đỡ Đánh Cờ, held 0.6–1.0 s with move events, either in place or sliding 90–120 view-px off the pad, ×3 each (30 presses). Pad colour sampled 0.25 s and 0.85 s after release | Nothing held after release | **Still stuck, intermittently:** ▶ stayed lit with the hero still walking at 0.85 s (1/3 in place); ◀ stayed lit (2/3 in place); Cờ stayed lit across the next presses (1/3). Sliding ◀ to the right onto ▶ left **▶** stuck (2/3). Đỡ can't be read by colour (hint pulse), and Đánh never stayed lit. **Control:** 12 holds with no move events: 0 stuck | **FAIL** | r203_R-held-moves_after-release_t0.25s.png, r203_R-held-moves_after-release_t0.85s_still-walking.png, r203_L-stuck_t0.25s.png, r203_L-stuck_t0.85s.png, r203_flag-stuck_t0.25s.png, r203_flag-stuck_t0.85s_oi-over-goal-text.png |
| 1b | Background while holding ▶ | Hold ▶ (no move events), send to the background, return, Chơi tiếp | Paused; nothing held after resume | Paused screen on return; after resume ▶ is not lit and the hero isn't walking | **PASS** | r203_bg-while-holding-right_paused.png, r203_bg-hold_after-resume_t1.2s.png |
| 1c | Pause while holding | — | — | Needs a second touch on pause while holding a pad | NOT ASSESSED (single pointer) | — |
| 2 | **R2-04** quiz Tiếp + `why` ≥ 0.9 s | Right pick on Q1 and Q2, timed captures | Neither before 0.9 s | Q1: the 0–0.62 s frame shows only "Đúng rồi!" (no `why`, no Tiếp); the 0.62–1.14 s frame has both. Q2: a capture started at 0.62 s already had them. So not shown before ~0.6 s; 0.6–0.9 s isn't resolvable without frame-step | **PASS** (bounded; r2 showed Tiếp in the 0–0.67 s frame) | r204_q1_t0-0.62s_no-tiep.png, r204_q1_t0.62-1.14s_tiep.png, r204_q2_capture-from-0.62s_tiep.png |
| 3 | **R2-05** fresh-install launch | Uninstall, install, launch; 23 back-to-back captures | No grey; report the time to the first non-grey frame | **No grey frame at all.** Launch colour (#393153) from 1.2 s to 5.9 s; **first title frame in the 5.9–6.5 s capture** (the first non-launch-colour frame). ~6 s on the launch colour on the first launch after install | **PASS** (number: ≤6.5 s to title, 0 grey frames) | r205_launch-timing.txt, r205_launch-colour_t1.2s.png, r205_first-title-frame_t5.9-6.5s.png |
| 4 | **R2-06** pause in the quiz | Pause on Q2 | The quiz behind "Tạm dừng" | The dimmed quiz is behind the pause menu | **PASS** | r206_pause-in-quiz.png |
| 5 | **G2** reach-the-flag | Walk in, attack only, timed | No walking through enemies, no edge pinning, auto-face; time the encounters | The hero **stops at the enemy** and is never pinned at the right edge. Đánh alone hits enemies on either side (auto-face, including the from-left spear in encounter 2). Encounter 1 cleared ≈13.6 s after the first attack; encounter 2 ≈17.5 s (≈45 s for both, walking included). No turning mid-swing seen (not frame-checked) | **PASS** | g2_enc1_hero-stops-at-enemy.png, g2_enc1_cleared_t13.6s.png, g2_enc2_start_no-pinning.png, g2_enc2_enemy-from-left_hero-between.png, g2_enc2_cleared_t17.5s.png, g2_reached-flag_ending.png |
| 6 | **Dialogue beat** (beat 2) | `-startScreen play -beat 2`, VI and EN; full run too | 9 lines; "Xin vào!" twice from line 2; asks; Tiếp; debounce; text fits; pause/resume | 9 lines in order (narrator / guard / hero / king, with portraits and moods). "Xin vào!" / "Let me in!" on lines 2 and 3 (hand hint on the first). A double tap on "Xin vào!" advanced **one** line. All lines fit in VI and EN. Pause at line 4 → resume returns to line 4. Ends with medal 2 and the walk-on. Note: the beat **title draws over the hero's head** (EN "Asking to see the king" overlaps it clearly; VI "Xin gặp vua" touches it) | **PASS**, title overlap noted (N1) | n2_*.png, n2_en_*.png |

## Regression (one full run from a fresh install, VI)

| # | Case | Actual | Result | File |
|---|---|---|---|---|
| R1 | Skip warning on first play; Keep reading → same box | Warning (Keep reading default) → same box | **PASS** | reg1_skip-warning-first-play.png, reg2_keep-reading_same-box.png |
| R2 | Double tap on intro Tiếp | One box advanced | **PASS** | reg3_intro-double-tap_one-advance_box3.png |
| R3 | Full mission: intro (4 boxes), walk, dialogue, hold-meter, training, reach-the-flag, ending, quiz 0 retries | Played through; 5 medals; 3★ | **PASS** | reg4_results_full-read.png |
| R4 | Medal gold only for a full read; no warning once earned | Gold "Nhận được huy hiệu!"; `medal = true`; then Skip on a new run → no warning, medal kept | **PASS** | reg4_results_full-read.png, reg8_medal-earned_skip-no-warning.png |
| R5 | Save after a kill on results | completed / stars 3 / medal kept after terminate + relaunch | **PASS** | reg5_relaunch-after-kill-on-results.png |
| R6 | EN persistence | Tap EN, kill, relaunch → EN title; `lang = en` | **PASS** | reg6_relaunch_EN-kept.png |
| R7 | Dynamic Island, both landscape directions | 16:9 game with side bars in both directions (rotated 180° in Device Hub) | **PASS** | reg7_frame_island-A.png, reg7_frame_island-B.png, reg7_device_island-B.png |
| R8 | Title fits between the emblems (r2 R2-01) | "Dải Đất Anh Hùng" now fits | **PASS (R2-01 fixed)** | r205_first-title-frame_t5.9-6.5s.png |
| R9 | Themes sky gradient | River/village: light blue gradient, fine. **Camp: dark navy sky with dark brown goal text = low contrast** | **FAIL (iOS-R3-05)** | n3_camp-theme_goal-text-low-contrast.png |
| R10 | Text sizes (005h) | Larger text everywhere, but it **collides**: quiz question line 2 behind the cards (Q2, Q4), intro line 2 on Tiếp, card 1 title over the emblems, and "!" / "Ối!" over the HUD goal line | **FAIL (iOS-R3-02/03/04)** | bug_q2_*, bug_q4_*, bug_intro-box4_*, bug_card1-title-overlaps-emblems.png, n1_*, g2_enc1_windup_mark-over-goal-text.png |

## Bugs (bug-report format)

### iOS-R2-03 (reopened): A pad stays held after release when the touch reported moves
- **Severity:** High (S2). **Priority:** P1. **Build:** 9b0470a. **Platform:** iOS 27.0 Simulator (iPhone 18 Pro).
- **Steps:** training; hold ◀, ▶ or Cờ for ~1 s while the pointer reports move events (in place, or sliding off the pad), then release.
- **Expected:** released within a frame.
- **Actual:** stuck in about 1 of 3 tries per pad: ▶ keeps the hero walking (still at 0.85 s); ◀ and Cờ stay lit. Sliding
  from ◀ onto ▶ and releasing leaves ▶ stuck. Holds with no move events never stick (0/12). Probably the moved touch's
  end isn't matched to the pad it currently owns (ownership changes on move?), or a touch that moves onto another pad
  starts a second, never-ended hold.
- **Evidence:** r203_*.png (6 files).

### iOS-R3-02: Quiz question line 2 is hidden behind the answer cards (new text size)
- **Severity:** Medium (S3), the child can't read the whole question. **Priority:** P2.
- **Steps:** quiz Q2 ("Vì sao Quốc Toản … ở Bình Than?") and Q4 ("… thêu mấy chữ vàng?"), VI.
- **Actual:** the second line ("Bình Than?", "vàng?") is cut by the top of the cards.
- **Evidence:** bug_q2_question-line2-hidden-behind-cards_vi.png, bug_q4_question-line2-hidden-behind-cards_vi.png.

### iOS-R3-03: Two-line story text collides with the Tiếp button
- **Severity:** Low–Medium (S3). **Steps:** intro boxes 2 and 4 (and box 1, "Toản."). **Actual:** the second line sits on the top edge of Tiếp.
- **Evidence:** bug_intro-box2_empty-picture_text-on-tiep.png, bug_intro-box4_text-overlaps-tiep.png.

### iOS-R3-04: The card title runs into the side emblems; "!" and "Ối!" are drawn over the HUD goal line
- **Severity:** Low (S4).
- **Actual:** the part 1 card title "Khi các vương hầu họp bàn ở Bình Than" overlaps both emblems. With the larger goal
  text lower in the HUD, the partner/enemy "!" and the hero "Ối!" are drawn over the goal sentence (training and camp).
- **Evidence:** bug_card1-title-overlaps-emblems.png, n1_telegraph-mark-over-goal-text.png,
  g2_enc1_windup_mark-over-goal-text.png, g2_enc2_oi-over-goal-text.png, r203_flag-stuck_t0.85s_oi-over-goal-text.png.

### iOS-R3-05: The camp theme's dark sky makes the HUD goal text unreadable
- **Severity:** Medium (S3), readability for children. **Steps:** reach-the-flag (camp).
- **Actual:** dark brown goal text ("Đến lá cờ của quân nhà Trần!") on the dark navy camp sky.
- **Fix idea:** light text or a backing plate on dark themes.
- **Evidence:** n3_camp-theme_goal-text-low-contrast.png.

### iOS-R3-06: The intro story pictures are empty
- **Severity:** Medium (S3), a visual regression. **Steps:** fresh run, intro boxes 1–4.
- **Expected:** a picture (r2 drew the village and hero).
- **Actual:** an empty sky-gradient frame on all 4 intro boxes. The intro entries in mission.json have no picture id, so
  probably the procedural intro scene was replaced by the theme sky.
- **Evidence:** bug_intro-box1_empty-picture.png, bug_intro-box2_empty-picture_text-on-tiep.png, bug_intro-box4_text-overlaps-tiep.png.

## Notes

- N1: the dialogue beat title is drawn over the hero's head (EN especially): n2_en_l1_title-over-hero-head.png.
- N2: in training, when the hero walks back left the camera doesn't follow. The first dummy, the stuck arrow and the
  partner (with its "!") end up half off-screen at the left edge: reg_training_stuck-arrow-at-left-edge.png,
  n4_training_partner-half-offscreen-left.png.
- N3: the quiz question text uses a lighter weight than the card labels (005h?). It's still readable.
- Multi-touch, audio hearing and exact frame timings: NOT ASSESSED (Simulator, single pointer, no frame-step).
