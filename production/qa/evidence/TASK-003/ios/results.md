# TASK-003 iOS QC: Trần Quốc Toản mission prototype

- Build: c7f1173 (branch `qa/TASK-003-ios`)
- Date: 2026-11-14, by game-qc-ios
- Device: Simulator "iPhone Duo" (iPhone19,4, foldable), iOS 27.1 (24A94425), Mobile Safari
- Served: `python3 -m http.server 8123` from `prototypes/tqt-mission/`. Port 8000 was already taken
  by another session's server, so I used my own port to be sure c7f1173 was tested.

**Overall verdict: NOT ASSESSED.** One check (the portrait overlay) was observed. The other cases
could not run.

## Why the cases couldn't run

1. **No notched iPhone with Dynamic Island.** iOS 27.1 runs only "iPhone Duo".
   `simctl create` refuses iPhone 16 Pro, 17 Pro and 18 Pro with "Incompatible device".
   iPhone Duo is a foldable: its inner display (2007×2853) stays black while folded, and the cover
   display (1398×2034) shows Safari.
2. **No way to rotate or tap.** Xcode 27 has no Simulator.app; Device Hub replaced it. Device Hub
   opens with no window that Orca can read, because Orca Computer Use has no macOS Accessibility
   permission. `simctl` has no rotate, tap or swipe command. So I couldn't switch to landscape,
   touch the game, or open Safari Web Inspector.

## Results

| # | Case | Steps | Expected | Actual | Result | File |
|---|---|---|---|---|---|---|
| 1a | Portrait overlay | Open localhost:8123 in portrait | Rotate overlay shows | "Xoay ngang điện thoại nhé" with the phone icon; diacritics not clipped | PASS | c1_portrait-overlay_iphone-duo-cover_ios27.1.png |
| 1b | Overlay clears in landscape | Rotate to landscape | Game shows | Couldn't rotate | NOT ASSESSED | — |
| 2 | Safe area on both landscape sides | Landscape left and right, check notch/island and home indicator | No button in an unsafe zone | No Dynamic Island iPhone on iOS 27.1, and couldn't rotate | NOT ASSESSED | — |
| 2b | Fullscreen refusal; pads ≥72 CSS px | Landscape play | No error, game plays in the window | Needs landscape plus Web Inspector | NOT ASSESSED | — |
| 3 | Controls: move, hold Defend, Attack, slide ◀/▶ | Touch | No stuck input | No touch input. Multi-touch can't be tested in the Simulator anyway | NOT ASSESSED | — |
| 4 | 4 beats, "!" warning, knockback, dome helmets, no lives | Play | As listed | Needs landscape plus touch | NOT ASSESSED | — |
| 5 | First-use hand hint; stall hint after ~5 s | Play | As listed | Needs landscape plus touch | NOT ASSESSED | — |
| 6 | Quiz, retry, stars, unlock | Play | As listed | Needs landscape plus touch | NOT ASSESSED | — |
| 7 | VI by default; EN switch kept after reload | Portrait overlay text, then the switch | VI by default | VI by default seen on the overlay; the EN switch needs touch | NOT ASSESSED (VI default only) | c1_portrait-overlay_iphone-duo-cover_ios27.1.png |
| 8 | Sound after a release gesture; no unlock warning | Tap, then Web Inspector | No warning | No touch, no Web Inspector | NOT ASSESSED | — |
| 9 | Offline, no favicon 404, no Translate prompt | Server log plus screen | Same-origin only, no favicon request | Safari fetched only `/`, font.css, config.js, strings.js and content.js, with no favicon request (the one favicon.ico 404 in the log was my own curl). No Translate prompt on screen. A real no-network run needs Web Inspector or a network toggle | NOT ASSESSED (partial observation) | c1_portrait-overlay_iphone-duo-cover_ios27.1.png |

Also kept: c1_inner-display-black_iphone-duo_ios27.1.png, the folded inner display, which is black.

## What would unblock the run

- **Option A:** Luan grants macOS Accessibility (and Screen Recording) to Orca Computer Use so I can
  drive Device Hub (rotate, tap, Web Inspector). This still tests a foldable, not a Dynamic Island
  iPhone.
- **Option B:** an older iOS runtime (for example iOS 26.x) that supports iPhone 16 Pro / 17 Pro,
  plus Option A for input.
- **Option C:** a real Dynamic Island iPhone on the Mac's network, which also covers multi-touch
  and sound.

No bugs filed: nothing was observed failing.
