#!/bin/bash

set -euo pipefail

if [[ "$#" -lt 1 ]]; then
  echo "usage: $0 APP_BUNDLE [APP_BUNDLE ...]" >&2
  exit 2
fi

readonly expected_names=(
  phoebe-chirubi-angry-private
  phoebe-chirubi-soft-private
  phoebe-chirubi-mildly-angry-private
)

for app_bundle in "$@"; do
  if [[ -d "${app_bundle}/Contents/Resources/PrivateAudio" ]]; then
    audio_dir="${app_bundle}/Contents/Resources/PrivateAudio"
  else
    audio_dir="${app_bundle}/PrivateAudio"
  fi

  if [[ ! -d "$audio_dir" ]]; then
    echo "missing PrivateAudio directory: $app_bundle" >&2
    exit 1
  fi

  echo "checking $audio_dir"
  for name in "${expected_names[@]}"; do
    audio_file="${audio_dir}/${name}.m4a"
    if [[ ! -f "$audio_file" ]]; then
      echo "missing private audio: $audio_file" >&2
      exit 1
    fi

    audio_info="$(/usr/bin/afinfo "$audio_file")"
    if ! grep -Eq 'Data format:.*1 ch,[[:space:]]+44100 Hz, aac' <<<"$audio_info"; then
      echo "unexpected audio format: $audio_file" >&2
      exit 1
    fi

    duration="$(awk -F': ' '/estimated duration:/ { print $2; exit }' <<<"$audio_info")"
    if [[ -z "$duration" ]]; then
      echo "missing duration metadata: $audio_file" >&2
      exit 1
    fi
    echo "  ${name}: ${duration}"
  done
done

echo "private audio bundle verification passed"
