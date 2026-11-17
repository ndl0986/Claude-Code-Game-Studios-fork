# TASK-026 device run 1: the Preview on Luan's iPhone (developer check)

- Device: iPhone 17 Pro (iPhone18,1), iOS 27.2 (24B119), wired, paired with the dev Mac. Developer Mode on.
- Build: Preview config at 9af55da, development-signed by the free Personal Team 4KRK8K334N with
  `tools/ios/install-device.sh` (55cbbe6). Bundle `com.galaxyandsun.daidatanhhung.preview`, display name
  "Dải Đất Anh Hùng (preview)". The free profile expires 2026-11-24 12:15 UTC; rerun the script before then.
- Steps Luan did once: added his Apple ID in Xcode (the Personal Team loaded), Trust This Computer, Developer Mode
  (Settings → Privacy & Security → Developer Mode → Restart → Turn On), and on the first launch trusted the developer
  (Settings → General → VPN & Device Management → Developer App → Trust). Before the trust tap, the launch was
  refused with "…its profile has not been explicitly trusted by the user". After it, `devicectl device process launch`
  opened the app.
- Script lesson (55cbbe6): a free team's profile must list the device, so the build targets the phone's UDID
  (`-allowProvisioningDeviceRegistration`). A generic iOS destination wouldn't register it.

## ADR-0002, partial (the game was put on hold before a played run)

Instruments **Activity Monitor**, 20 s, app launched by xctrace and left on the title (no input). The Preview build has
`get-task-allow` (development signing), so these are the optimised build's numbers.

| Time | Physical footprint | Real memory | CPU | Threads |
|---|---|---|---|---|
| 1.1 s (launch) | 118 MiB | 46.8 MiB | 20 % | 13 |
| 2.2 s (peak) | **133 MiB** | 48.5 MiB | 18 % | 13 |
| 6–20 s (title, idle) | **≈ 111 MiB** | ≈ 48 MiB | 15–20 % | 7–9 |

- Memory at the title is about 111 MiB of footprint, well inside an iPhone's per-app limit. The mission and quiz peaks
  are **not measured**: they need someone to play a full mission while Instruments records (Game Performance + Game
  Memory).
- **Frame time on a real iPhone: NOT ASSESSED** (the same reason). ADR-0002's frame-time box stays open.
- Observation: 15–20 % CPU on an idle title is worth a look when the game resumes. SpriteKit redraws every frame at the
  display's rate (ProMotion), even when nothing moves.

The trace itself (idle-mem2.trace) stays in the developer's scratchpad. It's large, and only this summary is kept.
