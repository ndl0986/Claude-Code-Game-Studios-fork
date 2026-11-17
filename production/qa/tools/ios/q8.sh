#!/bin/bash
# QC helper for the iOS Simulator (game-qc-ios).
# usage: q8.sh shot NAME | tmp | launch ARGS... | term | defaults
# env:   U   Simulator UDID (default: QC iPhone 18 Pro E9F515E9)
#        E   evidence folder for `shot` (default: TASK-006/ios-qc-r8 in this worktree)
#        S   scratch folder for `tmp` (default: $TMPDIR)
ROOT=$(cd "$(dirname "$0")/../../../.." && pwd)
E=${E:-$ROOT/production/qa/evidence/TASK-006/ios-qc-r8}
S=${S:-${TMPDIR:-/tmp}}
U=${U:-E9F515E9-58F2-4A92-ABEF-C5CD59CE8183}
ID=com.galaxyandsun.daidatanhhung
cmd=$1; shift
case $cmd in
 shot) mkdir -p "$E"; xcrun simctl io $U screenshot "$E/$1.png" >/dev/null 2>&1; echo "$E/$1.png";;
 tmp) xcrun simctl io $U screenshot "$S/tmp.png" >/dev/null 2>&1; sips -Z 1100 "$S/tmp.png" --out "$S/view.png" >/dev/null; echo "$S/view.png";;
 launch) xcrun simctl terminate $U $ID 2>/dev/null; xcrun simctl launch $U $ID "$@";;
 term) xcrun simctl terminate $U $ID;;
 defaults) P=$(xcrun simctl get_app_container $U $ID data); plutil -p "$P/Library/Preferences/$ID.plist" 2>&1;;
 *) sed -n 2,6p "$0"; exit 2;;
esac
