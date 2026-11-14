# TASK-003 iOS QC, run r1: STOPPED by Luan

- Build: 203d73e, merged into `qa/TASK-003-ios`
- Date: 2026-11-14, by game-qc-ios
- Device: Simulator "iPhone Duo" (iPhone19,4), iOS 27.1 (24A94425), Mobile Safari, cover display,
  landscape. Driven through Device Hub with `orca computer`; Safari Web Inspector on the Mac was
  attached through the Develop menu.
- Served: `python3 -m http.server 8123` from `prototypes/tqt-mission/`, opened as
  `localhost:8123/?v=203d73e` so Safari would not use a cached copy.
- **Run stopped part-way by Luan's order** (the game moves to native Swift/SpriteKit). Unfinished
  cases are marked "stopped by Luan, not run".

**Overall: NOT ASSESSED (stopped).** Nothing observed failed.

**Caveat for every safe-area result:** it comes from a foldable's cover display with a punch-hole
camera, not from a Dynamic Island iPhone. iOS 27.1 only runs the iPhone Duo.

| # | Case | Steps | Expected | Actual | Result | File |
|---|---|---|---|---|---|---|
| 1 | Boot; portrait overlay; clears in landscape | Open, rotate portrait → landscape → portrait → the other landscape | Overlay in portrait only | Overlay shows in portrait ("Xoay ngang điện thoại nhé"). The title screen shows in both landscape directions | PASS | c1_landscape-title_camera-right.png, c1b_portrait-again.png, ../c1_portrait-overlay_iphone-duo-cover_ios27.1.png |
| 2 | Safe area on both landscape sides | Both landscape directions; Web Inspector: `insets()`, canvas style, `ui` pad boxes | Nothing under the camera or the home indicator | Safari keeps its web view clear of the camera and puts its own controls on the camera side, so `env(safe-area-inset-*)` = 0 on every side. Viewport 594×368 CSS px; canvas 594×334 at top 16, fully inside. Every pad box lies inside the viewport. The camera and Safari's controls sit outside the canvas on both sides | **Partial PASS** (foldable cover display, not Dynamic Island) | c2_safe-area_landscape-camera-left_frame.png, c1_landscape-title_camera-right.png |
| 2b | Fullscreen refused; pads ≥72 CSS px | Web Inspector | Plays in the window, no error | `document.fullscreenEnabled` = false, no fullscreen element, game plays in the window. Pads measured in CSS px: ◀ 74.3, ▶ 74.3, Defend 74.3, Attack 85.4. The console was not checked for errors | PASS (pads, plays in the window); console not checked | c4_play-start.png |
| 3 | Controls | Single taps on ▶ ×5, ◀→▶ slides ×3, then Attack, ▶ and Defend once each | Move, hold, attack, slide; nothing stuck | Taps on ▶ move the hero (hero.x 344, then further right). Pads release after each tap (no pad stays lit). Orca's drags are too fast to tell whether sliding works. Hold-Defend: stopped by Luan, not run. Real multi-touch can't be done in the Simulator | Partial (no stuck input seen); rest stopped by Luan, not run; multi-touch NOT ASSESSED | c3a_after-5-taps-right.png, c3b_slide-left-to-right_x3.png, c3c_after-attack-right-defend.png |
| 4 | 4 beats, "!" warning, knockback, dome helmets, no lives | — | — | — | Stopped by Luan, not run | — |
| 5 | Hand on first use; stall hint after ~5 s | Start play; leave it idle | Hand, then a pulse | Hand pointing at ▶ on first entry, gone after the first move. After an idle gap the ▶ pad pulses with a gold ring | PASS (as observed; the 5 s timing was not measured) | c4_play-start.png, c3c_after-attack-right-defend.png |
| 6 | Quiz, retry, stars, unlock | — | — | — | Stopped by Luan, not run | — |
| 7 | VI default; EN switch kept after reload; diacritics | Look at the screens | VI by default | `lang` = vi. Vietnamese diacritics render unclipped on the title, intro (including the Ặ Ỗ Ữ ẫ ợ stress text) and pads. EN switch and reload: stopped by Luan, not run | Partial PASS (VI default, diacritics) | c1_landscape-title_camera-right.png, c3_after-start_t1s.png |
| 8 | Sound after a release gesture; one tone per press | Web Inspector: AudioContext state; count tone() calls | Running after a gesture; 1 tone per press | AudioContext `running` after the first taps (Start / Tiếp). I had wrapped `tone()` with a counter in the console, but Mac Safari quit before I could read it. Hearing it: NOT ASSESSED | Partial (unlock OK); tone count stopped by Luan, not run | — |
| 9 | Offline / no favicon 404 / no Translate prompt | Server log, screen | Same-origin files only | The server log for the ?v=203d73e load shows `/`, font.css, config.js, strings.js and content.js only: no favicon request, no other host. No Translate prompt seen. A real no-network run: stopped by Luan, not run | Partial (same-origin, no favicon, no Translate) | — |

## Notes

- The Mac's Safari, which hosted Web Inspector, quit once during the run with no crash report found.
  I reopened it and the simulator page was unaffected.
- Port 8000 is held by another session's server, so this run used 8123.
- The `content.js?qc=…` lines in the server log are my Web Inspector read-outs, not game traffic.
- No bugs filed.
