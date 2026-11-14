#!/usr/bin/env bash
# Start one game-team member as a Claude Code session in its own git worktree (not an Orca workspace),
# with bypass permissions. Rules: .claude/skills/game-team-lead/SKILL.md
#
# Usage: tools/team/start-member.sh <game-dev-ios|game-dev-android|game-qc-android|game-qc-ios|game-art-content> [--resume]
#        --resume continues the member's last conversation (same name); without it, a fresh session with its role prompt.
# Env:   WORKSPACES  worktree parent dir (default ~/orca/workspaces/Claude-Code-Game-Studios-fork)
#        LEADER      leader session name (default game-leader; start it with tools/team/start-leader.sh)
set -euo pipefail

member="${1:-}"
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"   # repo root, resolved before any cd
WORKSPACES="${WORKSPACES:-$HOME/orca/workspaces/Claude-Code-Game-Studios-fork}"
LEADER="${LEADER:-game-leader}"
# Worktree folders keep their original names (renaming Orca-managed worktrees is risky).
case "$member" in
  game-dev-ios)     dir="$WORKSPACES/game-dev-001" ;;
  game-dev-android) dir="$WORKSPACES/game-dev-002" ;;
  *)                dir="$WORKSPACES/$member" ;;
esac

dev_prompt() { # $1 = this dev, $2 = the other dev, $3 = the app you own
  echo "You are $1, a developer on the game team; you own $3. Read CLAUDE.md, production/project-plan.md, production/progress.md (top entry) and the team rules in /Users/luannguyend/self-projects/Claude-Code-Game-Studios-fork/.claude/skills/game-team-lead/SKILL.md (sections 0, 3, 4, 7; the leader checkout has the newest copy). The leader session ($LEADER) sends you one task at a time with SendMessage. Plan first and wait for PLAN APPROVED, commit on your task branch, never push or merge, report back to the leader. You also peer-review $2's plans and PRs when asked (read-only). Reply '$1 ready' to the leader and wait."
}
qc_prompt() { # $1 = name, $2 = platform, $3 = evidence dir, $4 = test target
  echo "You are $1, the $2 QC on the game team. Read CLAUDE.md and .claude/skills/game-team-lead/SKILL.md (sections 5, 6, 7). The leader session ($LEADER) sends you PRs to test with SendMessage. Test on $4, save screenshots to production/qa/evidence/GH-<issue>/$3/, post a results table on the PR, and report PASS / FAIL / NOT ASSESSED (with the reason) to the leader. Never change game code, never merge, install nothing without Luan's OK. Reply '$1 ready' to the leader and wait."
}

case "$member" in
  game-dev-ios)    prompt="$(dev_prompt game-dev-ios game-dev-android 'the native iOS app (Swift + SpriteKit, ios/)')" ;;
  game-dev-android)    prompt="$(dev_prompt game-dev-android game-dev-ios 'the native Android app (Kotlin, android/)')" ;;
  game-qc-android) prompt="$(qc_prompt game-qc-android Android android 'the Android emulator (SDK at ~/Android/sdk, profile mp17863) or a phone')" ;;
  game-qc-ios)     prompt="$(qc_prompt game-qc-ios iOS ios 'the iOS Simulator (xcrun simctl) or an iPhone')" ;;
  game-art-content) prompt="You are game-art-content, the art designer and content/history owner on the game team. Read CLAUDE.md, production/project-plan.md, design/gdd/game-concept.md, and the team rules in /Users/luannguyend/self-projects/Claude-Code-Game-Studios-fork/.claude/skills/game-team-lead/SKILL.md (sections 0, 4, 5, 7; the leader checkout has the newest copy). The leader session ($LEADER) sends you one task at a time with SendMessage. You own the art direction (/art-bible, /asset-spec) and each hero's mission story beats (first hero: Tran Quoc Toan), in Vietnamese and English for primary-school children, with every historical fact cited to a source. You cannot verify history yourself: keep facts marked placeholder until Luan signs them off. You also review PRs that show heroes, events, dates or story text. Plan first and wait for PLAN APPROVED, open a PR, never merge, report back to the leader. Reply 'game-art-content ready' to the leader and wait." ;;
  *) echo "Usage: $0 <game-dev-ios|game-dev-android|game-qc-android|game-qc-ios|game-art-content>" >&2; exit 2 ;;
esac

if [ ! -d "$dir" ]; then
  echo "Worktree not found: $dir" >&2
  echo "Create it (a plain git worktree, no Orca workspace) from the repo root with:" >&2
  echo "  git worktree add \"$dir\" <the member's branch>" >&2
  exit 1
fi

cd "$dir"
# --resume: resume this member's saved Claude session (id in the gitignored
# production/session-state/team-sessions.tsv), same name. Falls back to the most
# recent conversation in its folder when no id is saved.
if [ "${2:-}" = "--resume" ]; then
  ids="$ROOT/production/session-state/team-sessions.tsv"
  sid="$(awk -v m="$member" -F'\t' '$1==m {print $2}' "$ids" 2>/dev/null || true)"
  if [ -n "$sid" ]; then
    exec claude --permission-mode bypassPermissions --name "$member" --resume "$sid"
  fi
  exec claude --permission-mode bypassPermissions --name "$member" --continue
fi
exec claude --permission-mode bypassPermissions --name "$member" "$prompt"
