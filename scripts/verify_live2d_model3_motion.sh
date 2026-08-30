#!/usr/bin/env bash

set -euo pipefail

readonly PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
readonly SDK_ROOT="${PROJECT_ROOT}/PrivateAssets/SDK/CubismSdkForNative-5-r.5"
readonly MODEL_ROOT="${1:-${PROJECT_ROOT}/PrivateAssets/Live2D/Exports/PhoebeLive2D}"
readonly MODEL3_PATH="${MODEL_ROOT}/phoebe.model3.json"
readonly CORE_LIBRARY="${SDK_ROOT}/Core/lib/macos/arm64/libLive2DCubismCore.a"
readonly PROBE_ROOT="${PROJECT_ROOT}/.runtime/live2d-model3-probe"
readonly PROBE_BINARY="${PROBE_ROOT}/probe_model3_motion"

[[ -s "${MODEL3_PATH}" ]] || { echo "missing model3.json: ${MODEL3_PATH}" >&2; exit 1; }
[[ -f "${SDK_ROOT}/Core/include/Live2DCubismCore.h" ]] || { echo "missing Cubism Core headers" >&2; exit 1; }
[[ -f "${CORE_LIBRARY}" ]] || { echo "missing macOS Cubism Core library" >&2; exit 1; }

mkdir -p "${PROBE_ROOT}"
clang++ -std=c++14 \
  -I"${PROJECT_ROOT}/Live2DRuntime/include" \
  -I"${SDK_ROOT}/Core/include" \
  "${PROJECT_ROOT}/Live2DRuntime/src/PhoebeLive2DRuntime.cpp" \
  "${PROJECT_ROOT}/Live2DRuntime/tools/probe_model3_motion.cpp" \
  "${CORE_LIBRARY}" \
  -o "${PROBE_BINARY}"

"${PROBE_BINARY}" "${MODEL3_PATH}"
