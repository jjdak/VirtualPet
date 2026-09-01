#!/usr/bin/env bash

set -euo pipefail

readonly PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
readonly DEVELOPER_DIR_VALUE="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"
readonly XCODEBUILD="${DEVELOPER_DIR_VALUE}/usr/bin/xcodebuild"
readonly DEVICETool="${DEVELOPER_DIR_VALUE}/usr/bin/devicectl"
readonly IOS_SCHEME="${SCHEME:-VirtualPet}"
readonly WATCH_SCHEME="${WATCH_SCHEME:-VirtualPetWatch}"
readonly PHYSICAL_SCOPE="${PHYSICAL_SCOPE:-all}"

command -v rg >/dev/null 2>&1 || {
  echo "missing command: rg" >&2
  exit 1
}
[[ -x "$XCODEBUILD" ]] || {
  echo "missing executable: $XCODEBUILD" >&2
  exit 1
}

case "$PHYSICAL_SCOPE" in
  ios|watch|all) ;;
  *)
    echo "unsupported PHYSICAL_SCOPE '$PHYSICAL_SCOPE'; use ios, watch, or all" >&2
    exit 2
    ;;
esac

check_root="${WORK_ROOT:-$(mktemp -d /tmp/VirtualPetPhysicalCheck.XXXXXX)}"
mkdir -p "$check_root"
destinations_log="$check_root/destinations.log"
watch_destinations_log="$check_root/watch-destinations.log"
devices_log="$check_root/devices.log"

DEVELOPER_DIR="$DEVELOPER_DIR_VALUE" "$XCODEBUILD" \
  -project "$PROJECT_ROOT/VirtualPet.xcodeproj" \
  -scheme "$IOS_SCHEME" \
  -showdestinations > "$destinations_log" 2>&1

DEVELOPER_DIR="$DEVELOPER_DIR_VALUE" "$XCODEBUILD" \
  -project "$PROJECT_ROOT/VirtualPet.xcodeproj" \
  -scheme "$WATCH_SCHEME" \
  -showdestinations > "$watch_destinations_log" 2>&1

DEVELOPER_DIR="$DEVELOPER_DIR_VALUE" "$DEVICETool" list devices > "$devices_log" 2>&1 || true

physical_iphone_count="$(rg '^\s*\{ platform:iOS, arch:[^,]+, id:[0-9A-Za-z-]{16,},' "$destinations_log" | rg -v 'error:' | wc -l | tr -d ' ' || true)"
physical_watch_count="$(rg '^\s*\{ platform:watchOS, arch:[^,]+, id:[0-9A-Za-z-]{16,},' "$watch_destinations_log" | rg -v 'error:' | wc -l | tr -d ' ' || true)"
iphone_ineligible_count="$(rg -c '^\s*\{ platform:iOS,.*error:' "$destinations_log" || true)"
watch_ineligible_count="$(rg -c '^\s*\{ platform:watchOS,.*error:' "$watch_destinations_log" || true)"
simulator_count="$(rg -c '^\s*\{ platform:iOS Simulator,' "$destinations_log" || true)"

physical_iphone_count="${physical_iphone_count:-0}"
physical_watch_count="${physical_watch_count:-0}"
iphone_ineligible_count="${iphone_ineligible_count:-0}"
watch_ineligible_count="${watch_ineligible_count:-0}"
simulator_count="${simulator_count:-0}"

echo "Physical acceptance preflight"
echo "project: $PROJECT_ROOT"
echo "iOS scheme: $IOS_SCHEME"
echo "watchOS scheme: $WATCH_SCHEME"
echo "scope: $PHYSICAL_SCOPE"
echo "iPhone destination: $([[ "$physical_iphone_count" -gt 0 ]] && echo ready || echo unavailable) (available=$physical_iphone_count, ineligible=$iphone_ineligible_count)"
echo "Apple Watch destination: $([[ "$physical_watch_count" -gt 0 ]] && echo ready || echo unavailable) (available=$physical_watch_count, ineligible=$watch_ineligible_count)"
echo "iOS Simulator destinations: $simulator_count"

