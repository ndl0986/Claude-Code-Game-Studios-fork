# TASK-007 Android r12 pre-freeze evidence

Device: emulator-5556 (devandroid002, k ≈ 0.488), debug build. Training finish frames at `--ef slow 0.1` (wall time = 10 × sim), tap at t = 0.
Debug stages: `--es startScreen play --ei beat 4 --es stage finishright` (hero at screen x 1045, facing right) / `finishleft` (x 100, facing left).

| Shot | Checks |
|---|---|
| 01 finishright before the tap | Cờ teach hand beside Cờ, clear of every pad's visible square (Hints Rule 6, docs 0f90158) |
| 02–04 finishright rise and hold | Banner: plain vermilion `#D64A2E` cloth, ≈ 4 px gold `#E8A93B` border, behind the hero (125), risen. Partner: a d18 follower (straw-beige tunic, muted-vermilion sash, plain topknot, no headband), **0.62 × the hero's height** (on screen ≈ 143 vs 231 px), 110 in front, faces the banner, staff upright; **the cloth never covers its face** (r10 B8) |
| 05 hold, last frame (t 14.9 s) | Still the training scene |
| 06–07 camp (t 15.3, 16.0 s) | **Camera cut in the same update** as the beat change: the first camp frame already has the hero in view at the same screen x as later frames (no catch-up pan); FinishHoldTest proves the same-update cut |
| 08–09 camp | Cheer, walk pads, no straw dummies on the night sky |
| 10–12 finishleft (EN) | Front doesn't fit, so the partner fades in and stands beyond the banner, clear of the cloth, facing it |
| 13–14 ending VI/EN | Full-bleed ending still; pole clear of the pause/sound block (r11) |
| 15–17 quiz | q1 VI; q2 wrong EN (shake, "Try again!"); q3 right VI |
| 18 results | Debug results (3 stars, new medal) shown from memory |
| 19 play beat 1 | Regression |
| save-01/02, prefs XML | **Debug jumps write no progress** (parity with iOS r9). Fresh install; jumps to results (newmedal), quiz past the end, unlock and title (lang en); then a normal launch. The title shows 0 stars and no medal. The save holds only `lang` (still saved, as on iOS) and `seen_open` (written by the normal launch's title load) |

Unit tests (JVM 165/165): FigureScaleTest (partner 0.62 × hero), DebugSaveTest (a jumped quiz answered 5/5 and a jumped run carried to results write nothing; every jump target; language and sound still saved; a real run still writes stars, medal and completed), FinishHoldTest, TraceTest (trace 1.3, byte-identical).
