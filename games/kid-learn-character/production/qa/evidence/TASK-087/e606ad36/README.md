# TASK-087 ADR-0010 — DeviceSpike build at e606ad36 (the "Freeze continuity" device test)

- `build-ios-simulator.txt`, `build-macos.txt`: DeviceSpike with the P-7 / M-14 continuity measurement (chirp, tap,
  Δ = resume − freeze, start delay vs rewind) and the capped-rewind debug line, from a tree identical to e606ad36;
  BUILD SUCCEEDED, no warnings; headless (nice 10, load < 40, no other xcodebuild, no boot, no launch); `$HOME`
  masked as `~`.
- The H-1 offline evidence is unchanged: `../0b59653a/`.
- Not device evidence: the test runs in P-7 / M-14.
