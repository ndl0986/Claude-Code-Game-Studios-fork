# Developer pre-freeze pass for iOS r6 (not QC evidence)

game-dev-ios's run-and-observe check before freezing r6, on its own Simulator "iPhone 18 Pro – dev-ios"
(iOS 27.0, FB836E51-D39E-42C3-A60E-96159EE6516C), headless, shut down afterwards. QC's device was not used.
Screens via debug launch arguments; saved progress via `simctl spawn … defaults write` (stars, medal).

**Input Rule 1 is now built:** the 1280×720 world is fitted to the safe rect (k 0.529 on the 18 Pro), and
the backdrop (sky band, ground) runs on into the Dynamic Island side areas; story screens keep the night colour.

| Shot | Checks |
|---|---|
| 00–02 title fresh VI / 2★ EN / 3★ + medal VI | D-27 hero card: portrait in a drum-ring frame, name, best stars (outline → filled), medal (outline → gold); title row 56/800 with no emblems; no standing hero; Start at top 375; map stub and debug line under it; the VI\|EN chip at pad_min (title.md 5.2, AC4–4d) |
| 03 intro VI | Full-bleed story picture (P-06), text panel bottom-anchored above Tiếp, Bỏ qua as tall as Tiếp on one row (story-screens 5.2, AC10) |
| 04 beat card EN | Card panel H 235 bottom-anchored, the title row inside its top, "Part 1" above it, below the corner block |
| 05–06 dialogue VI line 1 / EN ask | Title inside the panel on line 1; speaker panel with the portrait (256) bottom-aligned on the speaker's side; the ask button in Tiếp's slot with the hint hand off its label (dialogue.md 5.2) |
| 07 training EN | Banner text 2 lines inside the 112 bar (R5-01 fixed: line height 1.35 × size) with an ink outline (hud 3.3 AC16) |
| 08 finish VI | `-stage finish`: the finish step with W12's full pad set (+ Cờ) |
| 09 blocks EN, 10 camp VI | Pops beside the head with a per-theme outline: ink on light skies, cream on the camp (hud 3.3 AC15) |
| 11 ending EN | Full-bleed picture, bottom panel |
| 12–15 quiz, results, unlock, pause | Quiz counter beside the dots; unlock names "Anh hùng mới" (sample, N3); pause and sound/chip as before |
| 16–18 strike contact (video frames at 60 fps, 3.250 / 3.267 / 3.283 s) | The padded tip on the hero's chest for 2 frames (≈ 33 ms), then the pushed pose and flash (Combat V/A, hud AC13; render-only) |

Automated at this tip: GameCore 105/105 (`swift test`); app unit 4/4 and UI touch cases 5/5 (`xcodebuild
test-without-building`, own Simulator): R2-03 per pad, the ◀→▶ slide, holding ▶ across a beat change, B1
(measured press gap), 15b holding ▶ 5 s.
