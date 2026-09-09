#!/bin/bash
set -euo pipefail

VERSION="${VERSION:-}"
ZIP_ARCH="${ZIP_ARCH:-${DEB_ARCH:-amd64}}"

[ -z "$VERSION" ] && { echo "VERSION is required" >&2; exit 1; }

echo "==> Building Headscale ${VERSION} for ${ZIP_ARCH}"

DOWNLOAD_URL="https://github.com/juanfont/headscale/releases/download/v${VERSION}/headscale_${VERSION}_linux_${ZIP_ARCH}"
curl -fL -o headscale "$DOWNLOAD_URL"

mkdir -p app_root/bin app_root/ui app_root/config
chmod +x headscale
cp headscale app_root/headscale

cp apps/headscale/fnos/bin/headscale-server app_root/bin/headscale-server
chmod +x app_root/bin/headscale-server
cp -a apps/headscale/fnos/ui/* app_root/ui/ 2>/dev/null || true
# Seed config: the upstream download is a bare binary, so without this a fresh
# install has no --config file and headscale exits immediately on start.
cp apps/headscale/fnos/config/config.yaml app_root/config/config.yaml

cd app_root
tar -czf ../app.tgz .
