#!/bin/bash

set -euo pipefail

project_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$project_dir"

tracked_paths="$(git ls-files --cached)"

private_matches="$(printf '%s\n' "$tracked_paths" | rg -i '(^|/)(PrivateAssets|PrivateAudio|PrivateModels|PrivateMotionAtlases)(/|$)|(^|/)SharedAssets/PrivateAudio(/|$)|(^|/)SharedAssets/Assets\.xcassets/Phoebe(Private|HeadPatPrivate|BodyPokePrivate|ChirpPrivate)\.imageset(/|$)' || true)"
if [[ -n "$private_matches" ]]; then
  echo "private assets are staged or tracked in the public tree:" >&2
  printf '%s\n' "$private_matches" >&2
  exit 1
fi

legacy_matches="$(printf '%s\n' "$tracked_paths" | rg -i '(^|/)(claude\.md|release_notes\.md|final_report\.md)$' || true)"
if [[ -n "$legacy_matches" ]]; then
  echo "legacy documents must not be staged or tracked:" >&2
  printf '%s\n' "$legacy_matches" >&2
  exit 1
fi

if ! git diff --check; then
  echo "whitespace errors found in the working tree" >&2
  exit 1
fi

echo "public tree verification passed"
