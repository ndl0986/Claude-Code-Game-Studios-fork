# TASK-007 Android r11 pre-freeze evidence (QC r10 B8)

Device: emulator-5556 (devandroid002, k ≈ 0.488). Debug build. Finish frames at `--ef slow 0.1` (wall time = 10 × sim).
Debug stages (screenshots only): `--es stage finishright` puts the hero at screen x 1045 facing right at the Cờ step (QC's measured real-flow position, x ≈ 1000–1090); `finishleft` at screen x 100 facing left (AC33 case d).

| Shot | Checks |
|---|---|
| 01–03 front case (hero 1045, facing right) | Partner starts 1.2 × enemy_reach right of its spot (off screen, no fade), walks in linearly, stands 110 in front of the hero, faces the banner (left); no overlap with the cloth or the hero |
| 04–06 case (d) (hero 100, facing left; banner on his right) | Front (left) doesn't fit, so the partner stands beyond the banner (right), ≥ 8 clear of the cloth; starts on screen, so it fades in (0.1 s sim: half-faded), then faces the banner (left) |
| 07 the hold's end | Cheer, walk pads; no straw dummies over the next beat's night sky (AC34) |

Unit tests: FinishHoldTest (both edges × both facings, every-resume restart with N = 5, dummies cleared), TraceTest on trace 1.3 (data TASK-005t, branch only).
