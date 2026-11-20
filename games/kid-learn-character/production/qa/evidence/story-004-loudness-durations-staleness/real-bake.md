# Story 004: the real voice bake (72 Dinosaurs lines, en-us)

Run 2026-11-20 on the build Mac in a scratch copy of the content (`<scratch>`): `kidtools bake-voice` with the Kokoro
helper (pins as story 003), the trim (−50 dBFS K-weighted 10 ms, 20 ms pad, 5 ms fades) and the limiter (−1 dBTP
ceiling, 5 ms lookahead, 50 ms release, 6 dB warning) from `src/voice-scripts/en-us.json`. The theme was the
key-table/001 draft (`theme.draft.json` at c297d8ed) copied in as `theme.json`. Nothing here is committed content
(option A: baked files land with theme.json).

Command output: `bake-voice: 74 file(s) baked, 0 theme(s) skipped, 0 limiter warning(s)` (72 `.caf`, the
provenance and `theme.json`'s `voiceDurations`), exit 0.

## Before the limiter (the same renders, one gain to −16 LUFS)

51 of 72 lines over −1 dBTP and 30 over full scale (up to +3.2 dBFS); the clip guard refused the bake at letter C,
so nothing was written. Speech peak-to-loudness: median 15.8 dB, max 19.2 dB.

## After (measured by `LoudnessMeter` on the decoded written files, from the provenance)

- Loudness: -16.43 … -16.00 LUFS (target −16 ± 1, A7).
- True peak: max -1.10 dBTP (ceiling −1).
- Limiter: 31 of 72 lines reduced, max 2.87 dB; none over the 6 dB warning.

## voiceDurations (trimmed; V15 limits: word 1.5 s under K-53, was 1.25 s; letter and number 1.0 s)

| line | seconds | limiter dB | over 1.25 s |
|---|---|---|---|
| word_five_baby_dinosaurs | 1.470 | 2.29 | yes |
| word_seven_baby_dinosaurs | 1.470 | 1.38 | yes |
| word_nine_baby_dinosaurs | 1.450 | 0.01 | yes |
| word_six_baby_dinosaurs | 1.430 | 1.80 | yes |
| word_four_baby_dinosaurs | 1.390 | 0.58 | yes |
| word_three_baby_dinosaurs | 1.370 | 1.50 | yes |
| word_eight_baby_dinosaurs | 1.360 | 1.94 | yes |
| word_one_baby_dinosaur | 1.270 | 0.00 | yes |
| word_two_baby_dinosaurs | 1.270 | 1.70 | yes |
| word_quetzalcoatlus | 1.260 | 0.88 | yes |
| word_xenoceratops | 1.220 | 1.84 |  |
| word_zuniceratops | 1.150 | 0.34 |  |
| word_wuerhosaurus | 1.120 | 0.00 |  |
| word_ankylosaurus | 1.110 | 2.01 |  |
| word_edmontosaurus | 1.090 | 1.52 |  |
| word_an_empty_nest | 1.050 | 2.87 |  |
| word_velociraptor | 1.050 | 0.00 |  |
| word_juravenator | 1.040 | 0.00 |  |
| word_brachiosaurus | 1.010 | 0.09 |  |
| word_lambeosaurus | 1.000 | 0.13 |  |
| word_tapejara | 0.970 | 0.00 |  |
| word_stegosaurus | 0.960 | 0.00 |  |
| word_hadrosaurus | 0.930 | 0.76 |  |
| word_triceratops | 0.930 | 0.33 |  |
| word_kentrosaurus | 0.920 | 0.83 |  |
| word_utahraptor | 0.920 | 0.34 |  |
| word_diplodocus | 0.900 | 1.07 |  |
| word_gallimimus | 0.890 | 0.00 |  |
| word_yutyrannus | 0.850 | 0.00 |  |
| word_iguanodon | 0.840 | 0.00 |  |
| word_oviraptor | 0.800 | 0.00 |  |
| word_maiasaura | 0.790 | 0.00 |  |
| word_tee_rex | 0.740 | 0.01 |  |
| word_fossil | 0.660 | 0.54 |  |
| word_raptor | 0.660 | 0.00 |  |
| word_nest | 0.560 | 0.00 |  |
| letter_w | 0.780 | 2.45 |  |
| number_9 | 0.670 | 0.00 |  |
| number_0 | 0.620 | 0.00 |  |
| number_7 | 0.600 | 0.00 |  |
| number_3 | 0.580 | 0.00 |  |
| number_5 | 0.580 | 0.00 |  |
| letter_q | 0.560 | 1.90 |  |
| number_6 | 0.550 | 1.06 |  |
| number_1 | 0.530 | 0.00 |  |
| number_4 | 0.530 | 0.16 |  |
| number_8 | 0.520 | 0.00 |  |
| letter_g | 0.500 | 0.00 |  |
| letter_s | 0.500 | 0.00 |  |
| letter_t | 0.500 | 0.00 |  |
| letter_y | 0.500 | 0.00 |  |
| number_2 | 0.500 | 0.00 |  |
| letter_v | 0.490 | 0.48 |  |
| letter_x | 0.490 | 0.00 |  |
| letter_z | 0.490 | 0.57 |  |
| letter_b | 0.480 | 0.00 |  |
| letter_c | 0.480 | 1.59 |  |
| letter_d | 0.480 | 0.00 |  |
| letter_j | 0.480 | 0.00 |  |
| letter_m | 0.480 | 0.00 |  |
| letter_n | 0.480 | 0.00 |  |
| letter_p | 0.480 | 0.00 |  |
| letter_f | 0.470 | 0.00 |  |
| letter_l | 0.460 | 0.00 |  |
| letter_e | 0.450 | 0.00 |  |
| letter_u | 0.450 | 0.36 |  |
| letter_k | 0.440 | 0.00 |  |
| letter_h | 0.430 | 0.00 |  |
| letter_r | 0.400 | 0.00 |  |
| letter_i | 0.320 | 0.00 |  |
| letter_o | 0.310 | 0.00 |  |
| letter_a | 0.300 | 0.00 |  |

## Reproducible

A second full bake into a fresh scratch copy, same inputs: `diff -rq` of the two `voice/` folders (72 `.caf` and
`provenance.json`) printed nothing, and `cmp` of the two `theme.json` files printed nothing: byte-identical.
