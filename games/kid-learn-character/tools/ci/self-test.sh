#!/usr/bin/env bash
# Watches each gate fail on a planted break (ADR-0002 V1, V4; ADR-0011 V1, V3). Prints one line per check and exits 1
# if any gate failed to catch its plant. Works on temporary copies; never edits the tree.
set -u
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT
bad=0
expect_fail() { local name="$1"; shift; if "$@" >/dev/null 2>&1; then echo "MISSED $name"; bad=$((bad + 1)); else echo "caught $name"; fi; }
expect_pass() { local name="$1"; shift; if "$@" >/dev/null 2>&1; then echo "ok     $name"; else echo "BROKEN $name"; bad=$((bad + 1)); fi; }

# ban grep: a clean copy passes, each plant fails
mkdir -p "$T/ban/apple"; cp -R "$ROOT/apple/KidCore" "$ROOT/apple/MorphCore" "$ROOT/apple/ContractKit" "$T/ban/apple/"
rm -rf "$T/ban/apple/KidCore/.build" "$T/ban/apple/MorphCore/.build" "$T/ban/apple/ContractKit/.build"
expect_pass "ban-grep clean tree" "$ROOT/tools/ci/ban-grep.sh" "$T/ban"
plant() { cp -R "$T/ban" "$T/p"; printf '%s\n' "$1" >> "$T/p/apple/KidCore/Sources/KidCore/Helpers.swift"; expect_fail "ban-grep planted: $1" "$ROOT/tools/ci/ban-grep.sh" "$T/p"; rm -rf "$T/p"; }
plant 'let plantedDate = Date()'
plant 'import UIKit'
plant 'let plantedChar: Character = "a"'
plant 'let plantedRound = round(2.5)'
plant 'let n = key.count'
# ContractKit (K-38): the import rule only; JSON decoding is allowed there, a UI or app import is not
CK="apple/ContractKit/Sources/ContractKit/Fixture.swift"
cp -R "$T/ban" "$T/p"; printf 'import UIKit\n' >> "$T/p/$CK"; expect_fail "ban-grep planted in ContractKit: import UIKit" "$ROOT/tools/ci/ban-grep.sh" "$T/p"; rm -rf "$T/p"
cp -R "$T/ban" "$T/p"; printf 'import LetterMorph\n' >> "$T/p/$CK"; expect_fail "ban-grep planted in ContractKit: import LetterMorph" "$ROOT/tools/ci/ban-grep.sh" "$T/p"; rm -rf "$T/p"
cp -R "$T/ban" "$T/p"; printf 'let ckDecoder = JSONDecoder()\n' >> "$T/p/$CK"; expect_pass "ban-grep allows JSONDecoder in ContractKit" "$ROOT/tools/ci/ban-grep.sh" "$T/p"; rm -rf "$T/p"

# API surface: a stale file fails the check
SG="$ROOT/.build/swiftpm/KidCore/out/symbolgraph" K="$ROOT/.build/swiftpm/Tools/debug/kidtools"
if [ -x "$K" ] && [ -d "$SG" ]; then
  cp "$ROOT/contracts/kidcore-api.md" "$T/api.md"; printf -- '- `planted` (func): `func planted()`\n' >> "$T/api.md"
  expect_fail "api-surface stale file" "$K" api-surface --check "$SG" KidCore "$T/api.md"
else echo "SKIP api-surface (run verify.sh first)"; fi

# simulator guards: run a copy of sim-guard against planted env files
mkdir -p "$T/g/tools/ci" "$T/g/tools/dev/apple" "$T/g/tools/qa/apple"; cp "$ROOT/tools/ci/sim-guard.sh" "$T/g/tools/ci/"
echo "DEV_SIM_UDID=475D45B4-557A-4594-B121-60D7F402D033" > "$T/g/tools/dev/apple/sim.env"
expect_fail "sim-guard --dev refuses QC's iPad simulator" "$T/g/tools/ci/sim-guard.sh" --dev
echo "DEV_SIM_UDID=e9f515e9-0000-0000-0000-000000000000" > "$T/g/tools/dev/apple/sim.env"
expect_fail "sim-guard --dev refuses QC's iPhone simulator (any case)" "$T/g/tools/ci/sim-guard.sh" --dev
echo "DEV_SIM_UDID=4B088DA4-B145-4226-9ED5-23B12DCEA676" > "$T/g/tools/dev/apple/sim.env"
expect_pass "sim-guard --dev accepts a developer simulator" "$T/g/tools/ci/sim-guard.sh" --dev
echo "DEV_SIM_UDID=" > "$T/g/tools/dev/apple/sim.env"
expect_fail "sim-guard --dev refuses empty" "$T/g/tools/ci/sim-guard.sh" --dev
echo "QC_SIM_UDID=4B088DA4-0000-0000-0000-000000000000" > "$T/g/tools/qa/apple/sim.env"
expect_fail "sim-guard --qc refuses another simulator" "$T/g/tools/ci/sim-guard.sh" --qc
echo "QC_SIM_UDID=" > "$T/g/tools/qa/apple/sim.env"
expect_fail "sim-guard --qc refuses empty" "$T/g/tools/ci/sim-guard.sh" --qc
echo "QC_SIM_UDID=E9F515E9-0000-0000-0000-000000000000" > "$T/g/tools/qa/apple/sim.env"
expect_fail "sim-guard --qc refuses QC's iPhone simulator (this game is iPad-only)" "$T/g/tools/ci/sim-guard.sh" --qc
echo "QC_SIM_UDID=475D45B4-557A-4594-B121-60D7F402D033" > "$T/g/tools/qa/apple/sim.env"
expect_pass "sim-guard --qc accepts QC's iPad simulator" "$T/g/tools/ci/sim-guard.sh" --qc

# verify.sh: a run stopped by the load check is never reported as PASS (exit 4, a STOPPED summary)
vout="$(LOAD_MAX=-1 "$ROOT/tools/ci/verify.sh" --dev --no-xcode 2>&1)"; vrc=$?
if [ "$vrc" = 4 ] && printf '%s\n' "$vout" | grep -q '^verify: STOPPED (load), not a pass' && ! printf '%s\n' "$vout" | grep -q '^verify: PASS'; then
  echo "caught verify stopped by load is not a PASS"
else echo "MISSED verify stopped by load is not a PASS (exit $vrc)"; bad=$((bad + 1)); fi

echo "self-test: $( [ "$bad" -eq 0 ] && echo PASS || echo "FAIL ($bad)")"
[ "$bad" -eq 0 ]
