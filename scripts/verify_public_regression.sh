#!/bin/bash

set -euo pipefail

project_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
developer_dir="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"
destination="${DESTINATION:-platform=iOS Simulator,name=iPhone 17,OS=26.2}"
work_root="${WORK_ROOT:-$(mktemp -d /tmp/VirtualPetPublicRegression.XXXXXX)}"
clone_dir="${work_root}/source"
mac_test_dir="${work_root}/mac-tests"
ios_test_dir="${work_root}/ios-ui-tests"

mkdir -p "$clone_dir" "$mac_test_dir" "$ios_test_dir"
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

run_test() {
  local label="$1"
  local log_path="$2"
  shift 2

  echo "running public regression: ${label}"
  if ! DEVELOPER_DIR="$developer_dir" xcodebuild "$@" > "$log_path" 2>&1; then
    echo "public regression failed: ${label}" >&2
    tail -n 80 "$log_path" >&2
    exit 1
  fi
  local xctest_count swift_testing_count
  xctest_count="$(sed -nE 's/.*Executed ([0-9]+) tests, with 0 failures.*/\1/p' "$log_path" | tail -n 1)"
  swift_testing_count="$(sed -nE 's/.*Test run with ([0-9]+) tests in [0-9]+ suite.* passed.*/\1/p' "$log_path" | tail -n 1)"
  if [[ "${xctest_count:-0}" -eq 0 && "${swift_testing_count:-0}" -eq 0 ]]; then
    echo "public regression produced no verifiable test count: ${label}" >&2
    tail -n 100 "$log_path" >&2
    exit 1
  fi
  if rg -q "TEST FAILED|Test run with [0-9]+ tests in [0-9]+ suite.*failed|Executed [0-9]+ tests, with [1-9][0-9]* failures" "$log_path"; then
    echo "public regression reported a failure: ${label}" >&2
    tail -n 100 "$log_path" >&2
    exit 1
  fi
  rg -n "Test run with [0-9]+ tests in [0-9]+ suite.* passed|Executed [0-9]+ tests, with 0 failures|TEST SUCCEEDED" "$log_path" | tail -n 8
}

run_test "macOS arm64 unit tests" "$mac_test_dir/test.log" \
  -project "$clone_dir/VirtualPet.xcodeproj" \
  -scheme VirtualPet \
  -destination 'platform=macOS,arch=arm64' \
  -derivedDataPath "$mac_test_dir/derived-data" \
  -only-testing:VirtualPetTests \
  -skip-testing:VirtualPetUITests \
  -skip-testing:VirtualPetUITestsLaunchTests \
  -parallel-testing-enabled NO \
  CODE_SIGNING_ALLOWED=NO \
  test

run_test "iPhone 17 iOS UI tests" "$ios_test_dir/test.log" \
  -project "$clone_dir/VirtualPet.xcodeproj" \
  -scheme VirtualPet \
  -destination "$destination" \
  -derivedDataPath "$ios_test_dir/derived-data" \
  -only-testing:VirtualPetUITests \
  -parallel-testing-enabled NO \
  CODE_SIGNING_ALLOWED=NO \
  test

echo "public regression passed"
echo "source: $clone_dir"
echo "logs: $work_root"
