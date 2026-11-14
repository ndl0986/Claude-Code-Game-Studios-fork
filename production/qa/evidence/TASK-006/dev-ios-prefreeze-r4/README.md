# Developer pre-freeze pass for iOS r4 (not QC evidence)

game-dev-ios's own run-and-observe check before freezing r4, on its own Simulator
"iPhone 18 Pro – dev-ios" (iOS 27.0, UDID FB836E51-D39E-42C3-A60E-96159EE6516C), headless, captured
with `xcrun simctl io FB836E51-… screenshot`. QC's device (E9F515E9) was not used.

Build: feat/TASK-006-ios-native at the commit before the r4 base merge (the merge added only the
`pad_gap` and `drag_threshold` tuning keys, which iOS does not read yet, and no iOS code). Every screen in VI and EN, reached with debug launch arguments:
`-startScreen title|intro|play|ending|quiz|results|unlock|skipwarn|pause -beat N -stage card|ask|blocks|telegraph|wrong|right|newmedal -q N -stars N -lang vi|en`.

Checked against the r3 bugs: R3-02 (quiz prompt clear of the cards), R3-03 (intro text clear of
Tiếp), R3-04 (no emblems beside the card title; pops below the goal; the dialogue title inside the
panel), R3-05 (goal on a cream plate), R3-06 (intro picture shows the village and hero), and the
UX calls (right card #D9F2D0 + #3FA34D border + tick, wrong card #E6E1F0, ink labels; unlock with
one button; the title's map-stub line). Not checkable by screenshot: touch release (R2-03, QC's
retest), audio, feel.
