# TASK-078 DeviceSpike v1 — headless proof at 849dd1d0 (NOT install evidence)

The minimal spike check is an install gate, not a PKC verdict (ADR-0011 D1). Install evidence is made in each device
session by `prototypes/DeviceSpike/tools/device-build.sh` on the exact signed iphoneos / macOS product, into that
run's `<run task>/<sha>/` folder. This folder only shows that the tool chain works on this sha.

- `spike-check-mac.txt`, `build-mac.log`, `test.log`: DeviceSpike macOS product built by `device-build.sh mac`,
  TASK-077 art bundled, bundle id `com.galaxyandsun.devicespike`: all items PASS, clean tree.
- `norive/…`: TASK-033 SpikeNoRive (P-1 baseline) macOS product: all PASS (item 6 n/a: no Keys screen).
- Not run here: the signed iphoneos build (needs the team ID, which stays local; the device session runs it).
- Item 7 now FAILs on no sha or a dirty tree (checked both ways); the selector/URL-literal pass is new.
