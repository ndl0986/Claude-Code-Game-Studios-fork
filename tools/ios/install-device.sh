#!/bin/bash
# install-device.sh — build the game and install it on a real iPhone, signed by Xcode's automatic signing
# (TASK-026 Path A: Luan's free Personal Team, or the paid team later). Rerun it weekly: a free team's
# provisioning profile expires 7 days after it is issued, and then the app no longer opens until it is rebuilt
# and reinstalled. Progress (stars, medal) is kept: installing over the old app keeps its saved data.
#
# Usage:  TEAM_ID=ABCDE12345 DEVICE="Luan's iPhone" tools/ios/install-device.sh [--dry-run]
# Env:    TEAM_ID  required. The team ID Xcode signs with: Xcode → Settings → Accounts → the "(Personal Team)",
#                  or the 10-character ID in the first signing's log. Never committed to the project.
#         DEVICE   required. The phone's name, UDID or ECID as `xcrun devicectl list devices` prints it.
#         CONFIG   Preview (default; D-37: optimised, debug code compiled out, UNSIGNED badges shown, R12 gate
#                  skipped, bundle …preview) or Debug (bundle …debug; only for a debugger session). Release is
#                  archive-only (tools/ios/archive-upload.sh) and is refused here.
#         OUT      derived-data folder (default build/device in the repo, gitignored)
#         LAUNCH   1 to open the app after installing
# --dry-run prints the commands and runs nothing.
#
# The phone must be paired with this Mac (cable the first time; after that it can work over the same Wi-Fi when
# Xcode's Device Hub has the network connection on), unlocked, and in Developer Mode. See
# production/releases/ios-device-and-testflight.md.
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"
DRY=0; [ "${1:-}" = "--dry-run" ] && DRY=1
TEAM_ID=${TEAM_ID:-}; DEVICE=${DEVICE:-}
CONFIG=${CONFIG:-Preview}; OUT=${OUT:-build/device}
case "$CONFIG" in
  Preview) BUNDLE=com.galaxyandsun.daidatanhhung.preview; EXTRA=() ;;
  Debug)   BUNDLE=com.galaxyandsun.daidatanhhung.debug; EXTRA=("PRODUCT_BUNDLE_IDENTIFIER=$BUNDLE") ;;
  *) echo "CONFIG must be Preview or Debug (Release is archive-only: tools/ios/archive-upload.sh)" >&2; exit 2 ;;
esac
[ -n "$TEAM_ID" ] || { echo "TEAM_ID is not set (Xcode → Settings → Accounts → your team)" >&2; exit 2; }
[ -n "$DEVICE" ] || { echo "DEVICE is not set (xcrun devicectl list devices)" >&2; exit 2; }
if xcrun simctl list devices 2>/dev/null | grep -qF -- "$DEVICE"; then
  echo "DEVICE '$DEVICE' matches a Simulator; this script installs on a real iPhone only" >&2; exit 2
fi
APP="$OUT/Build/Products/$CONFIG-iphoneos/DaiDatAnhHung.app"
# The phone's UDID: a free team's provisioning profile must list the device, and xcodebuild registers it only when it
# builds for that device (not for generic/platform=iOS).
UDID=$(mkdir -p "$OUT" && xcrun devicectl list devices --json-output "$OUT/devices.json" >/dev/null 2>&1 && python3 -I - "$OUT/devices.json" "$DEVICE" <<'PY'
import json, sys
devs = json.load(open(sys.argv[1]))["result"]["devices"]
want = sys.argv[2]
for d in devs:
    hw, dp = d.get("hardwareProperties", {}), d.get("deviceProperties", {})
    if hw.get("reality") != "physical": continue
    if want in (hw.get("udid"), dp.get("name"), d.get("identifier"), str(hw.get("ecid"))):
        print(hw.get("udid")); break
PY
)
[ -n "$UDID" ] || [ $DRY = 1 ] || { echo "no paired physical device matches '$DEVICE' (xcrun devicectl list devices)" >&2; exit 2; }
BUILD=(xcodebuild build -project ios/DaiDatAnhHung.xcodeproj -scheme DaiDatAnhHung -configuration "$CONFIG"
  -destination "platform=iOS,id=${UDID:-<udid>}" -derivedDataPath "$OUT" -allowProvisioningUpdates -allowProvisioningDeviceRegistration
  "DEVELOPMENT_TEAM=$TEAM_ID" CODE_SIGN_STYLE=Automatic ${EXTRA[@]+"${EXTRA[@]}"})
INSTALL=(xcrun devicectl device install app --device "$DEVICE" "$APP")
LAUNCHCMD=(xcrun devicectl device process launch --device "$DEVICE" "$BUNDLE")
if [ $DRY = 1 ]; then
  printf '%q ' "${BUILD[@]}"; echo; printf '%q ' "${INSTALL[@]}"; echo
  [ "${LAUNCH:-0}" = 1 ] && { printf '%q ' "${LAUNCHCMD[@]}"; echo; }
  exit 0
fi
mkdir -p "$OUT"
echo "building $CONFIG ($BUNDLE) for team $TEAM_ID …"
"${BUILD[@]}" > "$OUT/build.log" 2>&1 || { echo "build failed: $OUT/build.log" >&2; grep -m5 "error:" "$OUT/build.log" >&2; exit 1; }
EXP=$(security cms -D -i "$APP/embedded.mobileprovision" 2>/dev/null | plutil -extract ExpirationDate raw -o - - 2>/dev/null || echo "?")
echo "signed; the provisioning profile expires $EXP (rerun this script before then)"
TRANSPORT=$(xcrun devicectl device info details --device "$DEVICE" 2>/dev/null | grep -m1 -i "Transport Type" | awk "{print \$NF}" || true)
echo "device connection: ${TRANSPORT:-unknown} (wired = cable, localNetwork = Wi-Fi)"
"${INSTALL[@]}"
[ "${LAUNCH:-0}" = 1 ] && "${LAUNCHCMD[@]}"
echo "installed $APP on $DEVICE"
