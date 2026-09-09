#!/bin/bash
set -euo pipefail

VERSION="${VERSION:-${1:-}}"
TARGET_ARCH="${TARBALL_ARCH:-${DEB_ARCH:-amd64}}"

[ -z "$VERSION" ] && { echo "VERSION is required" >&2; exit 1; }

case "$TARGET_ARCH" in
  amd64|x86|x86_64) ;;
  *) echo "Surface 电池驱动仅支持 x86_64，收到架构: $TARGET_ARCH" >&2; exit 1 ;;
esac

echo "==> Building Surface 电池驱动 ${VERSION} for x86"

WORK_DIR=$(mktemp -d)
trap 'rm -rf "$WORK_DIR"' EXIT
ARCHIVE_URL="https://github.com/xiowo/fnos_surface_battery_driver/archive/refs/tags/v${VERSION}.tar.gz"

curl -fL -o "$WORK_DIR/source.tar.gz" "$ARCHIVE_URL"
mkdir -p "$WORK_DIR/app_root"
tar -xzf "$WORK_DIR/source.tar.gz" -C "$WORK_DIR/app_root" --strip-components=1

# Preserve the upstream release-tag tree exactly. Its app/ directory contains
# the Web UI and unmodified driver source; cmd/ contains the manual build logic.
tar -czf app.tgz -C "$WORK_DIR/app_root" .

echo "Built app.tgz for Surface 电池驱动 ${VERSION} (x86)"
