# AudioToolbox AAC encode determinism (content-pipeline/003; found by 007's determinism test)

**Question:** is `VoiceBake.encode` (AVAudioFile, AAC-LC mono 48 kHz 64 kbit/s) byte-stable for identical PCM?

**Harness:** `enc.swift` encodes one fixed 70 000-frame signal with the bake's settings; one process per run.
`boxhash.py` hashes only the `mdat` (audio) and `stsz` (sample sizes) boxes, so header timestamps don't count.
Build: `swiftc -O -o enc enc.swift`. Run: `./enc out.m4a whole|chunked [default|cbr|cbrmax]`.

**Results (2026-11-20, this Mac: 8 performance + 4 efficiency cores; Xcode 27.1, macOS 27.2):**

| Variant (20 processes each) | Distinct `mdat` outputs | Split |
|---|---|---|
| default, whole-buffer write | 2 | 14 / 6 |
| default, 1024-frame chunks | 2 | 13 / 7 |
| `AVAudioBitRateStrategy_Constant`, whole | 2 | 9 / 11 |
| constant, chunks | 2 | 16 / 4 |
| constant + `AVAudioQuality.max`, whole | 2 | 16 / 4 |
| constant + max, chunks | 2 | 18 / 2 |
| default, `taskpolicy -b` (mostly efficiency cores), ×2 | 2 | 3 / 17 (both runs) |
| default, normal scheduling | 2 | 14 / 6 |

- Exactly **two** bitstreams appear for the same PCM, whatever the settings; which one you get shifts with the
  scheduling class. Reading: AudioToolbox's AAC encoder takes a different code path on performance vs efficiency
  cores. **No encoder setting we can set makes it byte-stable.** (Inferred from the QoS shift; not confirmed by Apple.)
- **The two bitstreams decode to audio that differs by max −101.0 dBFS, RMS −124.1 dBFS**, in 2 047 of 70 000 frames
  (about two AAC packets): below the 16-bit floor (−96 dBFS), inaudible. Same frame count.
- 003's in-process byte test (`test_encoding_the_same_audio_twice_gives_identical_bytes`) passed 15/15, likely because
  one process stays on one core class; the property it asserts does not hold across processes.
- 003's two full 72-line voice bakes earlier matched byte for byte, by the same chance.
