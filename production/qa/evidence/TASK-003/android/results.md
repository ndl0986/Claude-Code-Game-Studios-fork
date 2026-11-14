# TASK-003 Android QC: Trần Quốc Toản mission prototype

**Overall verdict: FAIL.** One low-severity console error fails case 10 (B1). The other cases pass, apart from sound, which could not be heard (NOT ASSESSED, case 8). The gameplay, touch, quiz, language and offline criteria all pass on the emulator.

| Item | Value |
|---|---|
| Build | commit `46898b7` (branch `proto/TASK-003-mission-prototype`), tested on `qa/TASK-003-android` |
| Game | `prototypes/tqt-mission/index.html`, served by `python3 -m http.server 8000` and `adb reverse tcp:8000 tcp:8000` |
| Device | Android emulator `mp17863`: `sdk_gphone64_arm64`, **API 36**, 1080x2400 @ 420 dpi, gesture navigation, display cutout (punch-hole) on the short edge |
| Browser | Chrome 133.0.6943.137 (landscape viewport 863x304 CSS px below the toolbar, devicePixelRatio 2.625) |
| Emulator GPU | `-gpu swiftshader_indirect`. The default hardware GPU (gfxstream) gave stale `screencap` frames, so the emulator was restarted and every shot below was retaken. |
| Input | Real kernel touch events: `adb shell input tap` for single taps, and `sendevent` on `/dev/input/event1` (multi-touch protocol B, root adb) for holds, slides and two-finger input. |
| Observation | Chrome remote DevTools over `adb forward tcp:9222 localabstract:chrome_devtools_remote`. Game state was read through `window.game`. Console and network were logged to `devtools-log.txt`. |
| Real phone | None connected, so there is no low-end phone pass yet. |
| Date | 2026-11-14 |

Some screens were opened with the game's own `?scene=` / `?beat=` deep links: the EN caption and ending, the 3-star and 1-star quiz runs, the beat 4 leader, the idle hint, and the offline run. The first full run was played by touch from Title to Unlock: all 4 beats, then the quiz, giving 2 stars.

## Results

