#!/usr/bin/env bash
# ADR-0011 D4: the gates, fastest first. Exits non-zero if any gate fails. Runs at nice 10 and stops if the load
# average goes above LOAD_MAX (default 40). Headless only (K-34): no Simulator window, no macOS app launch.
#   tools/ci/verify.sh (--dev | --qc) [--app <path.app>]... [--evidence <dir>] [--no-xcode]
set -u
if [ -z "${VERIFY_NICED:-}" ]; then VERIFY_NICED=1 exec nice -n 10 "$0" "$@"; fi
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT" || exit 2
SIMPATH="" EVIDENCE="" XCODE=1 APPS=()
while [ $# -gt 0 ]; do
  case "$1" in
    --dev|--qc) SIMPATH="$1" ;;
    --app) shift; APPS+=("$1") ;;
    --evidence) shift; EVIDENCE="$1" ;;
    --no-xcode) XCODE=0 ;;
    *) echo "verify: unknown option $1" >&2; exit 2 ;;
  esac; shift
done
LOAD_MAX="${LOAD_MAX:-40}"
BUILD="$ROOT/.build"
OUT="$(mktemp)"; fails=0
say() { printf '%s\n' "$*" | sed "s#$HOME#~#g" | tee -a "$OUT"; }
load_ok() {
  local l; l="$(sysctl -n vm.loadavg | awk '{print $2}')"
  if awk "BEGIN{exit !($l > $LOAD_MAX)}"; then say "STOP load $l > $LOAD_MAX: verify paused (re-run when the load is down)"; finish 4; fi
}
gate() { # name, command...
  local name="$1"; shift; load_ok
  local log; log="$(mktemp)"
  if "$@" >"$log" 2>&1; then say "PASS $name"; else say "FAIL $name"; sed "s#$HOME#~#g" "$log" | grep -E 'BAN |STALE|error:|FAIL|failed|REFUSED' | head -20 | sed 's/^/    /' | tee -a "$OUT"; fails=$((fails + 1)); fi
  rm -f "$log"
}
finish() {
  say "verify: $( [ "$fails" -eq 0 ] && echo PASS || echo "FAIL ($fails)") at $(git rev-parse --short HEAD 2>/dev/null)$(git diff --quiet 2>/dev/null || echo ' (with local changes)')"
  if [ -n "$EVIDENCE" ]; then mkdir -p "$EVIDENCE"; cp "$OUT" "$EVIDENCE/verify.txt"; fi
  rm -f "$OUT"; exit "${1:-$([ "$fails" -eq 0 ] && echo 0 || echo 1)}"
}

say "verify: $(xcodebuild -version | head -1), $(swift --version 2>&1 | head -1 | sed 's/.*Swift version /Swift /; s/ (.*//')"
# 1. ADR-0002 ban grep
gate "ban-grep (ADR-0002 V1)" tools/ci/ban-grep.sh "$ROOT"
# 2. API surface staleness (ADR-0002 V4)
api_check() {
  (cd apple/Tools && swift build --scratch-path "$BUILD/swiftpm/Tools" -q) || return 1
  local m
  for m in KidCore MorphCore; do
    (cd "apple/$m" && swift package --scratch-path "$BUILD/swiftpm/$m" dump-symbol-graph >/dev/null) || return 1
    "$BUILD/swiftpm/Tools/debug/kidtools" api-surface --check "$BUILD/swiftpm/$m/out/symbolgraph" "$m" "contracts/$(echo "$m" | tr '[:upper:]' '[:lower:]')-api.md" || return 1
  done
}
gate "api-surface (ADR-0002 V4)" api_check
# 3. Content and contracts (ADR-0003, ADR-0004): wired in S2.
say "OBSERVED contracts: harness not wired until S2, $(ls -d contracts/*-v*/ 2>/dev/null | wc -l | tr -d ' ') contracts unrun"
# 4. swift test
for m in MorphCore KidCore ContractKit Tools; do gate "swift test $m" swift test --package-path "apple/$m" --scratch-path "$BUILD/swiftpm/$m"; done
# 5. Xcode, headless
if [ "$XCODE" = 1 ]; then
  gate "xcodebuild build macOS" xcodebuild -project apple/LetterMorph.xcodeproj -scheme LetterMorph -destination platform=macOS -derivedDataPath "$BUILD/xcode" -quiet build
  gate "xcodebuild test macOS (hostless unit tests)" xcodebuild -project apple/LetterMorph.xcodeproj -scheme LetterMorph -destination platform=macOS -derivedDataPath "$BUILD/xcode" -only-testing:LetterMorphTests -quiet test
  if [ -n "$SIMPATH" ]; then
    if SIM="$(tools/ci/sim-guard.sh "$SIMPATH")"; then
      gate "xcodebuild test iPad simulator ($SIMPATH, headless)" xcodebuild -project apple/LetterMorph.xcodeproj -scheme LetterMorph -destination "platform=iOS Simulator,id=$SIM" -derivedDataPath "$BUILD/xcode" -quiet test
    else say "FAIL simulator guard ($SIMPATH)"; fails=$((fails + 1)); fi
  else say "SKIP iPad simulator test: pass --dev or --qc"; fi
fi
# 6. ADR-0003 D8 bundle-content scan, only with --app
if [ "${#APPS[@]}" -eq 0 ]; then say "SKIP bundle-content scan: no --app given (QC runs it on both Release .apps)"; fi
bundle_scan() {
  local hits; hits="$(find "$1" \( -name src -o -name '*.svg' -o -name fixtures -o -name tools -o -name '*.py' -o -name '*.sh' \) 2>/dev/null)"
  [ -z "$hits" ] || { printf 'FAIL bundle contains: %s\n' "$hits"; return 1; }
}
for a in "${APPS[@]+"${APPS[@]}"}"; do gate "bundle-content scan $(basename "$a")" bundle_scan "$a"; done
finish
