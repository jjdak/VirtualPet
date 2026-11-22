#!/bin/zsh
cd "$(dirname "$0")/.." || exit 1
exec python3 living_world/src/departure_server.py --port 4199 "$@"
