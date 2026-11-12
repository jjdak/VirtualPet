#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
source_file='PrivateAssets/Courtyard/Blender/B2/courtyard-b2-reference-v6-focused.blend'
if [[ ! -f "$source_file" ]]; then
  echo '缺少 B2 私人源工程，请按 docs/archive/B2_CLOSEOUT.md 恢复。' >&2
  exit 1
fi
for clip in 69_16 69_18 16_33; do
  if [[ ! -f "PrivateAssets/Courtyard/Animations/CMU/${clip}.fbx" ]]; then
    echo "缺少 CMU ${clip}.fbx，来源与许可见 docs/sim/S2_CONTACT_PASS.md。" >&2
    exit 1
  fi
done
/Applications/Blender.app/Contents/MacOS/Blender -b "$source_file" --python blender/scripts/export-sim-s1.py
if [[ -f 'PrivateAssets/Courtyard/Animations/Quaternius/Universal Animation Library[Standard]/Unreal-Godot/UAL1_Standard.glb' ]]; then
  /Applications/Blender.app/Contents/MacOS/Blender -b --python blender/scripts/retarget-sim-s2.py
else
  echo 'S2 需要 Quaternius Standard 免费动作包，见 sim/README.md。' >&2
  exit 1
fi
/Applications/Blender.app/Contents/MacOS/Blender -b --python blender/scripts/retarget-sim-s2-transitions.py
/Applications/Godot.app/Contents/MacOS/Godot --headless --path sim --editor --import
