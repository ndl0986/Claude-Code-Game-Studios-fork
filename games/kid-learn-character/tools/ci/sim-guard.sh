#!/usr/bin/env bash
# ADR-0011 D3: pick the simulator for a run and refuse the wrong one. Prints the UDID on success.
#   tools/ci/sim-guard.sh --dev   DEV_SIM_UDID from tools/dev/apple/sim.env (untracked); refuses QC's E9F515E9…
#   tools/ci/sim-guard.sh --qc    QC_SIM_UDID from tools/qa/apple/sim.env (untracked); refuses every other simulator
set -u
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
QC_PREFIX="E9F515E9"
case "${1:-}" in
  --dev) f="$ROOT/tools/dev/apple/sim.env"; var=DEV_SIM_UDID ;;
  --qc)  f="$ROOT/tools/qa/apple/sim.env";  var=QC_SIM_UDID ;;
  *) echo "sim-guard: pass --dev or --qc" >&2; exit 2 ;;
esac
udid=""
if [ -f "$f" ]; then udid="$(sed -n "s/^$var=//p" "$f" | head -1 | tr -d '[:space:]')"; fi
if [ -z "$udid" ]; then echo "sim-guard: REFUSED: $var is empty (set it in ${f#"$ROOT"/})" >&2; exit 3; fi
up="$(printf '%s' "$udid" | tr '[:lower:]' '[:upper:]')"
if [ "$1" = --dev ] && [ "${up#"$QC_PREFIX"}" != "$up" ]; then echo "sim-guard: REFUSED: the dev path cannot use QC's simulator $QC_PREFIX…" >&2; exit 3; fi
if [ "$1" = --qc ] && [ "${up#"$QC_PREFIX"}" = "$up" ]; then echo "sim-guard: REFUSED: the QC path uses only QC's simulator $QC_PREFIX…" >&2; exit 3; fi
printf '%s\n' "$udid"
