# TASK-087 ADR-0010 revision — headless build at 66d60b31

- `build-ios-simulator.txt`, `build-macos.txt`: `xcodebuild` of `prototypes/DeviceSpike` (the tone tests with the
  detector tap, the simulated media reset and the D9 split logs) from a tree identical to 66d60b31; both BUILD SUCCEEDED,
  no warnings. Headless (K-34): nice 10, load < 40, no other xcodebuild, no simulator booted, nothing launched.
  `$HOME` masked as `~`; logs verbatim otherwise.
- H-1 (the offline cut check) is unchanged since a70779fb (`../a70779fb/`).
- Not device evidence: the rows P-1, P-7, P-8, P-9, M-14 decide ADR-0010.
