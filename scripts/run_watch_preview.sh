#!/usr/bin/env bash

set -euo pipefail

readonly PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
readonly DEVELOPER_DIR_VALUE="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"
readonly SIMCTL="${DEVELOPER_DIR_VALUE}/usr/bin/simctl"
readonly SCHEME="${SCHEME:-VirtualPetWatch}"
readonly BUNDLE_ID="${BUNDLE_ID:-com.yourcompany.VirtualPet.watchkitapp}"
readonly DEVICE_NAME_VALUE="${DEVICE_NAME:-Apple Watch SE 3 (40mm)}"
readonly DEVICE_UDID_OVERRIDE="${DEVICE_UDID:-}"
readonly DERIVED_DATA="${DERIVED_DATA:-${PROJECT_ROOT}/.runtime/watchPreviewDerivedData}"
readonly SCREENSHOT="${SCREENSHOT:-${PROJECT_ROOT}/.runtime/watch-preview.png}"

require_file() {
  [[ -x "$1" ]] || {
    echo "missing executable: $1" >&2
    exit 1
  }
}

require_file "$SIMCTL"
command -v xcodebuild >/dev/null 2>&1 || {
  echo "missing command: xcodebuild" >&2
  exit 1
}

find_device() {
  if [[ -n "$DEVICE_UDID_OVERRIDE" ]]; then
    printf '%s\n' "$DEVICE_UDID_OVERRIDE"
    return
  fi

  "$SIMCTL" list devices available | DEVICE_NAME="$DEVICE_NAME_VALUE" python3 -c '
import os
import re
import sys

name = os.environ["DEVICE_NAME"]
for line in sys.stdin:
    if name not in line or "(unavailable" in line:
        continue
    match = re.search(r"\(([0-9A-Fa-f-]{36})\)", line)
    if match:
        print(match.group(1))
        break
'
}

readonly DEVICE_UDID_VALUE="$(find_device)"
[[ -n "$DEVICE_UDID_VALUE" ]] || {
  echo "no available watchOS Simulator named '$DEVICE_NAME_VALUE'; set DEVICE_NAME or DEVICE_UDID" >&2
  exit 1
}

device_state="$($SIMCTL list devices | awk -v udid="$DEVICE_UDID_VALUE" '$0 ~ udid { if ($0 ~ /Booted/) print "Booted"; else print "Shutdown"; exit }')"
if [[ "$device_state" != "Booted" ]]; then
  "$SIMCTL" boot "$DEVICE_UDID_VALUE" >/dev/null
  "$SIMCTL" bootstatus "$DEVICE_UDID_VALUE" -b >/dev/null
fi

DEVELOPER_DIR="$DEVELOPER_DIR_VALUE" xcodebuild \
  -project "$PROJECT_ROOT/VirtualPet.xcodeproj" \
  -scheme "$SCHEME" \
  -destination "platform=watchOS Simulator,id=$DEVICE_UDID_VALUE" \
  -derivedDataPath "$DERIVED_DATA" \
  ENABLE_USER_SCRIPT_SANDBOXING=NO \
  CODE_SIGNING_ALLOWED=NO \
  build

app_path="$DERIVED_DATA/Build/Products/Debug-watchsimulator/VirtualPetWatch.app"
[[ -d "$app_path" ]] || {
  echo "built app not found: $app_path" >&2
  exit 1
}

"$SIMCTL" install "$DEVICE_UDID_VALUE" "$app_path"
"$SIMCTL" launch "$DEVICE_UDID_VALUE" "$BUNDLE_ID"

mkdir -p "$(dirname "$SCREENSHOT")"
sleep "${PREVIEW_WAIT:-2}"
"$SIMCTL" io "$DEVICE_UDID_VALUE" screenshot "$SCREENSHOT" >/dev/null

echo "preview device: $DEVICE_NAME_VALUE ($DEVICE_UDID_VALUE)"
echo "preview app: $app_path"
echo "preview screenshot: $SCREENSHOT"
