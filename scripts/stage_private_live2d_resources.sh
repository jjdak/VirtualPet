#!/usr/bin/env bash

set -euo pipefail

readonly source_root="${PROJECT_DIR}/PrivateAssets/Live2D/Exports/PhoebeLive2D"
readonly resources_root="${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}"
readonly destination_root="${resources_root}/PhoebeLive2D"
readonly required_files=(
  "phoebe.model3.json"
  "phoebe.moc3"
  "phoebe.cdi3.json"
  "textures/texture_00.png"
)

# The private model is intentionally absent from public checkouts. The normal
# SpriteKit fallback remains buildable when this directory does not exist.
if [[ ! -d "${source_root}" ]]; then
  echo "Private Live2D model not present; keeping SpriteKit fallback."
  exit 0
fi

mkdir -p "${resources_root}"
for relative_path in "${required_files[@]}"; do
  source_path="${source_root}/${relative_path}"
  destination_path="${destination_root}/${relative_path}"
  if [[ ! -s "${source_path}" ]]; then
    echo "Private Live2D model is missing: ${source_path}" >&2
    exit 1
  fi
  mkdir -p "$(dirname "${destination_path}")"
  ditto "${source_path}" "${destination_path}"
done
echo "Staged private Live2D model at ${destination_root}"
