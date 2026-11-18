# TASK-078 DeviceSpike v1 — minimal spike check (headless, K-34)

- **sha:** `ea51346e` (code `dbdc8930` + check fix `ea51346e`), branch `design/TASK-078-devicespike-v1`.
- **Check:** `prototypes/DeviceSpike/tools/spike-check.sh` (TASK-075 "Checks before an install", the 7 items).
- `spike-check-devicespike.txt`: DeviceSpike, iOS Simulator + macOS app: **all PASS** (exit 0).
- `spike-check-task033-norive.txt`: TASK-033 `SpikeNoRive` (`gen-xcodeproj.py --no-rive`), the P-1 baseline:
  **all PASS** (exit 0). Its source NOTE lists Rive and `URLProtocol` lines under `#if !NORIVE`; the binary scan of
  both images (main binary plus its debug dylib) finds no Rive, WebKit, Network.framework or URL-loading symbol.
- **Control:** the same check on the normal TASK-033 `Spike` (Rive) build FAILs items 4 and 2/3 (remote package;
  RiveRuntime linked), so the binary scan detects what it looks for.
- **Headless smoke** on dev sim E243AD8D (iPad A16, Simulator numbers are not evidence): Render with `-smoke YES`
  logged 600 frames in options A and B; Audio, Keys, Lock screens opened with no crash. The first run crashed in
  `RenderScene.layout()` (SKScene(size:) calls didChangeSize before the layers exist), fixed in `dbdc8930`.
  With TASK-077's three test creatures copied in locally (not committed), both options drew them correctly.
- **Not done here:** any device run (iPad or Mac foreground). Those follow the device-checks plan sessions
  (MAC FREE; remove the app from the iPad after each session).
