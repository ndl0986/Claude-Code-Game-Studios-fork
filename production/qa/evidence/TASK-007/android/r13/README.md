# TASK-007 Android r13 pre-freeze evidence

Device: emulator-5556 (devandroid002, k ≈ 0.488), debug build.

| Shot | Checks |
|---|---|
| 01 / 01b finishright hold (slow 0.1), close-up | Skin `#F1C9A0` (look sheet d18: one skin for everyone). Pixel sample of the partner's face: `#F1C9A0`. Partner still 0.62 × the hero, banner clear of its face |
| 02 pause screen | Regression |
| 03–05 pause during the finish hold, resume (normal speed) | Paused mid-hold; after "Chơi tiếp" the banner is up (hold restarted at the end of the rise), then the camp |

Resume timing (iOS r10 N1 parity): a screen capture can't resolve 33 ms, so the exact claim is proven by FrameClockTest on synthetic 60 Hz vsyncs. A long paused frame leaves 0.9 STEP in the accumulator; the resume frame runs no step; the hold ends **exactly** on frame 50 after the resume frame (0.833 s), never early. Making `resumed()` a no-op fails 3 of 6 tests.

Unit tests: JVM 171/171 (FrameClockTest 6 new). TraceTest (trace 1.3) is byte-identical: the change is in the app's frame loop and colours only.
