# DeviceSpike — the ★ ADR device spike (PROTOTYPE - NOT FOR PRODUCTION)

**Task:** TASK-078 (game-dev-ios). **Plan:** `production/team/TASK-075-spike-plan.md`. **Rows:**
`production/qa/device-checks-plan.md` (§ Spike runs). **Status: in progress** (v1 built and checked headless; no device
run yet).

## Hypotheses (one per screen; each decides an ADR option, never a GDD AC)
| Screen | ADR | Question | Rows |
|---|---|---|---|
| Audio | 0010 | Does the candidate graph (7 players / 4 buses, limiter, `.soloAmbient`, scheduling with `.interrupts` off the main thread, 30 ms ramp cuts) answer within one frame on the iPad, cut without clicks, and survive interruptions and route changes? | P-1, P-7, P-8, P-9, M-14 |
| Keys | 0007 | Do UIKit `pressesBegan` (iPad) and the AppKit monitor with `flagsChanged` (Mac) give the normalized events input-filter-v1 expects? Does the Mac key-state read trigger an Input Monitoring prompt? | P-15, M-1, M-2, M-3 |
| Lock / Guided Access | 0008 | Borderless window at the screen frame, or native full screen, for the kiosk? Do the covers, the in-window overlay and the chord hold? | M-3–M-7, P-4 |
| Render A/B | 0009 | Live paths (A) or per-part textures (B) for the layered cast art, under the full stage with the Scene worst case? | P-2, P-3, P-11, P-13, M-10, M-12, M-13 |

## What's here
| Path | What |
|---|---|
| `SpikeKit/` | Pure helpers, `swift test` (7 tests): `KeyMap` (normalized `KeyEvent`, Input R2 resolve, the chord), `StageFit` (Reveal Stage F1), `PPI` (ADR-0006 D7, unknown → class max), `SVGArt` (the cast-art subset with the `<part>_<layer>` suffix rule) |
| `DeviceSpike/` | The app (iPadOS 26 + macOS 26), SwiftUI shell + SpriteKit: `AudioSpike/AudioScreen`, `KeysScreen`, `LockScreen`, `RenderScene/RenderScreen`, `SpikeLog` |
| `tools/gen-xcodeproj.py` | Writes `DeviceSpike.xcodeproj`: one target, **no remote package, no Rive**; local `SpikeKit` and TASK-033's `MorphCore`; resources: TASK-033 `fixtures/` and `art/` once TASK-077 is merged |
| `tools/spike-check.sh` | The minimal spike check (TASK-075), run before any install |
| `art/` | TASK-077's three test creatures (game-art-content's branch; until it merges, the Render screen uses the TASK-033 silhouette) |

## How to run (headless first, K-34)
```sh
python3 tools/gen-xcodeproj.py
(cd SpikeKit && swift test)
xcodebuild -project DeviceSpike.xcodeproj -scheme DeviceSpike -destination 'generic/platform=iOS Simulator' build
xcodebuild -project DeviceSpike.xcodeproj -scheme DeviceSpike -destination 'generic/platform=macOS' build
tools/spike-check.sh . DeviceSpike DeviceSpike.xcodeproj/project.pbxproj <the .app paths>
```
Launch arguments: `-screen audio|keys|lock|render` opens a screen; `-smoke YES` logs the Render frame stats after 600
frames (Simulator numbers are never evidence). Device runs follow the device-checks plan's sessions (MAC FREE for the
Mac; a Personal Team build for the iPad; **remove the app from the child's iPad after each session**).

## Notes
- The production frame driver (display link → `tick(now:)`, ADR-0006 D3) is the stage story's; here the `SKView`'s own
  loop drives the scene, since the spike measures drawing cost.
- Option B rasterises each part once at load (at ~2.5×), not at build time; its load numbers are therefore an upper bound
  for the PNG-tier option, and its frame cost is the same kind (sprites).
- The iPad ppi table holds spike values; each production row must cite Apple's tech-specs page (ADR-0006 D7).
- The frame dump writes PNGs to Caches/framedump (P-3 / M-12 rehearsal); it slows frames while it runs.

## Findings
None yet: no device run. Headless: both platforms build; SpikeKit tests pass; the minimal spike check passes
(`production/qa/evidence/TASK-078/`).
