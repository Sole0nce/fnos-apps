#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

VERSION="${VERSION:-latest}"

echo "==> Building MSLX ${VERSION} (Docker app, image docker.mslmc.cn/...:latest)"

WORK_DIR=$(mktemp -d)
trap "rm -rf $WORK_DIR" EXIT

# MSLX 是 Docker 应用：fpk 里 app.tgz 只含 docker-compose + ui。
# 镜像固定用官方源 latest tag（国内拉取快、永远最新），版本号由
# get-latest-version.sh 从 Docker Hub 解析用于 manifest/release。
mkdir -p "${WORK_DIR}/docker"
cp "${REPO_ROOT}/apps/MSLX/fnos/docker/docker-compose.yaml" "${WORK_DIR}/docker/"

cp -a "${REPO_ROOT}/apps/MSLX/fnos/ui" "${WORK_DIR}/ui"

cd "${WORK_DIR}"
tar czf "${REPO_ROOT}/app.tgz" docker/ ui/

echo "Built app.tgz for MSLX ${VERSION} ($(du -h "${REPO_ROOT}/app.tgz" | cut -f1))"
