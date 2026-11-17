# TASK-007 Android r14 pre-freeze evidence

Device: emulator-5556 (devandroid002, k ≈ 0.488), debug build.

| Shot | Checks |
|---|---|
| 01 / 01b Cờ teach hand (finishright, VI) and close-up | ASSET-033 placeholder: a child's hand in the one skin `#F1C9A0` (look sheet d18 L72), cream `#FFF6E3` sleeve cuff, ink outline kept; no white glove (spec L249 negatives). Pixel samples from 01b: palm `#F1C9A0`, cuff `#FFF6E3`. Placement unchanged (beside Cờ, clear of every pad's visible square) |
| 02 walk hint (beat 1, EN) | The same hand on the move pad |
| ref-ios-r10 | iOS r10 pre-freeze `01-hint-hand.png` (game-dev-ios's evidence, copied for comparison): it shows the white glove with a red cuff because it was taken before iOS's freeze. iOS's frozen r10 (760a5b2) already has the skin hand with the cream cuff (baeb0f7), so iOS needs no change. (Corrected 2026-11-17; the first version of this row said iOS still had the glove.) |

Unit tests: JVM 173/173 (drawing colours only; trace 1.3 unchanged).

## W17 and W20 (folded into r14, leader's call)

| Shot | Checks |
|---|---|
| 03–04 hold-meter (beat 3, VI/EN) | W17: the special pad shows a clenched fist (skin `#F1C9A0`, ink outline, cream cuff); label still `ui.pad.special` until D-34 |
| 05 training finish | The special pad still shows the banner |
| 06–07 skip warning (VI/EN) | W20: "Đọc tiếp / Keep reading" big (440), default (pulsing) and on the RIGHT with an open-book icon; "Vẫn bỏ qua / Skip anyway" smaller (340) on the left with a skip-arrow icon; both pad_min tall. **QC note:** the two buttons swapped sides |

Unit tests: SpecialIconTest (fist on hold-meter, banner on training; mutation-checked). JVM 175/175.

## W18 leave card (folded into r14 after the strings merged, docs 3f464b4)

| Shot | Checks |
|---|---|
| 08 pause menu (VI) | "Chơi tiếp" big on top; "Về bản đồ" smaller, lower, with a map icon (pause.md) |
| 09–10 leave card (VI/EN) | ASSET-324 card, ASSET-334 placeholder picture (a parchment map with a dotted path home), `ui.pause.leave_confirm` "Về bản đồ? / Leave the story?", "Về bản đồ / To the map" (cream, small, left, map icon), "Chơi tiếp / Keep playing" (gold, big, right, default/pulsing, ▶ icon). No red |
| 11–13 real taps | Menu "Về bản đồ" → card (11); card "Chơi tiếp" → back to the menu, run intact (12); menu → card → "Về bản đồ" → the title (13) |

**"To the map" goes to the title for now:** the map screen isn't built yet (TASK-025). This is expected; don't flag it.

The card slides up over 0.25 s and its buttons take the entry lock while it does (Input Rule 13). P/Esc and Enter on the card = "Chơi tiếp".

Unit tests: LeaveCardTest (7): the card discards nothing; Chơi tiếp returns to the menu with the run intact; only the card's Về bản đồ leaves; entry lock on its buttons; closing it doesn't relock the menu; a new pause never reopens an old card; the line in VI/EN. Mutation-checked (letting the menu leave directly fails it). JVM 182/182.
