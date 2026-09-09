#!/bin/bash
set -euo pipefail

VERSION="${VERSION:-}"
TARBALL_ARCH="${TARBALL_ARCH:-${DEB_ARCH:-amd64}}"

[ -z "$VERSION" ] && { echo "VERSION is required" >&2; exit 1; }

# Map CI arch names to PicoClaw asset names
case "$TARBALL_ARCH" in
  amd64) ASSET_ARCH="x86_64" ;;
  arm64) ASSET_ARCH="arm64" ;;
  *) echo "Unsupported arch: $TARBALL_ARCH" >&2; exit 1 ;;
esac

echo "==> Building PicoClaw ${VERSION} for ${TARBALL_ARCH} (${ASSET_ARCH})"

DOWNLOAD_URL="https://github.com/sipeed/picoclaw/releases/download/v${VERSION}/picoclaw_Linux_${ASSET_ARCH}.tar.gz"
curl -fL -o picoclaw.tar.gz "$DOWNLOAD_URL"

mkdir -p extracted
tar -xzf picoclaw.tar.gz -C extracted

# Find the picoclaw + launcher binaries (launcher = WebUI console, issue #283)
PICOCLAW_BIN=$(find extracted -name "picoclaw" -type f ! -name "picoclaw-launcher*" | head -1)
[ -z "$PICOCLAW_BIN" ] && { echo "picoclaw binary not found in tarball" >&2; exit 1; }
LAUNCHER_BIN=$(find extracted -name "picoclaw-launcher" -type f | head -1)
[ -z "$LAUNCHER_BIN" ] && { echo "picoclaw-launcher binary not found in tarball" >&2; exit 1; }

mkdir -p app_root/bin app_root/ui app_root/config

cp "$PICOCLAW_BIN" app_root/picoclaw
chmod +x app_root/picoclaw
cp "$LAUNCHER_BIN" app_root/picoclaw-launcher
chmod +x app_root/picoclaw-launcher

cp apps/picoclaw/fnos/bin/picoclaw-server app_root/bin/picoclaw-server
# Seed config: without it the gateway aborts on first start with no model_list.
cp apps/picoclaw/fnos/config/picoclaw-config.json app_root/config/picoclaw-config.json
chmod +x app_root/bin/picoclaw-server
cp -a apps/picoclaw/fnos/ui/* app_root/ui/ 2>/dev/null || true

cd app_root
tar -czf ../app.tgz .
