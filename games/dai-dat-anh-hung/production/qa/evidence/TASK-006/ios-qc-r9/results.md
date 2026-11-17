# TASK-006 iOS QC r9 — 9c12a4a (docs 0f90158)

## **r9 QC result: PASS on everything assessed; 3 items NOT ASSESSED; 2 notes for game-dev-ios (not bugs)**

Device: QC iPhone 18 Pro Sim, iOS 27.0, E9F515E9 (k ≈ 0.529). Run on 2026-11-16, 22:43–23:20. Device Hub touch is still
blocked ("AX reads stayed blocked", 22:47), so everything touch-driven comes from the harness.

## Build and fingerprints (re-hashed by QC, match the leader's)

- Frozen folder: `game-dev-001/production/qa/builds/TASK-006-ios-9c12a4a/`
- `DaiDatAnhHung` sha256 `d97a93024b9eacf0e37baf2f4fdf0df986597e1194300e06fe94680a2211fae2`. The installed copy on
  E9F515E9 matches after uninstall + install. Debug-iphonesimulator/ has the same bytes.
- `DaiDatAnhHung.debug.dylib` `4cc2e6a066fca952cd495a2061e5552a86ec7b5a8e9413373e92cd22a942a30c`
- `ios-touch-tests.sh` `18c3c0b3…1758` (unchanged since r7). .app tree `f1c8a906…6557` (sorted file sha256s, hashed)

## 1. Full UI suite: 22/22 passed, 0 skipped (`touch/`)

The whole run took 524 s. **Load:** 90 at the start (Android emulator + Sim boot), 7 at the end. So the timing cases
were re-run alone afterwards, at loads of 7–11 (`timing/`, `timing/load.txt`). They passed again. Those runs are the
ones that count.

