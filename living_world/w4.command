#!/bin/zsh
cd "$(dirname "$0")/.." || exit 1
exec python3 living_world/src/fork_server.py --port 4198 "$@"
