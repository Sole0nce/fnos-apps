#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../../lib/gh-api.sh
source "$SCRIPT_DIR/../../lib/gh-api.sh"

INPUT_VERSION="${1:-}"

TAG=$(gh_latest_tag "MetaCubeX/mihomo") || { echo "Failed to resolve version for mihomo" >&2; exit 1; }

if [ -n "$INPUT_VERSION" ]; then
  VERSION="$INPUT_VERSION"
else
  VERSION=$(echo "$TAG" | sed 's/^v//')
fi

if [ -z "$VERSION" ] || [ "$VERSION" = "null" ]; then
  echo "Failed to resolve version for mihomo" >&2
  exit 1
fi

echo "VERSION=$VERSION"

if [ -n "${GITHUB_OUTPUT:-}" ]; then
  echo "version=$VERSION" >> "$GITHUB_OUTPUT"
fi
