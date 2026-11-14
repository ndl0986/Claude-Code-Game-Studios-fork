#!/usr/bin/env bash
# Start the game team LEADER session at the repo root with a fixed name, so the
# member sessions (tools/team/start-<member>.sh) can always message it as
# "game-leader". Rules: .claude/skills/game-team-lead/SKILL.md
set -euo pipefail
cd "$(dirname "$0")/../.."
exec claude --permission-mode bypassPermissions --name game-leader "You are the game team leader (game-leader). Run /game-team-lead. Read production/session-state/active.md and the top entry of production/progress.md first, then follow its 'Resume here' steps. Never implement; ask Luan before merges, pushes or commits."
