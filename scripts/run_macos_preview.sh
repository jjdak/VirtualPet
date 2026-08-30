#!/usr/bin/env bash

set -euo pipefail

readonly PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
readonly DEVELOPER_DIR_VALUE="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"
readonly SCHEME="${SCHEME:-VirtualPet}"
readonly DERIVED_DATA="${DERIVED_DATA:-${PROJECT_ROOT}/.runtime/macOSPreviewDerivedData}"
readonly SCREENSHOT="${SCREENSHOT:-${PROJECT_ROOT}/.runtime/macos-preview.png}"
readonly APP_PATH="${APP_PATH:-${DERIVED_DATA}/Build/Products/Debug/VirtualPet.app}"

command -v xcodebuild >/dev/null 2>&1 || {
  echo "missing command: xcodebuild" >&2
  exit 1
}
command -v open >/dev/null 2>&1 || {
  echo "missing command: open" >&2
  exit 1
}

DEVELOPER_DIR="$DEVELOPER_DIR_VALUE" xcodebuild \
  -project "$PROJECT_ROOT/VirtualPet.xcodeproj" \
  -scheme "$SCHEME" \
  -destination 'platform=macOS,arch=arm64' \
  -derivedDataPath "$DERIVED_DATA" \
  ENABLE_USER_SCRIPT_SANDBOXING=NO \
  CODE_SIGNING_ALLOWED=NO \
  build

[[ -d "$APP_PATH" ]] || {
  echo "built app not found: $APP_PATH" >&2
  exit 1
}

open -n "$APP_PATH"

if [[ "${CAPTURE_SCREENSHOT:-1}" == "1" ]]; then
  command -v screencapture >/dev/null 2>&1 || {
    echo "missing command: screencapture" >&2
    exit 1
  }
  mkdir -p "$(dirname "$SCREENSHOT")"
  sleep "${PREVIEW_WAIT:-2}"
  screencapture -x "$SCREENSHOT"
fi

echo "preview app: $APP_PATH"
if [[ "${CAPTURE_SCREENSHOT:-1}" == "1" ]]; then
  echo "preview screenshot: $SCREENSHOT"
fi
