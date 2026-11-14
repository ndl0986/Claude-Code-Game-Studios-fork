#!/usr/bin/env bash
# Start the game team LEADER at the repo root, always named "game-leader", so the
# member sessions (tools/team/start-<member>.sh) can always message it.
#
# Usage: tools/team/start-leader.sh            resume the saved leader conversation
#        tools/team/start-leader.sh --fresh    start a new leader conversation
#
# The saved conversation id lives in production/session-state/leader-session.txt
# (machine-local, gitignored). Rules: .claude/skills/game-team-lead/SKILL.md
set -euo pipefail
cd "$(dirname "$0")/../.."
id_file=production/session-state/leader-session.txt
name=game-leader

if [ "${1:-}" != "--fresh" ] && [ -s "$id_file" ]; then
  exec claude --permission-mode bypassPermissions --name "$name" --resume "$(tr -d '[:space:]' < "$id_file")"
fi

exec claude --permission-mode bypassPermissions --name "$name" "You are the game team leader ($name). Run /game-team-lead. Read production/session-state/active.md and the top entry of production/progress.md first, then follow its 'Resume here' steps. Never implement; ask Luan before merges, pushes or commits. Save your conversation id: write the value of \$CLAUDE_CODE_SESSION_ID to $id_file."
