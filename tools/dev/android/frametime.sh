#!/bin/zsh
# frametime.sh <serial> [seconds=60] [package=com.galaxyandsun.daidatanhhung.preview]: TASK-007 low-end profiling.
# Turns on the opt-in frame-time log, relaunches the app, and collects its 10 s summaries while someone plays
# (the training beat and the camp), then saves them with the device details to
# production/qa/evidence/TASK-007/android/device/. Refuses emulator-5554 (game-qc-android's device).
set -euo pipefail
serial=${1:-}; secs=${2:-60}; pkg=${3:-com.galaxyandsun.daidatanhhung.preview}
[[ -n "$serial" ]] || { echo "usage: frametime.sh <serial> [seconds] [package]" >&2; exit 2; }
[[ "$serial" == emulator-5554 ]] && { echo "frametime: refusing emulator-5554 (QC's device)" >&2; exit 2; }
ROOT=${0:A:h:h:h:h}; ADB=(~/Android/sdk/platform-tools/adb -s "$serial")
model=$("${ADB[@]}" shell getprop ro.product.model | tr -d '\r'); maker=$("${ADB[@]}" shell getprop ro.product.manufacturer | tr -d '\r')
rel=$("${ADB[@]}" shell getprop ro.build.version.release | tr -d '\r'); sdk=$("${ADB[@]}" shell getprop ro.build.version.sdk | tr -d '\r')
slug=$(echo "$maker-$model" | tr ' /' '__'); out=$ROOT/production/qa/evidence/TASK-007/android/device; mkdir -p $out
f=$out/frametime-$slug-$(date +%Y%m%d-%H%M%S).txt
"${ADB[@]}" shell setprop debug.ddah.frametime 1
"${ADB[@]}" logcat -c
"${ADB[@]}" shell am force-stop $pkg
"${ADB[@]}" shell am start -n $pkg/com.galaxyandsun.daidatanhhung.GameActivity >/dev/null
echo "recording ${secs}s on $maker $model (Android $rel): play the training beat and the camp now"
sleep $secs
{ echo "# TASK-007 frame time: $maker $model, Android $rel (API $sdk), $pkg, $(date '+%Y-%m-%d %H:%M')"
  echo "# each line: one 10 s window; interval = vsync to vsync, work = the app's own frame work (input, sim, draw)"
  "${ADB[@]}" logcat -d -s DDAH-frametime:I; } > $f
"${ADB[@]}" shell setprop debug.ddah.frametime 0
echo "saved $f"; grep -c "frames=" $f | xargs echo "windows:"
