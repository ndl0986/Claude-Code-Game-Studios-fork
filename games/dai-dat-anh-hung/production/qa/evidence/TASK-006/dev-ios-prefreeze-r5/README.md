# Developer pre-freeze pass for iOS r5 (not QC evidence)

game-dev-ios's run-and-observe check before freezing r5, on its own Simulator
"iPhone 18 Pro – dev-ios" (iOS 27.0, UDID FB836E51-D39E-42C3-A60E-96159EE6516C), headless, captured with
`xcrun simctl io FB836E51-… screenshot`, shut down afterwards. QC's device (E9F515E9) was not used.
Screens reached with debug launch arguments (`-startScreen … -beat N -stage … -lang vi|en`).

| Shot | Checks |
|---|---|
| 00–01 walk VI/EN | Goal plate 920 × 56 at the top stack (centre 790), the same place as on banner beats (HUD AC10); no banner |
| 02 hold VI | Goal plate; special pad with the hold hand |
| 03–04 training VI/EN | Banner bar 920 × 112 in the sky band, VI 1 line / EN 2 lines in the fixed bar (AC9); dummies step shows only ◀ ▶ + attack (W12); EN: the dummy hint arrow clear of the bar, pointing at the dummy |
| 05–06 blocks VI/EN | + defend (W12); partner at spec height; "Ối!"/"Oof!" beside the head on the far side (N1, AC12) |
| 07–08 reach VI/EN | Encounter at its closest: no bar pixel on a body; the spear crosses only as a weapon; pop beside the head |
| 09 telegraph EN (0.8 s) | The "!" above the enemy's head drawn over the bar's z, fully visible; defend hint hand |
| 10 telegraph VI (5 s) | After the strike: pop beside the head |
| 11 dialogue VI | No goal or banner on dialogue; pause and sound top-left |
| 12–17 intro, ending, quiz, results, unlock, title | Pause and sound top-left on every screen, sound only on the title (W7); quiz counter top-centre; unlock names two different heroes and its title clears the buttons (N2) |

Shots 00–08 and 10–17 were taken on the first r5 build; two render fixes followed (the dummy and
enemy hint arrows lowered under the bar, the unlock title moved into the free band and the sample
hero loaded for the unlock jump). Shot 09 is from the second build and shots 04 and 16 from the final one.

Not observable by screenshot here (no touch injection on a headless Simulator): holding ▶ through
training (15b; covered by TrainingCapTests and the shared trace 1.1 replay, cam included), touch
release (R2-03) and the press-time debounce (B1). These are QC's.
