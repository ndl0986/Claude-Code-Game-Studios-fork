# TASK-006 iOS QC r8 — c388736

## **r8 QC INCOMPLETE (paused)**

The project was paused (Luan, relayed by the leader) while the touch suite was running. The xcodebuild run was
interrupted (SIGINT, then SIGTERM, exit 143) during `test_B1_two_fast_taps_on_next_advance_one_box`. The
result bundle was never finalised, so there is no summary.json, tests.json or attachments; per-case results below
come from `touch/xcodebuild.log`. Both Simulators are shut down. **No verdict for r8.** On resume the suite is
re-run from the start.

## Build and fingerprints (re-hashed by QC, match the leader's)

- Build: `game-dev-001/production/qa/builds/TASK-006-ios-c388736/`
- App executable sha256 `55913c2933ab3e01d9c0208659d00c8c89c935e381cc2b1120237edb69e90e35` (same as the
  installed copy on E9F515E9 after uninstall + install)
- `ios-touch-tests.sh` sha256 `18c3c0b3d6202980a9f2c3fa68e581e6e538ee5febd51985fd21cd0474c51758` (unchanged since r7)
- .app tree (sorted file sha256s, hashed) `752834f43b3a24928f421b0156caaa312f93b4d79727e034e400661da3bd23c9`

## UI touch suite (iPhone 18 Pro E9F515E9, 14 UI cases)

| Case | Result | Duration |
|---|---|---|
| MoreCases `test_a_tap_on_the_title_card_does_nothing` | passed | 313.7 s |
| MoreCases `test_an_attack_mash_through_the_beat_end_keeps_the_first_ending_box` | passed | 314.1 s |
| MoreCases `test_left_taps_as_the_training_card_appears_open_no_skip_warning` | passed (not skipped this time) | 309.0 s |
| MoreCases `test_one_landed_hit_in_slow_motion_for_contact_and_pop_screenshots` | passed | 339.9 s |
| MoreCases `test_skip_warning_keep_reading_then_stars_survive_a_relaunch` | passed | 332.1 s |
| R8Cases `test_a_mash_through_the_dialogue_holds_every_line` | passed | 321.4 s |
| R8Cases `test_a_mash_through_the_intro_holds_every_box` | passed | 312.8 s |
| R8Cases `test_pause_and_sound_respond_inside_the_lock` | passed | 309.8 s |
| R8Cases `test_story_screens_show_the_placeholder_and_no_sprites_or_top_stack` | passed | 366.8 s |
| TouchCases `test_15b_holding_right_in_training_stops_at_the_cap` | passed | 311.1 s |
| TouchCases `test_B1_two_fast_taps_on_next_advance_one_box` | **interrupted** (paused) | — |
| TouchCases `test_R2_03_press_move_release_on_each_pad_leaves_nothing_held` | not run | — |
| TouchCases `test_slide_from_left_to_right_walks_right_then_releases` | not run | — |
| TouchCases `test_holding_right_across_a_beat_change_leaves_nothing_held` | not run | — |

Not inspected because the bundle was lost: the cases' attachments (B7 press log, ◀ press log "locked", slow-motion
contact/pop frames, mash hold times). A pass here is the test's own assertion only.

Teardown note (DiagnosticReports cleared ~06:21): only 15b finished after the cleanup and it straddled it
(311 s, no change). Inconclusive; check the per-case durations on the re-run.

## Manual checks on the iPhone 17e (9312E6A1, k ≈ 0.515 measured: 1 world = 1.545 px)

Shots in this folder (`e*.png`, full-res 2532×1170). Done:

| # | Check | Result |
|---|---|---|
| 2 | Story screens: no play sprites/flag/dots/goal/banner, pause/sound corner only (intro, beat card, caption, dialogue, ask) | PASS (e03–e09, e07-caption-sample-*) |
| 2 | Placeholder size: intro 45–298 world (256 ✓), beat card 25–233 (208 ✓), caption (sample hero, grey stand-in) 45–300 (256 ✓) | PASS |
| 2 | "Phần n"/"Part n" gold + ink, ≈ 27 world tall (28 ✓), on cards/captions only (not on intro/dialogue) | PASS |
| 2 | Dialogue background dimmed; ask line with portrait | PASS (visual; dim % not sampled) |
| 2 | Ending = full-bleed scene_tqt_ending, VI/EN | PASS (e10/e11). Art note (as dev said): the flag pole top sits under the pause/sound corner |
| 3 | Corner block: nothing overlaps it on title, story panels, dialogue box, banner start | PASS (visual; 18 + P offset not measured) |
| 5 | Stuck arrow gold + ink: dummy (e12-15s), flag (e14-15s); "!" beside enemy head away from hero (e13-t1). Motto bar bottom ≈ 269 world; arrow top ≈ 377, "!" top ≈ 296, flag pole top ≈ 290 (spec 290); cloth ≈ 89 world wide (92) — all below the bar, flag not over the motto | PASS |
| 6 | Cream "Ối!" outline on camp night sky (e13-t2) | PASS (visual) |
| 4 | Quiz small layout on the 17e: Tiếp ≈ 447 wide at x ≈ 813 (spec 450 at 812), right card left slot + why line beside it, VI/EN (e20–e22) | PASS (17e only) |

Not done (paused):

- 4 on the **iPhone 18 Pro (k 0.517)**: small layout, wrong cards fade / right card glide, every animated
  pixel ≤ 720, pill ink and clip, per-question lock (two quick Tiếp taps).
- 6 ink pop outline on the **day village sky** (the slow-motion case's frame was lost with the bundle).
- 7 medal under mash in a real run; reading the ◀ and pause/sound press logs.
- 8 regression (D-27 title, safe-rect fit, R6-01/02, skip warning → Keep reading, 3★ + medal after relaunch) beyond
  what the passed cases cover.
- 1 deliberate tap 0.6 s after the last press, checked by hand / log.
