#!/bin/bash
set -euo pipefail

INPUT_VERSION="${1:-}"

TAG=$(curl -fsSL "https://api.github.com/repos/xiowo/fnos_surface_battery_driver/releases/latest" | jq -r '.tag_name')

if [ -n "$INPUT_VERSION" ]; then
  VERSION="${INPUT_VERSION#v}"
else
  VERSION="${TAG#v}"
fi

[ -z "$VERSION" ] || [ "$VERSION" = "null" ] && {
  echo "Failed to resolve version for surface-battery" >&2
  exit 1
}

echo "VERSION=$VERSION"

if [ -n "${GITHUB_OUTPUT:-}" ]; then
  {
    echo "version=$VERSION"
    echo "full_version=$VERSION"
    echo "upstream_tag=v$VERSION"
  } >> "$GITHUB_OUTPUT"
fi
