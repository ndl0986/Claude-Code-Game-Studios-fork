#!/bin/bash
# ios-touch-tests.sh — run the frozen iOS build's XCUITest touch cases on QC's own Simulator (TASK-023 G).
#
# Usage:  tools/qa/ios-touch-tests.sh <frozen build folder> [output folder]
#   <frozen build folder>  production/qa/builds/TASK-006-ios-<hash>  (holds DaiDatAnhHung.app, the
#                          *.xctestrun file and Debug-iphonesimulator/ with the UI-test runner)
#   [output folder]        default: <frozen build folder>/touch-results-<date-time>
# Env:    SIM_UDID  the Simulator to use (default: QC's iPhone 18 Pro, E9F515E9-58F2-4A92-ABEF-C5CD59CE8183)
#         ONLY      one test, e.g. ONLY=test_B1_two_fast_taps_on_next_advance_one_box
#         TIMEOUT   hard cap on the whole run in seconds (default 900); each test also times out after 120 s
#
# Nothing is compiled (test-without-building runs the frozen bundles). It needs no macOS Accessibility
# permission: iOS-Simulator UI tests are driven inside the Simulator. The Simulator must be booted.
# Output: result.xcresult, summary.json and tests.json (pass/fail per case), and attachments/ (the
# screenshots and notes each case attaches, with manifest.json). B1 reports its measured tap gap; a run
# where XCUITest's taps were >= 0.25 s apart is reported SKIPPED ("not exercised"), never as a pass.
set -euo pipefail
BUILD=${1:?usage: ios-touch-tests.sh <frozen build folder> [output folder]}
OUT=${2:-$BUILD/touch-results-$(date +%Y%m%d-%H%M%S)}
UDID=${SIM_UDID:-E9F515E9-58F2-4A92-ABEF-C5CD59CE8183}
RUN=$(ls "$BUILD"/*.xctestrun 2>/dev/null | head -1)
[ -n "$RUN" ] || { echo "no .xctestrun in $BUILD" >&2; exit 2; }
xcrun simctl list devices | grep -q "$UDID) (Booted)" || { echo "Simulator $UDID is not booted" >&2; exit 2; }
mkdir -p "$OUT"
FILTER="DaiDatAnhHungUITests"; [ -n "${ONLY:-}" ] && FILTER="DaiDatAnhHungUITests/TouchCasesUITests/$ONLY"
set +e
# guards against a hung run sitting on the CPU: per-test timeouts in XCTest, and a hard cap on the whole run
# (TIMEOUT seconds, default 900) when a `timeout` command exists
CAP=""; command -v timeout >/dev/null && CAP="timeout ${TIMEOUT:-900}"
$CAP xcodebuild test-without-building -xctestrun "$RUN" -destination "id=$UDID" -only-testing:"$FILTER" \
  -test-timeouts-enabled YES -default-test-execution-time-allowance 120 -maximum-test-execution-time-allowance 300 \
  -resultBundlePath "$OUT/result.xcresult" > "$OUT/xcodebuild.log" 2>&1
STATUS=$?
set -e
xcrun xcresulttool get test-results summary --path "$OUT/result.xcresult" > "$OUT/summary.json" || true
xcrun xcresulttool get test-results tests --path "$OUT/result.xcresult" > "$OUT/tests.json" || true
xcrun xcresulttool export attachments --path "$OUT/result.xcresult" --output-path "$OUT/attachments" > /dev/null || true
grep -E "Test Case .*(passed|failed|skipped)" "$OUT/xcodebuild.log" | sed 's/^Test Case //' || true
echo "results: $OUT  (xcodebuild exit $STATUS)"
exit $STATUS
