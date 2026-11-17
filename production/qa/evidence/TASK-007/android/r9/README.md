# TASK-007 Android r9 pre-freeze evidence

Device: emulator-5556 (devandroid002, pixel_7, k ≈ 0.488). Debug build. 2026-11-15.

| Shot | Checks |
|---|---|
| 01–04 pops (sample hero fights: village, bamboo, river, camp) | "Ối!" outline from the sky band (SkyContrast): ink on village/bamboo/river, cream on the camp night sky |
| 05 reach-the-flag (`--es stage flag`, debug: past the encounter, idle) | Goal flag 120, box y 290–470, wholly below the motto bar; stuck arrow gold, beside the flag |
| 06 training finish (`--es stage special --ef slow 0.1`, then a tap on Cờ) | Raised banner held lower beside the hero (top ≥ 276), clear of his head (offset 125 on banner beats) |
| 07–08 ending VI/EN | `pic.scene_tqt_ending` full-bleed, no tint; cloth and sun above the panel |
| 09 regression: quiz small layout (k 0.488) right pick, EN | Unchanged from r8: right card left, why line right, Tiếp 450 on the bottom row; pill unclipped |
| 10 regression: dialogue mash | From line 1 (lock already passed), 16 taps on Tiếp/ask in 3.72 s (≈ 0.23 s apart): ends on line 4, so 3 advances (≈ 1.75 s each), not ≈ 8 |

Found in the pass and fixed before the freeze: at the lower height the raised banner's cloth covered the hero's face (offset 60); it now sits 125 behind him (CueLayoutTest.theRaisedBannerClearsTheHerosHead).
Noted, not changed (hints are outside the r8 bar rule): the special-pad hint hand above "Cờ" reaches into the bar band.
