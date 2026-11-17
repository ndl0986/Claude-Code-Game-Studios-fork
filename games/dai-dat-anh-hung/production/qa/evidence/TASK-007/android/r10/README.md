# TASK-007 Android r10 pre-freeze evidence

Device: emulator-5556 (devandroid002, pixel_7, k ≈ 0.488). Debug build. 2026-11-15.
Finish frames use `--ef slow 0.1` (0.1× sim speed), so wall-clock times below are 10× sim time.

| Shot | Checks |
|---|---|
| 01 Cờ teach hand (training special step, banner beat) | Hints Rule 6: the hand is left of Cờ at its mid-height, pointing right, wholly below the bar, off every pad |
| 02 finish +0.3 s sim | Rule 7c: every pad hidden at the Cờ tap; banner rising; partner re-entering from the right (away from the nearer screen edge) |
| 03 finish +0.8 s sim | Banner up, partner beside the hero facing him, staff upright (slice placeholder for the fist); no pads |
| 04 finish +1.7 s sim | Hold over (1.5 s): cheer stars, the 4th dot filled, walk pads only |
| 05–07 pause at +0.3 s sim, resume | Resume restarts the hold from the raise's end (once): the banner still up 0.7 s sim after the resume, then the beat ends |
| 08 camp "Ối!" (sample hero, camp fight) | hud AC15: double outline, cream inside, ink outside, readable over the mint hills |
| 09 bamboo "Ối!" | Ink-only outline unchanged on light skies |
| 10 regression | The Phần 5 card reached by real play (Cờ tap, the hold, then walking right), not via a debug stage |

Unit tests: FinishHoldTest (AC32 incl. the pause loop guard), HintLayoutTest (AC12 at k 0.40/0.488/0.517), SkyContrastTest.popStylePerTheme (AC15), TraceTest on trace 1.2 (data TASK-005s, not yet on docs).
Observation: the partner's upright staff tip reaches the bar band (weapons may pass behind the bar, hud §3.3).
