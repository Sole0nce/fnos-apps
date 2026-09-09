#!/bin/bash
set -euo pipefail

INPUT_VERSION="${1:-}"

INPUT_VERSION="${1:-}"

# Upstream publishes the runtime artefacts ONLY as Docker Hub tags
# (docker.io/logvar/danmu-api). GitHub has no releases and the git tags lag
# behind the image tags (git v1.19.16 vs image 1.20.7 at packaging time), so
# the Docker Hub tag list is the authoritative version source. Image tags are
# plain semver without a "v" prefix; "latest" and "*-test" tags are excluded.
if [ -n "$INPUT_VERSION" ]; then
  VERSION="$INPUT_VERSION"
else
  VERSION=$(curl -sL "https://hub.docker.com/v2/repositories/logvar/danmu-api/tags?page_size=100" | \
    jq -r '.results[].name' | grep -E '^[0-9]+\.[0-9]+\.[0-9]+$' | sort -V | tail -1)
fi

[ -z "$VERSION" ] || [ "$VERSION" = "null" ] && { echo "Failed to resolve version for danmu-api" >&2; exit 1; }

echo "VERSION=$VERSION"

if [ -n "${GITHUB_OUTPUT:-}" ]; then
  echo "version=$VERSION" >> "$GITHUB_OUTPUT"
fi
