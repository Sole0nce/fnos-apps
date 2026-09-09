#!/bin/bash
set -euo pipefail

INPUT_VERSION="${1:-}"

if [ -n "$INPUT_VERSION" ]; then
    VERSION="${INPUT_VERSION#v}"
else
    TAG=$(curl -fsSL "https://api.github.com/repos/deerwan/miair-next/releases/latest" | \
        jq -r '.tag_name')
    VERSION="${TAG#v}"
fi

[ -z "$VERSION" ] || [ "$VERSION" = "null" ] && {
    echo "Failed to resolve version for miair-next" >&2
    exit 1
}

echo "VERSION=$VERSION"

if [ -n "${GITHUB_OUTPUT:-}" ]; then
    echo "version=$VERSION" >> "$GITHUB_OUTPUT"
fi
