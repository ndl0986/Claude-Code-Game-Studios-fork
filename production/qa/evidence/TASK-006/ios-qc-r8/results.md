# TASK-006 iOS QC r8 — c388736

## **r8 QC result: PASS on everything assessed; 5 items NOT ASSESSED (no touch path); 1 open question**

(Earlier status lines kept below for the history: the 11-15 pause, then the 11-16 re-run.)

History: the 2026-11-15 run was paused during B1 and its result bundle was lost (commit eab7678). On 2026-11-16
the full suite was re-run from the start (09:21–09:37, uninstall + install, re-hashed). That run's bundle is kept
locally at `touch/result.xcresult` and is not committed. Its summary.json, tests.json, xcodebuild.log, and
attachments/ are committed. The work paused again for the team restart (leader, Luan's request).

## Build and fingerprints (re-hashed by QC, match the leader's)

- Build: `game-dev-001/production/qa/builds/TASK-006-ios-c388736/`
- App executable sha256 `55913c2933ab3e01d9c0208659d00c8c89c935e381cc2b1120237edb69e90e35` (same as the
  installed copy on E9F515E9 after uninstall + install)
- `ios-touch-tests.sh` sha256 `18c3c0b3d6202980a9f2c3fa68e581e6e538ee5febd51985fd21cd0474c51758` (unchanged since r7)
- .app tree (sorted file sha256s, hashed) `752834f43b3a24928f421b0156caaa312f93b4d79727e034e400661da3bd23c9`

## UI touch suite: re-run 2026-11-16, iPhone 18 Pro E9F515E9, 14 UI cases: 13 passed, 1 failed (iOS-R8-01: a flake, 3/3 on re-run)

| Case | Result | Duration | Evidence |
|---|---|---|---|
| MoreCases title card tap does nothing | passed | 9.4 s | |
| MoreCases B7 attack mash keeps ending box 1 | passed | 12.5 s | log: ending box 1 at 05.835 → quiz at 07.384 = **1.55 s** (≥ 1.5); four Next presses inside it dropped |
| MoreCases **◀ taps as the training card appears → no skip warning** | **FAILED** | 25.6 s | log: beatCard @ 52318.951, **fire:skip @ 52319.509 (+0.558 s)**, fire:skip @ +1.293 s; `XCTAssertEqual failed: ("Optional(true)") is not equal to ("Optional(false)") - no skip warning opened under the taps (attempt 1)` |
| MoreCases slow-motion hit (AC13 contact, pops) | passed | 53.5 s | day village sky "Oof!" has an **ink** outline (visual PASS); camp sky shot attached |
| MoreCases skip warning → Keep reading → 3★ survives relaunch | passed | 31.9 s | medal not asserted (debug jump, D-07) |
| R8 dialogue mash holds every line | passed | 20.3 s | e.g. line 1 → 2: 28.884 → 30.401 = 1.52 s; 2 → 3: 1.87 s |
| R8 intro mash holds every box | passed | 11.9 s | boxes 1.88 / 1.88 / ≥ 1.85 s |
| R8 pause and sound respond inside the lock | passed | 19.6 s | attempt 2: mute "locked 1", pause "locked 1" responded |
| R8 story screens: placeholder, no sprites, no top stack | passed | 65.1 s | 6 shots |
| 15b hold ▶ stops at the cap | passed | 10.1 s | cap 4520, cam 4520, hero_x 5580 |
| B1 two fast taps advance one box | passed | 6.8 s | gap 0.049 s; advanced true / false (0.15–0.25 s rests on AdvanceDebounceTests) |
| ▶ held across a beat change | passed | 18.2 s | |
| R2-03 press-move-release on each pad | passed | 10.7 s | |
| ◀ → ▶ slide | passed | 8.1 s | |

**Teardown check: the ~300 s "Checking for reports…" teardown is gone.** Cases take 6.8–65 s (2026-11-15: 309–367 s).
The whole run took 914 s (summary start→finish), down from about 80 min. This is after DiagnosticReports was cleared and
the Mac restarted. The folder now holds 5 reports.

### iOS-R8-01: NOT A BUG (test flake), leader accepted 2026-11-16

The case PASSED 3/3 when re-run alone (`touch-r801-1..3/`; load 8.2 at the start). Press times are relative to the log's beatCard entry,
which stands in for entered_at (same step). The test doesn't export entered_at or fires[], so "locked" is inferred from
`Flow.entryLocked` and from the test's own gate, which asserts only when the first skip press was locked:

| Run | beatCard @ | skip presses (s after the card) | Result |
|---|---|---|---|
| 11-16 suite | 52318.951 | +0.558 (locked: rolls the lock to ≈ +1.158), +1.293 (**after the lock**: a real press, so the warning correctly opened) | failed |
| re-run 1 | 95567.234 | +0.424, +0.819, +1.231 (each inside the rolling window, cap 1.5) | passed |
| re-run 2 | 95586.051 | +0.416, +0.784, +1.156 | passed |
| re-run 3 | 95600.251 | +0.427, +0.810, +1.193 | passed |

Cause: an XCUITest tap gap of 0.735 s (> 0.6) under host load let a post-lock tap reach Bỏ qua. The lock behaved as written.
For game-dev-ios r9: stop tapping when the next tap would land after lockUntil, and export entered_at + fires[] in the note.

#### Original draft (superseded)

- **Severity**: S2 (a child tapping ◀ as the card appears lands in the skip warning; this is the Android QC r6 case)
- **Build**: c388736, iPhone 18 Pro Sim iOS 27.0
- **Steps**: harness `MoreCasesUITests/test_left_taps_as_the_training_card_appears_open_no_skip_warning`
  (`-stage walkto`, taps on ◀'s spot, where Bỏ qua sits on the card)
- **Expected**: the entry lock drops the taps; no skip warning (Input Rule 13 / 13b)
- **Actual**: the first tap, 0.558 s after the card appeared (inside the 0.6 s lock), **fired skip**, and the skip warning opened
- **Note**: in r7 the first tap came at +0.695 s (outside the lock), so the case was skipped. On the paused 2026-11-15 run it
  passed, but that bundle was lost and its log can't be checked. Possible flake: re-run with ONLY= a few times to see if it repeats.

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

Done on 2026-11-16 from the suite: B1, R2-03, ◀→▶ slide, ▶ across a beat change (all PASS); the day-sky ink pop
(PASS, visual, from the slow-motion attachment); the mash holds ≥ 1.5 s and pause/sound inside the lock (PASS, from the logs).

## 18 Pro checks, 2026-11-16 evening (k ≈ 0.529 measured: 1 world ≈ 1.588 px; load per item)

| # | Check | Result | Load (1-min) | Evidence |
|---|---|---|---|---|
| 4 | Small quiz layout on the 18 Pro: cards on one row while choosing; after the right pick the right card is in the left slot with the why line beside it; Tiếp spans ≈ 811–1266 world (spec 812–1262, 450), bottom ≈ 707 | PASS | 70→17 (layout only) | p1–p8 |
| 4 | Every pixel ≤ 720 (static end states: Tiếp bottom ≈ 707, cards ≈ 577) | PASS (static); motion NOT ASSESSED | | p* |
| 4 | Pill: ink #23170D on #4BAF5F (6.33:1), unclipped, VI "Đúng rồi!" / EN "That's right!" | PASS | | p2, p6 |
| 4 | Wrong card: "Thử lại nhé!" under a dimmed card (static) | PASS (static) | | p7 |
| 4 | Fade / glide animation | **NOT ASSESSED**: `-stage right` jumps to the end state (screen recording v01 showed no glide); needs a real pick | 6.6 | |
| 4 | Per-question lock (two quick Tiếp taps don't pick a card) | **NOT ASSESSED**: no touch path (below) | | |
| 1 | Deliberate tap 0.6 s after the last press goes through | **NOT ASSESSED** on device. Logs show only that the post-cap press goes through (each box advanced on the press ≥ 1.5 s in). GameCore EveryBoxLockTests covers 0.6 s | | |
| 7 | Medal under mash in a real run | **NOT ASSESSED** on device (GameCore FullRunMashTests only) | | |
| 8 | D-27 title VI/EN, intro/ending without the R6-01 bar, 2-line prompts clear of sound (R6-02), results 3★ + medal, beat card | PASS | ~7 | r01–r06 |
| 8 | 3★ + medal survive a relaunch (seeded with defaults write, then relaunched) | PASS | | r07 |

**Why there's no touch:** Device Hub's accessibility window is blocked (`orca computer click`: "AX reads stayed blocked … toggle Orca
Computer Use off and on"), and CGEvents posted to the Device Hub process don't reach the Simulator. Fixing it needs Luan to toggle
Accessibility; QC doesn't change permissions. Better for r9: XCUITest cases for the per-question double tap, a deliberate 0.6 s tap, a real
pick (fade/glide frames), and a full-run medal under mash.

**Open question (not filed as a bug):** before I seeded anything, the title already showed 3★ **and the medal** (r01/r02). That was after the
11-16 harness run on a fresh install. The skip-warning case reaches the quiz by debug jump and its note says the medal isn't asserted (D-07).
So either a harness case earned the medal by a real-enough run, or a debug path awards it. Worth a quick look by game-dev-ios. I didn't dump
the saves before seeding, so this rests on the screenshot.

Helpers: `production/qa/tools/ios/` (q8.sh, scan, hist2, sheet, frames, taps; README).
