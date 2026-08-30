#!/bin/zsh

set -euo pipefail

PROJECT_ROOT="${0:A:h:h}"
AUDIO_DIR="$PROJECT_ROOT/PrivateAssets/AudioCandidates/BV1cx776cE57/AB"
AFPLAY_BIN="${AFPLAY_BIN:-/usr/bin/afplay}"
SELECTION="${1:-all}"

if [[ ! -x "$AFPLAY_BIN" ]]; then
  print -u2 "afplay not found: $AFPLAY_BIN"
  exit 1
fi

case "$SELECTION" in
  01|02|03)
    candidates=("$SELECTION")
    ;;
  all)
    candidates=(01 02 03)
    ;;
  *)
    print -u2 "usage: $0 [01|02|03|all]"
    exit 2
    ;;
esac

for candidate in $candidates; do
  audio_file="$AUDIO_DIR/${candidate}-ab-preview.m4a"
  if [[ ! -f "$audio_file" ]]; then
    print -u2 "missing private A/B preview: $audio_file"
    exit 1
  fi

  case "$candidate" in
    01) label="生气" ;;
    02) label="正常、略委屈" ;;
    03) label="轻微生气" ;;
  esac
  print "试听 $candidate（$label，A 原始 / B 轻度降噪连续拼接）"
  "$AFPLAY_BIN" "$audio_file"
done
