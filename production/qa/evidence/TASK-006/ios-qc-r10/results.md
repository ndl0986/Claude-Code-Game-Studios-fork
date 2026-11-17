# TASK-006 iOS QC r10 — 760a5b2 (branch head f024950, docs only)

## **r10 QC result: FAIL on item 1 (FrameClock resume: 2 of 9 solo runs under 0.828 s, bug iOS-R10-01). Items 2–4 PASS. NOT ASSESSED: Home from pause, and the Release byte check (QC doesn't build).**

Device: QC iPhone 18 Pro Sim, iOS 27.0, E9F515E9 (1 world ≈ 1.588 px). Run on 2026-11-17, 11:38–12:45. Device Hub
touch is still blocked ("AX reads stayed blocked", 11:41), so every touch comes from the frozen harness.
Android r14's W17 / W20 / W18 are not on iOS yet and are not flagged here, as the leader asked.

## Build and fingerprints (re-hashed by QC, match the dev README)

- Frozen folder: `game-dev-001/production/qa/builds/TASK-006-ios-760a5b2/`
- `DaiDatAnhHung` sha256 `a4176f96a34fde2d9896e3f7ce598255bd3aa8760979d5cdecc5b8e6a0a2d935`. Debug-iphonesimulator/ has
  the same bytes, and the installed copy on E9F515E9 matches after uninstall + install.
- `DaiDatAnhHung.debug.dylib` `70b95b9093ca3ab58d42c20d0aa85db3a554a861e55c81a6fb4e7796cb3d9fbd`
- `ios-touch-tests.sh` `18c3c0b3…1758` (unchanged since r7). .app tree `d458db78…d1f7` (sorted file sha256s, hashed)

## Full UI suite (`touch/`): 21/22 passed, 1 failed (infrastructure, passed alone)

It took 1318 s. **Load:** 159–204 at the start (the Simulator's own daemons right after boot, plus the Android
emulator), 4 at the end. So no timing result from the suite counts. The timing cases were re-run alone (`timing/`,
loads in `timing/load.txt`).

- **iOS-R8-01 (◀ as the card appears):** failed in the suite with `Failed to get matching snapshots: Error getting main
  window kAXErrorServerNotFound` (the harness launch helper, TouchCasesUITests.swift:21) at load ≈ 190. That's an
  XCTest infrastructure error, not an app assertion. **Alone it passed**: presses at +433 / +803 / +1193 ms, all locked;
  no warning.
- Every other case passed: B1 (gap), 15b cap, R2-03, slide, ▶ across a beat, title card, slow-motion hit, B7, R8 mashes,
  pause/sound in the lock, story screens, quiz A (fade/glide ≤ 720), A slow motion, B, C, D, finish hold, resume, r9 screens.

## 1. FrameClock (N1): **FAIL** — see iOS-R10-01

The resume case run alone 9 times (`timing/test_a_resume_restarts_the_hold_to_rise_done-1..9`). "Press" is `fire:resume`
(UITouch time). "Resume frame" is the first `play|…beatEnd` line after it. "Walk" is `walkTo`. All are log stamps.

