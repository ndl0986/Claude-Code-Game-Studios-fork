#!/bin/bash
# TASK-139: for each contract section that drifted by rev $1, the first commit after the lock that changed it.
# Observations only. Run from the repo root.
B=${1:-713dae86}
S=$PWD/.claude/scripts/review-receipts.sh
T=$(dirname "$0")/drift-work
mkdir -p "$T"
G=games/kid-learn-character
hashat() { # rev path section
  mkdir -p "$T/x/$(dirname "$2")"
  git show "$1:$2" > "$T/x/$2" 2>/dev/null || { echo none; return; }
  (cd "$T/x" && bash "$S" sections-hash "$2" 2>/dev/null | awk -v r="$2#$3" '{l=$0; sub(/^Reviewed-Section-Hash: /,"",l); h=l; sub(/.* /,"",h); k=l; sub(/ [^ ]*$/,"",k); if (k==r) print h}')
}
for f in $(git ls-tree -r --name-only "$B" -- $G/contracts | grep 'sources.lock$'); do
  c=$(basename "$(dirname "$f")")
  lc=$(git log -1 --format=%h "$B" -- "$f")
  git show "$B:$f" | grep '^Reviewed-Section-Hash: ' | sed 's/^Reviewed-Section-Hash: //' | while IFS= read -r line; do
    h=${line##* }; ref=${line% *}; p=${ref%%#*}; s=${ref#*#}
    case $p in games/*) ;; *) p=$G/$p; echo "$c | NOTE lock path not repo-relative: $ref";; esac
    cur=$(hashat "$B" "$p" "$s")
    [ "$cur" = "$h" ] && continue
    first=""
    for r in $(git rev-list --reverse "$lc..$B" -- "$p"); do
      x=$(hashat "$r" "$p" "$s"); [ "$x" != "$h" ] && { first=$r; break; }
    done
    echo "$c | $(basename "$p")#$s | lock@$lc | first-change $(git log -1 --format='%h %s' $first 2>/dev/null | cut -c1-90)"
  done
done
