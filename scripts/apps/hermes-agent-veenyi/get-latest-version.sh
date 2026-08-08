#!/bin/bash
set -euo pipefail

# Follows the latest release of veenyi/fnos-hermes-agent and extracts the
# version number from its tag. Upstream tags carry a repo prefix, e.g.
# "fnos-hermes-agent_v0.21.95" (and some releases use "v0.21.92"), so we
# extract the x.y.z(-N)? portion instead of naively stripping a "v".
# The fnOS package version == that extracted version.

INPUT_VERSION="${1:-}"

VERSION=""
if [ -n "$INPUT_VERSION" ]; then
  # accept "v0.21.92", "0.21.92", "fnos-hermes-agent_v0.21.95", ...
  VERSION=$(echo "$INPUT_VERSION" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+(-[0-9]+)?' | head -1 || true)
else
  TAG=$(curl -sL "https://api.github.com/repos/veenyi/fnos-hermes-agent/releases/latest" \
    | grep -oE '"tag_name"[[:space:]]*:[[:space:]]*"[^"]+"' | head -1 \
    | sed -E 's/.*"([^"]+)"$/\1/' || true)
  if [ -z "$TAG" ]; then
    TAG=$(git ls-remote --tags --refs https://github.com/veenyi/fnos-hermes-agent.git \
      | awk -F/ '{print $NF}' | sort -V | tail -1 || true)
  fi
  VERSION=$(echo "$TAG" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+(-[0-9]+)?' | head -1 || true)
fi

[ -z "$VERSION" ] && { echo "Failed to resolve version for hermes-agent-veenyi" >&2; exit 1; }

echo "VERSION=$VERSION"

if [ -n "${GITHUB_OUTPUT:-}" ]; then
  echo "version=$VERSION" >> "$GITHUB_OUTPUT"
fi
