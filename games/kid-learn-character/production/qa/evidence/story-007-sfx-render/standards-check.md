# Story 007: the D5 meter against the standards

Sources: EBU Tech 3341 (2023) Table 1; ITU-R BS.1770-5 (11/2023) Annex 1 and Annex 2.

- ITU-R BS.1770-5 (11/2023): https://www.itu.int/dms_pubrec/itu-r/rec/bs/R-REC-BS.1770-5-202311-I!!PDF-E.pdf
- EBU Tech 3341 v4.0 (2023-11): https://tech.ebu.ch/files/live/sites/tech/files/shared/tech/tech3341.pdf

The coordinator and the reviewer (game-dev-android) checked the meter against text taken from the official PDFs.
"Match" means the code already agreed with the document. "Fixed" means it was changed in this round to agree.

## Meter constants (`apple/Tools/Sources/ToolsCore/Loudness.swift`)

| Constant | Value in code | Source | Result |
|---|---|---|---|
| K-weighting stage 1 (shelf), 48 kHz | b0 1.53512485958697, b1 -2.69169618940638, b2 1.19839281085285, a1 -1.69065929318241, a2 0.73248077421585 | BS.1770-5 Annex 1, Table 1 | match |
| K-weighting stage 2 (RLB high-pass), 48 kHz | b0 1, b1 -2, b2 1, a1 -1.99004745483398, a2 0.99007225036621 | BS.1770-5 Annex 1, Table 2 | match |
| Block length, overlap | 400 ms, 75 % (100 ms hop) | BS.1770-5 Annex 1, gating | match |
| Absolute gate | -70 LUFS | BS.1770-5 Annex 1, gating | match |
| Relative gate | -10 LU | BS.1770-5 Annex 1, gating | match |
| Loudness offset | -0.691 | BS.1770-5 Annex 1 | match |
| True-peak FIR, phases 0-3 (12 taps each) | phase 2 = phase 1 reversed, phase 3 = phase 0 reversed | BS.1770-5 Annex 2, Table 1 | match |
| Citation in the doc comments | was "BS.1770-4" | BS.1770-5 (11/2023) | fixed |
| K-weighting at other sample rates | derived from the analog prototype; reproduces the 48 kHz table to 1e-7 (a test) | our own derivation, not a table | n/a (own choice) |

## Test cases (`apple/Tools/Tests/ToolsTests/LoudnessTests.swift`)

Loudness cases are stereo in Tech 3341 and the meter is mono. Each case is synthesised on one channel, so the expected
value is the stereo value minus 3.01 dB, within ±0.1 LU. True peak is measured per channel, so cases 15-19 keep their
expected values with no -3.01 adjustment, within +0.2 / -0.4 dB.

| Case (Table 1) | Signal | Expected (stereo → mono) | Result |
|---|---|---|---|
| 1 | 1 kHz, 20 s at -23 dBFS | -23.0 → -26.01 LUFS (integrated and momentary max) | match |
| 2 | 1 kHz, 20 s at -33 dBFS | -33.0 → -36.01 LUFS | match |
| 3 | 10 s -36, 60 s -23, 10 s -36 dBFS | -23.0 → -26.01 LUFS; the ungated comparison is recomputed for 10/60/10 (-1.18 dB) | fixed (was 20/40/20) |
| 4 | 10 s -72, 10 s -36, 60 s -23, 10 s -36, 10 s -72 dBFS | -23.0 → -26.01 LUFS | fixed (was our own signal) |
| 5 | 20 s -26, 20.1 s -20, 20 s -26 dBFS | -23.0 → -26.01 LUFS | fixed (added) |
| 15 | fs/4, 0.50 FFS, phase 0.0°, 10 ms fade in and out | -6.0 dBTP | fixed (added) |
| 16 | fs/4, 0.50 FFS, phase 45.0°, 10 ms fades | -6.0 dBTP | fixed (was mislabelled as case 15) |
| 17 | fs/6, 0.50 FFS, phase 60.0°, 10 ms fades | -6.0 dBTP | fixed (added) |
| 18 | fs/8, 0.50 FFS, phase 67.5°, 10 ms fades | -6.0 dBTP | fixed (added) |
| 19 | fs/4, 1.41 FFS, phase 45.0°, 10 ms fades | +3.0 dBTP | fixed (added) |
| 20-23 | the EBU's own downloadable files | — | not covered (the files are not in the repo) |
| (not in Table 1) | 5 s at mono -75 LUFS: gated out; 5 s at -69.5: reads -69.5 | absolute gate alone | kept as `test_adapted_absolute_gate_at_minus_70_lufs`, labelled as our adaptation |
| (not in Table 1) | 0.2 s tone at -20 dBFS, padded to 400 ms | -26.02 LUFS momentary max | own case (ADR-0003 D5, sounds under 0.4 s) |

All cases pass (`swift test`, Tools).
