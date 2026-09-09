#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../../lib/gh-api.sh
source "$SCRIPT_DIR/../../lib/gh-api.sh"

INPUT_VERSION="${1:-}"

TAG=$(gh_latest_tag "Kareadita/Kavita") || { echo "Failed to resolve version for kavita" >&2; exit 1; }

if [ -n "$INPUT_VERSION" ]; then
  VERSION="$INPUT_VERSION"
else
  # Docker tags use 3-segment versions (e.g. 0.8.9), GitHub uses 4-segment (e.g. v0.8.9.1)
  VERSION=$(echo "$TAG" | sed 's/^v//' | sed 's/\.[0-9]*$//')
fi

[ -z "$VERSION" ] || [ "$VERSION" = "null" ] && { echo "Failed to resolve version for kavita" >&2; exit 1; }

echo "VERSION=$VERSION"

if [ -n "${GITHUB_OUTPUT:-}" ]; then
  echo "version=$VERSION" >> "$GITHUB_OUTPUT"
fi
