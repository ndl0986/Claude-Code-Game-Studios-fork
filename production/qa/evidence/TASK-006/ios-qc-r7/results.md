# TASK-006 iOS QC r7: b53cfde

- **Build:** feat/TASK-006-ios-native @ b53cfde, frozen at `game-dev-001/production/qa/builds/TASK-006-ios-b53cfde/`.
- **Fingerprints, re-hashed by QC:**
  - app executable sha256 `0cbd2d6f8e16a52e4140a9c562badadd13a2bd3a8e511e64257e9a8b4e303294`: matches the leader's
  - `ios-touch-tests.sh` sha256 `18c3c0b3d6202980a9f2c3fa68e581e6e538ee5febd51985fd21cd0474c51758`: matches
  - whole .app tree (for the record): `d9d133bd031d6b57a4efcfa17e255d5052f2fb13ef7818e4fa32dd81565c1e7a`
- **Devices:**
  - iPhone 18 Pro Sim, iOS 27.0 (E9F515E9-…). The fa163d3 build was uninstalled first.
  - iPhone 17e Sim (9312E6A1-…), used for item 4 only: booted, app installed, shot, shut down.
- **Verdict:** **PASS** on everything assessed; no new bugs. NOT ASSESSED items are listed below and don't count as passes.

## 7. Harness: 10 UI cases (`touch/summary.json`)
- Result: Passed. 9 passed, 0 failed, **1 skipped**. Run took 3155 s; xcodebuild exited 0.
- As the leader warned, each case spent ~300 s in XCTest teardown. This is a host issue, not an app defect.
- The 27.1-named xctestrun ran on the 27.0 runtime.

| Case | Result | Measured / seen |
|---|---|---|
| R2-03 per pad | PASS | nothing held |
| ◀→▶ slide | PASS | |
| Hold ▶ across a beat change | PASS | |
| B1 | PASS | gap 0.050 s, advanced true/false. 0.15–0.25 s is covered only by the AdvanceDebounceTests unit test. |
| 15b | PASS | cap 4520 = cam, hero_x 5580 = cap + 1060 |
| Title card tap does nothing | PASS | title unchanged |
| Slow-motion hit (AC13 + pop) | PASS (visual, see below) | strike landed in ×0.1 slow motion |
| B7 Attack mash through the beat end | PASS | see item 1 |
| Skip warning → Keep reading; 5 right → 3★ survives a relaunch | PASS | results "You earned the medal!"; title after relaunch shows 3★ + medal |
| ◀ tapped as the training card appears | **SKIPPED, not exercised** | the first tap landed 0.695 s after the card (lock 0.6 s), so it hit Skip (`fire:skip`) |

- `result.xcresult` is not committed. `attachments/manifest.json` maps each file to its case.

## Retest items

| # | Item | Result | Evidence |
|---|---|---|---|
| 1 | B7 rolling entry lock on every ending box | **PASS** for the lock; medal under mashing **NOT ASSESSED** | B7 log (attachments `82ED7C04…txt`) |
| 2 | R6-01: no flat bar in the home-indicator inset | **PASS** | 10, 11, 14, 15 |
| 3 | R6-02: 2-line quiz prompt clear of the sound button | **PASS** | 30–32 |
| 4 | Small-k quiz option (c) | **PASS on the 17e** (small layout reached by the card/Tiếp-row rule, not k < 0.48) | 40–43 |
| 5a | ◀ as the training card appears → no skip warning | **NOT ASSESSED** (harness SKIPPED) | `E5D3905D…txt` |
| 5b | Skip warning → Keep reading | PASS | harness |
| 6 | "Đúng rồi!/That's right!" pill | **PASS** | 33, 34 |
| 7 | Harness 10 cases | 9 PASS, 1 SKIPPED | touch/ |
| 8 | Regression | PASS (pause/sound exempt from the lock: NOT ASSESSED) | 01, 12, 20, 22, 24, 35–37 |

### Item 1: B7 details
- **Ending box 0:** entered at 869.568. The first Next press at +1.387 s advanced it. Box 0 held ≥ 0.6 s.
- **Ending box 1:** entered at 870.968, with Next mashed:
  - presses at +0.33, +0.70, +1.04 and +1.38 s were dropped;
  - the press at +1.73 s, past the 1.5 s cap, started the quiz.
  - So the rolling lock holds up to the cap and releases after it.
- **Limits:** 18 taps in total; uses the debug shortcut `-stage flag`. The rolling cap itself is proven by `EntryLockTests`.
- **Medal under mashing:** not asserted by any case. The B7 case uses `-stage flag`, and the 3★ case reaches the quiz by a debug jump (D-07). NOT ASSESSED.

### Item 2: R6-01
- Bottom row y 1200 is scene colour on intro (D0A060 ground) and ending (80B050 grass).
- Column x 4 runs scene colour all the way down; no flat #303050 band.

### Item 3: R6-02
- Q2 (VI), Q4 and Q5 (EN) now start below the corner block. All lines are clear of the pause/sound buttons.

### Item 4: small-k, iPhone 17e (2532×1170)
- Expected k ≈ 0.51, so `scale < 0.48` alone wouldn't switch.
- With the 2-line Q2/Q4 prompts, the small layout engaged anyway:
  - the wrong cards are gone and the right card sits in the left slot;
  - the why line sits to its right (wrapping to 2 lines on Q4 EN);
  - Tiếp is bottom-right;
  - nothing overlaps (40, 41).
- Choosing on 2-line Q5: cards clear of the corner block (42). Title fits (43).
- A phone with k < 0.48 isn't available. That branch is covered by `QuizLayoutTests` (`pad(0.40).small`).

### Item 6: pill (18 Pro, 33 VI / 34 EN)

| Check | Measured |
|---|---|
| Pill box | x 1136–1485, y 439–501 px, i.e. 350×63 px |
| Size in world px | 350/1.59 × 63/1.59 ≈ **220 × 40** ✓ |
| Centred on the card | card x 1000–1621, centre 1310.5; pill centre 1310.5 ✓ |
| Placement | on the card's top row, over the picture's top edge |
| Label | not clipped, VI and EN |
| Label ink | sampled **#23170D**, spec #1A120C. The small delta is likely colour-space/antialias. Contrast on pill green #4BAF5F is 6.33:1 (6.69:1 at the spec colour). |

### AC13 contact and "Oof!" pop (harness slow-motion screenshots)
- **AC13 contact:** the contact frame shows the enemy spear tip on the hero's chest. The after frame shows the hero pushed back and blinking. PASS (visual).
- **Theme:** the case's screenshots are on the **night** camp (beat 5), not the day camp sky the harness doc names.
- **Night contrast:** fill #E34B38, cream outline #FFF8E8, sky #4B517C.
  - outline vs sky 7.17:1
  - fill vs outline 3.72:1
  - readable
- **Day camp sky (r5 N1): NOT ASSESSED.** For the record: if the same pop sat on the day sky (#C6E2EE), the cream outline would be only 1.28:1 against it, with the red fill at 2.91:1. That is a calculation, not a captured frame.

### Regression
- Every screen checked keeps the safe-rect fit with scene colour to every edge:
  - title VI 3★ + medal
  - dialogue EN
  - camp banner VI
  - night telegraph EN
  - finish pads EN
  - results EN (2★, no medal: "Read it all for a medal")
  - unlock VI ("Anh hùng mới")
  - pause VI
- The banner sits in the sky band on day and night.
- **Transient:** the first results shot (35) shows a black capsule at the Dynamic Island position, pixel x 80–120, y 460–745. Three reshoots, including 35b, are clean. It's a one-off system overlay, not drawn by the game.
