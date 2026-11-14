#!/usr/bin/env bash
# Start game-dev-001 (bypass permissions). See start-member.sh.
exec "$(dirname "$0")/start-member.sh" game-dev-001 "$@"
