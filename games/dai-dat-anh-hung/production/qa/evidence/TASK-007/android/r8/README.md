# TASK-007 Android r8 pre-freeze evidence

Device: emulator-5556 (devandroid002, k ≈ 0.488, small quiz layout). Debug build, captured 2026-11-15.

| Shot | Checks |
|---|---|
| 01–02 intro VI/EN | Placeholder portrait 256 in the drum ring at x 640 (y 45–301); no hero sprite, no top stack; pause/sound only (story AC12) |
| 03–04 beat card VI/EN | Portrait 208 (y 25–233); "Phần 1 / Part 1" 28 px #FFC531 with ink outline above the panel (story AC13); no sprites/flag/dots/goal/banner |
| 05–06 caption VI/EN (sample hero, beat 2) | Portrait 256; "Phần 2 / Part 2" label |
| 07–08 ending VI/EN | No placeholder, no sprites (ending keeps its own scene) |
| 09–10 dialogue VI line 1 / EN ask line | Scene dimmed 30% (black 0.30), no play sprites or top stack; ask-hint hand still shows (dialogue AC9) |
| 11–16 quiz small layout at k 0.488, VI/EN | Choosing (cards on the Tiếp row), wrong, after right pick (right card in the left slot, why line right of it, Tiếp 450 on the bottom row ≤ 702). "Đúng rồi!/That's right!" pill: deep ink #1A120C, unclipped, no "…", drawn after the orbit stars |
| 17 quiz reference layout (`--ef padScale 0.8`, simulates k ≥ 0.534) | Why line left of Tiếp on the bottom row; Tiếp 340 (x 922–1262) |
| 18 training (banner beat) stall | Stuck arrow gold #FFC531 with ink outline, beside the dummy, away from the hero, below the bar (hud AC17) |
| 19 training partner windup (`--ez freeze true`) | "!" beside the partner's head away from the hero, fully below the bar |
| 20 reach-the-flag leader windup | "!" beside the leader's head, clear of the hammer, below the bar |
| 21 reach-the-flag encounter stall | Stuck arrow beside the enemy, below the bar |

Not captured on device: the flag arrow (the flag needs to be on screen after the encounter; placement covered by `CueLayoutTest.theArrowNeverTouchesTheBarOverADummyAnEnemyOrTheFlag`) and the 0.35 s mash timelines (covered by `EnterLockTest` AC22/AC11: each box and line holds 1.75 s). The small layout's mid-glide frame is not captured.
