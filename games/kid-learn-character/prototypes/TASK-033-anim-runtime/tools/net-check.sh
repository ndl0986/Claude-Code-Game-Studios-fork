#!/bin/sh
# PROTOTYPE - NOT FOR PRODUCTION (TASK-033 spike)
# Play-time network check on macOS. The Release app is sandboxed WITHOUT com.apple.security.network.client, so any
# outbound connection is denied by the sandbox and logged. Four cases, each ~25 s with presses:
#   1 spritekit (control)  2 rive mascot.riv loadCdn=false  3 rive hosted_assets.riv loadCdn=false
#   4 rive hosted_assets.riv loadCdn=true  (positive control: the legacy default; expected to TRY the CDN)
# For each: the sandbox/network log lines for the app's process, and lsof -i samples of its sockets.
set -u
cd "$(dirname "$0")/.."
OUT=../../production/qa/evidence/TASK-033/network; mkdir -p "$OUT"
APP=build/dd/Build/Products/Release/Spike.app
codesign -d --entitlements - "$APP" > "$OUT/entitlements.txt" 2>&1
case_run() { # name args...
  name=$1; shift
  log stream --style compact --predicate '(process == "Spike") OR (sender == "Sandbox" AND eventMessage CONTAINS "Spike") OR (eventMessage CONTAINS "Spike" AND eventMessage CONTAINS "network")' > "$OUT/$name-log.txt" 2>&1 &
  lp=$!; sleep 2
  "$APP/Contents/MacOS/Spike" -label "net-$name" "$@" -latency 6 -hold 0.5 >/dev/null 2>&1 &
  pid=$!
  : > "$OUT/$name-lsof.txt"
  for i in $(seq 1 22); do echo "--- t=$i s" >> "$OUT/$name-lsof.txt"; lsof -nP -i -a -p $pid >> "$OUT/$name-lsof.txt" 2>&1; sleep 1; done
  kill $pid 2>/dev/null; wait $pid 2>/dev/null; sleep 1; kill $lp 2>/dev/null
  n=$(grep -ciE "deny.*network|network-outbound|NSURLErrorDomain|nw_|cdn|http" "$OUT/$name-log.txt")
  s=$(grep -c "IPv\|TCP\|UDP" "$OUT/$name-lsof.txt")
  echo "$name: network-related log lines=$n socket lines=$s"
}
case_run 1-spritekit -runtime spritekit
case_run 2-rive-mascot-cdn0 -runtime rive -riv mascot -cdn 0
case_run 3-rive-hosted-cdn0 -runtime rive -riv hosted_assets -cdn 0
case_run 4-rive-hosted-cdn1 -runtime rive -riv hosted_assets -cdn 1
