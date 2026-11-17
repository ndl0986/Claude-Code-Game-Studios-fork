# TASK-006 iOS QC r11 — 86ddce0 (Debug) + TASK-026 Preview 86ddce0

## **r11 QC result: PASS on items 1–8. Item 9 (skip-warning medal drum on the VI text): judged a bug, iOS-R11-01, S4, not a blocker. NOT ASSESSED on device: "a run that skips earns no medal" (GameCore only).**

Device: QC iPhone 18 Pro Sim, iOS 27.0, E9F515E9 (1 world ≈ 1.588 px; pad_min 72 pt = 216 px). Run on 2026-11-17,
14:59–15:30. Device Hub touch is still blocked, so every touch comes from the frozen harness. Pixel values are raw
NSBitmapImageRep reads of the XCUITest PNGs, in screen coordinates.

## Builds and fingerprints (re-hashed by QC, match the freeze note)

- Debug `TASK-006-ios-86ddce0/`: `DaiDatAnhHung` sha256 `2507a08167fbcb8dccd180d1c5dfe29d91781eba68a2a660000df7dc1dabb36d`
  (Debug-iphonesimulator/ has the same bytes; the installed copy matches). `DaiDatAnhHung.debug.dylib`
  `f08031c111f6ac52b2d96dd161a06d6260f2b11f6e54c52d9599b3005cb5c987`. `ios-touch-tests.sh` `18c3c0b3…1758` (unchanged since r7).
- Preview `TASK-026-ios-preview-86ddce0/DaiDatAnhHung.app` (`com.galaxyandsun.daidatanhhung.preview`, "Dải Đất Anh Hùng (preview)",
  0.1.0 (1)): `DaiDatAnhHung` `f6cf071213360deb957fb330e0c035497e38f8ded563777af0290cf730bf53d4`; the installed copy matches.

## Full Debug suite (`touch/`): 29/29 UI passed, 1 skipped (the opt-in Preview case, by design)

672 s, load 19.3 at the start (gated < 20), 9.1 at the end (`load-suite.txt`). So its timing cases count.

## 1. iOS-R10-01 re-test: **PASS** (`timing/`, load in `timing/load.txt`, every run started < 15)

| Run | Load start → end | Press → walk | Resume frame (log) → walk | App's wall time from the resume frame (`resume frame` note) | Case |
|---|---|---|---|---|---|
| suite | 19.3 → 9.1 | 0.864 | 0.852 | 0.8490 | passed |
| 1 | 9.6 → 10.7 | 0.869 | 0.850 | 0.8490 | passed |
| 2 | 10.7 → 10.6 | 0.871 | 0.850 | 0.8490 | passed |
| 3 | 10.6 → 10.4 | 0.870 | 0.850 | 0.8491 | passed |
| 4 | 10.3 → 12.0 | 0.870 | **0.866** | 0.8492 | passed |
| 5 | 12.0 → 16.7 | 0.870 | 0.850 | 0.8491 | passed |
| 6 | 14.8 → 13.8 | 0.869 | 0.850 | 0.8492 | passed |

