#!/bin/bash

set -euo pipefail

project_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
developer_dir="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"
destination="${DESTINATION:-platform=iOS Simulator,name=iPhone 17,OS=26.2}"
work_root="${WORK_ROOT:-$(mktemp -d /tmp/VirtualPetPublicBuild.XXXXXX)}"
clone_dir="${work_root}/source"
build_dir="${work_root}/derived-data"

mkdir -p "$clone_dir" "$build_dir"
git -C "$project_dir" archive --format=tar HEAD | tar -xf - -C "$clone_dir"

private_files="$(find "$clone_dir" -type f \( \
  -path '*/PrivateAssets/*' -o \
  -path '*/PrivateAudio/*' -o \
  -path '*/PrivateModels/*' -o \
  -path '*/PrivateMotionAtlases/*' -o \
  -path '*/SharedAssets/Assets.xcassets/PhoebePrivate*' -o \
  -name '*.m4a' -o -name '*.caf' -o -name '*.wav' \
\) -print)"
if [[ -n "$private_files" ]]; then
  echo "public archive contains private files:" >&2
  printf '%s\n' "$private_files" >&2
  exit 1
fi

build_target() {
  local scheme="$1"
  local target_destination="$2"
  local product_path="$3"

  echo "building public clone: ${scheme} (${target_destination})"
  DEVELOPER_DIR="$developer_dir" xcodebuild \
    -project "$clone_dir/VirtualPet.xcodeproj" \
    -scheme "$scheme" \
    -destination "$target_destination" \
    -derivedDataPath "$build_dir" \
    CODE_SIGNING_ALLOWED=NO \
    build

  [[ -d "$build_dir/$product_path" ]] || {
    echo "public clone build did not produce expected product: $build_dir/$product_path" >&2
    exit 1
  }
}

build_target "VirtualPet" "$destination" "Build/Products/Debug-iphonesimulator/VirtualPet.app"
build_target "VirtualPet" "platform=macOS,arch=arm64" "Build/Products/Debug/VirtualPet.app"
build_target "VirtualPetWatch" "generic/platform=watchOS" "Build/Products/Debug-watchos/VirtualPetWatch.app"

echo "public clone build passed"
echo "source: $clone_dir"
echo "derived data: $build_dir"
