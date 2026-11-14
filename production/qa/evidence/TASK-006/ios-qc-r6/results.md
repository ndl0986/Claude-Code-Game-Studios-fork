# TASK-006 iOS QC r6 — fa163d3

- **Build:** feat/TASK-006-ios-native @ fa163d3, frozen at `game-dev-001/production/qa/builds/TASK-006-ios-fa163d3/`
  - app fingerprint `9a3b1bd8…8764b`: matched
  - folder fingerprint `47303622…8188f`: matched
- **Device:** iPhone 18 Pro Simulator, iOS 27.0 (E9F515E9-58F2-4A92-ABEF-C5CD59CE8183)
- **Setup:** 1a8c443 was uninstalled before this build was installed. Saves were set through the simulator's `defaults` (stars, completed, medal). Screens were reached with debug jumps.
- **Verdict:** **FAIL**, with 2 new layout bugs (iOS-R6-01, iOS-R6-02).
  - All touch cases PASS.
  - The R5-01 fix PASS.
  - Some items are NOT ASSESSED (no touch path outside the harness).

## Touch: XCUITest harness (`touch/`)
Run: `tools/qa/ios-touch-tests.sh production/qa/builds/TASK-006-ios-fa163d3 <evidence>/touch`, test-without-building.
- xcodebuild exited 0.
- 5 passed, 0 failed, 0 skipped.
- The 27.1-named xctestrun ran on the 27.0 runtime without complaint. The log shows only `IDESchemeActionSDKRecord … invalidDigitCount(94232)` warnings.

| Case | Result | Measured |
|---|---|---|
| R2-03 press/move/release on each blocks-step pad | PASS | nothing held after each release |
| ◀→▶ slide | PASS | walked right; nothing held |
| Hold ▶ across a beat change | PASS | beat advanced; nothing held |
| B1 two fast taps on Next | PASS | UITouch gap **0.050 s**, advanced true/false. This exercises the debounce, but at a gap tighter than the 0.15–0.17 s a child's double-tap makes; the 0.15–0.25 s range is not exercised by XCUITest. |
| 15b hold ▶ 5 s in training | PASS | cap 4520, cam 4520, hero_x 5580 = cap + 1060 |

- Screenshots and notes are in `touch/attachments/`; `manifest.json` maps each file to its case.
- `result.xcresult` (1.9 MB) is not committed. It stays in the worktree.

## Non-touch

| # | Item | Result | Evidence |
|---|---|---|---|
| 1 | Title: fresh (outlines), 2★, 3★ + medal, VI and EN; no overlaps | PASS | 01–06 |
| 1b | Tapping the hero card does nothing | NOT ASSESSED (needs touch; not in the harness) | — |
| 2a | Story and dialogue boxes clear of the corner block | PASS | 10–15, B1 shot |
| 2b | Skip/Bỏ qua and Next/Tiếp ≥ pad_min (72 pt), on one row | PASS: Skip 76.7 pt tall, Next 78 pt; same row | 10 (measured) |
| 2c | Full-bleed story pictures | **FAIL: iOS-R6-01** | 10, 11, 14, 15 |
| 2d | Dialogue title inside the panel | PASS | 12, 13 |
| 3a | The EN banner inside its bar (R5-01) | **PASS**: wraps to 2 lines inside the bar | 20, 22, 24 |
| 3b | Banner outline contrast, measured | PASS: fill FFCE3E on bar E0603C 2.40:1; outline 4B3829 vs fill 7.46:1, vs bar 3.11:1. The bar is the same on day camp and night | 20, 24 |
| 3c | Pop ("Ối!/Oof!") outline per theme | NOT ASSESSED: needs a hit, which only touch can produce | — |
| 4 | Input Rule 1: world in the safe area, scene colours around the Dynamic Island | PASS on play and title: scene colours reach every edge (column scans at x 4 and x 2600). Fails on intro and ending, see iOS-R6-01 | 01, 12, 20 |
| 5 | `-stage finish` shows the Flag/Cờ, Defend and Attack pads (W12) | PASS | 22, 23 |
| 6 | AC13 strike contact frames | NOT ASSESSED: a swing needs touch | — |
| 7 | Regression (reachable without touch) | see below | 24, 30–35 |

### Regression notes
- Telegraph "!" disc (night): readable. Its top overlaps the banner's lower edge by about 10 pt at the debug jump position (24). Note only.
- Quiz wrong-pick feedback "Try again!" and the shaken card: OK (31).
- Results with 3★ and a new medal (VI): OK (32).
- Unlock VI now names "Anh hùng mới", so r5 N3 is fixed (33). EN shows "New hero" (34).
- Pause EN: OK (35).
- Not reachable without touch, so NOT ASSESSED:
  - skip/medal flow;
  - stars from real play;
  - save after a kill;
  - N1 (camp "Ối!" contrast);
  - r5 N2 (sound button over the picture corner). The pictures are now full-bleed, so the button sits over the scene by design.

## Bugs

### iOS-R6-01: intro/ending pictures stop above a flat dark bar
- **Severity:** S3 (visual, spec deviation)
- **Spec:**
  - story-screens.md: "the story picture is full-bleed (P-06: the step's background fills the screen behind everything)".
  - Input Rule 1: "no letterbox bars".
- **Repro:** `-startScreen intro` or `-startScreen ending`, VI or EN, on the iPhone 18 Pro landscape.
- **Expected:** the picture fills to the bottom edge, as the play scene and title do.
- **Actual:** pixel rows 1146–1206 of 1206 (20 pt, the home-indicator inset) are a flat #303050-ish bar across the full width (10, 14). The play/dialogue scene fills to the edge (12).

### iOS-R6-02: the quiz question's first line runs under the sound button
- **Severity:** S2 (text covered, in the corner block)
- **Repro:** `-startScreen quiz -q 2` (also `-q 4`, `-q 5`), VI or EN.
- **Expected:** the question starts clear of the corner block (story-screens.md: content top ≥ corner_bottom + 8), or is placed beside it.
- **Actual:**
  - Every question that wraps to 2 lines (Q2, Q4, Q5) starts beside the pause/sound block, at the height of the buttons' lower half.
  - Its first glyphs run under the sound button, e.g. "Vì"/"Why" on Q2 and "The"/"Which" on Q4/Q5 (30, 31, 37-quiz-q4/q5-en).
  - One-line questions (Q1, Q3) sit lower and are clear (36, 37-quiz-q3-en).
  - In r5 (letterboxed) Q1 was clear. A 2-line question wasn't captured in r5, so whether this is a regression is unknown.
