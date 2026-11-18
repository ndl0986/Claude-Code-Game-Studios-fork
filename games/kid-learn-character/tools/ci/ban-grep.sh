#!/usr/bin/env bash
# ADR-0002 Validation 1: the type and import ban over the cores' Sources. A gate (ADR-0011 D1): prints file:line for
# every hit and exits 1 if there is any. Comments are ignored (text after //).
#   tools/ci/ban-grep.sh [<root>]   root defaults to the game folder; scans <root>/apple/{KidCore,MorphCore}/Sources
#   and <root>/apple/ContractKit/Sources.
# ContractKit (K-38, test-only, never linked into the app) gets the import and platform rule only: it may import
# Foundation, Swift, XCTest, Testing, KidCore and MorphCore, and nothing else (no app, UI or platform-media framework,
# nothing from the app). The type, JSON-coding, String and rounding bans do not apply to it: decoding JSON is its job.
# Allowed by ADR-0002: Foundation and MorphCore imports; UInt64 in MorphCore, in KidCore's Seams.swift (RandomSource,
# DrawList) and Helpers.swift (the draw rule); UInt8 for byte arrays (SettingsBackend); `.rounded(` only in Helpers.swift
# (roundHalfAwayFromZero).
set -u
ROOT="${1:-$(cd "$(dirname "$0")/../.." && pwd)}"
hits=0
report() { printf 'BAN %s:%s: %s\n' "${1#"$ROOT"/}" "$2" "$3"; hits=$((hits + 1)); }

scan() { # file
  local f="$1" base n=0 line code mod
  base="$(basename "$f")"
  case "$f" in */MorphCore/Sources/*) mod=MorphCore ;; */ContractKit/Sources/*) mod=ContractKit ;; *) mod=KidCore ;; esac
  while IFS= read -r line || [ -n "$line" ]; do
    n=$((n + 1))
    code="${line%%//*}"
    [ -z "${code//[[:space:]]/}" ] && continue
    if [[ "$code" =~ ^[[:space:]]*(@testable[[:space:]]+)?import[[:space:]]+([A-Za-z_]+) ]]; then
      if [ "$mod" = ContractKit ]; then
        case "${BASH_REMATCH[2]}" in Foundation|Swift|XCTest|Testing|KidCore|MorphCore) ;; *) report "$f" "$n" "import ${BASH_REMATCH[2]} (ContractKit)" ;; esac
      else
        case "${BASH_REMATCH[2]}" in Foundation|Swift|MorphCore) ;; *) report "$f" "$n" "import ${BASH_REMATCH[2]}" ;; esac
      fi
    fi
    [ "$mod" = ContractKit ] && continue
    for w in Date Calendar Decimal Duration DispatchTime UUID JSONDecoder JSONEncoder JSONSerialization Codable Encodable Decodable Character Float CGFloat Int8 Int16 Int32 UInt16 UInt32 localizedUppercase localizedLowercase; do
      if [[ "$code" =~ (^|[^A-Za-z0-9_])$w([^A-Za-z0-9_]|$) ]]; then report "$f" "$n" "$w"; fi
    done
    if [[ "$code" =~ (^|[^A-Za-z0-9_])UInt64([^A-Za-z0-9_]|$) ]] && [ "$mod" = KidCore ] && [ "$base" != Seams.swift ] && [ "$base" != Helpers.swift ]; then
      report "$f" "$n" "UInt64 outside RandomSource / the draw rule"
    fi
    for p in 'key\.count' 'character\.count' 'word\.count' '\.uppercased\(' '\.lowercased\(' '(^|[^A-Za-z0-9_.])round\(' 'lround\(' 'rint\('; do
      if [[ "$code" =~ $p ]]; then report "$f" "$n" "${p//\\/}"; fi
    done
    if [[ "$code" =~ \.rounded\( ]] && [ "$base" != Helpers.swift ]; then report "$f" "$n" ".rounded( outside roundHalfAwayFromZero"; fi
  done < "$f"
}

for d in "$ROOT/apple/KidCore/Sources" "$ROOT/apple/MorphCore/Sources" "$ROOT/apple/ContractKit/Sources"; do
  [ -d "$d" ] || { echo "BAN missing $d"; hits=$((hits + 1)); continue; }
  while IFS= read -r f; do scan "$f"; done < <(find "$d" -name '*.swift' | LC_ALL=C sort)
done
if [ "$hits" -gt 0 ]; then echo "ban-grep: FAIL ($hits)"; exit 1; fi
echo "ban-grep: pass"
