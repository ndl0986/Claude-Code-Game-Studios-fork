#!/usr/bin/env bash
# ADR-0011 D3: pick the simulator for a run and refuse the wrong one. Prints the UDID on success.
#   tools/ci/sim-guard.sh --dev   DEV_SIM_UDID from tools/dev/apple/sim.env (untracked); refuses QC's simulators
#   tools/ci/sim-guard.sh --qc    QC_SIM_UDID from tools/qa/apple/sim.env (untracked); only QC's iPad simulator
# QC's simulators (ADR-0011 D3 note, TASK-097): 475D45B4… is QC's iPad (this game is iPad-only); E9F515E9… is QC's
# iPhone for the old game. This script is this game's only, so --qc accepts the iPad alone; --dev refuses both.
set -u
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
QC_IPAD="475D45B4"
QC_ALL="475D45B4 E9F515E9"
case "${1:-}" in
  --dev) f="$ROOT/tools/dev/apple/sim.env"; var=DEV_SIM_UDID ;;
  --qc)  f="$ROOT/tools/qa/apple/sim.env";  var=QC_SIM_UDID ;;
  *) echo "sim-guard: pass --dev or --qc" >&2; exit 2 ;;
esac
udid=""
if [ -f "$f" ]; then udid="$(sed -n "s/^$var=//p" "$f" | head -1 | tr -d '[:space:]')"; fi
if [ -z "$udid" ]; then echo "sim-guard: REFUSED: $var is empty (set it in ${f#"$ROOT"/})" >&2; exit 3; fi
up="$(printf '%s' "$udid" | tr '[:lower:]' '[:upper:]')"
if [ "$1" = --dev ]; then
  for p in $QC_ALL; do
    if [ "${up#"$p"}" != "$up" ]; then echo "sim-guard: REFUSED: the dev path cannot use QC's simulator $p…" >&2; exit 3; fi
  done
fi
if [ "$1" = --qc ] && [ "${up#"$QC_IPAD"}" = "$up" ]; then echo "sim-guard: REFUSED: the QC path uses only QC's iPad simulator $QC_IPAD…" >&2; exit 3; fi
printf '%s\n' "$udid"
