# TASK-007 Android r14 pre-freeze evidence

Device: emulator-5556 (devandroid002, k ≈ 0.488), debug build.

| Shot | Checks |
|---|---|
| 01 / 01b Cờ teach hand (finishright, VI) and close-up | ASSET-033 placeholder: a child's hand in the one skin `#F1C9A0` (look sheet d18 L72), cream `#FFF6E3` sleeve cuff, ink outline kept; no white glove (spec L249 negatives). Pixel samples from 01b: palm `#F1C9A0`, cuff `#FFF6E3`. Placement unchanged (beside Cờ, clear of every pad's visible square) |
| 02 walk hint (beat 1, EN) | The same hand on the move pad |
| ref-ios-r10 | iOS r10 pre-freeze `01-hint-hand.png` (game-dev-ios's evidence, copied for comparison): still the white glove with a red cuff, so iOS has the same change to make |

Unit tests: JVM 173/173 (drawing colours only; trace 1.3 unchanged).
