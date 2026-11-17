# Developer pre-freeze pass for iOS r7 (not QC evidence)

game-dev-ios's run-and-observe check before freezing r7, on its own Simulator "iPhone 18 Pro – dev-ios"
(iOS 27.0, FB836E51-D39E-42C3-A60E-96159EE6516C, k 0.529), shut down afterwards. QC's device was not used.
Screens via debug launch arguments (`-startScreen … -q N -stage … -lang vi|en`; title with `-resetProgress YES`).

| Shot | Checks |
|---|---|
| 00 title VI (fresh) | D-27 hero card unchanged from r6: outline stars and medal on a fresh install |
| 01–02 intro VI / EN, 03 ending VI | iOS-R6-01: the story picture now covers the area outside the safe rect too (the Dynamic Island side and the home-indicator band); no night-colour bars beside the picture |
| 04–05 quiz VI / EN | iOS-R6-02: the prompt starts below the pause/sound block (corner bottom + 8); the dots and "Câu n/N" sit in the free band right of it; 3 cards 380 × 290 |
| 06 / 06b right card EN / VI | **Fixed in this pass:** the "Đúng rồi! / That's right!" pill was drawn under the card picture and cut off ("That's"), with white text on #3FA34D (3.2:1). It is now centred on the card's top row over the picture (as Android draws it), 220 × 40, deep-ink #1A120C label (accessibility-requirements.md, quiz card labels). The why line and Tiếp/Next on the story row |
| 07 wrong card VI | Lavender card, #9C8FB8 border, ink-outlined circular arrow, picture at 45 %, "Thử lại nhé!" under the cards |
| 08 beat card EN | Card panel above the Skip/Next row, "Part 1" above it |

Not shown as stills (covered by the automated cases below): the entry lock (B7 attack mash through the beat end
keeps the first ending box; ◀ taps as the training card appears open no skip warning), the title-card tap, the
skip warning → Keep reading → quiz × 5 → 3★ after a relaunch. Small-k quiz (k < 0.48, cards on Tiếp's row, the
right card glides left) has no small-k Simulator here; it is covered by `QuizLayoutTests` only.

Automated at this tip: GameCore 111/111 (`swift test`); app unit 4/4 and UI touch cases 10/10
(`xcodebuild test-without-building`, own Simulator, result bundle `all7b-010353.xcresult`, before the pill fix,
which is render-only). Each UI case spends ~300 s in XCTest's teardown ("Checking for reports corresponding to
termination of 1 app(s)") on this host; the r6 harness unchanged shows the same, so it is the host, not the build.

**Release check (after the pill fix):** Release built three times into one derived-data path: A1, A2 (a touch-and-rebuild
control) and B (every `#if DEBUG` block removed from `GameScene.swift` and `DaiDatAnhHungApp.swift`). Each links, then
stops at the R12 content gate (claims C01–C16 unsigned), as designed. The executable is byte-identical in A1, A2 and B;
the B objects differ only in the source-line debug info that removing lines shifts, which the linker leaves out.
`strings` finds no `debugState` or `resetProgress` in the executable.
