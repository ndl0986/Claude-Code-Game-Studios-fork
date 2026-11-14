# TASK-007 Android r4: developer evidence (game-dev-android)

Build **c00c5e0** on `setup/TASK-007-android-kotlin`. APK `production/qa/builds/TASK-007-c00c5e0.apk`,
sha256 `107c882d97097f4c160ace140c02e1ed58491431018c1ba45724b49660721bfc`.
Device: my own AVD `devandroid002` (emulator-5556), API 36, 1080×2400 @ 420 dpi, landscape. **Not
the QC device.** Unit tests: 101/101 pass, 0 skipped (TraceTest replays `trace-tqt.json`). Release
gate: `production/qa/builds/TASK-007-release-gate.log` fails on R12 (C01–C16 pending), as it should.

Some shots are in EN, others in VI, because the language was switched between captures.
A few shots look slightly greyed. The emulator was dimming its display, so this isn't the app.

| Shot | Checks |
|---|---|
| `r4-10-B1-intro-double-tap-1..3` | **B1:** two `input tap`s on Tiếp, started together (`&` plus 0.1 s), 3 trials. Intro box 1 → **box 2** ("Năm ấy, quân Mông–Nguyên…", the line r3 skipped), never box 3. Root cause and fix in e0a24f2 (press-time debounce; `StoryDebounceTest`). QC's sendevent timings are the real test. |
| `r4-05-training-hand` | **B3b:** the attack hand points at Đánh from the upper left, in the gap, clear of Đỡ and Cờ (debug stage `teach`) |
| `r4-03-card-f1` | **B5:** no medallions beside the card heading; only the border |
| `r4-04-dialogue-ask` | "Let me in!": white label on red (4.7:1) |
| `r4-02-intro-two-lines` | Two-line story text centred at 505, clear of the picture (now ending at 440) and Tiếp |
| `r4-06-quiz-wrong` | Wrong card: #E6E1F0 fill, #9C8FB8 10 px border, circular arrow with ink outline, ink label, picture at full opacity |
| `r4-07-quiz-right` | Right card unchanged (the spec); the tick now has an ink outline |
| `r4-08-unlock` | One button, "To the map"; no Play again |
| `r4-01-title` | The map-stub line; no controls legend |
| `r4-09-title-muted-after-relaunch` | Mute → force-stop → relaunch: `shared_prefs/game.xml` has `sound=false`, and it toggles back to `true` (checked with run-as) |

Not shown (unit tests only): first-owner pad holds (Input Rule 6, `TouchAndLayoutTest`).
