#!/usr/bin/env bash
# Start game-qc-ios (bypass permissions). See start-member.sh.
exec "$(dirname "$0")/start-member.sh" game-qc-ios "$@"
