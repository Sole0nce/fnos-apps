#!/bin/bash
set -euo pipefail

INPUT_VERSION="${1:-}"

# The fpk packages the store-server binary published on the fork's own
# fnos-store releases (see build.sh), so the version comes from that repo's
# latest release.
#
# Use the authenticated API when a token is available: the unauthenticated
# api.github.com quota is per-runner-IP and shared between jobs, and a
# rate-limited response decodes to "null" — which used to surface as
# "Failed to resolve version for fnos-apps-store" on an otherwise fine build.
TAG=""
if command -v gh >/dev/null 2>&1 && [ -n "${GH_TOKEN:-}${GITHUB_TOKEN:-}" ]; then
  TAG=$(gh api repos/Sole0nce/fnos-store/releases/latest -q .tag_name 2>/dev/null || true)
fi
if [ -z "$TAG" ]; then
  TAG=$(curl -sL "https://api.github.com/repos/Sole0nce/fnos-store/releases/latest" | jq -r '.tag_name // empty')
fi

if [ -n "$INPUT_VERSION" ]; then
  VERSION="$INPUT_VERSION"
else
  VERSION="${TAG#v}"
fi

if [ -z "$VERSION" ] || [ "$VERSION" = "null" ]; then
  echo "Failed to resolve version for fnos-apps-store (tag='${TAG}')" >&2
  exit 1
fi

echo "VERSION=$VERSION"

if [ -n "${GITHUB_OUTPUT:-}" ]; then
  echo "version=$VERSION" >> "$GITHUB_OUTPUT"
fi
