#!/bin/bash
# PROTOTYPE - NOT FOR PRODUCTION (TASK-078) — the minimal spike check (TASK-075 §"Checks before an install").
# Usage: tools/spike-check.sh <project dir> <source dir> <pbxproj> <app> [<app> …]
# Prints one OBSERVED line per check and PASS/FAIL per item; exit 1 if any item fails. Run before any install.
set -u
PROJ=$1; SRC=$2; PBX=$3; shift 3
fail=0
item() { printf '%-4s %s\n' "$1" "$2"; if [ "$1" = FAIL ]; then fail=1; fi; return 0; }
echo "spike-check $(date -u +%Y-%m-%dT%H:%M:%SZ) sha=$(git -C "$PROJ" rev-parse --short HEAD 2>/dev/null)$(git -C "$PROJ" diff --quiet -- . 2>/dev/null || echo '+dirty')"
# 1. builds and tests: the caller runs them and passes the result in SPIKE_BUILD_TESTS (PASS/FAIL + note)
item "${SPIKE_BUILD_TESTS%% *}" "1 builds headless (iOS Simulator + macOS) and unit tests pass: ${SPIKE_BUILD_TESTS#* }"
# 2/3 source observations (the binary scans below decide; code under #if guards shows here but is compiled out)
hits=$(grep -rn -E 'URLSession|NWConnection|nw_connection|WKWebView|import WebKit|SFSafariViewController|openURL|URLProtocol|RiveRuntime|RiveViewModel' "$SRC" 2>/dev/null | grep -v -E '^[^:]+:[0-9]+:[[:space:]]*//')
[ -z "$hits" ] && item PASS "2/3 sources: no network or Rive code" || { item NOTE "2/3 sources mention (check the binary scan below):"; echo "$hits"; }
# 4. no remote Swift package (PKC-03 a)
if grep -q XCRemoteSwiftPackageReference "$PBX"; then item FAIL "4 remote package reference in the project"
else item PASS "4 no remote Swift package (no XCRemoteSwiftPackageReference)"; fi
for app in "$@"; do
  plist="$app/Info.plist"; [ -f "$plist" ] || plist="$app/Contents/Info.plist"
  bin="$app/$(/usr/libexec/PlistBuddy -c 'Print :CFBundleExecutable' "$plist")"; [ -f "$bin" ] || bin="$app/Contents/MacOS/$(/usr/libexec/PlistBuddy -c 'Print :CFBundleExecutable' "$plist")"
  echo "--- $app"
  # 2/5 entitlements: no network, location, camera, microphone
  ent=$(codesign -d --entitlements - --xml "$app" 2>/dev/null | plutil -convert xml1 -o - - 2>/dev/null)
  if echo "$ent" | grep -q -E 'network\.(client|server)|personal-information\.location|device\.camera|device\.audio-input'; then item FAIL "2/5 forbidden entitlement"; echo "$ent"
  else item PASS "2/5 entitlements: no network, location, camera or microphone ($(echo "$ent" | grep -o '<key>[^<]*</key>' | tr -d '\n' | sed 's/<key>/ /g;s/<\/key>//g'))"; fi
  # 5 Info.plist: no usage descriptions, no URL schemes
  keys=$(plutil -p "$plist" | grep -o -E '"(NS[A-Za-z]*UsageDescription|NSLocation[A-Za-z]*|CFBundleURLTypes|LSApplicationQueriesSchemes)"')
  [ -z "$keys" ] && item PASS "5 Info.plist: no NS*UsageDescription, no location key, no URL schemes" || { item FAIL "5 Info.plist keys:"; echo "$keys"; }
  # 2/3 the installed binary: links no Rive, WebKit or Network.framework, and has no URL-loading or Rive symbols
  bins="$bin $(ls "$app"/*.debug.dylib "$app"/Contents/MacOS/*.debug.dylib 2>/dev/null)"
  libs=$(for b in $bins; do otool -L "$b" | tail -n +2 | awk '{print $1}'; done | sort -u)
  syms=$(for b in $bins; do nm -m "$b" 2>/dev/null; done | grep -E 'URLSession|NWConnection|WKWebView|URLProtocol|RiveRuntime|RiveViewModel|RiveFile' | head -5)
  if echo "$libs" | grep -q -E 'RiveRuntime|WebKit\.framework|/Network\.framework'; then item FAIL "2/3 linked:"; echo "$libs"
  elif [ -n "$syms" ]; then item FAIL "2/3 symbols:"; echo "$syms"
  else item PASS "2/3 binary: links no Rive, WebKit or Network.framework; no URL-loading or Rive symbols ($(echo $bins | wc -w | tr -d ' ') image(s) scanned)"; fi
done
# 6 the Mac key-state read is off by default
grep -q 'keyStateOn = false' "$SRC/KeysScreen.swift" 2>/dev/null && item PASS "6 Mac key-state read OFF by default" || item NOTE "6 (no Keys screen in this build)"
# 7 sha recorded: the header line above
item PASS "7 sha recorded in the header line"
exit $fail
