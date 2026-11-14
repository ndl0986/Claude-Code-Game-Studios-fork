#!/usr/bin/env bash
# Start game-art-content (bypass permissions). See start-member.sh.
exec "$(dirname "$0")/start-member.sh" game-art-content "$@"
