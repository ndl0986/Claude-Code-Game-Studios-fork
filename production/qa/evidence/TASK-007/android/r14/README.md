# TASK-007 Android r14 pre-freeze evidence

Device: emulator-5556 (devandroid002, k ≈ 0.488), debug build.

| Shot | Checks |
|---|---|
| 01 / 01b Cờ teach hand (finishright, VI) and close-up | ASSET-033 placeholder: a child's hand in the one skin `#F1C9A0` (look sheet d18 L72), cream `#FFF6E3` sleeve cuff, ink outline kept; no white glove (spec L249 negatives). Pixel samples from 01b: palm `#F1C9A0`, cuff `#FFF6E3`. Placement unchanged (beside Cờ, clear of every pad's visible square) |
| 02 walk hint (beat 1, EN) | The same hand on the move pad |
| ref-ios-r10 | iOS r10 pre-freeze `01-hint-hand.png` (game-dev-ios's evidence, copied for comparison): still the white glove with a red cuff, so iOS has the same change to make |

Unit tests: JVM 173/173 (drawing colours only; trace 1.3 unchanged).

## W17 and W20 (folded into r14, leader's call)

| Shot | Checks |
|---|---|
| 03–04 hold-meter (beat 3, VI/EN) | W17: the special pad shows a clenched fist (skin `#F1C9A0`, ink outline, cream cuff); label still `ui.pad.special` until D-34 |
| 05 training finish | The special pad still shows the banner |
| 06–07 skip warning (VI/EN) | W20: "Đọc tiếp / Keep reading" big (440), default (pulsing) and on the RIGHT with an open-book icon; "Vẫn bỏ qua / Skip anyway" smaller (340) on the left with a skip-arrow icon; both pad_min tall. **QC note:** the two buttons swapped sides |

Unit tests: SpecialIconTest (fist on hold-meter, banner on training; mutation-checked). JVM 175/175.