| Case | Suite | Alone (load) | Evidence (note) |
|---|---|---|---|
| **A** fade/glide ≤ 720 | passed | (not timing) | 29 moving frames, 18 glide positions x 860 → 86 at y 278, **max bottom 575.7 ≤ 720** |
| **A** slow-motion shots | passed | | 299 frames, 180 positions, same max bottom; fading / gliding / end shots look right |
| **B** two quick Tiếp taps | passed | | index 0 → 1, picked 0, wrong 0. **Lock reached: false**: the second touch-down landed on the old Tiếp (+0.000 s), as the case's documented limit says. The per-question lock is proven only by GameCore `EveryBoxLockTests` |
| **C** deliberate tap | passed | passed (7.8) | +0.351 locked (end +0.600), +0.849 locked (end +0.951), **+1.547 advanced** (end +1.449, 0.098 s after); every press matches the rule |
| **D** mashed real run | passed | passed (6.7→10.5) | median press gap **0.398 s** (min 0.378) < 0.6; 133 taps; skip warning 0; debug_jumped 0; results medal + 3★; relaunch title 3★ + medal |
| 7c finish hold | passed | passed (7.5) | beatEnd → walkTo **1.517 s** (suite 1.516) ≥ 1.5 |
| 7c resume restarts the hold | passed | passed (7.8) | pause +0.731 s into the hold (after the rise); resume → walkTo **0.800 s** (suite 0.800). See note N1 |
| iOS-R8-01 ◀ as the card appears | passed | passed (10.5) | skip presses +467 / +860 / +1233 ms, all locked 1; no warning. entered_at and lock_until are now in the note |
| B7, intro and dialogue mash, pause/sound in the lock | passed | | B7: ending box 1 held 1.38 s (≥ 0.6, the case's bar; the first Next at +1.38 s advanced it), and box 2 held 1.77 s under five Next presses. Intro boxes held 2.26 / 1.65 / 1.83 / 1.83 s. Dialogue lines held ≥ 1.5 s. Mute and pause responded "locked 1" |
| r6/r7 cases (B1 gap 0.050, 15b cap 4520 / hero 5580, R2-03, slide, ▶ across a beat, title card, slow-motion hit) | all passed | | |

## 2. r9 spec checks on screen (from `test_r9_screens_banner_partner_and_hand` and the suite shots)

Pixel values come from the XCUITest PNGs (raw sRGB values; the files are tagged sRGB). 1 world ≈ 1.588 px.

| Check | Result | Evidence |
|---|---|---|
| 7c finish hold 1.5 s, taps dropped | **PASS** | above (1.517 s alone) |
| 7c every resume restarts to "rise done" | **PASS** for one resume after the rise (0.800 s ≥ 0.8). Two or three pauses, and a pause during the rise: **NOT ASSESSED** (no case does them; no touch path) | N1 |
| Placement (a) front spot, facing right (hero screen x 460) | **PASS** | rise 0.06 s: partner semi-transparent (on-screen start, fade); 0.26 s opaque; 0.76 s banner up, partner in front facing the banner |
| Placement (b) left edge facing left (hero x 70) → beyond the banner | **PASS** | partner right of the cloth, not over the cloth or the hero |
| Placement (c) start **off screen, no fade** | **NOT ASSESSED** | the harness's (c) stops at hero x 812 (`hero_x 5332 cam 4520`), where the start is on screen. No debug arg places the hero, and Device Hub can't be tapped. GameCore FinishHoldTests only |
| (d) right after a resume | **PASS** | banner up, partner opaque in place |
| Partner = follower at ≈ 0.62 × hero height | **PASS** | hero ≈ 282 px (hair to feet), partner ≈ 170 px → **≈ 0.60–0.62**. Topknot, no headband or tails; tunic ≈ #D8C9A3, sash ≈ #B9705C (quantised) |
| Banner #D64A2E + ≈ 4 px #E8A93B; never over the partner's face | **PASS** | cloth raw **#D64A2E**, border raw **#E8A93B**, ≈ 6 px = **3.8 world** on each side; cloth clear of the partner in every frame |
| Hints ≥ 276 on banner beats; hand clear of every pad's visible square | **PASS** | hand box (note) world x 940–1064, y 378–434. Its right edge (px ≈ 1974) is about 4 px (≈ 2.5 world) left of the Flag pad's ring (px ≈ 1978), so it's clear but close. Nothing overlaps the other pads |
| Double outline at camp, ink on day sky | **PASS** | camp "Oof!": red text, cream outline, ink ring outside. Day-village "Oof!": ink outline |
| AC14 picture bundle | **PASS (bundle)**: all 16 `pic.*` refs in mission + quiz resolve through assets.json; all 22 assets exist, bytes match, pictures decode at the recorded size. **NOT ASSESSED (fallback)**: the "file removed → background only / placeholder portrait + log line" half needs a modified build. That isn't QC's to make (a modified-copy attempt was declined), so it rests on the apps' own tests | script output in this file only |

## 3. Debug-save fix (`debugsave/`)

Fresh install (uninstall + install, no prefs file), then four debug jumps (`quiz -q 5 -stage right`,
`play -beat 4 -stage flag`, `caption -beat 1 -hero sample`, `quiz -q 1 -stage right`), then a plain launch:
**title shows 0★ and a grey medal: PASS** (`02-normal-launch-title.png`). Saved keys afterwards:
`seen_open.tran-quoc-toan = true` only. There are no stars, medal or completed keys. See note N2 about `seen_open`.

## 4. Regression

- Ending: the flag pole now sits clear of the pause/sound block (r11). The r8 art note is fixed.
- Story screens, captions, dialogue, intro: the placeholder shows, with no sprites and no top stack (case passed, 6 shots).
- The suite's quiz end state matches r8: the right card is in the left slot, the why line is beside it, and Tiếp shows.
- Mash holds, pause/sound inside the lock, B1, 15b, R2-03, slide, ▶ across a beat: all passed (above).

## Notes for game-dev-ios (not filed as bugs)

- **N1, resume hold length:** after a resume, the banner-up time before the walk-on is **0.800 s**, the same in both runs.
  Rule 7c says "restart to rise done (elapsed = the rise time, 0.67 s)", which leaves 1.5 − 0.67 ≈ **0.83 s**. AC32's
  threshold is ≥ 0.8 s, so the result passes, but with no margin. The app may treat the rise as 0.70 s, or the log may
  stamp the resume one or two frames late. Worth a look so the result doesn't sit exactly on the threshold.
- **N2, `seen_open` after a debug jump:** `ios-touch-tests.md` says a debug-jumped run never writes `seen_open`. On
  this build **every** launch writes `seen_open.tran-quoc-toan`. That includes all six debug jumps I tried, one at a
  time on a fresh install (`debugsave/isolate.txt`), and a plain launch to the title. Writing on a title load is the
  spec (Save Rule 5). The first hero is always open, so a child sees no difference. Either the guide's wording or the
  debug path should change.

## Not committed

`touch/result.xcresult` and `timing/*/result.xcresult` are kept locally only.
