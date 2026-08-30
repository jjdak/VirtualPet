#!/usr/bin/env bash

set -euo pipefail

readonly PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
readonly SDK_ROOT="${PROJECT_ROOT}/PrivateAssets/SDK/CubismSdkForNative-5-r.5"

if [[ ! -d "${SDK_ROOT}" ]]; then
  echo "missing SDK: ${SDK_ROOT}" >&2
  exit 1
fi

verify_sha256() {
  local expected="$1"
  local relative_path="$2"
  local actual

  actual="$(shasum -a 256 "${SDK_ROOT}/${relative_path}" | awk '{print $1}')"
  if [[ "${actual}" != "${expected}" ]]; then
    echo "checksum mismatch: ${relative_path}" >&2
    echo "expected ${expected}" >&2
    echo "actual   ${actual}" >&2
    exit 1
  fi
  echo "ok ${relative_path}"
}

verify_sha256 "0a7b16f8a3d9d536b86fda65e25b090099c1f78340195e4df5c475d60f372fb4" "cubism-info.yml"
verify_sha256 "6f1802780d1eb36ff39705e0764f9eeed9b41c313a13ac155270c6f4ad51d53f" "Core/include/Live2DCubismCore.h"
verify_sha256 "318da4dcfb4ced7221f7ec1487541152dee8c5275059b74156768d66499f0238" "Core/lib/macos/arm64/libLive2DCubismCore.a"
verify_sha256 "544ef4945c19d43919b861567328da6bfd95b99c2474114db403d24ed8292fcc" "Core/lib/ios/Release-iphoneos/libLive2DCubismCore.a"
verify_sha256 "315c224a1fb2d968822549070698e19081919f548f9120c279363735321f4632" "Core/lib/ios/Release-iphonesimulator-arm64/libLive2DCubismCore.a"
verify_sha256 "72b5d9470dad5b2cfe72d43583888afce0779fd557a425bc487b02a7c33ba855" "Samples/Metal/thirdParty/ios-cmake/ios.toolchain.cmake"

echo "Cubism Native 5-r.5 local SDK verified."
