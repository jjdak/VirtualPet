#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
source_file='PrivateAssets/Courtyard/Blender/B2/courtyard-b2-reference-v6-focused.blend'
if [[ ! -f "$source_file" ]]; then
  echo '缺少 B2 私人源工程，请按 docs/archive/B2_CLOSEOUT.md 恢复。' >&2
  exit 1
fi
/Applications/Blender.app/Contents/MacOS/Blender -b "$source_file" --python blender/scripts/export-sim-s1.py
/Applications/Godot.app/Contents/MacOS/Godot --headless --path sim --editor --import
