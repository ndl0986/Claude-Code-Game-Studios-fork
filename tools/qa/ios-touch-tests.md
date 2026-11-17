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
| `test_skip_warning_keep_reading_then_a_jumped_quiz_saves_nothing` | Bỏ qua → warning → Keep reading; 5 right answers → 3★; **r9: a debug-jumped run saves nothing**, so the relaunched title shows 0★ and no medal | the quiz is reached by a debug jump; a real run's save is `test_D` |

| `test_left_taps_as_the_training_card_appears_open_no_skip_warning` | Android QC r6: ◀ tapped as the training card appears (Bỏ qua sits on ◀'s spot) opens no skip warning: the entry lock drops the taps | debug start `-stage walkto`; SKIPPED "not exercised" if the first tap lands after the lock |

| `R8CasesUITests` (4 cases) | Input Rule 13b: a mash through the intro and the dialogue holds every box/line ≥ 1.5 s; pause and sound respond inside the lock; story screens show the placeholder, no sprites, no top stack | |
| `R9CasesUITests.test_the_finish_hold_lasts_and_drops_taps`, `test_a_resume_restarts_the_hold_to_rise_done` | mission-flow 7c / AC32: the banner moment holds 1.5 s and drops taps; a resume restarts it to "rise done", then the full 0.833 s banner-up (r10 N1: asserts ≥ 0.828 s after the press; expect 0.833–0.850 plus log jitter) | debug start `-stage finish` |
| `R9CasesUITests.test_A_quiz_fade_and_glide_stay_inside_720` | quiz §5.2 (small layout): a real right pick fades the wrong cards and glides the right card to the left slot; the app samples **every frame** of the motion: ≥ 5 glide positions and every quiz pixel ≤ 720 (note: max bottom, positions) | the quiz is reached by a debug jump (the pick is real); skips a question whose right card is already in the left slot |
| `R9CasesUITests.test_A_quiz_fade_and_glide_in_slow_motion_for_screenshots` | the same at ×0.1: three screenshots mid-animation (fading, gliding, end) for a visual check | visual judgement |
| `R9CasesUITests.test_B_two_quick_next_taps_advance_one_question_and_pick_nothing` | Input Rule 13b / quiz §5.2: a double tap on Tiếp (aimed at the band where Tiếp overlaps the next question's third card) advances one question; no card picked, none marked wrong; the second touch-down is in the app's touch log | **The per-question lock itself can't be reached by XCUITest here**: the overlap band is ≈ 1.4 world px tall on an 18 Pro, and the second touch-down comes in the same event batch as the first release, so it lands on the old Tiếp (gone at its release: nothing fires). The lock is proven by GameCore `EveryBoxLockTests`; the note says "lock reached: true/false" |
| `R9CasesUITests.test_C_a_tap_just_before_the_lock_end_drops_and_just_after_advances` | Input Rule 13, the deliberate tap: on an intro box a tap ≈ 0.1 s before the rolling lock's end is dropped and one ≈ 0.1 s after it advances; every press is checked against the rule (0.6 s, cap 1.5 s) replayed on the logged times | SKIPPED "not exercised" unless one press is within 0.2 s before and one within 0.25 s after the end (up to 4 launches) |
| `R9CasesUITests.test_D_a_mashed_real_run_keeps_the_medal_and_saves_it` | D-07 / D-16: a **real run from Start on a fresh install, no debug jumps**: every story box, card, caption, dialogue line and ask tapped every ≈ 0.35 s, the quiz answered by real taps → medal earned, 3★, no skip warning; a relaunch shows 3★ + medal | `-autoplay` (debug only) plays the play beats (walk, fights, training) with the GameCore bot; it never presses a story or quiz button |
| `R9CasesUITests.test_r9_screens_banner_partner_and_hand` | screenshots: the Cờ hint hand, the banner rise frames (×0.1), the partner's placements (front spot; left edge facing left, beyond the banner; right side; after a resume) | visual judgement |

Cases live in four classes: `TouchCasesUITests` (r6), `MoreCasesUITests` (r7), `R8CasesUITests` and `R9CasesUITests`.

Saves: since r9 a run started by a debug jump (`-startScreen …`) writes no progress after the jump: no stars, medal or
completed, and no new seen_open. Every launch still marks the first hero seen_open when the title loads, before any
jump (Save Rule 5; the first hero is always open). VI|EN is saved as usual. A Simulator that ran the suite is no longer left at 3★ + medal by the skip-warning case; `test_D` does
leave 3★ + medal (a real run), so reset the app's data before checking a fresh-install title.

Guards: each test times out after 420 s and the whole run after `TIMEOUT` (5400 s default). The ~300 s XCTest teardown
seen on 2026-11-15 is gone (2026-11-16: the full 27-case run takes ≈ 10 min; cases 6–105 s).
