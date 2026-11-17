# game-dev-android device tools

- `adbdev`: the only adb entry point for game-dev-android. It always uses `-s emulator-5556` (devandroid002) and refuses 5554 (game-qc-android's mp17863) in any argument or in `ANDROID_SERIAL`.
- `boot-5556.sh`: boots devandroid002 headless on port 5556. game-qc-android owns 5554's lifecycle; never start, stop or wipe it from here.
- `shot.sh <out_dir> <name> <wait_s> <am extras…>`: relaunch the debug app with debug extras (`--es startScreen play --ei beat 4 --es stage finishright --ef slow 0.1`, …), wait, and screencap.

## Install on a real phone without Play (D-37 preview build)

The **preview** build is release-like: not debuggable, no debug jumps, no sample hero. It shows missions whose history claims aren't approved yet, with their UNSIGNED badges, so it can never pass for a release (the R12 gate still blocks `assembleRelease`). Its app id is `com.galaxyandsun.daidatanhhung.preview` and its name is "Dải Đất Anh Hùng (preview)", so it installs beside any real build. It is never uploaded anywhere.

- **USB:** on the phone, Settings → About phone → tap "Build number" 7 times → Settings → System → Developer options → turn on "USB debugging" → plug the phone into the Mac and accept "Allow USB debugging" → on the Mac run `~/Android/sdk/platform-tools/adb devices` and copy the phone's serial → run `tools/dev/android/phone-install.sh <serial>`.
- **No USB (sideload):** run `tools/dev/android/phone-install.sh any --no-install`, which prints the APK path → copy that `.apk` to the phone (AirDrop is not available for Android; use Google Drive, a USB cable or email) → open it in the Files app → allow "Install unknown apps" for Files once → Install.

The first run creates the signing key in `~/.config/daidatanhhung/` (outside git, `chmod 600`). **Keep it**: a preview signed with a different key can't update the installed one (uninstall first).

## Frame time on a real phone (TASK-007 low-end profiling)

`tools/dev/android/frametime.sh <serial> [seconds=60]` turns on the opt-in recorder (`setprop debug.ddah.frametime 1`; off by default, debug and preview builds only, logcat only), relaunches the preview, and records while you play the training beat and the camp. It then saves the 10 s summaries with the phone's maker, model and Android version to `production/qa/evidence/TASK-007/android/device/`, and turns the recorder off. Each line gives the vsync interval (p50/p90/p99/max, frames over 20 and 34 ms) and the app's own frame work.
