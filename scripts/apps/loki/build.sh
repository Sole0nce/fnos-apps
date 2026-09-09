#!/bin/bash
set -euo pipefail

VERSION="${VERSION:-}"
ZIP_ARCH="${ZIP_ARCH:-${DEB_ARCH:-amd64}}"

[ -z "$VERSION" ] && { echo "VERSION is required" >&2; exit 1; }

echo "==> Building Loki ${VERSION} for ${ZIP_ARCH}"

DOWNLOAD_URL="https://github.com/grafana/loki/releases/download/v${VERSION}/loki-linux-${ZIP_ARCH}.zip"
curl -fL -o loki.zip "$DOWNLOAD_URL"

unzip -o loki.zip

mkdir -p app_root/bin app_root/ui app_root/config
LOKI_BIN="loki-linux-${ZIP_ARCH}"
[ ! -f "$LOKI_BIN" ] && { echo "loki binary not found in zip" >&2; exit 1; }

cp "$LOKI_BIN" app_root/loki
chmod +x app_root/loki

cp apps/loki/fnos/bin/loki-server app_root/bin/loki-server
chmod +x app_root/bin/loki-server
# Seed config: the upstream zip ships only the binary, so without this a fresh
# install has no -config.file and loki exits immediately on start.
cp apps/loki/fnos/config/loki-config.yaml app_root/config/loki-config.yaml
cp -a apps/loki/fnos/ui/* app_root/ui/ 2>/dev/null || true

cd app_root
tar -czf ../app.tgz .
