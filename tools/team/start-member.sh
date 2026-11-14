#!/usr/bin/env bash
# Start one game-team member as a Claude Code session in its own Orca worktree,
# with bypass permissions. Rules: .claude/skills/game-team-lead/SKILL.md
#
# Usage: tools/team/start-member.sh <game-dev-001|game-dev-002|game-qc-android|game-qc-ios>
# Env:   WORKSPACES  worktree parent dir (default ~/orca/workspaces/Claude-Code-Game-Studios-fork)
#        LEADER      leader session name (default claude-code-game-studios-fork-b5)
set -euo pipefail

member="${1:-}"
WORKSPACES="${WORKSPACES:-$HOME/orca/workspaces/Claude-Code-Game-Studios-fork}"
LEADER="${LEADER:-claude-code-game-studios-fork-b5}"
dir="$WORKSPACES/$member"

dev_prompt() { # $1 = this dev, $2 = the other dev
  echo "You are $1, a developer on the game team. Read CLAUDE.md, production/project-plan.md and .claude/skills/game-team-lead/SKILL.md (sections 0, 3, 4, 7). The leader session ($LEADER) sends you one GitHub issue at a time with SendMessage. Plan first and wait for PLAN APPROVED, open a PR into main, never merge, report back to the leader. You also peer-review $2's plans and PRs when asked (read-only). Reply '$1 ready' to the leader and wait."
}
qc_prompt() { # $1 = name, $2 = platform, $3 = evidence dir, $4 = test target
  echo "You are $1, the $2 QC on the game team. Read CLAUDE.md and .claude/skills/game-team-lead/SKILL.md (sections 5, 6, 7). The leader session ($LEADER) sends you PRs to test with SendMessage. Test on $4, save screenshots to production/qa/evidence/GH-<issue>/$3/, post a results table on the PR, and report PASS / FAIL / NOT ASSESSED (with the reason) to the leader. Never change game code, never merge, install nothing without Luan's OK. Reply '$1 ready' to the leader and wait."
}

case "$member" in
  game-dev-001)    prompt="$(dev_prompt game-dev-001 game-dev-002)" ;;
  game-dev-002)    prompt="$(dev_prompt game-dev-002 game-dev-001)" ;;
  game-qc-android) prompt="$(qc_prompt game-qc-android Android android 'the Android emulator (SDK at ~/Android/sdk, profile mp17863) or a phone')" ;;
  game-qc-ios)     prompt="$(qc_prompt game-qc-ios iOS ios 'the iOS Simulator (xcrun simctl) or an iPhone')" ;;
  *) echo "Usage: $0 <game-dev-001|game-dev-002|game-qc-android|game-qc-ios>" >&2; exit 2 ;;
esac

if [ ! -d "$dir" ]; then
  echo "Worktree not found: $dir" >&2
  echo "Create it from the repo root with:" >&2
  echo "  orca worktree create --name $member --no-parent --base-branch docs/vn-history-game-plan --json" >&2
  exit 1
fi

cd "$dir"
exec claude --permission-mode bypassPermissions --name "$member" "$prompt"
