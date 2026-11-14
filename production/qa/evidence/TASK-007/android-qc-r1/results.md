# TASK-007 Android QC, round 1 (native Kotlin slice, bfe3890). IN PROGRESS

**Status: in progress.** This is a partial commit at the leader's request. Cases not finished are marked "not run yet".

| Item | Value |
|---|---|
| Build | `bfe3890` on `setup/TASK-007-android-kotlin`. `app-debug.apk`, sha256 `397a4622d733ac71…`, versionName 0.1.0, minSdk 26, targetSdk 35. |
| Permissions | None requested. `aapt2 dump permissions` lists no INTERNET permission. |
| Device | Android emulator `mp17863`, API 36, 1080x2400 at 420 dpi, gesture navigation, display cutout on the left (136 px in landscape 90°), `-gpu host`. |
| Method | Real kernel multi-touch via `sendevent` (`mt.py`/`wt.py`: world 1280x720 to screen px). 60 fps `screenrecord`, with each frame read with its timestamp by a Swift AVAssetReader tool. Screenshots. `run-as` to read the saved prefs. A clean install, then `pm clear`. |
| Date | 2026-11-14 |

| # | Case | Result | Notes | Evidence |
|---|---|---|---|---|
| 1 | Title, VI/EN, remembered, diacritics | **PASS** (so far) | VI on a fresh install. VI\|EN fires **on release** (held 0.8 s it stays VI, and lifting switches it to EN). Sliding off the button before lifting does **not** fire. After `force-stop` and relaunch, EN is remembered (`shared_prefs/game.xml` holds only `lang=en`). "Dải Đất Anh Hùng" and the intro lines (ặ, ữ, ỏ, ố) are not clipped. The EN check of later screens has not been run yet. | `tc01-title-vi-fresh.png`, `tc01-title-en-after-release.png`, `tc01-title-en-remembered-after-relaunch.png` |
| 2 | Intro, fights, captions, ending, quiz, results | **FAIL** (B1). The rest has not been run yet. | The intro shows 7 boxes, and a single tap advances one box. **Two taps within 0.25 s advance two boxes** (mission-flow AC9), 3 of 3 times: box 1 → 3, 4 → 6, and 6 → straight into play, skipping box 7. The fights, captions, ending, quiz and results haven't been played through yet. | `tc02-intro-box1-vi.png`, `tc02-intro-after-double-tap.png` |
| 3 | Touch | **Partial PASS** | Holding ▶ while a second finger taps Attack: the hero keeps walking and the pad lights for the swing; no input stayed held after both lifts. The ▶→◀ slide and the slide-off were recorded but not yet analysed. Home, the upward gesture swipe, menu-vs-pad firing and one tone per press have not been run yet. | `tc03-multitouch-hold-right-plus-attack.png` |
| 4 | Combat rules | **PASS** for the items measured. The leader timing has not been run yet. | **Telegraph:** the first "!" frame is at 4.038 s and the strike ("Ối!") is at 5.138 s, so **1.100 s**. The frame at 5.122 s still shows the windup. **Unblocked strike:** the hero is pushed and flashes. **Held defend:** blocked, with "Đỡ được!" and no push (natural play at 11.29 s, and the debug telegraph stage). **Press-and-release during the windup** (0.3 s press, released about 0.5 s before the strike): **not** blocked ("Ối!"), as AC15 requires. **Attack tapped while defending:** no swing while the shield is up (AC10). The exact AC18 next-frame case can't be timed by touch and is covered by unit tests. Not run yet: the leader's 1.32 s, flee, no lives across the 4 fights. | `tc04-telegraph-*.png`, `tc04-held-defend-blocks-t11.29.png`, `tc04-telegraph-stage-held-defend-blocked.png`, `tc04-press-release-defend-*.png` |
| 5 | Hints | **Partial PASS** | The hand is on ▶ at the start and gone once the hero moves. The hand appears above Attack when the first enemy shows, and above Defend during a windup before the first block. The stall arrow over the enemy plus the Attack pulse appear after idling. The ~5 s stall timing and the reset on resume have not been run yet. | `tc05-hand-on-right-pad-start.png` |
| 6 | Layout, letterbox | not run yet (measurements are below) | | |
| 7 | Pause, background/resume, rotation | not run yet | | |
| 8 | Sound | not run yet. NOT ASSESSED for hearing. | | |
| 9 | Offline, logcat | not run yet (the APK has no INTERNET permission) | | |
| 10 | Release gate (build log) | not run yet | | |

## Bug

### B1: Two quick taps on "Tiếp" skip a story box (mission-flow AC9)
- **Severity:** Medium (S3). A child who double-taps misses part of the story; the last intro box can be skipped straight into play. **Priority:** P2.
- **Build / device:** bfe3890 debug, emulator mp17863 API 36.
- **Steps:** 1. Start, which opens intro box 1. 2. Tap "Tiếp" twice, 0.15–0.2 s apart (each touch 0.05 s).
- **Expected:** Only one box advances (AC9: two taps within 0.25 s, one box).
- **Actual:** Two boxes advance, 3 of 3 times (1 → 3, 4 → 6, 6 → play, skipping box 7). A single tap advances exactly one box (3 → 4).
- **Evidence:** `tc02-intro-box1-vi.png` (box 1), `tc02-intro-after-double-tap.png` (box 3).
- **Likely cause (from reading bfe3890):** in `GameView.drainInput`, the `firedThisFrame` guard only applies to quiz cards (`key.startsWith("card")`) and only within one frame. `Game.next()` has no 0.25 s debounce.

## Observations so far

- **The UNSIGNED badge covers story text** (debug only). On the intro boxes the `UNSIGNED Cxx` badge sits on the first text line (for example, it hides "Trần, có một" on box 1). This matters if the history reviewer reads debug builds. Suggestion: draw the badge above the picture or at the line end.
- **Letterbox** (measured; judgement to follow in case 6): the safe rect is the cutout (left 136), the status bar ignoring visibility (top 74) and the gesture zone (bottom 84). World scale k = 1.281, so the world is 1639x922 px at x 448–2088, y 74–996. Bands are 448 px on the left and 312 px on the right. **The game uses 68% of the screen width and 58% of its area.**
- **Debug `startScreen` extras are ignored when the app is already running** (the intent is delivered to the existing activity). QC must `force-stop` first. This only affects tooling.
