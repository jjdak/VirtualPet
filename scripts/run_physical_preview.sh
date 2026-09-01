#!/usr/bin/env bash

set -euo pipefail

readonly PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
readonly DEVELOPER_DIR_VALUE="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"
readonly DEVICETool="${DEVELOPER_DIR_VALUE}/usr/bin/devicectl"
readonly PLATFORM="${PLATFORM:-ios}"
readonly DEVICE_ID="${DEVICE_ID:-}"
readonly DERIVED_DATA="${DERIVED_DATA:-$(mktemp -d /tmp/VirtualPetPhysicalPreview.XXXXXX)}"
readonly WORK_ROOT="${WORK_ROOT:-$(mktemp -d /tmp/VirtualPetPhysicalPreviewLog.XXXXXX)}"

[[ -x "$DEVICETool" ]] || {
  echo "missing executable: $DEVICETool" >&2
  exit 1
}

if [[ -z "$DEVICE_ID" ]]; then
  echo "usage: DEVICE_ID=<CoreDevice identifier> PLATFORM=ios|watchos $0" >&2
  echo "this script never guesses a physical device" >&2
  exit 2
fi

case "$PLATFORM" in
  ios)
    scheme="${SCHEME:-VirtualPet}"
    destination_platform="iOS"
    product_directory="Debug-iphoneos"
    app_name="VirtualPet.app"
    bundle_id="${BUNDLE_ID:-com.yourcompany.VirtualPet}"
    ;;
  watchos)
    scheme="${SCHEME:-VirtualPetWatch}"
    destination_platform="watchOS"
    product_directory="Debug-watchos"
    app_name="VirtualPetWatch.app"
    bundle_id="${BUNDLE_ID:-com.yourcompany.VirtualPet.watchkitapp}"
    ;;
  *)
    echo "unsupported PLATFORM '$PLATFORM'; use ios or watchos" >&2
    exit 2
    ;;
esac

mkdir -p "$WORK_ROOT"
details_log="$WORK_ROOT/device-details.log"
if ! DEVELOPER_DIR="$DEVELOPER_DIR_VALUE" "$DEVICETool" device info details \
  --device "$DEVICE_ID" > "$details_log" 2>&1; then
  echo "unable to inspect device: $DEVICE_ID" >&2
  tail -n 40 "$details_log" >&2
  exit 1
fi

pairing_state="$(sed -nE 's/.*pairingState: ([^[:space:]]+).*/\1/p' "$details_log" | tail -n 1)"
developer_mode="$(sed -nE 's/.*developerModeStatus: ([^[:space:]]+).*/\1/p' "$details_log" | tail -n 1)"
ddi_services="$(sed -nE 's/.*ddiServicesAvailable: ([^[:space:]]+).*/\1/p' "$details_log" | tail -n 1)"
tunnel_state="$(sed -nE 's/.*tunnelState: ([^[:space:]]+).*/\1/p' "$details_log" | tail -n 1)"

echo "Physical preview preflight"
echo "platform: $PLATFORM"
echo "scheme: $scheme"
echo "device: $DEVICE_ID"
echo "pairing: ${pairing_state:-unknown}"
echo "Developer Mode: ${developer_mode:-unknown}"
echo "DDI services: ${ddi_services:-unknown}"
echo "tunnel: ${tunnel_state:-unknown}"

if [[ "${pairing_state:-}" != "paired" || "${developer_mode:-}" != "enabled" || "${ddi_services:-}" != "true" || "${tunnel_state:-}" == "disconnected" || "${tunnel_state:-}" == "unavailable" || -z "${tunnel_state:-}" ]]; then
  echo "device is not ready; no build, install, or launch was attempted" >&2
  echo "enable Developer Mode, keep the device unlocked and connected, then rerun this command" >&2
  echo "diagnostics: $WORK_ROOT" >&2
  exit 1
fi

build_args=(
  -project "$PROJECT_ROOT/VirtualPet.xcodeproj"
  -scheme "$scheme"
  -destination "platform=$destination_platform,id=$DEVICE_ID"
  -derivedDataPath "$DERIVED_DATA"
  CODE_SIGNING_ALLOWED=YES
  ENABLE_USER_SCRIPT_SANDBOXING=NO
)
if [[ -n "${DEVELOPMENT_TEAM:-}" ]]; then
  build_args+=(DEVELOPMENT_TEAM="$DEVELOPMENT_TEAM")
fi

DEVELOPER_DIR="$DEVELOPER_DIR_VALUE" xcodebuild "${build_args[@]}" build

app_path="$DERIVED_DATA/Build/Products/$product_directory/$app_name"
[[ -d "$app_path" ]] || {
  echo "built app not found: $app_path" >&2
  exit 1
}

install_json="$WORK_ROOT/install.json"
launch_json="$WORK_ROOT/launch.json"
DEVELOPER_DIR="$DEVELOPER_DIR_VALUE" "$DEVICETool" device install app \
  --device "$DEVICE_ID" \
  --timeout 180 \
  --json-output "$install_json" \
  "$app_path"
DEVELOPER_DIR="$DEVELOPER_DIR_VALUE" "$DEVICETool" device process launch \
  --device "$DEVICE_ID" \
  --terminate-existing \
  --timeout 60 \
  --json-output "$launch_json" \
  "$bundle_id"

echo "physical preview launched"
echo "app: $app_path"
echo "diagnostics: $WORK_ROOT"