iphone_id="$(awk '/iPhone/ && $0 !~ /Apple Watch/ && $0 ~ /[0-9A-Fa-f]{8}-[0-9A-Fa-f-]{27}/ { match($0, /[0-9A-Fa-f]{8}-[0-9A-Fa-f-]{27}/); print substr($0, RSTART, RLENGTH); exit }' "$devices_log")"
iphone_developer_mode="unknown"
iphone_ddi_services="unknown"
iphone_tunnel_state="unknown"
iphone_pairing_state="unknown"
if [[ -n "$iphone_id" && -x "$DEVICETool" ]]; then
  iphone_details="$check_root/iphone-details.log"
  DEVELOPER_DIR="$DEVELOPER_DIR_VALUE" "$DEVICETool" device info details --device "$iphone_id" > "$iphone_details" 2>&1 || true
  iphone_developer_mode="$(sed -nE 's/.*developerModeStatus: ([^[:space:]]+).*/\1/p' "$iphone_details" | tail -n 1)"
  iphone_ddi_services="$(sed -nE 's/.*ddiServicesAvailable: ([^[:space:]]+).*/\1/p' "$iphone_details" | tail -n 1)"
  iphone_tunnel_state="$(sed -nE 's/.*tunnelState: ([^[:space:]]+).*/\1/p' "$iphone_details" | tail -n 1)"
  iphone_pairing_state="$(sed -nE 's/.*pairingState: ([^[:space:]]+).*/\1/p' "$iphone_details" | tail -n 1)"
  echo "iPhone pairing: ${iphone_pairing_state:-unknown}"
  echo "iPhone Developer Mode: ${iphone_developer_mode:-unknown}"
  echo "iPhone DDI services: ${iphone_ddi_services:-unknown}"
  echo "iPhone tunnel: ${iphone_tunnel_state:-unknown}"
else
  echo "iPhone pairing: unavailable"
  echo "iPhone Developer Mode: unavailable"
  echo "iPhone DDI services: unavailable"
  echo "iPhone tunnel: unavailable"
fi
echo "iPhone CoreDevice ID: ${iphone_id:-unavailable}"
iphone_ready=false
if [[ "$physical_iphone_count" -gt 0 && "$iphone_pairing_state" == "paired" && "$iphone_developer_mode" == "enabled" && "$iphone_ddi_services" == "true" && "$iphone_tunnel_state" != "disconnected" && "$iphone_tunnel_state" != "unavailable" && -n "$iphone_tunnel_state" ]]; then
  iphone_ready=true
fi

watch_id="$(awk '/Apple Watch/ && $0 ~ /[0-9A-Fa-f]{8}-[0-9A-Fa-f-]{27}/ { match($0, /[0-9A-Fa-f]{8}-[0-9A-Fa-f-]{27}/); print substr($0, RSTART, RLENGTH); exit }' "$devices_log")"
watch_ready=false
developer_mode="unknown"
ddi_services="unknown"
tunnel_state="unknown"
pairing_state="unknown"
if [[ -n "$watch_id" && -x "$DEVICETool" ]]; then
  watch_details="$check_root/watch-details.log"
  DEVELOPER_DIR="$DEVELOPER_DIR_VALUE" "$DEVICETool" device info details --device "$watch_id" > "$watch_details" 2>&1 || true
  developer_mode="$(sed -nE 's/.*developerModeStatus: ([^[:space:]]+).*/\1/p' "$watch_details" | tail -n 1)"
  ddi_services="$(sed -nE 's/.*ddiServicesAvailable: ([^[:space:]]+).*/\1/p' "$watch_details" | tail -n 1)"
  tunnel_state="$(sed -nE 's/.*tunnelState: ([^[:space:]]+).*/\1/p' "$watch_details" | tail -n 1)"
  pairing_state="$(sed -nE 's/.*pairingState: ([^[:space:]]+).*/\1/p' "$watch_details" | tail -n 1)"
  echo "Apple Watch pairing: ${pairing_state:-unknown}"
  echo "Apple Watch Developer Mode: ${developer_mode:-unknown}"
  echo "Apple Watch DDI services: ${ddi_services:-unknown}"
  echo "Apple Watch tunnel: ${tunnel_state:-unknown}"
