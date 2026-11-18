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

# contract-rows.sh (K-40, /story-done): reads a planted registry row by row; observations, never verdicts
CR="$ROOT/tools/ci/contract-rows.sh"
cat > "$T/cr.md" <<'MD'
## Current versions

| Contract | Version | Owner GDD | Layers | Status |
|---|---|---|---|---|
| alpha-v1 | v1 | alpha.md | KidCore | superseded |
| alpha-v2 | v2 | alpha.md; other.md F1 | KidCore | x |
| beta-v1 | v1 | beta.md (G1) | KidCore | x |
| gamma-v1 | v1 | gamma.md | KidCore | x |

## Registry

| Contract | Row | Cases |
|---|---|---|
| alpha-v1 | superseded-by: alpha-v2 | 3 |
| alpha-v2 | not-started: story:alpha | 4 |
| beta-v1 | runner: BetaRunner | 5 |
MD
cr_planted_other() { sed 's/runner: BetaRunner/runnr BetaRunner/' "$T/cr.md" > "$T/cr2.md"; ! "$CR" --readme "$T/cr2.md" --system beta | grep -q 'kind=other'; }
cr_has() { local want="$1"; shift; "$CR" --readme "$T/cr.md" "$@" | grep -qx -- "$want"; }
cr_only() { local want="$1"; shift; [ "$("$CR" --readme "$T/cr.md" "$@")" = "$want" ]; }
expect_pass "contract-rows: an owner's not-started row" cr_has 'ROW alpha-v2 kind=not-started owner=alpha,other story=story:alpha match=system row=not-started: story:alpha' --system alpha
expect_pass "contract-rows: the superseded row is reported as superseded-by" cr_has 'ROW alpha-v1 kind=superseded-by owner=alpha story=- match=system row=superseded-by: alpha-v2' --system design/gdd/alpha.md
expect_pass "contract-rows: a cited GDD is blocked too (every stem in the Owner cell)" cr_only 'ROW alpha-v2 kind=not-started owner=alpha,other story=story:alpha match=system row=not-started: story:alpha' --system other
expect_pass "contract-rows: a partial stem matches nothing" cr_only 'NONE' --system alph
expect_pass "contract-rows: a note after the GDD is not a stem" cr_only 'ROW beta-v1 kind=runner owner=beta story=- match=system row=runner: BetaRunner' --system beta
expect_pass "contract-rows: matched by story id alone" cr_only 'ROW alpha-v2 kind=not-started owner=alpha,other story=story:alpha match=story row=not-started: story:alpha' --story story:alpha
expect_pass "contract-rows: a path never matches a placeholder" cr_only 'NONE' --story production/epics/alpha/alpha.md
expect_pass "contract-rows: an owned contract with no Registry row" cr_only 'UNREGISTERED gamma-v1 owner=gamma' --system gamma
expect_pass "contract-rows: a missing README is reported, not passed" cr_only "README MISSING $T/none.md" --readme "$T/none.md" --system alpha
expect_fail "contract-rows: no --system and no --story is a usage error" "$CR" --readme "$T/cr.md"
# the real registry: every owner's rows come back, and none is of an unknown form
cr_real() { local o out; for o in $(sed -n '/^## Current versions/,/^## /p' "$ROOT/contracts/README.md" | grep -oE '^\| [a-z0-9-]+-v[0-9]+ \| v[0-9]+ \| [A-Za-z0-9_.-]+\.md' | sed -E 's/.* ([A-Za-z0-9_.-]+)\.md$/\1/' | sort -u); do
  out="$("$CR" --system "$o")" || return 1; [ -n "$out" ] && [ "$out" != NONE ] || return 1; ! printf '%s\n' "$out" | grep -q -e 'kind=other' -e '^README MISSING' || return 1; done; }
expect_pass "contract-rows: every real registry row has a known form" cr_real
expect_fail "contract-rows: a row of no known form is seen (planted)" cr_planted_other

# verify.sh: a run stopped by the load check is never reported as PASS (exit 4, a STOPPED summary)
vout="$(LOAD_MAX=-1 "$ROOT/tools/ci/verify.sh" --dev --no-xcode 2>&1)"; vrc=$?
if [ "$vrc" = 4 ] && printf '%s\n' "$vout" | grep -q '^verify: STOPPED (load), not a pass' && ! printf '%s\n' "$vout" | grep -q '^verify: PASS'; then
  echo "caught verify stopped by load is not a PASS"
else echo "MISSED verify stopped by load is not a PASS (exit $vrc)"; bad=$((bad + 1)); fi

echo "self-test: $( [ "$bad" -eq 0 ] && echo PASS || echo "FAIL ($bad)")"
[ "$bad" -eq 0 ]
