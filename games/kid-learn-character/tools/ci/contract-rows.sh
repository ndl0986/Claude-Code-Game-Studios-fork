#!/usr/bin/env bash
# Prints the contract-registry rows that concern one story (K-40; ADR-0004 D5 note). Observations only, never a
# verdict: /story-done decides what a row means for the story. Reads contracts/README.md's two tables:
#   "## Current versions"  Contract | Version | Owner GDD | ...   (owner = the first `<stem>.md` in the Owner GDD cell)
#   "## Registry"          Contract | Row | Cases                 (runner: … | not-started: <story id> | superseded-by: …)
# A row concerns the story when its contract's owner GDD stem is --system, or its not-started story id is --story
# (compared as given, without `.md`, and as the file stem: a story path names its row however it is written there; a
# `story:<system>` placeholder names no file, so it never matches a path).
#
# Usage: contract-rows.sh [--system <gdd stem>] [--story <story id>] [--readme <path>]
# Output, one line each:
#   README MISSING <path>
#   ROW <contract> kind=<runner|not-started|superseded-by|other> owner=<stem|-> story=<id|-> match=<system|story|system+story> row=<row text>
#   UNREGISTERED <contract> owner=<stem>        (owned by --system, listed in Current versions, no Registry row)
#   NONE                                        (no row concerns the story)
# Exit 0 whenever the README was read or found missing; 2 on a usage error.
set -u
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
README="$ROOT/contracts/README.md" SYSTEM="" STORY=""
while [ $# -gt 0 ]; do
  case "$1" in
    --system) SYSTEM="${2:-}"; shift 2 ;;
    --story) STORY="${2:-}"; shift 2 ;;
    --readme) README="${2:-}"; shift 2 ;;
    *) echo "usage: contract-rows.sh [--system <gdd stem>] [--story <story id>] [--readme <path>]" >&2; exit 2 ;;
  esac
done
SYSTEM="${SYSTEM%.md}"; SYSTEM="${SYSTEM##*/}"
S1="${STORY%.md}"; S2="${S1##*/}"
if [ -z "$SYSTEM$STORY" ]; then echo "contract-rows.sh: give --system or --story" >&2; exit 2; fi
if [ ! -f "$README" ]; then echo "README MISSING $README"; exit 0; fi

awk -v sys="$SYSTEM" -v story="$STORY" -v s1="$S1" -v s2="$S2" '
  function trim(s) { gsub(/^[ \t`]+|[ \t`]+$/, "", s); return s }
  /^## /        { sec = ($0 ~ /^## Current versions/) ? "cur" : ($0 ~ /^## Registry/) ? "reg" : ""; next }
  sec == "" || $0 !~ /^\|/ { next }
  {
    n = split($0, c, "|"); name = trim(c[2])
    if (name == "" || name == "Contract" || name ~ /^-+$/ || name ~ /^:?-+:?$/) next
    if (sec == "cur") {
      own = trim(c[4])
      if (match(own, /[A-Za-z0-9_.-]+\.md/)) { o = substr(own, RSTART, RLENGTH); sub(/\.md$/, "", o) } else o = "-"
      owner[name] = o; if (!(name in seenc)) { seenc[name] = 1; corder[++nc] = name }
    } else {
      row[name] = trim(c[3]); if (!(name in seenr)) { seenr[name] = 1; rorder[++nr] = name }
    }
  }
  END {
    hits = 0
    for (i = 1; i <= nr; i++) {
      k = rorder[i]; r = row[k]; o = (k in owner) ? owner[k] : "-"
      kind = (r ~ /^runner:/) ? "runner" : (r ~ /^not-started:/) ? "not-started" : (r ~ /^superseded-by:/) ? "superseded-by" : "other"
      id = "-"; if (kind == "not-started") { id = r; sub(/^not-started:[ \t]*/, "", id); sub(/[ \t].*$/, "", id) }
      ms = (sys != "" && o == sys); mt = (story != "" && (id == story || id == s1 || id == s2))
      if (!ms && !mt) continue
      m = (ms && mt) ? "system+story" : ms ? "system" : "story"
      printf "ROW %s kind=%s owner=%s story=%s match=%s row=%s\n", k, kind, o, id, m, r; hits++
    }
    for (i = 1; i <= nc; i++) { k = corder[i]
      if (sys != "" && owner[k] == sys && !(k in seenr)) { printf "UNREGISTERED %s owner=%s\n", k, owner[k]; hits++ } }
    if (hits == 0) print "NONE"
  }' "$README"
