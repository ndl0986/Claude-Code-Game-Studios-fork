# TASK-087 ADR-0010 — H-1 final runs and DeviceSpike build at 0b59653a

- `h1-run1.txt` … `h1-run3.txt`: H-1 (`prototypes/DeviceSpike/tools/offline-cut-check.swift` as committed in 0b59653a),
  three runs of the final script (macOS 27.2, nice 10, load < 40). 4 signals × 8 start phases × 7 mechanisms.
  All three: the 4 gated mechanisms × 4 signals PASS at every phase (single tones worst −62.6 dBFS; chord and
  voice-like −61.6 dB per-sample gain step, limit −60); hard stop, `.interrupts` and naive pause FAIL at every phase
  (12/12); the detector self-check (a hard stop detected at every phase on every signal) passes.
- Continuity (D7, in content): in all 96 resumes, resume − freeze frame = −960 frames (20 ms rewind) + that
  rendering's player-start delay (the offline rig starts its player 0–1920 frames late). Two readings are positive
  (+720, +960) where the start delay (1680, 1920) exceeded the rewind; in the app the delay is at most one IO period,
  hence ADR-0010 D7's rewind rule. "Nothing skipped" is verified on the device (P-7, production AC-21).
- Scoped out offline: the chord and voice-like resume segment (alignment across a player restart is not reliable
  offline); the fade-out is measured; the fade-in is proven on the single tones; P-7 / M-14 listen to it.
- The script also carries env-gated diagnostic probes (`H1_PROBE`, `H1_PROBE2`, `H1_PROBE3`) used to find the rig's
  start jitter; they do not run in a normal run.
- `build-ios-simulator.txt`, `build-macos.txt`: DeviceSpike (AudioSpike with the D7 rewind rule) from a tree identical
  to 0b59653a; BUILD SUCCEEDED, no warnings; headless, no boot, no launch; `$HOME` masked as `~`.
- Supersedes `../fa856341/` (its chord/voice metric had the blind spot game-qc-ios found).
- Not device evidence: the rows P-1, P-7, P-8, P-9, M-14 decide ADR-0010.
