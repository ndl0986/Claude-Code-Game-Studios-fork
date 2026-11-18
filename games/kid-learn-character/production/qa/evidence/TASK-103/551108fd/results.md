# H-1 option B size and memory (ADR-0009, TASK-103)

**Mac CPU, not device evidence.** Apple M4 Pro, macOS 27.2.1, swift-driver version: 1.168.6 Apple Swift version 6.4. Art: TASK-077's three test creatures at 551108fd (`prototypes/DeviceSpike/art/`). The 36-item extrapolation is **partial** (3 test creatures, linear).

Run from `prototypes/DeviceSpike/art/`: `swiftc -O option-b-size.swift -o <tmp>/optb && <tmp>/optb cast_dino_d_testsauropod_01.svg cast_dino_q_testflyer_01.svg cast_dino_t_testrex_01.svg` (PNGs are encoded in memory only; nothing is written to the repo).

| creature | parts | SVG bytes (A stand-in) | tier | PNG bytes (B) | texture bytes w*h*4 | part-box sum / one image (F6 cap 1.5) | Mac CPU raster ms |
|---|---|---|---|---|---|---|---|
| cast_dino_d_testsauropod_01 | 4 | 3081 | stage 1024 | 115524 | 2268436 | 0.37 | 18.2 |
| cast_dino_d_testsauropod_01 | 4 | 3081 | list 256 | 24503 | 142948 | 0.37 | 1.5 |
| cast_dino_d_testsauropod_01 | 4 | 3081 | parade 256 | 22853 | 142948 | 0.37 | 1.3 |
| cast_dino_q_testflyer_01 | 3 | 2888 | stage 1024 | 132791 | 3405676 | 0.56 | 12.8 |
| cast_dino_q_testflyer_01 | 3 | 2888 | list 256 | 26002 | 213752 | 0.56 | 1.4 |
| cast_dino_q_testflyer_01 | 3 | 2888 | parade 256 | 23999 | 213752 | 0.56 | 1.3 |
| cast_dino_t_testrex_01 | 5 | 3836 | stage 1024 | 136270 | 2598328 | 0.43 | 9.8 |
| cast_dino_t_testrex_01 | 5 | 3836 | list 256 | 28429 | 163668 | 0.43 | 1.3 |
| cast_dino_t_testrex_01 | 5 | 3836 | parade 256 | 27016 | 163668 | 0.43 | 1.2 |

Totals over 3 creatures: SVG 9805 bytes. stage 1024: PNG 384585 bytes, texture 8272440 bytes; list 256: PNG 78934 bytes, texture 520368 bytes; parade 256: PNG 73868 bytes, texture 520368 bytes
Per creature, all tiers: PNG 179129 bytes vs SVG 3268 bytes. Linear extrapolation to 36 items (PARTIAL, 3 test creatures): PNG 6.15 MB vs SVG 0.11 MB.
