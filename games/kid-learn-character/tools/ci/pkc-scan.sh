#!/usr/bin/env bash
# ADR-0011 D5: the PKC scan suite. OBSERVATIONS ONLY: it prints "OBSERVED <pkc-id> <tool> <finding>" lines and exits 0
# unless a tool fails to run; QC writes the verdict in pkc-verdict.md (studio rule). Paths in output have $HOME masked.
#   tools/ci/pkc-scan.sh --static <path.app> [<path.app>...]   per merge candidate, headless
#   tools/ci/pkc-scan.sh --runtime                              per release candidate (device-checks plan; a stub here)
#   tools/ci/pkc-scan.sh --prove <proof-file>                   ADR-0011 V7: scan both fixtures, list every named API
set -u
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
NAMES="$ROOT/tools/ci/pkc-api-names.txt"
mask() { sed "s#$HOME#~#g"; }
obs() { printf 'OBSERVED %s\n' "$*" | mask; }

# Two-pass API scan (PKC Core Rules): nm -um (demangled) for symbols; otool -ov + strings -a for selectors. Tokens are
# whole identifiers (or selectors with ':'); leading underscores are stripped.
tokens() {
  { nm -um "$1" 2>/dev/null | xcrun swift-demangle 2>/dev/null; otool -ov "$1" 2>/dev/null; strings -a "$1" 2>/dev/null; } \
    | LC_ALL=C tr -c 'A-Za-z0-9_:' '\n' | sed 's/^_*//' | LC_ALL=C sort -u
}
# A plain name matches a whole token; a name ending in ':' matches a selector token that starts with it.
hits_for() { # tokenfile, name
  case "$2" in
    *:) awk -v n="$2" 'index($0, n) == 1 { print; exit }' "$1" ;;
    *)  grep -F -x -e "$2" "$1" | head -1 ;;
  esac
}
machos() { find "$1" -type f \( -perm -u+x -o -name '*.dylib' \) -exec sh -c 'file -b "$1" | grep -q Mach-O && echo "$1"' _ {} \; | LC_ALL=C sort; }

api_scan() { # app or binary, platform (ios|macos)
  local target="$1" plat="$2" t bin h
  t="$(mktemp)"
  if [ -d "$target" ]; then while IFS= read -r bin; do tokens "$bin"; done < <(machos "$target") | LC_ALL=C sort -u > "$t"; else tokens "$target" > "$t"; fi
  while read -r pkc name where; do
    case "$pkc" in ''|\#*) continue ;; esac
    case "$where" in both|"$plat") ;; *) continue ;; esac
    h="$(hits_for "$t" "$name")"
    if [ -n "$h" ]; then obs "$pkc api-scan $(basename "$target") found $name (as $h)"; fi
  done < "$NAMES"
  rm -f "$t"
}

static_app() {
  local app="$1" plat=ios info bin ent fw pm
  [ -d "$app/Contents" ] && plat=macos
  info="$app/Info.plist"; [ "$plat" = macos ] && info="$app/Contents/Info.plist"
  obs "PKC-scan app $(basename "$app") platform $plat"
  # PKC-01 entitlements: the signed product, and the CODE_SIGN_ENTITLEMENTS source file
  local cs; cs="$(codesign -dv "$app" 2>&1)"
  if ! codesign -d "$app" >/dev/null 2>&1 || printf '%s' "$cs" | grep -q 'linker-signed'; then
    obs "PKC-01 codesign unsigned (no signature, or only the linker's ad-hoc signature: not a signed product, entitlements unread)"
  elif printf '%s' "$cs" | grep -q '^Signature=adhoc'; then
    obs "PKC-01 codesign adhoc (file-based only; Xcode-added entitlements NOT ASSESSED)"
    codesign -d --entitlements - --xml "$app" 2>/dev/null | plutil -convert json -o - - 2>/dev/null | tr ',' '\n' | tr -d '{}' | awk 1 \
      | while IFS= read -r e; do [ -n "$e" ] && obs "PKC-01 codesign entitlement $e"; done
  else
    obs "PKC-01 codesign signed by a team (team id masked)"
    codesign -d --entitlements - --xml "$app" 2>/dev/null | plutil -convert json -o - - 2>/dev/null | tr ',' '\n' | tr -d '{}' | awk 1 \
      | while IFS= read -r e; do [ -n "$e" ] && obs "PKC-01 codesign entitlement $e"; done
  fi
  ent="$ROOT/apple/Config/LetterMorph-macOS.entitlements"
  if [ "$plat" = macos ]; then
    plutil -convert json -o - "$ent" 2>/dev/null | tr ',' '\n' | tr -d '{}' | awk 1 | while IFS= read -r e; do [ -n "$e" ] && obs "PKC-01 CODE_SIGN_ENTITLEMENTS $e"; done
  fi
  # PKC-02/03/04/06 linked frameworks; PKC-03 (b) paths, (c) Frameworks/
  while IFS= read -r bin; do
    otool -L "$bin" 2>/dev/null | tail -n +2 | awk '{print $1}' | while read -r l; do obs "PKC-03 otool-L $(basename "$bin") $l"; done
  done < <(machos "$app")
  fw="$app/Frameworks"; [ "$plat" = macos ] && fw="$app/Contents/Frameworks"
  if [ -d "$fw" ]; then obs "PKC-03 Frameworks/ $(ls "$fw" | tr '\n' ' ')"; else obs "PKC-03 Frameworks/ absent"; fi
  # PKC-03 (d) Swift module names in the binaries' symbols ($s<len><Module>)
  while IFS= read -r bin; do
    nm "$bin" 2>/dev/null | awk '{print $NF}' | grep -E '^_?\$s[0-9]+' | grep -vE 'Tl$' | sed -E 's/^_?\$s([0-9]+)(.*)/\1 \2/' \
      | while read -r n rest; do echo "${rest:0:$n}"; done
  done < <(machos "$app") | LC_ALL=C sort -u | while read -r m; do obs "PKC-03 swift-module $m"; done
  # PKC-04/06/08 Info.plist keys
  plutil -convert json -o - "$info" 2>/dev/null | grep -oE '"[A-Za-z0-9_-]+" *:' | tr -d '":' | LC_ALL=C sort -u | while read -r k; do obs "PKC-08 Info.plist key $k"; done
  # PKC-09 privacy manifest
  pm="$(find "$app" -name PrivacyInfo.xcprivacy | head -1)"
  if [ -n "$pm" ]; then
    plutil -p "$pm" | grep -E 'NSPrivacy|"[0-9A-F]{4}\.[0-9]"' | sed 's/^ *//' | while IFS= read -r l; do obs "PKC-09 privacy-manifest $l"; done
  else obs "PKC-09 privacy-manifest absent"; fi
  # API scans (PKC-01, 02, 05, 06, 09, 12)
  api_scan "$app" "$plat"
}

