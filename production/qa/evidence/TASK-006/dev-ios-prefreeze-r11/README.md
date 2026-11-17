# Developer pre-freeze pass for iOS r11 (not QC evidence)

game-dev-ios, own Simulator "iPhone 18 Pro – dev-ios" (FB836E51-…, k ≈ 0.529). QC's device was not used.

**Frozen at `86ddce0`** (branch feat/TASK-006-ios-native):
- **Debug**: `production/qa/builds/TASK-006-ios-86ddce0/`, run with its own `ios-touch-tests.sh`.
- **Preview** (D-37, Simulator build): `production/qa/builds/TASK-026-ios-preview-86ddce0/DaiDatAnhHung.app`. Install it on
  the Simulator, then run the Debug folder's opt-in `PreviewCheckUITests` with `TEST_RUNNER_PREVIEW_CHECK=1` (guide:
  "Opt-in: the Preview build").

Superseded: the `TASK-006-ios-8233026` and `TASK-026-ios-preview-8233026` folders (their clock judders on a walk; see 2).

Base: r10 (760a5b2) + docs, merged with 3f464b4 (the W18 string) and feat/TASK-026-testflight-prep (6ea5047: the
Preview config, icon, privacy manifest and scripts; leader's base decision).

## Items for QC to check, one by one

1. **W17, the fist on the hold-meter's special pad** (2035c9e): skin, ink outline, knuckle creases, the thumb across, a
   cream cuff. Training's finish keeps the banner. The label stays `ui.pad.special` (D-34). Shots 01–03.
2. **iOS-R10-01 fix, the clock** (7ef28c9, 86ddce0). See "iOS-R10-01" below. The banner-up after a resume is now
   ≈ 0.849 s of wall time from the resume frame, which is 51 frames, as Android's 0.850. It is 0.85–0.87 s from the
   press, never short. A walk is as smooth as r10.
3. **W20, the skip warning** (2035c9e): "Đọc tiếp / Keep reading" big (440), gold, pulsing (the default) and on the
   **RIGHT** with an open-book icon. "Vẫn bỏ qua / Skip anyway" is smaller (340), cream, on the left with a
   skip-arrow icon. **The two buttons swapped sides.** Shots 04–05.
4. **W18, the leave card** (2035c9e): the pause menu's second button is now "Về bản đồ / To the map", smaller and
   lower, with a map icon. It opens the card (ASSET-324 card, ASSET-334 placeholder map picture, "Về bản đồ? / Leave
   the story?"). On the card, "Về bản đồ" is cream, small, left, with a map icon, and "Chơi tiếp" is gold, big, right
   and the default, with ▶. No red.
   - The card slides up 60 px and fades in over 0.25 s.
   - Its buttons take the rolling entry lock (0.6 s, cap 1.5 s); the menu stays exempt, and closing the card doesn't
     relock it.
   - "Chơi tiếp" returns to the menu with the run intact. Only the card's "Về bản đồ" leaves, and it goes to **the
     title** (the map screen is TASK-025; expected, don't flag).
   - `home()` can't leave from pause, and resume isn't live under the card.
   - Shots 06–14.
5. **"Home from pause" for QC** (iOS QC r10 NOT ASSESSED): in r11 that path is the leave card. The new case R11 (e)
   leaves from play by real taps (pause → "Về bản đồ" → the card's "Về bản đồ" → the title; Start begins again at
   intro line 0). Shot 14.
6. **R8 uses a strings.json entry's own `field`** (970f740, D-21, as Android). The merged `ui.pause.leave_confirm`
   (field `dialog`, id ending `_confirm`) failed 4 content tests against the 12-character button budget, because iOS
   typed strings by id only.
7. **Button rows ≥ pad_min** (2035c9e): every W20 and W18 button (skip warning, pause menu, leave card) is
   `rowH = max(110, pad_min in world px)` tall. That is ≈ 136 world px at k 0.529. The plan's h 100 would have been
   under pad_min.
8. **Preview inside r11**: the TASK-026 Preview build is part of this freeze. Check that the title shows the hero and
   Start, a story screen shows `UNSIGNED Cxx`, and there are no debug jumps.

## iOS-R10-01 (QC r10: banner-up after a resume 0.816–0.833 s)

- **Diagnosis.** Debug-only instrumentation on the resume frame (`resume_frame` in the debug state, mach-clock seconds,
  the same base as the press and the log), over 10 runs on r10's clock:
  - SpriteKit's `currentTime` on the resume frame is 2–18 ms after the press, and `update` runs ≈ 1 ms later. So
    nothing before the press was credited, and QC's stale-currentTime reading doesn't hold.
  - The hold was always exactly 50 steps and 0.8333 s of `currentTime`, but only **0.816–0.830 s of wall time**
    (44–47 frames, with 41–46 ms stalls).
  - So on the Simulator, `currentTime` ran up to a frame ahead of the wall clock. QC's systemUptime stamps were right:
    the banner really was up that short a time.
- **Fix, which took two tries.**
  - Feeding `systemUptime` read at the update (7ef28c9) fixed the hold but judders a walk: 5 of 216 frames ran 0 or 2
    steps.
  - `min(currentTime, systemUptime)` still judders: 3 of 216 in the 8233026 frozen run.
  - **86ddce0**: `currentTime` minus the largest lead it has shown over the wall clock. That lead only ever grows and
    stays under about a frame. The resume frame starts from the wall time itself.
  - The result is as even as `currentTime`, never ahead of the wall clock, and nothing before the resume frame is
    credited.
- **Test that would have caught it.**
  - The resume case asserts ≥ 50/60 s of wall time from the resume frame's update and from the press.
  - I watched it fail on r10's clock (0.828 and 0.817 s).
  - Fixed: 0.849 s from the resume frame in 5 of 5 runs, and 0.857–0.873 s from the press.
- **Smoothness** (leader's ask), R11 (f): a 3 s walk and a training walk with ▶ held, counting frames by steps run on
  this clock and on a shadow clock fed `currentTime` alone (r10).
  - On 86ddce0 the histograms are **identical**: [0, 221, 1, 0] and [0, 216, 0, 0] in the frozen run. The one 2-step
    frame is a real frame stall, the same on both clocks.
  - No judder is added.

## Shots

| Shot | Checks |
|---|---|
| 01–02 hold-meter fist pad VI / EN | W17: the fist inside the Cờ pad, cuff at the bottom; the skin teach hand points at it |
| 03 training finish | The special pad keeps the banner |
| 04–05 skip warning VI / EN | W20: "Đọc tiếp / Keep reading" big on the right with the book; "Vẫn bỏ qua / Skip anyway" small on the left with the chevrons. **Note:** the warning's medal drum (unchanged since r9, at y 210) grazes the top of the first text line in VI. It isn't new in r11; QC's call |
| 06–07 pause menu VI / EN | "Chơi tiếp" big on top; "Về bản đồ / To the map" smaller, lower, map icon |
| 08–09 leave card VI / EN | The card: map picture (dotted path to a hut, gold roof), the line, "Về bản đồ" left/small/cream, "Chơi tiếp" right/big/gold with ▶ |
| 10 sliding in (×0.1) | Mid-slide: the card lower and part-faded, the dim fading in |
| 11 (a) after an early tap | The card still up after a locked tap on its "Về bản đồ" |
| 12 (b) after Chơi tiếp | Back to the menu |
| 13 (c) after the card's Về bản đồ | The title |
| 14 (e) after leaving by real taps | The title |

The shots come from a run of 2035c9e's drawing code. The clock commits after it change no drawing.

## Automated results

- **GameCore** `swift test`: **164/164**: + LeaveCardTests (7) and SpecialIconTests (2), mutation-checked (a `home()`
  that leaves from pause fails 7 assertions, a `resume()` live under the card fails 1).
- **Full suite** on 8233026's tree: 34 passed (5 app + 29 UI) and 1 skipped (the opt-in Preview case).
- **Frozen Debug 86ddce0**: **29/29 UI passed**, 0 failed, 1 skipped (the opt-in Preview case, by design).
- **Frozen Preview 86ddce0**: `PreviewCheckUITests` **1/1**. The title has the hero and Start; intro box 1 shows
  `UNSIGNED C01`; there is no debug state.
- **Release check** (`tools/qa/ios-release-check.sh`, 86ddce0):
  - **Release**: A1 = A2 = B (204 `#if DEBUG` lines stripped), `d0ee4cbd…96be`, strings/nm clean, stops at R12 as
    designed.
  - **Preview**: A1 = A2 = B, `7c3fd39d…cd29`, strings/nm clean.
  - The new debug keys (`resume_frame`, `step_hist`, `leave_card`, `walk_ct`) are in the scan.

Frozen executables (86ddce0):
- Debug: `DaiDatAnhHung` `2507a081…b36d`, `DaiDatAnhHung.debug.dylib` `f08031c1…c987`.
- Preview: `DaiDatAnhHung` `f6cf0712…53d4`. The byte check's Preview hash differs because it builds in another derived-data
  path.
