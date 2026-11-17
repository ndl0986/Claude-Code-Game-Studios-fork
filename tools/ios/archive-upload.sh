#!/bin/bash
# archive-upload.sh — archive the Release app and upload it to App Store Connect for TestFlight (TASK-026 Path B).
# Needs the paid Apple Developer Program membership and the app record in App Store Connect
# (production/releases/ios-device-and-testflight.md). Release still stops at the R12 content gate until Luan
# signs off history claims C01–C16 (ADR-0001): this script never skips it.
#
# Usage:  TEAM_ID=ABCDE12345 tools/ios/archive-upload.sh [--dry-run]
# Env:    TEAM_ID       required: the paid team's 10-character ID
#         BUILD_NUMBER  CFBundleVersion (default: `git rev-list --count HEAD`, which only grows on main)
#         UPLOAD        1 (default) uploads; 0 exports an .ipa to OUT/export and sends nothing
#         OUT           output folder (default build/archive, gitignored)
#         ASC_KEY_PATH, ASC_KEY_ID, ASC_ISSUER_ID   optional App Store Connect API key (.p8 kept outside the repo,
#                       e.g. ~/.appstoreconnect/private_keys). Without them, the Apple ID signed in to Xcode is used.
# --dry-run prints the commands and runs nothing.
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"
DRY=0; [ "${1:-}" = "--dry-run" ] && DRY=1
TEAM_ID=${TEAM_ID:-}
[ -n "$TEAM_ID" ] || { echo "TEAM_ID is not set (the paid team's ID)" >&2; exit 2; }
[ -z "$(git status --porcelain)" ] || [ $DRY = 1 ] || { echo "the working tree has changes; archive a committed state" >&2; exit 2; }
N=${BUILD_NUMBER:-$(git rev-list --count HEAD)}
VERSION=$(grep -m1 -o 'MARKETING_VERSION = [^;]*' ios/DaiDatAnhHung.xcodeproj/project.pbxproj | cut -d' ' -f3)
OUT=${OUT:-build/archive}; ARCHIVE="$OUT/DaiDatAnhHung-$VERSION-$N.xcarchive"
AUTH=()
if [ -n "${ASC_KEY_PATH:-}" ]; then
  AUTH=(-authenticationKeyPath "$ASC_KEY_PATH" -authenticationKeyID "${ASC_KEY_ID:?}" -authenticationKeyIssuerID "${ASC_ISSUER_ID:?}")
fi
OPTS="$OUT/ExportOptions.plist"
ARCH=(xcodebuild archive -project ios/DaiDatAnhHung.xcodeproj -scheme DaiDatAnhHung -configuration Release
  -destination generic/platform=iOS -archivePath "$ARCHIVE" -allowProvisioningUpdates ${AUTH[@]+"${AUTH[@]}"}
  "DEVELOPMENT_TEAM=$TEAM_ID" CODE_SIGN_STYLE=Automatic "CURRENT_PROJECT_VERSION=$N")
EXPORT=(xcodebuild -exportArchive -archivePath "$ARCHIVE" -exportOptionsPlist "$OPTS" -exportPath "$OUT/export"
  -allowProvisioningUpdates ${AUTH[@]+"${AUTH[@]}"})
CHECK=(tools/qa/ios-release-check.sh Release)
if [ $DRY = 1 ]; then
  echo "# version $VERSION build $N"
  printf '%q ' "${CHECK[@]}"; echo; printf '%q ' "${ARCH[@]}"; echo; printf '%q ' "${EXPORT[@]}"; echo
  exit 0
fi
mkdir -p "$OUT"
echo "1/3 release check (no debug code in Release) …"; "${CHECK[@]}"
echo "2/3 archive $VERSION ($N) …"
"${ARCH[@]}" > "$OUT/archive.log" 2>&1 || { echo "archive failed: $OUT/archive.log" >&2; grep -m5 "error:" "$OUT/archive.log" >&2; exit 1; }
cp ios/Config/ExportOptions.plist "$OPTS"
plutil -replace teamID -string "$TEAM_ID" "$OPTS"
[ "${UPLOAD:-1}" = 1 ] || plutil -replace destination -string export "$OPTS"
echo "3/3 export ($( [ "${UPLOAD:-1}" = 1 ] && echo upload || echo "ipa only")) …"
"${EXPORT[@]}" > "$OUT/export.log" 2>&1 || { echo "export failed: $OUT/export.log" >&2; grep -m5 "error" "$OUT/export.log" >&2; exit 1; }
echo "done: $ARCHIVE. Uploads appear in App Store Connect → TestFlight after processing (usually minutes)."
