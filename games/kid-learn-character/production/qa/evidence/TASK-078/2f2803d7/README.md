# TASK-078 DeviceSpike v1 — headless proof at 2f2803d7 (NOT install evidence)

The minimal spike check is an install gate, not a PKC verdict (ADR-0011 D1). Install evidence is made in each device
session by `prototypes/DeviceSpike/tools/device-build.sh` on the exact signed iphoneos / macOS product, into that
run's `<run task>/<sha>/` folder. This folder only shows that the tool chain works on this sha.

- `spike-check-mac.txt`, `build-mac.txt`, `test.txt`: DeviceSpike macOS product (`device-build.sh mac`), TASK-077
  art bundled, bundle id `com.galaxyandsun.devicespike`, ad-hoc signed: all items PASS, clean tree. SpikeKit 7/7.
- `norive/…`: TASK-033 SpikeNoRive (P-1 baseline) macOS product: all PASS (item 6 n/a: no Keys screen); MorphCore
  tests pass.
- Logs are `.txt` because `*.log` is gitignored (849dd1d0's were never committed; that folder is replaced by this).
- Not run here: the signed iphoneos build (the team ID stays local; the device session runs it).
