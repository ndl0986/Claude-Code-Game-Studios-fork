# game-dev-android device tools

- `adbdev`: the only adb entry point for game-dev-android. It always uses `-s emulator-5556` (devandroid002) and refuses 5554 (game-qc-android's mp17863) in any argument or in `ANDROID_SERIAL`.
- `boot-5556.sh`: boots devandroid002 headless on port 5556. game-qc-android owns 5554's lifecycle; never start, stop or wipe it from here.
- `shot.sh <out_dir> <name> <wait_s> <am extras…>`: relaunch the debug app with debug extras (`--es startScreen play --ei beat 4 --es stage finishright --ef slow 0.1`, …), wait, and screencap.