project_scan() { # PKC-03 (a): the app project's package references and the app's Package.resolved only (K-38 note)
  local p="$ROOT/apple/LetterMorph.xcodeproj/project.pbxproj" r
  grep -oE 'XC(Local|Remote)SwiftPackageReference; [a-zA-Z]+ = [^;]+' "$p" | while IFS= read -r l; do obs "PKC-03 project package-reference $l"; done
  r="$(find "$ROOT/apple/LetterMorph.xcodeproj" -name Package.resolved | head -1)"
  if [ -n "$r" ]; then obs "PKC-03 Package.resolved $(grep -c '"identity"' "$r") pins"; else obs "PKC-03 Package.resolved absent"; fi
  # PKC-14: log calls in our app and core code (lines only; QC reads them in context, #if DEBUG or not)
  grep -rnE '\b(print|debugPrint|NSLog|os_log)\(|Logger\(' "$ROOT/apple/LetterMorph" "$ROOT/apple/KidCore/Sources" "$ROOT/apple/MorphCore/Sources" 2>/dev/null \
    | while IFS= read -r l; do obs "PKC-14 log-call ${l#"$ROOT"/}"; done
  obs "PKC-14 log-call scan done"
}

prove() { # ADR-0011 V7: both fixtures, every named API for its platform, plus the whole-name check
  local out="$1" macbin="$ROOT/.build/pkc-fixture-macos" iosbin="$ROOT/.build/pkc-fixture-ios.dylib" sdk plat bin t h
  mkdir -p "$ROOT/.build"
  (cd "$ROOT/tools/ci/scan-fixture/macos" && swiftc -parse-as-library -O main.swift -o "$macbin") || return 2
  sdk="$(xcrun --sdk iphoneos --show-sdk-path)"
  (cd "$ROOT/tools/ci/scan-fixture/ios" && xcrun -sdk iphoneos swiftc -target arm64-apple-ios26.0 -sdk "$sdk" -O -emit-library \
     -module-name PKCFixture Fixture.swift -o "$iosbin") || return 2
  {
    echo "# ADR-0011 V7 scan proof: $(xcodebuild -version | tr '\n' ' '); pkc-scan.sh sha256 $(shasum -a 256 "$0" | cut -c1-12)"
    for pair in "macos:$macbin" "ios:$iosbin"; do
      plat="${pair%%:*}"; bin="${pair#*:}"; t="$(mktemp)"; tokens "$bin" > "$t"
      while read -r pkc name where; do
        case "$pkc" in ''|\#*) continue ;; esac
        case "$where" in both|"$plat") ;; *) continue ;; esac
        h="$(hits_for "$t" "$name")"
        if [ -n "$h" ]; then echo "listed $plat $pkc $name (as $h)"; else echo "MISSING $plat $pkc $name"; fi
      done < "$NAMES"
      printf 'status\nmystat\n' > "$t.neg"
      if [ -z "$(hits_for "$t.neg" stat)" ]; then echo "whole-name $plat: 'status' does not match 'stat'"; else echo "MISSING whole-name $plat: 'status' matched 'stat'"; fi
      rm -f "$t" "$t.neg"
    done
  } | mask > "$out"
  echo "listed: $(grep -c '^listed' "$out"); missing: $(grep -c '^MISSING' "$out")"
}

case "${1:-}" in
  --static)
    shift; [ $# -gt 0 ] || { echo "pkc-scan: --static needs at least one .app" >&2; exit 2; }
    obs "pkc-scan static: $(xcodebuild -version | head -1); the scan is proven in scan-proof-xcode-*.txt"
    project_scan
    for a in "$@"; do [ -d "$a" ] || { echo "pkc-scan: no such app $a" >&2; exit 2; }; static_app "$a"; done
    obs "runtime rows NOT run here: PKC-01c (M-11, P-5), PKC-05 live read (M-8, S-2), PKC-14 log stream (M-11); device-checks plan"
    ;;
  --runtime)
    obs "runtime rows: see the device-checks plan sessions M-8, M-11, P-5, S-2 (production/qa/device-checks-plan.md)"
    ;;
  --prove)
    prove "${2:?usage: pkc-scan.sh --prove <proof-file>}" || exit 2
    ;;
  *) echo "usage: pkc-scan.sh --static <app>... | --runtime | --prove <file>" >&2; exit 2 ;;
esac
