#!/bin/bash
set -euo pipefail

INPUT_VERSION="${1:-}"

if [ -n "$INPUT_VERSION" ]; then
  VERSION="$INPUT_VERSION"
else
  # GSManager 版本跟随 Docker Hub 镜像 tag（如 3.13.21），与 GitHub release tag 同步
  VERSION=$(curl -sL "https://hub.docker.com/v2/repositories/xiaozhu674/gameservermanager/tags?page_size=25&ordering=last_updated" | \
    jq -r '.results[] | select(.name != "latest") | .name' | head -1)
fi

VERSION=$(echo "$VERSION" | sed 's/^v//')

[ -z "$VERSION" ] || [ "$VERSION" = "null" ] && { echo "Failed to resolve version for docker-gsmanager" >&2; exit 1; }

echo "VERSION=$VERSION"

if [ -n "${GITHUB_OUTPUT:-}" ]; then
  echo "version=$VERSION" >> "$GITHUB_OUTPUT"
fi
