# TASK-033 evidence (spike, game-dev-ios, 2026-11-17)

Report: `design/tech/TASK-033-anim-runtime.md`. Prototype: `prototypes/TASK-033-anim-runtime/`.

**Builds:** Release, Xcode 27.1 (27A9275), iOS SDK 27.1, macOS SDK 27.
- **iPad Simulator:** "iPad (A16) – dev-ios-033" (E243AD8D-62DF-4C49-A763-5850B7BF8A7C), iOS 27.0, my own (QC's
  simulators were not used).
- **Mac:** MacBook Pro M4 Pro, 24 GB, macOS 27.2.1 (26B131).

| Folder / file | What |
|---|---|
| `screens/` | iPad Simulator frames: 01 the D glows, 02 the D dissolves into stardust, 03 particles in flight, 04 landed on the outline, 05 the object (placeholder dinosaur), 06 a later frame, 07–08 Rive playing the stock `mascot.riv` (runtime cost only; not a morph) |
| `runs/` | `sim-*` (iPad Simulator) and `mac-*` (Mac): per-press CSV, frame times, memory, summary, and `*-net.txt` (in-app URL probe: no requests). Latency = 30 presses, hold 0.5 s; mash = 10 presses/s for 60 s, hold 3 s |
| `network/` | The sandboxed macOS network check (4 cases): stderr with OS_ACTIVITY_DT_MODE, `[net]` probe lines, `lsof` samples, entitlements; `static-rive-binary.txt` |
| `size/ios-device-size.txt` | arm64 Release .app sizes with and without Rive |
| `lockin/` | The macOS kiosk shortcut test, kiosk on and off (text only; the desktop screenshots were deleted for privacy) |
| `research/` | Desk research with official links: runtimes and engines, child lock-in |
| `procedure-ipad.md` | The 240 fps camera procedure for the child's iPad (device numbers NOT ASSESSED until it is run) |

**Fonts and assets:**
- Fredoka (Google Fonts), Version 2.001, SIL Open Font License 1.1: copyright 2016 The Fredoka Project Authors.
  Source: github.com/google/fonts `ofl/fredoka` at commit 7af0d90 (`prototypes/.../third_party/fredoka/` has the
  font, OFL.txt and METADATA.pb). Used only by the bake tool.
- Rive sample files (fetched at build time, not committed):
  - From rive-app/rive-ios tag 6.30.1, MIT: `Example-iOS/Assets/mascot.riv` (sha256 480e8c22…ebb4) and
    `Tests/Assets/hosted_assets.riv` (sha256 ce730ce3…6f6).
  - No separate asset licence was found, so the repo's MIT licence applies.
- The roar is synthesised by `tools/make-roar.py` (no licence question).
- The dinosaur silhouette is a hand-drawn placeholder.
