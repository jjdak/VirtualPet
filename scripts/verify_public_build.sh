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

DEVELOPER_DIR="$developer_dir" xcodebuild \
  -project "$clone_dir/VirtualPet.xcodeproj" \
  -scheme VirtualPet \
  -destination "$destination" \
  -derivedDataPath "$build_dir" \
  CODE_SIGNING_ALLOWED=NO \
  build

app_path="$build_dir/Build/Products/Debug-iphonesimulator/VirtualPet.app"
[[ -d "$app_path" ]] || {
  echo "public clone build did not produce an iOS app: $app_path" >&2
  exit 1
}

echo "public clone build passed"
echo "source: $clone_dir"
echo "app: $app_path"
