#!/bin/bash
# ios-release-check.sh — prove that no debug code reaches an optimised iOS build (TASK-026; the r9/r10 freeze check).
#
# Usage:  tools/qa/ios-release-check.sh [config ...]        (default: Release Preview)
# Env:    OUT   work folder (default: a new mktemp folder; kept, so the logs and executables can be read afterwards)
#         REF   git ref to check (default: HEAD; the working tree is never touched)
#
# For each configuration it builds the app three times into ONE derived-data path, from a `git archive` copy of REF:
#   A1  as committed;
#   A2  every Swift source touched, then rebuilt (a rebuild control: A1 == A2 shows the build is deterministic);
#   B   every `#if DEBUG … #else … #endif` block replaced by its #else branch (or nothing) in every Swift source.
# A1 == A2 == B (sha256 of the app executable) means no line inside `#if DEBUG` reaches that configuration.
# Then `strings` / `nm` on A1 look for the debug-only keys and symbols by name.
#
# Release stops at the R12 content gate (ADR-0001) while history claims are unsigned: that is expected and
# accepted only when the log shows the gate's own message and the executable was linked. Preview (D-37) skips
# the gate and must build cleanly. Exit 0 only when every configuration passes.
set -uo pipefail
ROOT=$(git rev-parse --show-toplevel)
GAME=games/dai-dat-anh-hung # TASK-028: the game folder inside the repo
REF=${REF:-HEAD}
OUT=${OUT:-$(mktemp -d "${TMPDIR:-/tmp}/ios-release-check.XXXXXX")}
CONFIGS=("$@"); [ ${#CONFIGS[@]} -gt 0 ] || CONFIGS=(Release Preview)
DEBUG_KEYS='debugState|resetProgress|autoplay|timeScale|quiz_motion|quiz_overlap|debug_jumped|lock_until|lock_context|sprites_visible|max_bottom|touch:%|resume_frame|step_hist|leave_card|walk_ct'
DEBUG_SYMS='botInput|didFinishUpdate|quizMotion|debugAutoplay|debugPublish|lockUntilForDebug'
FAIL=0
echo "ref $(git -C "$ROOT" rev-parse --short "$REF"), work folder $OUT"

strip_debug() { # replace each `#if DEBUG` block by its #else branch; other #if blocks are kept as they are
  python3 -I - "$@" <<'PY'
import sys
for p in sys.argv[1:]:
    out, stack = [], []          # stack entries: 'drop' / 'keep' (a DEBUG block's branches) or 'other'
    for line in open(p, encoding='utf-8'):
        t = line.strip()
        if t.startswith('#if'):
            if t == '#if DEBUG': stack.append('drop'); continue
            stack.append('other')
        elif t.startswith('#else') and stack and stack[-1] in ('drop', 'keep'):
            stack[-1] = 'keep'; continue
        elif t.startswith('#endif') and stack:
            if stack.pop() in ('drop', 'keep'): continue
        if 'drop' in stack: continue
        out.append(line)
    open(p, 'w', encoding='utf-8').write(''.join(out))
PY
}

for CONFIG in "${CONFIGS[@]}"; do
  W="$OUT/$CONFIG"; mkdir -p "$W/src"
  git -C "$ROOT" archive "$REF" "$GAME/ios" "$GAME/content" | tar -x -C "$W/src"
  DD="$W/dd"
  APP="$DD/Build/Products/$CONFIG-iphonesimulator/DaiDatAnhHung.app/DaiDatAnhHung"
  build() { # $1 = label
    (cd "$W/src/$GAME" && xcodebuild build -project ios/DaiDatAnhHung.xcodeproj -scheme DaiDatAnhHung -configuration "$CONFIG" \
      -destination "generic/platform=iOS Simulator" -derivedDataPath "$DD" > "$W/$1.log" 2>&1)
    local st=$?
    if [ $st -ne 0 ]; then
      if [ "$CONFIG" = Release ] && grep -q "claims not signed off" "$W/$1.log" && [ -f "$APP" ]; then
        echo "  $1: stopped at the R12 gate (expected while claims are unsigned)"
      else
        echo "  $1: BUILD FAILED (see $W/$1.log)"; return 1
      fi
    fi
    cp "$APP" "$W/$1.bin" && shasum -a 256 "$W/$1.bin" | cut -d' ' -f1
  }
  echo "== $CONFIG"
  H1=$(build A1) || { FAIL=1; echo "$H1"; continue; }; echo "  A1 ${H1##*$'\n'}"
  find "$W/src/$GAME/ios" -name '*.swift' -exec touch {} +
  H2=$(build A2) || { FAIL=1; echo "$H2"; continue; }; echo "  A2 ${H2##*$'\n'}"
  FILES=$(grep -rl --include='*.swift' '^ *#if DEBUG$' "$W/src/$GAME/ios/DaiDatAnhHung" "$W/src/$GAME/ios/GameCore/Sources")
  BEFORE=$(cat $FILES | wc -l); strip_debug $FILES; AFTER=$(cat $FILES | wc -l)
  echo "  B: stripped $((BEFORE - AFTER)) lines from $(echo $FILES | wc -w | tr -d ' ') files"
  HB=$(build B) || { FAIL=1; echo "$HB"; continue; }; echo "  B  ${HB##*$'\n'}"
  if [ "${H1##*$'\n'}" = "${H2##*$'\n'}" ] && [ "${H1##*$'\n'}" = "${HB##*$'\n'}" ]; then echo "  A1 = A2 = B: no #if DEBUG code in $CONFIG"
  else echo "  MISMATCH: debug code reaches $CONFIG (or the build is not deterministic)"; FAIL=1; fi
  K=$(strings "$W/A1.bin" | grep -E -c "$DEBUG_KEYS"); S=$(nm "$W/A1.bin" | grep -E -c "$DEBUG_SYMS")
  echo "  strings: $K debug keys, nm: $S debug symbols"
  [ "$K" = 0 ] && [ "$S" = 0 ] || FAIL=1
done
[ $FAIL = 0 ] && echo "PASS" || echo "FAIL"
exit $FAIL