| Run | Load at start → end (1-min) | Press → walk (case's number) | Resume frame → walk | Press → frame | Case |
|---|---|---|---|---|---|
| 1 | 5.2 → 6.1 | 0.835 | 0.816 | 0.019 | passed |
| 2 | 6.1 → 23.4 | **0.823** | 0.818 | 0.005 | **failed** |
| 3 | 23.4 → 34.6 (over 20, not counted) | 0.839 | 0.828 | 0.011 | passed |
| 4 | 8.1 → 16.2 | 0.845 | 0.833 | 0.012 | passed |
| 5 | 14.3 → 13.4 | 0.840 | 0.830 | 0.010 | passed |
| 6 | 13.4 → 8.3 | **0.824** | 0.818 | 0.006 | **failed** |
| 7 | 8.3 → 11.7 | 0.846 | 0.833 | 0.014 | passed |
| 8 | 11.7 → 16.1 | 0.839 | 0.823 | 0.016 | passed |
| 9 | 14.8 → 14.2 | 0.838 | 0.821 | 0.017 | passed |

Suite run (load falling from ≈ 190, not counted): 0.836 press → walk, 0.833 frame → walk.

- The leader's bar: 0.833 ≤ t ≤ 0.850 after the resume frame, about ±3 ms jitter, anything under 0.828 a FAIL.
- By the press (the case's own assertion, ≥ 0.828): **2 of 9 fail** (0.823, 0.824). Run 6 started and ended under 15.
- By the resume frame, as the leader asked: **0.816–0.833 in every run.** None is above 0.833, and 6 of 9 are under
  0.828. The short runs are the ones where the resume frame came quickly after the press (5–6 ms).
- r9 was 0.800 every time, so the fix moved it about one frame, but on this build the walk still sometimes comes
  ≈ 1 frame (10–17 ms) early on the log's clock.
- **Home from pause, no jump: NOT ASSESSED.** No harness case presses Home from pause, and Device Hub can't be tapped.
  The code path is the same `leftPause` frame (`Flow.home()` leaves `.pause`). It rests on GameCore `FrameClockTests`.

### Bug iOS-R10-01 (`/bug-report` format, not filed under production/qa/bugs; for game-dev-ios via the leader)

- **Title**: After a resume in the finish hold, the walk-on sometimes starts < 0.828 s after the press (≈ 1 frame early)
- **Severity**: S4-Low (a child can't see one frame; it fails the r10 acceptance bound and the frozen case's assertion)
- **Priority**: P2-Fix soon (it blocks r10 item 1)
- **Category**: Gameplay (timing) · **System**: mission flow 7c / AC32, GameCore FrameClock + GameScene loop
- **Frequency**: Sometimes (2/9 alone at low load; 6/9 under 0.828 measured from the resume frame)
- **Regression**: No (r9 was 0.800 every time; r10 improves it but doesn't reach the bound reliably)
- **Build**: 760a5b2 Debug, iPhone 18 Pro Sim iOS 27.0 (E9F515E9)
- **Steps**: `SIM_UDID=E9F515E9… ONLY=R9CasesUITests/test_a_resume_restarts_the_hold_to_rise_done
  ios-touch-tests.sh <760a5b2 folder> <out>`, repeated (`-startScreen play -stage finish`, pause in the hold after the
  rise, resume).
- **Expected**: walkTo ≥ 0.833 s after the resume frame (0.833–0.850, ±3 ms), never < 0.828 s after the press.
- **Actual**: run 2 `fire:resume @ 148423.646`, `play|0|beatEnd @ 148423.651`, `walkTo @ 148424.469` → 0.823 / 0.818 s.
  Run 6: 0.824 / 0.818 s. The case failed with its own ≥ 0.828 assertion both times.
- **Technical context (QC reading only, not verified)**: the screen-change log is stamped with wall time
  (`ProcessInfo.systemUptime`, GameScene.swift:1168) when the update publishes it, but `FrameClock` credits time from
  SpriteKit's `currentTime`. If the resume frame's update runs later than its `currentTime`, the next frame credits that
  gap. The 50 steps then finish before 0.833 s of logged wall time has passed. Either the clock should credit from the
  resume frame's actual time, or the case and bound should measure on the frame clock. Which one is the dev's and the
  leader's call.
- **Evidence**: `timing/test_a_resume_restarts_the_hold_to_rise_done-2/` and `-6/` (summary.json, tests.json,
  attachments: "banner-up after the resume", "resume log"); `timing/load.txt`.

## 2. Skin #F1C9A0: **PASS** (`skin/`, `skin/samples.txt`)

Raw pixel values in both the XCUITest PNGs and plain `simctl` screenshots are exactly **241,201,160 = #F1C9A0**. The
dev's "#F5D3AF" is a colour-managed read of the same pixels, not a different colour. The hand and the face match.

| Where | Shot | Value |
|---|---|---|
| Hero face and hand | 04, 05, 02, 03 | #F1C9A0 |
| Partner (follower) face | 05 | #F1C9A0 |
| Enemy face (spear, camp fight) | 06 | #F1C9A0 (cluster at x 1280–1400). All enemy kinds use the same `face()` with `C.skin`; the leader kind wasn't on screen |
| "child" picture icon (sample hero, quiz q2) | 01 | #F1C9A0 |
| Title portrait | 07 | #F1C9A0 |
| Old #F5C9A0 | 04, 05, 06, 07, pushed pose | 0 pixels |

## 3. Hint hand (ASSET-033): **PASS** (`skin/04-hint-hand-suite.png`)

Palm, finger and thumb #F1C9A0. Cuff cream #FFF6E3. Ink #3A2A1F outline around the palm, finger, thumb **and the cuff**
(≈ 5–6 px ≈ 4 world on the cuff's left and top edges). No white glove, no red cuff. The placement is unchanged
(hand box world 940,378,124,56, left of the Flag pad and pointing at it).

## 4. Short r9 regression: **PASS** (Release byte check NOT ASSESSED by QC)

| Check | Result | Evidence |
|---|---|---|
| Debug paths write no progress | **PASS** | Fresh install, then five jumps (`quiz -q 5 -stage right`, `play -beat 4 -stage flag`, `caption -beat 1 -hero sample`, `quiz -q 1 -stage right`, `play -beat 5 -stage finish`), then a plain launch: only `seen_open.tran-quoc-toan` saved (the title-load write the guide now documents). Title 0★, grey medal (`debugsave/`) |
| 0.6 s rolling lock, 1.5 s cap | **PASS** | Case C alone at load 13.8: +0.355 locked (end +0.600), +0.874 locked (end +0.955), **+1.587 advanced** (end +1.474); all match the rule. iOS-R8-01 alone: three presses inside the rolling window, all locked |
| Finish hold 1.5 s | **PASS** | alone at load 14.0: beatEnd → walkTo **1.516 s** |
| Partner ≈ 0.62 × hero | **PASS** | 177 / 286 px = **0.62** (shot 05) |
| Full mission + quiz → 3★ + medal | **PASS** | Case D alone at load 12.2: a real run from Start, no debug jumps, median press gap 0.397 s (min 0.377), 128 taps, no skip warning; results medal + 3★; relaunch title 3★ + medal (shots 07, 08) |
| Release A1 = A2 = B | **NOT ASSESSED by QC** | QC doesn't build. Dev README: Release built three times (baeb0f7, the same app source as 760a5b2), all three sha256 `78ddc3fb…6491`; `strings` / `nm` clean |

## Not committed

`touch/result.xcresult`, `timing/*/result.xcresult`, and the `.log` files are local only.