| # | Case | Steps | Expected | Actual | Result | Evidence |
|---|---|---|---|---|---|---|
| 1 | Boot and portrait overlay | Open the page in portrait, then rotate to landscape (`user_rotation 1`). | The "turn your phone" overlay shows in portrait and clears in landscape. | The overlay "Xoay ngang điện thoại nhé" shows, with an animated phone. In landscape `#rotate` is `display:none` and the title screen draws. | PASS | `tc01-portrait-overlay.png`, `tc01-landscape-title-vi.png` |
| 2 | Touch controls | Hold ▶ for 1 s, slide ▶→◀, lift. Tap Attack. Hold Defend through a telegraphed strike. Hold ◀ and tap Attack twice with a second finger. Lift. Slide off the pad and lift. Hold ▶ and press Home. | ◀ ▶ move, a slide switches direction, Defend blocks, Attack knocks back, multi-touch works, nothing stays held, taps fire on press. | Hold ▶: x 300→685. Slide: face −1, held `left`. Lift: held `[]`, x stays put. Attack: `atk` started while the finger was still down (fires on press), enemy `hurt`, hits 1, star burst. Defend: a `block` event and the shield raised. Multi-touch: held `left+attack`, 2 swings while still walking (at 0.4× speed as designed). Lift: held `[]`, x steady at 892. Slid off the pad: still held until lift, then cleared. Home mid-hold: cleared on return. | PASS | `tc02-attack-knockback.png`, `tc02-multitouch-move-plus-attack.png`, `tc05-hand-hint-defend-held.png` |
| 3 | Thumb size, gesture bar, punch-hole | Measure the canvas and pads in both landscape directions. Read the window and inset bounds from `uiautomator` and `dumpsys window`. | Buttons are thumb-sized and clear of the gesture bar and the punch-hole. | The page ends at y=1017 and the gesture bar is at 1017–1080, so nothing overlaps. Chrome letterboxes the cutout (black band at x 0–136, or on the right in reverse landscape). The pads sit inside the page. Pad size: visible Ø 67.5 CSS px (◀ ▶ Defend), Attack 77.6 CSS px; hit areas 77.6 / 89 CSS px. See O1: this is below the brief's 72 CSS px target because Chrome leaves a 304 px-tall viewport, not 360. | PASS (see O1) | `tc01-landscape-title-vi.png`, `tc03-landscape-reverse-cutout-right.png`, `tc03-play-reverse-landscape-cutout-right.png` |
| 4 | 4 beats, telegraph, knock-back, flee, no game over, dome helmets | Play all 4 beats by touch. | 4 beats; "!" warning; knock-back; the weapon drops and the enemy runs; no lives or game over; dome helmets. | 4 `beat` and 4 `caption` events, then `ending`. 12 `flee` events (2+3+4+3, all enemies). 47 unblocked hits only pushed the hero back; there are no lives, no health bar and no game over. A yellow glow and "!" show during windup. Dropped spears lie on the ground and the enemy runs off dazed. Spear soldier, shield soldier and leader all wear rounded dome helmets, none conical. | PASS | `tc04-beat1..4-fight.png`, `tc04-beat1..4-caption-vi.png`, `tc04-beat4-leader.png`, `tc04-beat4-flee-drops-weapon.png`, `tc04-ending-vi.png`, `tc05-hand-hint-defend-held.png` ("!") |
| 5 | Hints | Watch first use, then stay idle for over 5 s in walk and in a fight. | A hand on first use; after about 5 s idle, an arrow and a pulsing Attack. | The hand bobs on ▶ at start, moves to Attack when the first soldier arrives, then to Defend during the first windup. Fight stall over 5 s: a down-arrow over the nearest enemy and Attack pulses. Walk idle: ▶ pulses next to the "Đi tiếp →" arrow. See O2: the walk pulse appears right after a caption. | PASS | `tc05-hand-hint-move.png`, `tc05-hand-hint-attack.png`, `tc05-hand-hint-defend-held.png`, `tc05-stall-hint-arrow-pulsing-attack.png`, `tc05-stall-arrow-beat1.png`, `tc05-idle-hint-walk-arrow-pulse.png` |
| 6 | Quiz | Four picture questions. Run A: 2 wrong. Run B: 0 wrong. Run C: 3 wrong. Re-tap a greyed card. | Wrong answers grey out and the child can retry; 3/2/1 stars by retries; then the unlock screen. | Each question has 3 picture cards. A wrong card greys out with "Thử lại nhé!", and re-tapping it does nothing (retries unchanged). A correct card turns green with "Đúng rồi!" and stars. 0 retries gave 3 stars, 2 gave 2, 3 gave 1. "Tiếp" leads to "Mở khoá anh hùng tiếp theo!" with Chơi lại / Về bản đồ. | PASS | `tc06-quiz-q1-vi.png` … `tc06-quiz-q4-vi.png`, `tc06-quiz-q1-wrong-greyed-vi.png`, `tc06-quiz-two-wrong-greyed-vi.png`, `tc06-quiz-q1-correct-vi.png`, `tc06-results-3stars-en.png`, `tc06-results-2stars-vi.png`, `tc06-results-1star-vi.png`, `tc06-unlock-vi.png` |
| 7 | VI default, EN switch, remembered, diacritics | Clear `tqt.lang` and load. Switch VI/EN on each screen. Reload. | VI by default; EN on every screen; the choice survives a reload; diacritics are not clipped. | The page loads in VI. VI \| EN is present and works on title, intro, play, pause, caption, ending, quiz, results and unlock. After reload, `localStorage tqt.lang=en` and the title is in EN. "Ặ Ỗ Ữ ẫ ợ", "Đáp án C Ặ Ỗ Ữ ẫ ợ" and "Trần Quốc Toản" render in full, with no clipping of stacked marks. Long EN answers wrap inside their cards. | PASS (see B2) | `tc07-intro-vi.png`, `tc07-intro-en.png`, `tc07-play-en.png`, `tc07-pause-en.png`, `tc07-pause-vi.png`, `tc07-caption-en.png`, `tc07-ending-en.png`, `tc07-quiz-q1-en.png`, `tc07-unlock-en.png`, `tc07-title-en-after-reload.png`, `tc06-quiz-two-wrong-greyed-vi.png` (diacritics close-up) |
| 8 | Sound | Play beat 1 and the quiz by touch. Read the Web Audio state, count `sfx` calls, and check Android playback. | Drum, clang and chime are audible. | Signal level: AudioContext `running` at 48 kHz, gain 0.5, not muted. The drum, clang, swoosh, bonk, chime and tap effects all fire. Chrome's AAudio stream is `state:started`, `USAGE_MEDIA`, on the speaker device. **No one listened**: this session cannot hear the emulator. See B3: the first touch may be silent. | NOT ASSESSED (cannot listen; signal present) | `tc08-audio-signal.txt` |
| 9 | Offline | Log all network events over remote DevTools across 18 page loads. Then stop the server and remove `adb reverse`, and finish the quiz, results and unlock. | No network requests after load. | The only requests are at load time: page, `font.css`, `config.js`, `strings.js`, `content.js`, and the inline `data:` font. None happen during play. With the server stopped (`curl` returns 000), quiz → results (3★) → unlock still worked, with no requests and no errors. | PASS | `devtools-log.txt` (from "offline: server stopped"), `tc09-offline-unlock-after-server-stopped.png` |
| 10 | No console errors | Remote DevTools Runtime and Log events across the session. | No console errors. | There are no JS exceptions and no `console.error` from game code. There is **1 console error**: `Failed to load resource: 404 … /favicon.ico`, from Chrome's automatic favicon request (B1). There is also 1 warning, "The AudioContext was not allowed to start …" (B3). | **FAIL** (B1, low) | `devtools-log.txt` |

