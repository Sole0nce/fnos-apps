#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../../lib/gh-api.sh
source "$SCRIPT_DIR/../../lib/gh-api.sh"

INPUT_VERSION="${1:-}"

TAG=$(gh_latest_tag "Sonarr/Sonarr") || { echo "Failed to resolve version for sonarr" >&2; exit 1; }

if [ -n "$INPUT_VERSION" ]; then
  VERSION=$(echo "$INPUT_VERSION" | sed 's/^v//')
else
  VERSION=$(echo "$TAG" | sed 's/^v//')
fi

[ -z "$VERSION" ] || [ "$VERSION" = "null" ] && { echo "Failed to resolve version for sonarr" >&2; exit 1; }

echo "VERSION=$VERSION"

if [ -n "${GITHUB_OUTPUT:-}" ]; then
  echo "version=$VERSION" >> "$GITHUB_OUTPUT"
fi
