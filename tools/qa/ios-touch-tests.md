# iOS touch tests (XCUITest) — what QC runs and what each case proves

Run: `tools/qa/ios-touch-tests.sh <frozen build folder> [output folder]` (see the script header). Real
touches on QC's own Simulator, no macOS Accessibility, nothing compiled. Each case reads the Debug-only
`debugState` element (compiled out of Release; checked byte-for-byte at each freeze).

| Case | Proves | Limits |
|---|---|---|
| `test_R2_03_press_move_release_on_each_pad_leaves_nothing_held` | R2-03: press, move, release on every pad of the blocks step → nothing held | one finger at a time |
| `test_slide_from_left_to_right_walks_right_then_releases` | Input Rule 9: ◀ → ▶ slide walks right; release holds nothing | |
| `test_holding_right_across_a_beat_change_leaves_nothing_held` | holding ▶ through the walk's end: the hold ends cleanly | |
| `test_B1_two_fast_taps_on_next_advance_one_box` | B1: two taps on Tiếp closer than 0.25 s advance one box; reports the measured UITouch.timestamp gap | **XCUITest can't place a tap at 0.15–0.25 s**: its fastest pair is ≈ 0.05 s and two separate taps are ≥ 0.3 s apart. That range is proven by the unit test `AdvanceDebounceTests` (press times injected: a 0.15 s press after a 0.30 s frame stall is dropped on all 6 advance paths; +0.25 s is accepted). A run whose gap is ≥ 0.25 s is reported SKIPPED, never PASS. |
| `test_15b_holding_right_in_training_stops_at_the_cap` | Combat 15b: ▶ 5 s → camera at the cap, hero at cap + 1060 | |
| `test_a_tap_on_the_title_card_does_nothing` | title AC4e: the card is display only (no screen change, no button fires) | |
| `test_one_landed_hit_in_slow_motion_for_contact_and_pop_screenshots` | screenshots of the AC13 contact and the "Ối!" pop (camp sky) for QC to judge | `-timeScale 0.1` slows the same fixed steps; the judgement is visual |
| `test_an_attack_mash_through_the_beat_end_keeps_the_first_ending_box` | B7 / Input Rule 13: Attack mashed through reach-the-flag's end keeps ending box 1 ≥ 0.6 s (rolling lock, cap 1.5 s) | **uses the debug shortcut `-stage flag`** (hero at the flag, encounters counted cleared), reported in its note; the rolling cap itself is proven by `EntryLockTests` |
| `test_skip_warning_keep_reading_then_stars_survive_a_relaunch` | Bỏ qua → warning → Keep reading; 5 right answers → 3★; a relaunch keeps 3★ on the title card | the quiz is reached by a debug jump, so **the medal is not asserted** (D-07 needs a fully read and played run) |

Guards: each test times out after 120 s and the whole run after `TIMEOUT` (900 s default).
