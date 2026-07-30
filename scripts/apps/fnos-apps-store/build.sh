#!/bin/bash
set -euo pipefail

VERSION="${VERSION:-}"
TARBALL_ARCH="${TARBALL_ARCH:-${DEB_ARCH:-amd64}}"

[ -z "$VERSION" ] && { echo "VERSION is required" >&2; exit 1; }

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
APP_FNOS_DIR="$REPO_ROOT/apps/fnos-apps-store/fnos"

echo "==> Building fnos-apps-store ${VERSION} for ${TARBALL_ARCH}"

DOWNLOAD_URL="https://github.com/Sole0nce/fnos-store/releases/download/v${VERSION}/store-server-linux-${TARBALL_ARCH}"
curl -fL -o store-server "$DOWNLOAD_URL"
chmod +x store-server

mkdir -p app_root
mv store-server app_root/store-server

# Include files that appcenter-cli extracts to /vol1/@appcenter/<app>/
# These are needed for desktop icon, port forwarding, and permissions.
cp -a "$APP_FNOS_DIR/ui" app_root/
cp -a "$APP_FNOS_DIR/config" app_root/
cp "$APP_FNOS_DIR/fnos-apps-store.sc" app_root/

cd app_root
tar -czf ../app.tgz .