- From the resume frame: 0.849 s of wall time in all 7 (the app's own reading), = 51 frames, and 0.850–0.852 on the
  log in 6 of 7. **Never short.** r10 was 0.816–0.833.
- Run 4's log figure (0.866) is one frame over 0.850. The app's wall time for the same hold is 0.8492, so the walkTo
  log line was published one frame late (a frame stall); the hold itself wasn't longer. Noted, not a fail.
- From the press: 0.864–0.871 (the freeze note says 0.85–0.87).
- **No judder (R11 f), alone, ×2:** a 3 s walk and a training walk with ▶ held. The r11 clock and the r10 shadow
  (currentTime) have identical histograms in every run: [0, 222, 0, 0] ×2 (0 judder frames); [0, 220, 1, 1] and
  [0, 220, 2, 0] (2 two-or-more-step frames on both clocks: real stalls). The suite run: [0, 221, 1, 0] on both.

## 2. W17 fist: **PASS** (`DF2E…` VI, `F2BE…` EN, `C3BD…` training)

The hold-meter's Cờ pad shows a fist: skin #F1C9A0 (also in EN), ink #3A2A1F outline, three knuckle creases, the thumb
across, cream #FFF6E3 cuff; label "Cờ". The skin teach hand points at it. Training's finish still shows the flag
(banner) on its Cờ pad.

## 3. W20 skip warning: **PASS** (layout and both paths); medal rules PASS except one sub-check NOT ASSESSED

- "Đọc tiếp / Keep reading": big, gold, pulsing (the default), on the **right**, open-book icon. "Vẫn bỏ qua / Skip anyway":
  smaller, cream, on the **left**, double-chevron icon (VI `54760D45…`, EN `F1F9E240…`).
- `R11 test_d` passed: the right one keeps reading, the left one skips.
- Medal: a real run with no skip earns it and keeps it across a relaunch (case D, suite: median press gap 0.397 s,
  130 taps, skip warning never seen, 3★ + medal). A debug-jumped run saves nothing (`test_skip_warning…saves_nothing`).
  **"A run that skips earns no medal": NOT ASSESSED on device** (no harness case finishes a run after Skip anyway;
  GameCore `BeatTypeTests.test_missionflow_AC25_skipping_a_dialogue_costs_the_medal`).
- **Against Android r14 beea731** (`android-qc-r14/r14-20-skipwarn-vi.png`, `pv14-07-leave-card.png`): the same layout,
  sides, icons and sizes on both the warning and the leave card. One difference: Android's medal drum sits clear above
  the text; iOS's touches it (item 9).

## 4. W18 leave card: **PASS**

- The pause menu: "Chơi tiếp" big on top; "Về bản đồ / To the map" smaller, lower, map icon (`47D3…` VI, `447E…` EN).
- The card (`17B8…` VI "Về bản đồ?", `95E8…` EN "Leave the story?"): map picture; "Về bản đồ" left, small, cream, map
  icon; "Chơi tiếp / Keep playing" right, big, gold, ▶. No red.
- `R11 test_a` passed: a tap on the card's "Về bản đồ" at +0.422 s was locked; the card stayed up.
- `test_b` passed: "Chơi tiếp" → the menu, run intact; resume → the same beat. `test_c` passed: the card's "Về bản đồ" → the title.
- **Real taps (R11 e)**, suite and alone: pause → "Về bản đồ" → the card's "Về bản đồ" → the title; Start → intro line 0. Passed both times.
- **Nothing written on leave** (`leave/saves.txt`): before the alone run of test_e the save held completed, medal,
  seen_open and 3★ (from case D). After it the plist is **byte-identical** (sha256 `5b6a7945…4c1a`) with the same
  mtime (15:12:51); the title still shows 3★ + medal (`leave/test_e/…`). Limit: test_e starts by a debug jump, which
  writes nothing anyway, so this shows that leaving doesn't clear or rewrite the save, not that a real run's leave
  skips a write.

## 5. R8 uses the string's own `field` (D-21): **PASS (on screen)**

`ui.pause.leave_confirm` has `"field": "dialog"`. "Leave the story?" (16 characters, over the 12-character button
budget) is drawn whole as the card's line in EN. The content tests are GameCore's (dev: 164/164); QC doesn't compile.

## 6. Buttons ≥ pad_min: **PASS**

Heights down a column through each button's fill, rim to rim, in px (216 px = 72 pt ≈ 136 world). The pulsing ones
scale 1.00–1.04, never under 1.

| Button | px | Button | px |
|---|---|---|---|
| Pause "Chơi tiếp" (pulsing) | 228 (fill 216) | Pause "Về bản đồ" | 222 |
| Card "Về bản đồ" | 221 | Card "Chơi tiếp" (pulsing) | 229 |
| Warning "Vẫn bỏ qua" | 222 | Warning "Đọc tiếp" (pulsing) | 229 |

## 7. Preview: **PASS** (`preview/`)

The Preview app installed beside Debug. Then `TEST_RUNNER_PREVIEW_CHECK=1 ONLY=PreviewCheckUITests/test_preview_title_then_story_screens_show_the_unsigned_strip ios-touch-tests.sh <Debug folder>`:
**passed** (11.2 s). It asserts there's no debug state and ignores the `-startScreen` jump. Shots: 01 the title with the
hero card and "Bắt đầu" (0★, its own fresh data; no "Bản chơi thử" line); 02 intro box 1 with **UNSIGNED C01** at the
top; 03 the same 2 s later.

## 8. Short regression: **PASS** (Release check NOT ASSESSED by QC)

| Check | Result |
|---|---|
| Debug paths save nothing (`debugsave/`) | Fresh install, four jumps (incl. `-startScreen pause -stage leave`), a plain launch: only `seen_open`; title 0★, grey medal |
| Tap lock 0.6 s, cap 1.5 s | case C (suite): +0.342 locked, +0.847 locked (end +0.942), **+1.551 advanced** (end +1.447); iOS-R8-01: +425/+794/+1153 ms all locked |
| Finish hold | 1.517 s (suite) |
| B7 | ending box 1 held 1.38 s before the first Next advanced it |
| Partner 0.62 × hero | 177 / 286 px = 0.62; partner skin #F1C9A0 |
| Hint hand | box (940, 378, 124, 56), unchanged |
| Full run → 3★ + medal | case D (above) |
| Skin #F1C9A0 | hero, partner, fist, hand: exact |
| Release / Preview A1 = A2 = B | NOT ASSESSED by QC (doesn't build). Dev: Release `d0ee4cbd…96be`, Preview `7c3fd39d…cd29`, strings/nm clean |

## 9. The skip-warning medal drum on the VI text: **a bug (iOS-R11-01), S4-Low, not an r11 blocker**

Measured on the suite's shots: the lowest gap between the drum's outer ring and the first text line's ink, over
x 1180–1480:
- **VI: 0 px.** At x 1313 the circumflex of "nhận" starts on the ring's last row. At x 1315 the ink replaces the
  ring's last 2 rows, so the letter overlaps the drum (the text draws on top).
- **EN: 7 px** (≈ 4.4 world) clear.

Why I call it a bug rather than acceptable:
- In Vietnamese the diacritic carries meaning (â vs a). Here it sits on a decoration, on the screen whose whole job
  is to be read before a child chooses.
- Android r14 draws the same warning with the drum clear of the text, so it is also a parity difference.
- It is small (the mark is still readable) and has been there since r9, so it doesn't block r11.

### Bug iOS-R11-01 (`/bug-report` format; for game-dev-ios via the leader)

- **Title**: Skip-warning medal drum touches the first VI text line (circumflex on "nhận" overlaps the ring)
- **Severity**: S4-Low · **Priority**: P3-Backlog · **Category**: UI · **System**: story screens / skip warning (W20)
- **Frequency**: Always (VI); EN clear by 7 px · **Regression**: No (since r9)
- **Build**: 86ddce0 Debug, iPhone 18 Pro Sim iOS 27.0
- **Steps**: open the skip warning in VI (`R11CasesUITests/test_r11_screens…`, attachment "r11 skip warning vi").
- **Expected**: the drum clear of the text, with a gap as in EN and Android r14.
- **Actual**: 0 px gap at x 1313; ≈ 2 px overlap at x 1315 (screen px), y ≈ 411–416.
- **Fix idea (dev's call)**: move the drum up, or the text line down, by ≥ 8 px (≈ 5 world), or size the gap from the
  line's ascender height (VI diacritics are taller than EN).

## Not committed

`touch/result.xcresult`, `timing/*/result.xcresult`, `leave/test_e/result.xcresult`, `preview/check/result.xcresult`
and the `.log` files are kept locally only.
