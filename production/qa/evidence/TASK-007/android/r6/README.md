# TASK-007 Android r6: developer evidence (game-dev-android)

Build **7790ee9** on `setup/TASK-007-android-kotlin`, the base merged with 005o and safe_bottom 720.
APK `production/qa/builds/TASK-007-7790ee9.apk`, sha256
`2fed0ba265dd8ee55a41ac95b0434d9dce8a6bca270bdeb38679cf47d0b59181`. Unit tests **107/107, 0 skipped**.
Release gate R12 fails, as it should (C01–C16). Device: my own AVD on emulator-5556 (k 0.488). Shots
marked k040 force k 0.40 with the debug extra `--ef padScale 1.22`, which draws pad_min as on a
k 0.40 phone. **Not the QC device.**

| Shot | Checks |
|---|---|
| `r6-00-title-fresh-install-vi` | **D-27 title** (after `pm clear`): title row (1 line, no emblems), hero card (determined portrait, name only, **3 outline stars, outline medal**), Start at pad_min, map stub and debug line stacked; sound top-left, chip at pad_min |
| `r6-01-title-vi` | The same with saved progress: best stars and medal from the store |
| `r6-13-title-k040-vi` | Title at k 0.40: corner and chip grow, still stacked (safe_bottom 720) |
| `r6-03-intro-en` | **B6:** intro full-bleed; the text panel bottom-anchored above the bottom row; Skip left and Next right, both pad_min |
| `r6-04-card-vi`, `r6-15-card-k040-en` | **B6:** beat card bottom-anchored, top below corner_bottom + 8 (also at k 0.40) |
| `r6-05-dialogue-line1-vi`, `r6-06-dialogue-ask-en`, `r6-16-dialogue-k040-vi` | The heading **inside** the dialogue panel (line 1); the portrait fits the panel; the ask button at pad_min |
| `r6-14-training-k040-en` | **Narrow plates** at k 0.40: start = corner right + 8, width 1270 − start, text box 720; EN banner 2 lines with ink outline `#3A2A20` |
| `r6-12-encounter-en` | Banner gold text with ink outline; pops outlined (ink on light skies) |
| `r6-17-AC13-contact-slow`, `r6-18-AC13-after-push-slow` | **AC13** (`--ef slow 0.08`, render-only): the spear tip on the hero's chest for 3 frames, then the push |
| `r6-07-quiz-right-vi` | Quiz: prompt below the corner, "Đúng rồi!" pill inside the right card, Tiếp at pad_min |
| `r6-02-results-en-2stars-medal`, `r6-08-results-vi`, `r6-09-unlock-vi` | pad_min Next / To the map |
| `r6-10-pause-vi`, `r6-11-skipwarn-vi` | pad_min buttons. **Known (r7):** the skip-warning buttons now reach the card's bottom edge (cosmetic) |

Also: the text line pitch is now exactly 1.35 × font size (it was ≈ 1.85 × through StaticLayout), so
on-screen wrapping matches R8c and the specs. Not in r6: the quiz small-k layout (0.40 ≤ k < 0.48,
design/quiz-small-k), planned for r7.