else
  echo "Apple Watch pairing: unavailable"
  echo "Apple Watch Developer Mode: unavailable"
  echo "Apple Watch DDI services: unavailable"
  echo "Apple Watch tunnel: unavailable"
fi
echo "Apple Watch CoreDevice ID: ${watch_id:-unavailable}"
if [[ "$physical_watch_count" -gt 0 && "$pairing_state" == "paired" && "$developer_mode" == "enabled" && "$ddi_services" == "true" && "$tunnel_state" != "disconnected" && "$tunnel_state" != "unavailable" && -n "$tunnel_state" ]]; then
  watch_ready=true
fi

display_info="$(system_profiler SPDisplaysDataType 2>/dev/null || true)"
display_state_raw="$(printf '%s\n' "$display_info" | sed -nE 's/.*Display Asleep: (Yes|No).*/\1/p' | head -n 1)"
case "$display_state_raw" in
  Yes) display_state="Asleep" ;;
  No) display_state="Awake" ;;
  *) display_state="" ;;
esac
if [[ -z "$display_state" ]]; then
  if printf '%s\n' "$display_info" | rg -q '^\s*Online: Yes\s*$'; then
    display_state="Online"
  elif printf '%s\n' "$display_info" | rg -q '^\s*Online: No\s*$'; then
    display_state="Offline"
  fi
fi
echo "Mac display: ${display_state:-unknown}"

echo "iPhone readiness: $([[ "$iphone_ready" == true ]] && echo ready || echo not-ready)"
echo "Apple Watch readiness: $([[ "$watch_ready" == true ]] && echo ready || echo not-ready)"
display_ready=false
if [[ "$display_state" == "Awake" || "$display_state" == "Online" ]]; then
  display_ready=true
fi

exit_code=0
scope_ready=true
case "$PHYSICAL_SCOPE" in
  ios)
    [[ "$iphone_ready" == true && "$display_ready" == true ]] || scope_ready=false
    ;;
  watch)
    [[ "$watch_ready" == true && "$display_ready" == true ]] || scope_ready=false
    ;;
  all)
    [[ "$iphone_ready" == true && "$watch_ready" == true && "$display_ready" == true ]] || scope_ready=false
    ;;
esac

if [[ "$scope_ready" != true ]]; then
  exit_code=1
  echo "physical acceptance is not ready; no device or desktop state was changed" >&2
  echo "manual next steps:" >&2
  if [[ "$PHYSICAL_SCOPE" == "ios" || "$PHYSICAL_SCOPE" == "all" ]] && [[ "$iphone_ready" != true ]]; then
    echo "- iPhone: enable Developer Mode in Settings > Privacy & Security, trust this Mac, then reconnect it." >&2
    if [[ -n "$iphone_id" ]]; then
      echo "  after recovery: DEVICE_ID='$iphone_id' PLATFORM=ios ./scripts/run_physical_preview.sh" >&2
    fi
  fi
  if [[ "$PHYSICAL_SCOPE" == "watch" || "$PHYSICAL_SCOPE" == "all" ]] && [[ "$watch_ready" != true ]]; then
    echo "- Apple Watch: keep it unlocked and near the paired iPhone/Mac, enable Developer Mode, then reconnect it." >&2
    if [[ -n "$watch_id" ]]; then
      echo "  after recovery: DEVICE_ID='$watch_id' PLATFORM=watchos ./scripts/run_physical_preview.sh" >&2
    fi
  fi
  if [[ "$display_ready" != true ]]; then
    echo "- Mac: unlock or wake the display before visual and speaker acceptance." >&2
  fi
else
  echo "physical acceptance preflight is ready"
fi

echo "diagnostics: $check_root"
exit "$exit_code"
