#!/usr/bin/env bash

set -euo pipefail

readonly PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
readonly SOURCE_ROOT="${PROJECT_ROOT}/Live2DRuntime"
readonly SDK_ROOT="${PROJECT_ROOT}/PrivateAssets/SDK/CubismSdkForNative-5-r.5"
readonly IOS_TOOLCHAIN="${SDK_ROOT}/Samples/Metal/thirdParty/ios-cmake/ios.toolchain.cmake"
readonly BUILD_ROOT="${PROJECT_ROOT}/PrivateAssets/Build/PhoebeLive2DRuntime"
readonly OUTPUT_PATH="${PROJECT_ROOT}/PrivateAssets/Build/PhoebeLive2DRuntime.xcframework"
readonly XCODEBUILD="/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild"
readonly CMAKE_GENERATOR="Unix Makefiles"

export DEVELOPER_DIR="/Applications/Xcode.app/Contents/Developer"

if [[ ! -f "${SDK_ROOT}/Core/include/Live2DCubismCore.h" ]]; then
  echo "missing Cubism SDK: ${SDK_ROOT}" >&2
  exit 1
fi

if [[ ! -f "${IOS_TOOLCHAIN}" ]]; then
  echo "missing ios-cmake 4.5.0; run the SDK setup_ios_cmake script first" >&2
  exit 1
fi

rm -rf "${BUILD_ROOT}" "${OUTPUT_PATH}"
mkdir -p "${BUILD_ROOT}"

build_ios_slice() {
  local name="$1"
  local platform="$2"
  local core_library="$3"
  local build_dir="${BUILD_ROOT}/${name}"
  local wrapper_library

  cmake -S "${SOURCE_ROOT}" -B "${build_dir}" -G "${CMAKE_GENERATOR}" \
    -D CMAKE_TOOLCHAIN_FILE="${IOS_TOOLCHAIN}" \
    -D PLATFORM="${platform}" \
    -D DEPLOYMENT_TARGET=26.2 \
    -D CUBISM_CORE_INCLUDE="${SDK_ROOT}/Core/include"
  cmake --build "${build_dir}" --config Release --target PhoebeLive2DRuntime

  wrapper_library="$(find "${build_dir}" -type f -name 'libPhoebeLive2DRuntime.a' -print -quit)"
  if [[ -z "${wrapper_library}" ]]; then
    echo "wrapper library was not produced for ${name}" >&2
    exit 1
  fi

  /usr/bin/libtool -static \
    -o "${BUILD_ROOT}/libPhoebeLive2DRuntime-${name}.a" \
    "${wrapper_library}" "${core_library}"
}

build_ios_slice \
  ios-arm64 \
  OS64 \
  "${SDK_ROOT}/Core/lib/ios/Release-iphoneos/libLive2DCubismCore.a"

build_ios_slice \
  ios-arm64-simulator \
  SIMULATORARM64 \
  "${SDK_ROOT}/Core/lib/ios/Release-iphonesimulator-arm64/libLive2DCubismCore.a"

readonly MAC_BUILD_DIR="${BUILD_ROOT}/macos-arm64"
cmake -S "${SOURCE_ROOT}" -B "${MAC_BUILD_DIR}" -G "${CMAKE_GENERATOR}" \
  -D CMAKE_OSX_ARCHITECTURES=arm64 \
  -D CMAKE_OSX_DEPLOYMENT_TARGET=15.7 \
  -D CUBISM_CORE_INCLUDE="${SDK_ROOT}/Core/include"
cmake --build "${MAC_BUILD_DIR}" --config Release --target PhoebeLive2DRuntime

readonly MAC_WRAPPER_LIBRARY="$(find "${MAC_BUILD_DIR}" -type f -name 'libPhoebeLive2DRuntime.a' -print -quit)"
/usr/bin/libtool -static \
  -o "${BUILD_ROOT}/libPhoebeLive2DRuntime-macos-arm64.a" \
  "${MAC_WRAPPER_LIBRARY}" \
  "${SDK_ROOT}/Core/lib/macos/arm64/libLive2DCubismCore.a"

"${XCODEBUILD}" -create-xcframework \
  -library "${BUILD_ROOT}/libPhoebeLive2DRuntime-ios-arm64.a" \
  -headers "${SOURCE_ROOT}/include" \
  -library "${BUILD_ROOT}/libPhoebeLive2DRuntime-ios-arm64-simulator.a" \
  -headers "${SOURCE_ROOT}/include" \
  -library "${BUILD_ROOT}/libPhoebeLive2DRuntime-macos-arm64.a" \
  -headers "${SOURCE_ROOT}/include" \
  -output "${OUTPUT_PATH}"

echo "created ${OUTPUT_PATH}"
