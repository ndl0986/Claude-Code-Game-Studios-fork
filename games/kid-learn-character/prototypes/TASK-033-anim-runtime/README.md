# TASK-033 spike: 2D animation runtime for the letter morph (PROTOTYPE - NOT FOR PRODUCTION)

**Status:** concluded (2026-11-17). Findings and the recommendation: `../../design/tech/TASK-033-anim-runtime.md`.
Evidence: `../../production/qa/evidence/TASK-033/`.

## Hypothesis
One shared, data-driven "stardust morph" (any glyph → any object silhouette) can be built natively with SpriteKit
for all 36 keys, with instant response and steady memory under mashing; its math can be a pure core that a Kotlin
port reproduces exactly. Rive is the alternative runtime; the spike measures what its runtime costs.

## What's here
| Path | What |
|---|---|
| `MorphCore/` | Swift package, no UI imports: SplitMix64, an SVG path subset (M L H V C Q Z, fixed 16-segment curves), arc-length sampling, the morph recipe (`Morph.swift` doc comment). `swift test`: 5 tests incl. the shared fixture. `swift run morph-fixture ../fixtures` regenerates it |
| `fixtures/` | `glyph-{D,B,3}.json` (baked outlines), `silhouette-dinosaur.json` (placeholder), `morph-spec.json` (timings), **`morph-D-dinosaur.json`: the shared fixture a Kotlin port must match within 1e-3** |
| `Spike/` | The app (iPadOS 26 + macOS 26): SwiftUI shell, (a) `MorphScene.swift` SpriteKit, (b) `RiveStage.swift` Rive, `Input.swift`, `Audio.swift`, `Metrics.swift`, `SpikeController.swift` |
| `tools/` | `bake-glyph.swift` (CoreText → SVG path), `make-roar.py` (placeholder sound), `fetch-riv.sh` (Rive samples at build time), `gen-xcodeproj.py`, `run-measure.sh`, `net-check.sh` |
| `third_party/fredoka/` | Fredoka (Google Fonts, OFL 1.1, Version 2.001) used only by the bake tool |

## How to run
```sh
tools/fetch-riv.sh                 # Rive sample files (not committed)
python3 tools/gen-xcodeproj.py     # Spike.xcodeproj: targets Spike (SpriteKit + Rive) and SpikeNoRive
open Spike.xcodeproj               # run Spike on an iPad Simulator or "My Mac"
(cd MorphCore && swift test)
tools/run-measure.sh <sim-udid>    # latency + mash runs → evidence/runs
tools/net-check.sh                 # sandboxed macOS network check → evidence/network
```
Launch arguments: `-runtime spritekit|rive`, `-latency N`, `-mash S`, `-hold S`, `-riv mascot|hosted_assets`,
`-cdn 0|1`, `-label NAME`. Keys D, B and 3 on screen or on a hardware keyboard.

## Findings
See the report. In short: SpriteKit + MorphCore does the procedural morph for any glyph and silhouette from data;
Rive plays authored files cheaply but a stock file can't show a procedural morph, and its legacy Apple API
fetches CDN-hosted assets unless `loadCdn: false` is passed.
