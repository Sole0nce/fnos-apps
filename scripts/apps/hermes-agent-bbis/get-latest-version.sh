#!/bin/bash
set -euo pipefail

# Follows the latest release of iranee/fnos-hermes-agent and extracts the
# version number from its tag. Upstream tags carry a repo prefix, e.g.
# "fnos-hermes-agent_v0.19.0-50", so we extract the x.y.z(-N)? portion.

INPUT_VERSION="${1:-}"

VERSION=""
if [ -n "$INPUT_VERSION" ]; then
  VERSION=$(echo "$INPUT_VERSION" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+(-[0-9]+)?' | head -1 || true)
else
  TAG=$(curl -sL "https://api.github.com/repos/iranee/fnos-hermes-agent/releases/latest" \
    | grep -oE '"tag_name"[[:space:]]*:[[:space:]]*"[^"]+"' | head -1 \
    | sed -E 's/.*"([^"]+)"$/\1/' || true)
  if [ -z "$TAG" ]; then
    TAG=$(git ls-remote --tags --refs https://github.com/iranee/fnos-hermes-agent.git \
      | awk -F/ '{print $NF}' | sort -V | tail -1 || true)
  fi
  VERSION=$(echo "$TAG" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+(-[0-9]+)?' | head -1 || true)
fi

[ -z "$VERSION" ] && { echo "Failed to resolve version for hermes-agent-bbis" >&2; exit 1; }

echo "VERSION=$VERSION"

if [ -n "${GITHUB_OUTPUT:-}" ]; then
  echo "version=$VERSION" >> "$GITHUB_OUTPUT"
fi
