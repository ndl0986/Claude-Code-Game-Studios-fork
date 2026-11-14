# TASK-003 Android QC, re-test r2 (fix commit 4b70244)

**Overall verdict: FAIL.** One new medium bug: **B4**, where fullscreen happens only on some Start taps. All three original bugs are fixed (B1, B2, B3 PASS), O2 is fixed, and the regression over cases 1–7 and 9 passes. The O1 fallback works: the pads measure at least 72 CSS px when fullscreen does not happen. Sound is still NOT ASSESSED for listening.

| Item | Value |
|---|---|
| Build | `4b70244` (on top of `46898b7`), merged into `qa/TASK-003-android` as `a71406b`. First-run evidence kept in the parent folder. |
| Device | Android emulator `mp17863`, API 36, 1080x2400 @ 420 dpi, gesture navigation, left punch-hole. Chrome 133.0.6943.137. `-gpu swiftshader_indirect`. |
| Method | As in r1: real kernel touch (`sendevent` multi-touch and `adb input tap`), Chrome remote DevTools with **cache disabled**, a fresh tab, 20 page loads. Some screens were opened with the game's `?scene=` deep links. |
| Date | 2026-11-14 |

## Fix re-tests

| Item | Steps | Expected | Actual | Result | Evidence |
|---|---|---|---|---|---|
| B1: favicon 404 / case 10 | Load in a fresh tab with the cache disabled, then reload 19 more times while playing every screen. Watch DevTools Log, Runtime and Network. | No favicon request and no console errors. | `<link rel="icon" href="data:,">` is present. No `/favicon.ico` request. **0** console errors, **0** warnings, **0** exceptions across 20 loads. | PASS | `devtools-log-r2.txt` |
| B2: Translate bar | Load in VI (portrait and landscape), switch to EN, reload, and wait more than 4 s each time. | No "Translate page?" bar. | `<html translate="no">` plus `meta google notranslate`. No bar in VI or EN, before or after reload. | PASS | `b2-no-translate-bar-vi-portrait.png`, `tc01-landscape-title-vi-toolbar.png`, `b2-no-translate-bar-en-after-reload.png`, `tc07-title-en-after-reload.png` |
| B3: audio from the first real tap | Fresh load, then one real touch on Bắt đầu. | AudioContext running after the first tap, and no "not allowed to start" warning. | `audio.ac.state = running` right after the first tap. The Start tap sound (`sfx.tap`) ran with the context already running. No autoplay warning in 20 loads. Listening is still not possible (case 8 stays NOT ASSESSED). | PASS | `devtools-log-r2.txt` |
| O1a: Start goes fullscreen and locks landscape | 15 fresh loads, one real touch on Bắt đầu each, holds of 0.06–0.3 s. | Every real tap goes fullscreen with orientation locked to landscape. | **Only some taps.** When it works: fullscreen 915x412, `landscape-primary`, pads 91.6 CSS px (Attack 105). In **7 of 15 taps** the game had already switched to `intro` before the finger lifted, so `gesture()` skipped the request and the game stayed in the browser window. → **B4** | **FAIL** (B4) | `o1-fullscreen-and-pads-measurements.txt`, `o1-fullscreen-intro-after-first-tap.png`, `o1-android-fullscreen-notice-first-time.png`, `tc07-pause-en.png` (toolbar after a tap that didn't go fullscreen) |
| O1b: pads with the toolbar shown | When fullscreen didn't happen: viewport 863x304, measure the pads. | ◀ ▶ Defend are at least 72 CSS px. | ◀ ▶ Defend are **72.0** CSS px (hit area 82.8). Attack is 77.7 (hit area 89.3). They still sit inside the page and clear the gesture bar. | PASS | `o1-pads-min72-toolbar-shown.png`, `o1-fullscreen-and-pads-measurements.txt` |
| O2: idle pulse after a caption | Open the beat 1 caption, tap Tiếp, then wait. | The ▶ pulse waits about 5 s after the caption closes. | `state.idle` was 1.9 s at 1.5 s with no pulse, and 7.1 s at 6 s with ▶ pulsing. The counter resets when the caption closes. | PASS | `o2-walk-2s-after-caption-no-pulse.png`, `o2-walk-6s-after-caption-pulse.png` |

## Regression, cases 1–7 and 9

| # | Case | Actual | Result | Evidence |
|---|---|---|---|---|
| 1 | Portrait overlay and landscape | The overlay shows in portrait and clears in landscape. | PASS | `tc01-portrait-overlay.png`, `tc01-landscape-title-vi.png` |
| 2 | Touch controls | **In fullscreen:** hold ▶ moves, ▶→◀ slide turns, and lift clears. **In toolbar mode:** hold ▶, slide to ◀, a second finger on Attack swings while walking (`left+attack`, swing), and both lifts leave nothing held. All 4 beats were played by touch: 56 blocks, 12 pushes, no stuck input. | PASS | `o1-fullscreen-and-pads-measurements.txt` (multi-touch samples), `tc04-beat*-fight.png` |
| 3 | Gesture bar and punch-hole | **Toolbar mode:** the page ends above the gesture bar and Chrome letterboxes the cutout. **Fullscreen:** the cutout inset is respected (left 52 CSS px). The lower ~24% of the pads sits in Android's system-gesture zone; taps there still register (see O5). | PASS (see O5) | `o1-pads-min72-toolbar-shown.png`, `tc05-hand-hint-move-fullscreen.png`, `o5-after-upward-thumb-slide-in-gesture-zone.png` |
| 4 | 4 beats, telegraph, knock-back, flee, no game over, dome helmets | Fullscreen touch run: 4 beats, 4 captions, ending. 12/12 soldiers dropped their weapons and fled. "!" glow on windup. The leader is shown. No lives or game over. Dome helmets throughout. | PASS | `tc04-beat1..4-fight.png`, `tc04-beat1-flee-drops-weapon.png`, `tc04-beat4-leader.png`, `tc04-beat1..4-caption.png`, `tc04-ending-vi.png` |
| 5 | Hints | The hand bobs on ▶ at start, and the hand and pulse hints still show. O2 is covered above. | PASS | `tc05-hand-hint-move-fullscreen.png`, `o2-walk-6s-after-caption-pulse.png` |
| 6 | Quiz | A wrong card greys and re-tapping it does nothing. 0, 2 and 3 retries gave 3, 2 and 1 stars, then the unlock screen. | PASS | `tc06-quiz-q1-vi.png`, `tc06-quiz-q1-wrong-greyed-vi.png`, `tc06-quiz-two-wrong-greyed-vi.png`, `tc06-results-3stars-en.png`, `tc06-results-2stars-vi.png`, `tc06-results-1star-vi.png`, `tc06-unlock-vi-offline.png` |
| 7 | VI default, EN switch, remembered, diacritics | VI on a fresh load. EN on title, intro, play, pause, caption, quiz, results and unlock. EN remembered after reload. "Ặ Ỗ Ữ ẫ ợ" not clipped. | PASS | `tc07-intro-vi-fullscreen.png`, `tc07-intro-en.png`, `tc07-play-en.png`, `tc07-pause-en.png`, `tc07-caption-en.png`, `tc07-quiz-q1-en.png`, `tc07-unlock-en.png`, `tc07-title-en-after-reload.png` |
| 9 | Offline | Server stopped and `adb reverse` removed at 14:46:41. The quiz (2★), results and unlock still worked, and the log shows no requests after that point. | PASS | `devtools-log-r2.txt` (after "offline: server stopped"), `tc06-unlock-vi-offline.png` |
| 8 | Sound (not re-run in full) | Context running from the first tap; still not listened to. | NOT ASSESSED (cannot listen) | — |

## New bug (`/bug-report` format)

### B4: The Start tap goes fullscreen only some of the time (race between finger-down and finger-up)
- **Severity:** Medium (S2–S3). Half of all players stay in the browser window with the toolbar, and get the smaller 72 px pads instead of 92 px. **Priority:** P2.
- **Device:** Android emulator mp17863, API 36, Chrome 133.
- **Steps:** 1. Load the game fresh, in landscape. 2. Tap "Bắt đầu" once with a normal finger tap (0.06–0.3 s). 3. Repeat after reloading.
- **Expected:** Every real tap on Bắt đầu enters fullscreen and locks to landscape.
- **Actual:** 7 of 15 taps stayed in the browser window. Start fires on `pointerdown`, and the next fixed step switches the scene to `intro`. `gesture()` runs on `pointerup` and requires `scene === 'title'`. If a step lands between finger-down and finger-up (any hold longer than about one frame, and it depends on timing), the condition is false and `requestFullscreen` is never called. The hold length doesn't predict it: 0.06 s failed once and 0.3 s succeeded once.
- **Evidence:** `o1-fullscreen-and-pads-measurements.txt` (`sceneAtUp: intro` ⇒ `fs: false` every time), `tc07-pause-en.png`.
- **Suggested fix:** decide on `pointerdown`, act on `pointerup`. In the canvas `pointerdown` handler, set `wantFs = scene === 'title' && !document.fullscreenElement` before the tap is queued. In `gesture()`, test `wantFs` instead of `scene === 'title'`, then clear it.

## Observations

- **O5, fullscreen bottom gesture zone.** With the nav bar hidden, `safe-area-inset-bottom` is 0, but Android keeps a mandatory system-gesture zone across the bottom 84 device px (32 CSS px). The lower ~24% of ◀ ▶ Defend sits in it. Taps and holds there reach the game: tested with hold, slide and lift. A thumb sliding upward from the bottom edge makes the system bars appear translucently over the HUD. The game stays fullscreen and keeps playing, and the bars auto-hide. This is low impact and normal immersive-mode behaviour. Raising the pads by about 30 CSS px in fullscreen would avoid it.
- **O6, double tap tone (pre-existing, not from this fix).** Every menu button plays `sfx.tap` twice: once from the tap loop (`for (const f of taps) { sfx.tap(); f(); }`) and once inside the handler (`startIntro`, `next`, `captionNext`). Cosmetic: two identical tones at the same moment.
- **O7, system notices on the first fullscreen.** Android shows a one-time "Viewing full screen" dialog that needs "Got it", and Chrome shows a "Drag from top… to exit full screen" toast over the Tiếp button for a few seconds. Both are system UI. A child may need help the very first time.
- **Still open:** no real low-end phone pass, and no one has listened to the sound.