## Bugs (`/bug-report` format)

### B1: favicon.ico 404 is logged as a console error on load
- **Severity:** Low (S4), cosmetic. **Priority:** P3.
- **Device:** Android emulator mp17863, API 36, Chrome 133.
- **Steps:** 1. Serve `prototypes/tqt-mission/`. 2. Open `http://localhost:8000/` in Chrome with remote DevTools attached. 3. Read the Console.
- **Expected:** No console errors (TASK-003 plan review item 5: "zero console errors").
- **Actual:** `Failed to load resource: the server responded with a status of 404 (File not found) http://localhost:8000/favicon.ico`. The page has no icon link, so Chrome requests `/favicon.ico`. It appears on the first load (Chrome then caches the miss).
- **Evidence:** `devtools-log.txt`, line `14:08:03 LOG.error [network] …favicon.ico`.
- **Suggested fix:** add `<link rel="icon" href="data:,">` (or an inline SVG icon) to `<head>`.

### B2: Chrome's "Translate page? Vietnamese to English" bar covers the top of the game on every load
- **Severity:** Low (S3–S4). It is Chrome UI, not game code, but a child can tap "Translate". **Priority:** P3.
- **Device:** Android emulator mp17863, API 36, Chrome 133, system language English.
- **Steps:** 1. Load the game, in VI or EN. 2. Look at the top of the screen.
- **Expected:** Nothing covers the title or the VI \| EN button.
- **Actual:** A "Translate page? Vietnamese to English · Translate" bar shows over the title and next to the language button for several seconds. It appears even with EN chosen.
- **Evidence:** `bug-translate-bar-covers-title.png`.
- **Suggested fix:** `<html lang="vi" translate="no">` plus `<meta name="google" content="notranslate">`. The game has its own language switch.

### B3: Audio is unlocked on touch `pointerdown`, which Chrome does not treat as a user gesture
- **Severity:** Low (S3). **Priority:** P3.
- **Device:** Android emulator mp17863, API 36, Chrome 133.
- **Steps:** 1. Fresh load. 2. Tap "Bắt đầu".
- **Expected:** The AudioContext starts on the first touch, and the tap sound plays.
- **Actual:** Chrome warns "The AudioContext was not allowed to start. It must be resumed (or created) after a user gesture". `startAudio()` runs from `pointerdown`, and for touch only `pointerup`/`touchend`/`click` count as user activation. Audio is `running` after later touches, so only the first sound(s) of a session are at risk of silence.
- **Evidence:** `devtools-log.txt`, line `14:10:39 LOG.warning … AudioContext was not allowed to start`.
- **Suggested fix:** also call `startAudio()` from `pointerup` (or `touchend`) on the canvas. Keep actions on `pointerdown`.

## Observations (not failures; decisions for the leader or dev)

- **O1, pad size in Chrome.** With Chrome's toolbar, the landscape viewport on this 412-dp-tall phone is 863x304 CSS px. The canvas fits at 540x304 (scale 0.42), so ◀ ▶ Defend are 67.5 CSS px across (hit area 77.6) and Attack is 77.6 (hit area 89). The brief's "≥ 72 CSS px" assumes a 640x360 screen. They still read as thumb-sized, and are far above Android's 48 dp minimum. Requesting fullscreen on the Start tap (Fullscreen API) would give the full 412 px height and pads of about 91 CSS px.
- **O2, the idle timer runs during the caption.** `state.idle` keeps counting while a caption is open (it was 16 s when the walk resumed). After tapping "Tiếp", ▶ pulses immediately instead of after 5 s. Cosmetic.
- **O3, test environment.** The emulator's default hardware GPU (gfxstream) returned stale or mixed `screencap` frames and a flickering viewport, so I switched to swiftshader. In three runs, one tap that came 0.8 s after another right after a page load never reached the page: no `pointerdown` fired, so the game code was never reached. I treat it as emulator or Chrome-infobar timing, not a game defect. A real phone pass should watch for dropped quick taps.
- **O4, cold load time.** The first load on a cold emulator took about 9 s before sub-resources were fetched (`font.css` is 370 KB of base64). That is local server plus emulator; recheck on a real phone over the final hosting.
- **No real low-end phone** was available. Touch feel, audible sound and real-world tap latency still need a device pass.
