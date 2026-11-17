#!/bin/sh
# PROTOTYPE - NOT FOR PRODUCTION (TASK-033 spike)
# Latency (30 synthetic presses, hold 0.5 s) and mash (10 presses/s for 60 s) per runtime, on the dev iPad
# Simulator and natively on this Mac (Release builds). Results land in production/qa/evidence/TASK-033/runs/.
#   tools/run-measure.sh <simulator-udid> [sim|mac|both]
set -u
cd "$(dirname "$0")/.."
SIM=$1; WHERE=${2:-both}
OUT=../../production/qa/evidence/TASK-033/runs; mkdir -p "$OUT"
BID=com.galaxyandsun.spike033
MACAPP=build/dd/Build/Products/Release/Spike.app/Contents/MacOS/Spike
MACDOCS="$HOME/Library/Containers/$BID/Data/Documents"
run_sim() { # label secs args...
  label=$1; secs=$2; shift 2
  xcrun simctl terminate "$SIM" $BID >/dev/null 2>&1
  xcrun simctl launch "$SIM" $BID -label "$label" "$@" >/dev/null
  sleep "$secs"
  D=$(xcrun simctl get_app_container "$SIM" $BID data)/Documents
  cp "$D/$label"-* "$OUT/" 2>/dev/null; xcrun simctl terminate "$SIM" $BID >/dev/null 2>&1
  echo "== $label"; cat "$OUT/$label-summary.txt" 2>/dev/null; echo
}
run_mac() {
  label=$1; secs=$2; shift 2
  "$MACAPP" -label "$label" "$@" >/dev/null 2>&1 &
  pid=$!; sleep "$secs"; kill $pid 2>/dev/null; wait $pid 2>/dev/null
  cp "$MACDOCS/$label"-* "$OUT/" 2>/dev/null
  echo "== $label"; cat "$OUT/$label-summary.txt" 2>/dev/null; echo
}
if [ "$WHERE" != mac ]; then
  xcrun simctl install "$SIM" build/dd/Build/Products/Release-iphonesimulator/Spike.app
  for rt in spritekit rive; do
    run_sim "sim-$rt-latency" 92 -runtime $rt -latency 30 -hold 0.5
    run_sim "sim-$rt-mash" 68 -runtime $rt -mash 60
  done
fi
if [ "$WHERE" != sim ]; then
  # one launch per runtime: 30 latency presses (hold 0.5), then the 60 s mash (hold 3.0) -> <label>-latency/-mash
  for rt in spritekit rive; do
    run_mac "mac-$rt" 160 -runtime $rt -latency 30 -hold 0.5 -mash 60
    for part in latency mash; do echo "== mac-$rt-$part"; cat "$OUT/mac-$rt-$part-summary.txt" 2>/dev/null; echo; done
  done
fi
