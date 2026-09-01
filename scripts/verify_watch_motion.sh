#!/usr/bin/env bash

set -euo pipefail

readonly PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
readonly DEVELOPER_DIR_VALUE="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"
readonly SIMCTL="${DEVELOPER_DIR_VALUE}/usr/bin/simctl"
readonly SCHEME="${SCHEME:-VirtualPetWatch}"
readonly BUNDLE_ID="${BUNDLE_ID:-com.yourcompany.VirtualPet.watchkitapp}"
readonly DEVICE_NAME_VALUE="${DEVICE_NAME:-Apple Watch SE 3 (44mm)}"
readonly DEVICE_UDID_OVERRIDE="${DEVICE_UDID:-}"
readonly DERIVED_DATA="${DERIVED_DATA:-${PROJECT_ROOT}/.runtime/watchMotionDerivedData}"
readonly CAPTURE_DIR="${CAPTURE_DIR:-${PROJECT_ROOT}/.runtime/watch-motion-check}"
readonly PREVIEW_WAIT="${PREVIEW_WAIT:-1}"
readonly MOTION_WAIT="${MOTION_WAIT:-0.8}"

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
command -v sips >/dev/null 2>&1 || {
  echo "missing command: sips" >&2
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
"$SIMCTL" launch "$DEVICE_UDID_VALUE" "$BUNDLE_ID" >/dev/null

rm -rf "$CAPTURE_DIR"
mkdir -p "$CAPTURE_DIR"
sleep "$PREVIEW_WAIT"
"$SIMCTL" io "$DEVICE_UDID_VALUE" screenshot "$CAPTURE_DIR/frame-0.png" >/dev/null
sleep "$MOTION_WAIT"
"$SIMCTL" io "$DEVICE_UDID_VALUE" screenshot "$CAPTURE_DIR/frame-1.png" >/dev/null

# Compare the character region, not the clock or message. Derive the crop from
# the captured dimensions so the check also works for the 40mm/42mm/46mm
# simulator variants. The crop starts below the status clock and ends above the
# title/message block.
image_width="$(sips -g pixelWidth "$CAPTURE_DIR/frame-0.png" | awk '/pixelWidth/ {print $2}')"
image_height="$(sips -g pixelHeight "$CAPTURE_DIR/frame-0.png" | awk '/pixelHeight/ {print $2}')"
crop_width=$((image_width * 34 / 100))
crop_height=$((image_height * 29 / 100))
crop_x=$(( (image_width - crop_width) / 2 ))
crop_y=$((image_height * 12 / 100))
for frame in "$CAPTURE_DIR/frame-0.png" "$CAPTURE_DIR/frame-1.png"; do
  sips -c "$crop_height" "$crop_width" --cropOffset "$crop_y" "$crop_x" "$frame" \
    --out "${frame%.png}-character.png" >/dev/null
done

hash0="$(shasum -a 256 "$CAPTURE_DIR/frame-0-character.png" | awk '{print $1}')"
hash1="$(shasum -a 256 "$CAPTURE_DIR/frame-1-character.png" | awk '{print $1}')"
if [[ "$hash0" == "$hash1" ]]; then
  echo "watch character region did not change between captures" >&2
  echo "captures: $CAPTURE_DIR" >&2
  exit 1
fi

echo "watch motion regression passed"
echo "device: $DEVICE_NAME_VALUE ($DEVICE_UDID_VALUE)"
echo "character frame hashes: $hash0 -> $hash1"
echo "captures: $CAPTURE_DIR"
