# TASK-006 iOS QC, round 5 (part 1: non-touch; touch NOT ASSESSED)

- **Build:** frozen `feat/TASK-006-ios-native` @ `1a8c443`. Fingerprint run from the game-dev-001 root =
  `02fb413a…01774a0` (**matches**); my copy matches it file by file. 0602974 was uninstalled first. Not rebuilt.
- **Device:** iPhone 18 Pro Simulator iOS 27.0, `E9F515E9-58F2-4A92-ABEF-C5CD59CE8183`. **Branch:** `qa/TASK-006-ios-r5` from `e8ccfc6`.
- **r4:** closed as "non-touch PASS, touch NOT ASSESSED (Accessibility)" (97574d8, pushed by the leader).
- **Touch:** macOS Accessibility worked for one read, then blocked again. That read showed Device Hub now displays the
  18 Pro **in portrait** (the app is rotated inside it) and lists a second device "iPhone 18 Pro – dev…". I stopped
  posting blind clicks. **Touch items 1–4 (R2-03, B1, 15b, full regression): NOT ASSESSED (Accessibility).** They move to
  the r6 XCUITest harness, per the leader.
- **Method here:** debug jumps (`-startScreen`, `-beat`, `-stage`, `-lang`) + `simctl io screenshot`, VI and EN.

**Overall part 1: FAIL. 1 bug (EN banner overflow), 2 low notes.** Everything else in items 5–9 passes.

| # | Check (spec) | Steps | Expected | Actual | Result | File |
|---|---|---|---|---|---|---|
| 5a | Goal plate in the same place on every beat (hud §3.3) | walk, hold, training ×3, reach, encounter | Same position | Cream goal plate at the same top-centre spot on walk, hold-meter, training (all stages) and reach-the-flag; dialogue has none | **PASS** | v_walk_*, v_hold_*, v_train-*, v_reach_* |
| 5b | Banner bar in the sky, 1 line VI / 2 EN, covers no body at the closest encounter | training + reach, VI/EN; encounter series | Bar fits its text; no body under it | VI: 1 line, fits. **EN: 2 lines, but line 2 ("kindness") overflows the bar's bottom edge** (the text crosses the border). No body under the bar in any encounter frame: the enemy helmet stays below it; only the hero's spear shaft reaches into it | **FAIL: iOS-R5-01** (EN overflow); body clearance PASS | v_train-finish_en.png, v_reach-encounter_en.png, v_encounter-series_en_*.png |
| 5c | Nothing overlaps pause/sound | all screens | Clear | Clear on every play screen | **PASS** | v_* |
| 5d | Telegraph "!" draws over the bar | encounter series | Over the bar | "!" drawn on top of the bar (covers part of "kindness" in EN) | **PASS** | v_encounter-series_en_4.png, _6.png |
| 5e | Hint arrows just above the target | encounter series | Just above the head | Stuck arrow just above the enemy helmet | **PASS** | v_encounter-series_en_5.png, _8.png |
| 6 | Fighters at spec height; spear tip reaches the hero; pops beside the head | encounter series, training blocks | As named | Smaller fighters; the spear tip touches the hero's body in windup/strike; "Oof!"/"Ối!" beside the head (left). Note: "Oof!" is dark red on the navy camp sky, low contrast | **PASS** (note N1) | v_encounter-series_en_4.png, v_train-blocks_vi.png |
| 7 | W12 training pads per step | `-beat 4` (dummies), `-stage blocks`, `-stage finish` | Dummies ◀▶+Đánh; blocks +Đỡ; finish +Cờ | Dummies: ◀▶ + Đánh ✔. Blocks: ◀▶ + Đỡ + Đánh ✔. `-stage finish` shows the dummies layout (◀▶ + Đánh, no Cờ), so it looks like that jump isn't supported. The finish step needs play | Dummies/blocks **PASS**; finish NOT ASSESSED (no jump) | v_train-dummies_*, v_train-blocks_*, v_train-finish_* |
| 8 | W7: pause + sound top-left on story, quiz, results, unlock; sound only on the title | title, intro, card, ending, quiz, results, unlock | As named | Title: sound only ✔. Intro, card, ending, quiz, results, unlock: pause + sound top-left ✔. Note: on intro and ending the sound button **overlaps the picture frame's top-left corner** | **PASS** (note N2) | v_title_*, v_intro_*, v_card_*, v_ending_*, v_quiz_*, v_results_*, v_unlock_* |
| 9 | Unlock: two different heroes (N2); title clear of sound | `-startScreen unlock` | Two names | VI: "Trần Quốc Toản" → "**⟨placeholder⟩ Anh hùng**"; EN: "Trần Quốc Toản" → "Hero". Different ✔, but VI shows the raw "(placeholder)" text (no 2nd hero in data yet). Title clear of sound ✔ | **PASS** (note N3) | v_unlock_vi.png, v_unlock_en.png |
| R2-05 | Launch | (r4 timing; not re-timed) | — | Title drawn on launch, no grey seen in captures | PASS (spot) | v_title_vi.png |

## Bug

### iOS-R5-01: The English banner bar is too short for its 2-line text
- **Severity:** Low–Medium (S3). **Priority:** P2. **Build:** 1a8c443.
- **Steps:** training or reach-the-flag with EN (`-startScreen play -beat 4 -lang en`, `-beat 5`).
- **Expected:** "Defeat the strong enemy, repay the king's / kindness" inside the bar (hud §3.3: 2 lines EN).
- **Actual:** the second line sits on and below the bar's bottom border, so the bar doesn't grow to 2 lines.
- **Evidence:** v_train-finish_en.png, v_reach-encounter_en.png, v_encounter-series_en_2.png.

## Notes
- N1: "Oof!" / "Ối!" is drawn dark red, so it's low contrast on the navy camp sky (v_encounter-series_en_5.png).
- N2: on intro and ending, the top-left sound button overlaps the picture frame's corner (v_intro_*, v_ending_*).
- N3: the unlock screen's second hero name is the raw placeholder in VI ("⟨placeholder⟩ Anh hùng"); EN shows "Hero".
- N4: the Duo runtime (iOS 27.1) is gone; the 18 Pro shows portrait in Device Hub since the simulator drop.

## Touch (NOT ASSESSED in r5, Accessibility): to run with the r6 XCUITest harness
R2-03 per pad (30+), the ◀→▶ slide, a hold ▶ across a beat change, B1 on intro/card/dialogue/ask/ending with the
measured gap, 15b (hold ▶ 3–8 s at the training start), the full regression run.
