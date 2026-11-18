# TASK-087 ADR-0010 — headless evidence at a70779fb

- `offline-cut-check.txt`: H-1, `prototypes/DeviceSpike/tools/offline-cut-check.swift` at a70779fb (AVAudioEngine
  offline manual rendering, the ADR's D2 chain with Apple's PeakLimiter; 100 Hz tone at −1 dBFS; detector = largest
  second difference; AC-9 threshold −60 dBFS). Hard stop, `.interrupts` on a busy player and a naive pause FAIL at
  −38.7 dBFS; the D5 cut (gate to 0, 40 ms settle, stop) and the D7 freeze/resume PASS at the clean floor.
- H-2: `DeviceSpike` (AudioSpike implementing D1–D8) built for iOS Simulator and macOS, no warnings (xcodebuild,
  headless, nice 10, load < 40; no simulator booted, nothing launched).
- Not install evidence and not device evidence: the rows P-1, P-7, P-8, P-9, M-14 decide ADR-0010.
