#!/usr/bin/env bash

set -euo pipefail

readonly source_root="${PROJECT_DIR}/SharedAssets/Assets.xcassets"
readonly resources_root="${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}"
readonly destination_root="${resources_root}/PhoebePrivateArt"

declare -a mappings=(
  "PhoebePrivate.imageset/phoebe-private-idle-3x.png|phoebe-idle.png"
  "PhoebeHeadPatPrivate.imageset/phoebe-headpat-private.png|phoebe-headpat.png"
  "PhoebeBodyPokePrivate.imageset/phoebe-bodypoke-private.png|phoebe-bodypoke.png"
  "PhoebeChirpPrivate.imageset/phoebe-chirp-private.png|phoebe-chirp.png"
)

# These source files are ignored private assets. Public checkouts keep the
# placeholder path because no mapping is staged when the files are absent.
mkdir -p "${destination_root}"
for mapping in "${mappings[@]}"; do
  source_relative="${mapping%%|*}"
  destination_name="${mapping##*|}"
  source_path="${source_root}/${source_relative}"
  destination_path="${destination_root}/${destination_name}"
  rm -f "${destination_path}"
  if [[ -s "${source_path}" ]]; then
    ditto "${source_path}" "${destination_path}"
  fi
done

if find "${destination_root}" -type f -maxdepth 1 -print -quit | grep -q .; then
  echo "Staged private Phoebe artwork at ${destination_root}"
else
  echo "Private Phoebe artwork not present; keeping placeholder fallback."
fi
