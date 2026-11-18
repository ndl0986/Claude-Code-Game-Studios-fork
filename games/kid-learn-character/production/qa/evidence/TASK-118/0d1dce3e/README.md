# DeviceSpike no-flash pad + G5-method dump — build at 0d1dce3e

- `build-ios-simulator.txt`, `build-macos.txt`: DeviceSpike from a tree identical to 0d1dce3e; BUILD SUCCEEDED, no compiler warnings (the one `appintentsmetadataprocessor` notice is in every DeviceSpike build); headless (generic destinations, nice 10, load < 40, no other xcodebuild, no simulator booted, nothing launched); `$HOME` and temp paths masked; no team ID present.
- Not device evidence. On the device: the Audio pad shows a 36 pt press dot instead of a full-pad flash (a retained screenshot belongs to the device session); the frame dump writes raw frames by ADR-0013 D5's method and logs the V7 probe (dump off / on, against 0.5 px).
- Run every spike screen with the child out of view of the screen (README).
- Supersedes `../57e77663/` (game-qc-ios REVISE: the dump copies the view's ignoresSiblingOrder and shouldCullNonVisibleNodes).
