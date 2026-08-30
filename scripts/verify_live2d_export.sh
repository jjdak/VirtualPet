#!/usr/bin/env bash

set -euo pipefail

readonly PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
readonly MODEL_ROOT="${1:-${PROJECT_ROOT}/PrivateAssets/Live2D/Exports/PhoebeLive2D}"
readonly MODEL_JSON="${MODEL_ROOT}/phoebe.model3.json"
readonly CONTRACT_MANIFEST="${PROJECT_ROOT}/docs/live2d/phoebe-layer-manifest.json"

require_command() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "missing command: $1" >&2
    exit 1
  }
}

for command_name in jq sips shasum; do
  require_command "$command_name"
done

[[ -f "$MODEL_JSON" ]] || { echo "missing model3: $MODEL_JSON" >&2; exit 1; }

check_reference() {
  local relative_path="$1"
  local absolute_path="${MODEL_ROOT}/${relative_path}"
  [[ -s "$absolute_path" ]] || {
    echo "missing or empty reference: ${relative_path}" >&2
    exit 1
  }
  echo "ok reference: ${relative_path}"
}

readonly moc_reference="$(jq -er '.FileReferences.Moc' "$MODEL_JSON")"
check_reference "$moc_reference"

while IFS= read -r texture_reference; do
  check_reference "$texture_reference"
done < <(jq -er '.FileReferences.Textures[]' "$MODEL_JSON")

display_reference="$(jq -er '.FileReferences.DisplayInfo' "$MODEL_JSON")"
check_reference "$display_reference"

model_version="$(jq -er '.Version' "$MODEL_JSON")"
[[ "$model_version" == "3" ]] || {
  echo "unexpected model3 version: ${model_version}" >&2
  exit 1
}

texture_reference="$(jq -er '.FileReferences.Textures[0]' "$MODEL_JSON")"
texture_path="${MODEL_ROOT}/${texture_reference}"
texture_width="$(sips -g pixelWidth "$texture_path" | awk 'NR == 2 { print $2 }')"
texture_height="$(sips -g pixelHeight "$texture_path" | awk 'NR == 2 { print $2 }')"
texture_alpha="$(sips -g hasAlpha "$texture_path" | awk 'NR == 2 { print $2 }')"
[[ "$texture_alpha" == "yes" ]] || {
  echo "texture has no alpha channel: ${texture_reference}" >&2
  exit 1
}
echo "ok texture: ${texture_reference} (${texture_width}x${texture_height}, alpha=${texture_alpha})"

readonly display_json="${MODEL_ROOT}/${display_reference}"
missing_ids=()
while IFS= read -r required_id; do
  if jq -e --arg required_id "$required_id" '.Parameters[]? | select(.Id == $required_id)' "$display_json" >/dev/null; then
    echo "ok parameter: ${required_id}"
    continue
  fi

  mapped_ids=()
  while IFS= read -r mapped_id; do
    [[ -n "$mapped_id" ]] && mapped_ids+=("$mapped_id")
  done < <(jq -r --arg required_id "$required_id" '.parameterMappings[$required_id]? // [] | .[]' "$CONTRACT_MANIFEST")

  mapped_ok=1
  if (( ${#mapped_ids[@]} == 0 )); then
    mapped_ok=0
  else
    for mapped_id in "${mapped_ids[@]}"; do
      if ! jq -e --arg mapped_id "$mapped_id" '.Parameters[]? | select(.Id == $mapped_id)' "$display_json" >/dev/null; then
        mapped_ok=0
        break
      fi
    done
  fi

  if (( mapped_ok == 1 )); then
    echo "ok mapped parameter: ${required_id} <- ${mapped_ids[*]}"
  else
    missing_ids+=("$required_id")
  fi
done < <(jq -er '.requiredParameters[]' "$CONTRACT_MANIFEST")

if (( ${#missing_ids[@]} > 0 )); then
  echo "parameter contract mismatch: ${missing_ids[*]}" >&2
  echo "exported IDs:" >&2
  jq -r '.Parameters[].Id' "$display_json" >&2
  echo "mapped parameters accepted: ParamEyeSmile <- ParamEyeLSmile + ParamEyeRSmile; ParamHairSwing <- ParamHairFront/ParamHairSide/ParamHairBack" >&2
  echo "missing production-v1 model parameter: ParamHatSwing (expected for RigLite; do not add a no-op parameter)" >&2
  exit 2
fi

echo "ok parameter contract"
echo "Live2D export references and texture validated: ${MODEL_ROOT}"
