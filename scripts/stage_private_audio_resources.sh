#!/bin/bash

set -euo pipefail

project_dir="${PROJECT_DIR:?PROJECT_DIR is required}"
target_dir="${TARGET_BUILD_DIR:?TARGET_BUILD_DIR is required}/${UNLOCALIZED_RESOURCES_FOLDER_PATH:?UNLOCALIZED_RESOURCES_FOLDER_PATH is required}/PrivateAudio"
source_dir="${project_dir}/SharedAssets/PrivateAudio"

mkdir -p "$target_dir"

for resource_name in \
  phoebe-chirubi-angry-private.m4a \
  phoebe-chirubi-soft-private.m4a \
  phoebe-chirubi-mildly-angry-private.m4a
do
  destination="${target_dir}/${resource_name}"
  rm -f "$destination"

  source="${source_dir}/${resource_name}"
  if [[ -f "$source" ]]; then
    cp "$source" "$destination"
    echo "staged private audio: ${resource_name}"
  else
    echo "private audio missing; runtime will stay silent: ${resource_name}"
  fi
done
