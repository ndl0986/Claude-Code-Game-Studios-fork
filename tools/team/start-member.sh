#!/usr/bin/env bash
# Start one game-team member as a Claude Code session in its own Orca worktree,
# with bypass permissions. Rules: .claude/skills/game-team-lead/SKILL.md
#
# Usage: tools/team/start-member.sh <game-dev-001|game-dev-002|game-qc-android|game-qc-ios|game-art-content> [--resume]
#        --resume continues the member's last conversation (same name); without it, a fresh session with its role prompt.
# Env:   WORKSPACES  worktree parent dir (default ~/orca/workspaces/Claude-Code-Game-Studios-fork)
#        LEADER      leader session name (default game-leader; start it with tools/team/start-leader.sh)
set -euo pipefail

member="${1:-}"
WORKSPACES="${WORKSPACES:-$HOME/orca/workspaces/Claude-Code-Game-Studios-fork}"
LEADER="${LEADER:-game-leader}"
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
  game-art-content) prompt="You are game-art-content, the art designer and content/history owner on the game team. Read CLAUDE.md, production/project-plan.md, design/gdd/game-concept.md, and the team rules in /Users/luannguyend/self-projects/Claude-Code-Game-Studios-fork/.claude/skills/game-team-lead/SKILL.md (sections 0, 4, 5, 7; the leader checkout has the newest copy). The leader session ($LEADER) sends you one task at a time with SendMessage. You own the art direction (/art-bible, /asset-spec) and each hero's mission story beats (first hero: Tran Quoc Toan), in Vietnamese and English for primary-school children, with every historical fact cited to a source. You cannot verify history yourself: keep facts marked placeholder until Luan signs them off. You also review PRs that show heroes, events, dates or story text. Plan first and wait for PLAN APPROVED, open a PR, never merge, report back to the leader. Reply 'game-art-content ready' to the leader and wait." ;;
  *) echo "Usage: $0 <game-dev-001|game-dev-002|game-qc-android|game-qc-ios|game-art-content>" >&2; exit 2 ;;
esac

if [ ! -d "$dir" ]; then
  echo "Worktree not found: $dir" >&2
  echo "Create it from the repo root with:" >&2
  echo "  orca worktree create --name $member --no-parent --base-branch docs/vn-history-game-plan --json" >&2
  exit 1
fi

cd "$dir"
# --resume: continue this member's most recent conversation in its worktree, same name.
if [ "${2:-}" = "--resume" ]; then
  exec claude --permission-mode bypassPermissions --name "$member" --continue
fi
exec claude --permission-mode bypassPermissions --name "$member" "$prompt"
