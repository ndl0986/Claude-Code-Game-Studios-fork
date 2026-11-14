#!/usr/bin/env bash
# Start game-dev-android (bypass permissions). Add --resume to continue its last conversation. See start-member.sh.
exec "$(dirname "$0")/start-member.sh" game-dev-android "$@"
