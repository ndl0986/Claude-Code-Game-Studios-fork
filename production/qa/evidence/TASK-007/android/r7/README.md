# TASK-007 Android r7: developer evidence (game-dev-android)

Build **ce119bf**. APK `production/qa/builds/TASK-007-ce119bf.apk`, sha256
`658826b8559d13e3313d870abf0c9ddae1a994ddf762aa0605217315717bae26`. Unit tests **117/117, 0 skipped**.
Release gate R12 fails, as it should. Device: my AVD on emulator-5556 (k 0.488); `k040` = forced
k 0.40 (`--ef padScale 1.22`). I booted 5556 only for this pass, after QC r6 closed, and shut it down
afterwards. **Not the QC device.**

| Shot | Checks |
|---|---|
| `r7-01-B7-ending-after-4-mash-taps-vi` | **B7:** four `input tap`s on Tiếp, started 0.33 s apart, right as the ending appears. Under this host load each `input` call takes ≈ 0.5 s to launch, so the taps really arrive further apart and the last lands past the 1.5 s cap. The ending advanced **exactly one box** (to "Trần Quốc Toản đã hy sinh…"); under r6 these taps reached the quiz. The exact timeline (+1.75 and +3.50 for a 0.35 s mash) is in EnterLockTest; QC's streaming injector is the real test. |
| `r7-02-smallk-quiz-choosing-k040-vi` | **Small-k quiz while choosing:** 380 × 290 cards, prompt below the corner, no Tiếp |
| `r7-03-smallk-quiz-after-right-k040-en` | **After the right pick:** the wrong cards are gone, the right card is in the left slot, the why line on its right, Tiếp bottom-right over the spent slot 3 |
| `r7-04-smallk-quiz-wrong-k040-vi` | A wrong pick: lavender card, "Thử lại nhé!" below the cards |
| `r7-05-quiz-reference-right-vi` | The reference layout (k ≥ 0.48) is unchanged; the counter and dots sit in the free band |
| `r7-06-skipwarn-spacing-vi` | The skip-warning card holds its pad_min buttons |

Unit tests only (no screenshot): the rolling lock's timeline, a ◀ tap on Bỏ qua as a card appears
(no skip warning; QC r6 cost a medal), a lone press at +0.65 accepted and +0.55 dropped, pause
tappable inside the window, and the dialogue entry lock.
