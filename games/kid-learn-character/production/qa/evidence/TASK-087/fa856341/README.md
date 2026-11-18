# TASK-087 ADR-0010 2nd revision — headless evidence at fa856341

- `h1-run3.txt` … `h1-run5.txt`: H-1 (`prototypes/DeviceSpike/tools/offline-cut-check.swift` as committed in fa856341),
  three runs of the final script (macOS 27.2, nice 10, load < 40). 4 signals × 8 start phases × 7 mechanisms.
  Gated mechanisms (D5 cut, D5 mute, D7 freeze/resume from position) PASS at every phase in all three runs; hard
  stop, `.interrupts` on a busy player and naive pause FAIL at every phase. Continuity: read the chord and
  voice-like lines (pure tones are ambiguous modulo their period). Earlier runs during development (with two
  measurement bugs since fixed: limiter latency not aligned, gain-metric gaps) are not evidence.
- `build-ios-simulator.txt`, `build-macos.txt`: `xcodebuild` of DeviceSpike (the D4 state machine, the D7 freeze by
  position) from a tree identical to fa856341; BUILD SUCCEEDED, no warnings; headless, no boot, no launch; `$HOME`
  masked as `~`.
- Not device evidence: the rows P-1, P-7, P-8, P-9, M-14 decide ADR-0010.
