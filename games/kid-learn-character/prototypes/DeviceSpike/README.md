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
| `tools/spike-check.sh` | The minimal spike check (TASK-075): an install gate, run on the exact product |
| `tools/device-build.sh` | Builds the signed iphoneos / macOS product, keeps its logs and runs the check into the run's evidence folder |
| `art/` | TASK-077's three test creatures (committed; without `art/` the Render screen falls back to the TASK-033 silhouette) |

## How to run (headless first, K-34)
```sh
python3 tools/gen-xcodeproj.py            # bundles art/ (TASK-077's committed creatures) when present
(cd SpikeKit && swift test)
xcodebuild -project DeviceSpike.xcodeproj -scheme DeviceSpike -destination 'generic/platform=iOS Simulator' build
```
Launch arguments: `-screen audio|keys|lock|render` opens a screen; `-option b` starts Render on option B; `-smoke YES`
logs the Render frame stats after 600 frames (Simulator numbers are never evidence).

## Before every install: build the exact product and gate it
The minimal spike check is **an install gate, not a PKC verdict** (ADR-0011 D1). It must run on **the exact product
that is about to be installed or run**, in that session, never on a Simulator or an earlier build:
```sh
tools/device-build.sh ios production/qa/evidence/<run task>/<sha>/            # signed iphoneos .app for the iPad
tools/device-build.sh mac production/qa/evidence/<run task>/<sha>/            # the macOS .app run under MAC FREE
tools/device-build.sh ios production/qa/evidence/<run task>/<sha>/ norive     # TASK-033 SpikeNoRive, P-1 baseline
```
Each writes `build-<plat>.log`, `test.log` and `spike-check-<plat>.txt` (with the signature lines) into the run's
evidence folder; exit 1 means **do not install**. Install that same `.app` (`build/device/…`), nothing rebuilt in
between. Signing: automatic, Luan's Personal Team (K-28, K-37); the team ID comes from `$SPIKE_TEAM_ID` or
`tools/team-id.local` (gitignored) and is masked as `<TEAM>` in the logs. Bundle id `com.galaxyandsun.devicespike`.
Device sessions follow the device-checks plan (MAC FREE for the Mac; **remove the app from the child's iPad after each
session**). The P-2/P-3 render rows use a build whose sha carries TASK-077's committed `art/`.

## Notes
- The production frame driver (display link → `tick(now:)`, ADR-0006 D3) is the stage story's; here the `SKView`'s own
  loop drives the scene, since the spike measures drawing cost.
- Option B rasterises each part once at load (at ~2.5×), not at build time; its load numbers are therefore an upper bound
  for the PNG-tier option, and its frame cost is the same kind (sprites).
- The iPad ppi table holds spike values; each production row must cite Apple's tech-specs page (ADR-0006 D7).
- The frame dump writes PNGs to Caches/framedump (P-3 / M-12 rehearsal); it slows frames while it runs.

## Findings
None yet: no device run. Headless: both platforms build; SpikeKit tests pass; the check works (headless proof in
`production/qa/evidence/TASK-078/`, not install evidence).
