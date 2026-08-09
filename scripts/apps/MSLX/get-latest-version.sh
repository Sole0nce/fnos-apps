#!/bin/bash
set -euo pipefail

INPUT_VERSION="${1:-}"

if [ -n "$INPUT_VERSION" ]; then
  VERSION="$INPUT_VERSION"
else
  # MSLX 版本跟随 Docker Hub 镜像 tag（如 v1.5.9），镜像仓库为
  # xiaoyululu/mslx-daemon。官方自建源 docker.mslmc.cn 需要鉴权无法自动
  # 查询，Docker Hub API 公开可查 tag 列表，用于每日构建版本检测。
  VERSION=$(curl -sL "https://hub.docker.com/v2/repositories/xiaoyululu/mslx-daemon/tags?page_size=25&ordering=last_updated" | \
    jq -r '.results[] | select(.name != "latest" and .name != "dev") | .name' | head -1)
fi

VERSION=$(echo "$VERSION" | sed 's/^v//')

[ -z "$VERSION" ] || [ "$VERSION" = "null" ] && { echo "Failed to resolve version for MSLX" >&2; exit 1; }

echo "VERSION=$VERSION"

if [ -n "${GITHUB_OUTPUT:-}" ]; then
  echo "version=$VERSION" >> "$GITHUB_OUTPUT"
fi
