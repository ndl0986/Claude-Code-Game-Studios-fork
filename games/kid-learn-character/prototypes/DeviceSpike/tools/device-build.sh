#!/bin/bash
# PROTOTYPE - NOT FOR PRODUCTION (TASK-078) — build the exact product to install, keep its logs, gate it.
# Usage: tools/device-build.sh <ios|mac> <evidence dir> [devicespike|norive]
#   devicespike (default): prototypes/DeviceSpike, scheme DeviceSpike, tests = SpikeKit
#   norive: prototypes/TASK-033-anim-runtime SpikeNoRive.xcodeproj (the P-1 baseline), tests = MorphCore
# ios builds a signed iphoneos .app with automatic signing on Luan's Personal Team (K-28, K-37). The team ID is
# never committed: it comes from $SPIKE_TEAM_ID or tools/team-id.local (one line, gitignored).
# mac builds the macOS .app (ad-hoc signed, sandbox-only entitlements). Headless (K-34): nothing is launched here.
# Writes into <evidence dir> (the run's <run task>/<sha>/): build-<plat>.txt, test.txt, spike-check-<plat>.txt.
# Exit: the spike check's exit (1 = do not install).
set -u
PLAT=${1:?ios|mac}; EV=${2:?evidence dir}; WHAT=${3:-devicespike}
HERE=$(cd "$(dirname "$0")/.." && pwd)
mkdir -p "$EV"; EV=$(cd "$EV" && pwd)
case $WHAT in
  devicespike) DIR=$HERE; PROJ=DeviceSpike.xcodeproj; SCHEME=DeviceSpike; SRC=DeviceSpike; PKG=SpikeKit ;;
  norive) DIR=$HERE/../TASK-033-anim-runtime; PROJ=SpikeNoRive.xcodeproj; SCHEME=SpikeNoRive; SRC=Spike; PKG=MorphCore ;;
  *) echo "unknown target $WHAT"; exit 2 ;;
esac
cd "$DIR" || exit 2
case $PLAT in
  ios) TEAM=${SPIKE_TEAM_ID:-$(cat "$HERE/tools/team-id.local" 2>/dev/null)}
       [ -n "$TEAM" ] || { echo "no team ID: set SPIKE_TEAM_ID or write tools/team-id.local"; exit 2; }
       DEST='generic/platform=iOS'; SIGN=(CODE_SIGN_STYLE=Automatic DEVELOPMENT_TEAM="$TEAM" -allowProvisioningUpdates)
       APP=build/device/Build/Products/Debug-iphoneos/$SCHEME.app ;;
  mac) DEST='generic/platform=macOS'; SIGN=(); APP=build/device/Build/Products/Debug/$SCHEME.app ;;
  *) echo "unknown platform $PLAT"; exit 2 ;;
esac
# K-34: niced, and wait while the machine is loaded (1-min load average above ~40)
while [ "$(sysctl -n vm.loadavg | awk '{print int($2)}')" -gt 40 ]; do echo "load high, waiting"; sleep 15; done
nice -n 10 xcodebuild -project "$PROJ" -scheme "$SCHEME" -destination "$DEST" -derivedDataPath build/device ${SIGN[@]+"${SIGN[@]}"} build \
  > "$EV/build-$PLAT.txt" 2>&1; b=$?
(cd "$PKG" && nice -n 10 swift test) > "$EV/test.txt" 2>&1; t=$?
grep -q 'BUILD SUCCEEDED' "$EV/build-$PLAT.txt" && [ $b -eq 0 ] && [ $t -eq 0 ] && r=PASS || r=FAIL
# the team ID stays out of the evidence
[ -n "${TEAM:-}" ] && sed -i '' "s/$TEAM/<TEAM>/g" "$EV/build-$PLAT.txt"
SPIKE_BUILD_TESTS="$r xcodebuild $SCHEME $PLAT exit $b; $PKG swift test exit $t (build-$PLAT.txt, test.txt)" \
  "$HERE/tools/spike-check.sh" . "$SRC" "$PROJ/project.pbxproj" "$APP" > "$EV/spike-check-$PLAT.txt" 2>&1; c=$?
codesign -dvv "$APP" 2>&1 | grep -E '^(Identifier|Authority|TeamIdentifier|Signature)' | sed "s/${TEAM:-NO_TEAM_SET}/<TEAM>/g" >> "$EV/spike-check-$PLAT.txt"
# the team ID stays out of the check output too (a FAIL prints the entitlements XML, which holds it on iOS)
[ -n "${TEAM:-}" ] && sed -i '' "s/$TEAM/<TEAM>/g" "$EV/spike-check-$PLAT.txt"
echo "$APP -> $EV (check exit $c)"; exit $c
