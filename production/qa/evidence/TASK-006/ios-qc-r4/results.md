# TASK-006 iOS QC, round 4 (part 1: non-touch; touch blocked)

- **Build:** frozen `feat/TASK-006-ios-native` @ `0602974`. Fingerprint run from the game-dev-001 root:
  `c7f62c3ee1962fe6fadb2892ecaa971a8dc40385429232e74ff76c6b88fe7659` (**matches**); my scratch copy matches it file by file.
  9b0470a was uninstalled first. Not rebuilt.
- **Device:** iPhone 18 Pro Simulator, iOS 27.0, `E9F515E9-58F2-4A92-ABEF-C5CD59CE8183`, booted by UDID after the CoreSimulator drop.
- **r3 saved state after the drop:** **survived**: completed, medal, stars 3, lang en, seen_open (r3-saved-state-after-sim-drop.txt).
- **Side effect of the drop:** the iPhone Duo is now "unavailable, runtime profile not found", so the iOS 27.1 runtime is gone.
- **Branch:** `qa/TASK-006-ios-r4` from `03f37bf`.
- **Blocker:** macOS Accessibility reads blocked again (Orca); my posted events don't land; Device Hub can't be re-mapped
  without AX or Screen Recording. Touch cases wait for Luan's toggle.

**Overall so far: NOT ASSESSED (touch blocked).** Every non-touch check passes; 2 notes.

| # | Check | Steps | Expected | Actual | Result | File |
|---|---|---|---|---|---|---|
| R2-05 | Fresh-install launch | Uninstall, install, launch; 24 captures | No grey; time to first non-grey frame | Launch colour 0–3.4 s, **title in the 3.4–3.9 s capture**, 0 grey frames | **PASS** (≤3.9 s) | r205_launch-timing.txt, r205_launch-colour_t0-0.6s.png, r205_first-title-frame_t3.4-3.9s.png |
| T1 | Title: map stub, no legend | Launch | Stub, no legend | "(Bản đồ sắp ra mắt)" plate in place of the controls legend | **PASS** | v_title-mapstub_vi.png |
| R3-06 | Intro pictures drawn | `-startScreen intro` | Picture | Village + hero picture drawn | **PASS** | v_intro_vi.png, v_intro_en.png |
| R3-03 | Intro text clear of Tiếp | Intro box 1, VI/EN | Gap above Tiếp | Two lines end above Tiếp with a gap | **PASS** (box 1; boxes 2–4 need taps) | v_intro_*.png |
| R3-04a | Card title, no emblems | `-beat 1 -stage card` | No emblems; title fits | No emblems; "Phần 1" + title + body fit (EN body wraps to 2 lines) | **PASS** | v_card-walk_*.png |
| R3-05 | Goal plate readable on camp | `-beat 5 -stage encounter` | Readable | The goal sits on a cream plate, dark text: readable on the navy camp sky (VI and EN) | **PASS** | v_reach-encounter_vi.png, v_telegraph_*.png |
| R3-04b | Pops below the goal line | Training blocks | "Ối!" not over the goal | Goal plate is at the top; "Ối!" is below it, but **drawn on the hero's own head/headband** in this capture | **PASS** (note N1) | v_training-blocks_vi.png |
| R3-02 | Quiz prompt line 2 visible | `-startScreen quiz -q 2` / `-q 4`, VI/EN | Fully visible | "Bình Than?", "vàng?", EN line 2 all visible above the cards | **PASS** | v_quiz2_*.png, v_quiz4_*.png |
| N-dlg | Dialogue title inside the panel | `-beat 2`, `-stage ask` | Inside the panel | "Xin gặp vua" / "Asking to see the king" inside the panel top; ask "Xin vào!" / "Let me in!" | **PASS** | v_dialogue_*.png, v_dialogue-ask_*.png |
| Q-right | Right card style | `-q 3 -stage right` | Pale green fill, green border, ink-outlined tick, ink label | Fill #E0F3D9, green border, green tick with dark outline, dark label | **PASS** | v_quiz-right_*.png |
| Q-wrong | Wrong card style | `-q 3 -stage wrong` | #E6E1F0 fill, lavender border, arrow | Fill sampled **#EBE7F3** (≈ spec; the dimmed picture tile is separate), border #ACA2C5, circular arrow; no red | **PASS** (fill within a few units of #E6E1F0) | v_quiz-wrong_*.png |
| U1 | Unlock: single "Về bản đồ" | `-startScreen unlock` | One button | One "Về bản đồ" / "To the map" button + "(Bản đồ sắp ra mắt)" | **PASS** (note N2) | v_unlock_*.png |
| — | Skip warning, results, ending | Jumps | As before | Unchanged from r3, OK | PASS | v_skipwarn_*, v_results_*, v_ending_* |

## Notes
- N1: in training, "Ối!" now sits on the hero's head (over the headband/face) rather than above it.
- N2: the unlock debug jump labels **both** medallions "Trần Quốc Toản" (the locked one with "?"). Probably the debug jump
  has no next hero to name; worth checking with real data that the second name is the next hero.

## Waiting for touch (part 2)
R2-03 stuck pads (30+ per pad, ◀→▶ slide, hold ▶ across a beat change), B1 double tap on every advance type (also under
load), R3-03 on intro boxes 2–4, the second-finger rule (will be NOT ASSESSED), the full regression run (skip flow,
medal, stars, save after a kill, EN, Dynamic Island, R2-04/06, G2).
