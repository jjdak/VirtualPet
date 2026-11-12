#!/bin/zsh
set -eu
cd "$(dirname "$0")/.."
exec python3 living_world/src/server.py "$@"
