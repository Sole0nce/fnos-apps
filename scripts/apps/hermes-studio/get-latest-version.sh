#!/bin/bash
set -euo pipefail

# Follows the latest release tag of veenyi/Fnos-Hermes-Studio (e.g. v0.6.39-1).
# The fnOS package version == the upstream tag with the leading "v" stripped.

INPUT_VERSION="${1:-}"

VERSION=""
if [ -n "$INPUT_VERSION" ]; then
  VERSION="${INPUT_VERSION#v}"
else
  TAG=$(curl -sL "https://api.github.com/repos/veenyi/Fnos-Hermes-Studio/releases/latest" \
    | grep -oE '"tag_name"[[:space:]]*:[[:space:]]*"[^"]+"' | head -1 \
    | sed -E 's/.*"([^"]+)"$/\1/' || true)
  if [ -z "$TAG" ]; then
    TAG=$(git ls-remote --tags --refs https://github.com/veenyi/Fnos-Hermes-Studio.git \
      | awk -F/ '{print $NF}' | sort -V | tail -1 || true)
  fi
  VERSION="${TAG#v}"
fi

[ -z "$VERSION" ] || [ "$VERSION" = "null" ] && { echo "Failed to resolve version for hermes-studio" >&2; exit 1; }

# Fail fast if the version doesn't look like an upstream version (x.y.z or x.y.z-N).
if ! echo "$VERSION" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+(-[0-9]+)?$'; then
  echo "[ERROR] Resolved version '$VERSION' is not a version-style tag (e.g. 0.6.39-1)" >&2
  exit 1
fi

echo "VERSION=$VERSION"

if [ -n "${GITHUB_OUTPUT:-}" ]; then
  echo "version=$VERSION" >> "$GITHUB_OUTPUT"
fi
