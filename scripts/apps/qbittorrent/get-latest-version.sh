#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../../lib/gh-api.sh
source "$SCRIPT_DIR/../../lib/gh-api.sh"

INPUT_VERSION="${1:-}"

UPSTREAM_TAG=$(gh_latest_tag "userdocs/qbittorrent-nox-static") || { echo "Failed to resolve version for qbittorrent" >&2; exit 1; }

if [ -n "$INPUT_VERSION" ]; then
  VERSION="$INPUT_VERSION"
else
  VERSION=$(echo "$UPSTREAM_TAG" | sed -E 's/release-([0-9]+\.[0-9]+\.[0-9]+)_.*/\1/')
fi

[ -z "$VERSION" ] || [ "$VERSION" = "null" ] && { echo "Failed to resolve version for qbittorrent" >&2; exit 1; }

echo "VERSION=$VERSION"
echo "UPSTREAM_TAG=$UPSTREAM_TAG"

if [ -n "${GITHUB_OUTPUT:-}" ]; then
  echo "version=$VERSION" >> "$GITHUB_OUTPUT"
  echo "upstream_tag=$UPSTREAM_TAG" >> "$GITHUB_OUTPUT"
fi
