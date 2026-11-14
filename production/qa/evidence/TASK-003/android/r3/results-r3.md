# TASK-003 Android QC, re-test r3 (fix commits c7f1173 and 203d73e). STOPPED by Luan

**Status: stopped, no overall verdict.** Luan stopped TASK-003 mid-round because the game is moving to native apps (Kotlin and Swift). Every item that was run passed. One item was never run, and the smoke test was cut short. Both are marked below.

| Item | Value |
|---|---|
| Builds | Part 1: `c7f1173`, merged as `6331321`. Part 2: `203d73e` (O6 fix), merged into `qa/TASK-003-android`. |
| Device | Android emulator `mp17863`, API 36, 1080x2400 @ 420 dpi, Chrome 133, `-gpu host`. The Mac was heavily loaded by other sessions. Under `swiftshader`, the emulator's system process stopped responding (ANR) and those trials were thrown away. During part 2, something outside this session shut the emulator down at 17:29 (its log shows a graceful-shutdown request followed by a kill). |
| Method | Real kernel touch (`sendevent` multi-touch and `adb input tap`), and Chrome remote DevTools with the cache disabled. Tap sounds were counted by wrapping `tone()` from DevTools; 660 Hz is the tap tone. |
| Date | 2026-11-14 |

| Item | Result | Notes | Evidence |
|---|---|---|---|
| B4: Start goes fullscreen and locks landscape | **PASS.** 18/18 on c7f1173, and 6/6 on 203d73e | **Part 1:** 18 fresh reloads. Pre-tap delay 0–3 s. Holds of 0.03–0.5 s, plus 3 instant `input tap`s, spread across the button. All 18 went to `intro`, fullscreen, `landscape-primary`. **Part 2 spot-check:** 6 more trials (holds 0.05–0.4 s, plus 2 `input tap`s), all fullscreen and `landscape-primary`. One trial was discarded because the reload didn't happen (`before=intro/true`) and was re-run as 5b. In r2, 7 of 15 failed. | `b4-fullscreen-trials.txt`, `b4-o6-r3b-trials.txt` |
| B4 side effect: VI\|EN on the title arms fullscreen | **stopped by Luan, not run** | | |
| O5: pads clear of the bottom gesture zone in fullscreen | **PASS** | The fullscreen viewport is 915x412, with insets `b:32 l:52`. The canvas is 676x380, so its bottom edge sits at device y 998, and Android's mandatory gesture zone starts at y 996. Pad bottom edges: ◀ ▶ at y 957, Defend at 977, Attack at 945, so all four are clear of the zone. A 0.3 s tap on the lowest edge of ▶ moved the hero (x 300 → 624) and left no input held after the lift. An upward thumb slide starting in the gesture zone: the game stayed fullscreen, in play, with nothing held. The system bars weren't in the screenshot taken 0.4 s later. Trade-off: the pads shrink from 91.6 to 84.5 CSS px (Attack 97), still above 72, and the scene is letterboxed a little more. | `o5-fullscreen-measurements.txt`, `o5-fullscreen-pads-above-gesture-zone.png`, `o5-after-upward-thumb-slide-r3b.png` |
| O6: one tap tone per press | **PASS** on 203d73e | **First press right after audio starts:** in both `input tap` trials the context had just started (`running@0`) and the tone sounded **once**; on c7f1173 it sounded 2–4 times. **Long presses** (the other 5 Start trials): one call each. **Clock running:** intro Tiếp, beat-1 caption Tiếp, pause and Chơi tiếp each gave **exactly one** 660 Hz call. A quiz card gave one 660 Hz call plus the "wrong" sound (260 Hz). The movement and fight pads play no tap tone. Still not listened to by a person. | `b4-o6-r3b-trials.txt` |
| Smoke: one beat by touch, one quiz answer, 0 console errors | **Partly run** | **Beat 1 by touch:** walk, fight and flee, then the caption, all in fullscreen (22 s); the caption Tiếp led into beat 2. **Quiz Q1 by touch:** a wrong card (card 2) greys out and shows "Thử lại nhé!" The correct-answer tap was never recorded because the emulator was shut down from outside at that moment; it was then **stopped by Luan, not run**. **Console:** across 10 page loads on 203d73e there were **0** errors, **0** warnings and **0** exceptions, up to the shutdown. | `smoke-beat1-fight-touch.png`, `smoke-beat1-caption-touch.png`, `smoke-quiz-q1-wrong-card-touch.png`, `devtools-log-r3b.txt` |

## Observation

- **O8, the Start tap tone is usually silent (low, cosmetic).** Audio is started when the finger lifts (the B3 fix), but the Start tone is queued when the finger goes down. If the finger is held for longer than one frame, the tone runs before audio exists. That happened in 4 of 6 trials (`none`). Only instant taps sounded it. The first quiz tap after a page load behaves the same way. No fix is needed for the browser build. Worth keeping in mind for the native app: start audio before the first UI sound.

## Still open (not done in the browser build)

- The VI|EN side effect, and the correct-answer quiz tap (stopped by Luan).
- No real low-end phone has been tested, and no one has listened to the sound.
