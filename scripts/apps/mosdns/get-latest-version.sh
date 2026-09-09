#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../../lib/gh-api.sh
source "$SCRIPT_DIR/../../lib/gh-api.sh"

INPUT_VERSION="${1:-}"

TAG=$(gh_latest_tag "IrineSistiana/mosdns") || { echo "Failed to resolve version for mosdns" >&2; exit 1; }

if [ -n "$INPUT_VERSION" ]; then
  VERSION="$INPUT_VERSION"
else
  VERSION=$(echo "$TAG" | sed 's/^v//')
fi

[ -z "$VERSION" ] || [ "$VERSION" = "null" ] && { echo "Failed to resolve version for mosdns" >&2; exit 1; }

echo "VERSION=$VERSION"
echo "UPSTREAM_TAG=v$VERSION"

if [ -n "${GITHUB_OUTPUT:-}" ]; then
  echo "version=$VERSION" >> "$GITHUB_OUTPUT"
  echo "upstream_tag=v$VERSION" >> "$GITHUB_OUTPUT"
fi
