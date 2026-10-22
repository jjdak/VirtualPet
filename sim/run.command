#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
godot_bin='/Applications/Godot.app/Contents/MacOS/Godot'
if [[ ! -x "$godot_bin" ]]; then
  echo '请先安装 Godot 4.7.2，详见 sim/README.md。' >&2
  exit 1
fi
if [[ ! -f assets/private/migration.json ]]; then
  echo '缺少私人导出资产，请先运行 sim/prepare-assets.command。' >&2
  exit 1
fi
"$godot_bin" --headless --path "$PWD" --editor --import
exec "$godot_bin" --path "$PWD"
