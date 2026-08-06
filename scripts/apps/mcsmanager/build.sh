#!/bin/bash
set -euo pipefail

VERSION="${VERSION:-}"

[ -z "$VERSION" ] && { echo "VERSION is required" >&2; exit 1; }

echo "==> Building MCSManager ${VERSION}"

DOWNLOAD_URL="https://github.com/MCSManager/MCSManager/releases/download/v${VERSION}/mcsmanager_linux_release.tar.gz"

# Download with integrity verification + retry. Same pattern as syncthing:
# GitHub release-assets CDN can deliver a full-length-but-corrupt payload over
# HTTP/2, so force HTTP/1.1, verify the gzip CRC, and re-fetch on corruption.
for attempt in 1 2 3 4 5; do
  curl -fL --http1.1 --retry 3 --retry-delay 2 --retry-all-errors \
    -o mcsmanager.tar.gz "$DOWNLOAD_URL"
  if gzip -t mcsmanager.tar.gz 2>/dev/null; then
    break
  fi
  echo "  attempt ${attempt}: corrupt download ($(wc -c < mcsmanager.tar.gz) bytes), retrying..." >&2
  rm -f mcsmanager.tar.gz
  [ "$attempt" -eq 5 ] && { echo "ERROR: could not obtain a valid MCSManager tarball after 5 attempts" >&2; exit 1; }
  sleep 3
done

# Extract. Archive root is mcsmanager/{web,daemon,install.sh,...}
# mcsmanager-common is an optionalDependency (file:../common) whose code is
# already inlined into app.js by webpack; the upstream tarball ships it as a
# dangling symlink (no common/ dir inside), which breaks tar extraction on
# some platforms — exclude it, matching the official fnOS-Pack layout.
tar -xzf mcsmanager.tar.gz --exclude='*/node_modules/mcsmanager-common'

# Upstream tarball ships web/ + daemon/ with bundled node_modules (offline
# install). fnOS layout requires a server/ root with luncher.mjs on top.
[ -d "mcsmanager/web" ] || { echo "mcsmanager/web not found after extraction" >&2; exit 1; }
[ -d "mcsmanager/daemon" ] || { echo "mcsmanager/daemon not found after extraction" >&2; exit 1; }

mkdir -p app_root/server
cp -a mcsmanager/web app_root/server/web
cp -a mcsmanager/daemon app_root/server/daemon
cp scripts/apps/mcsmanager/luncher.mjs app_root/server/luncher.mjs

# Sanity check: bundled node_modules must be present, otherwise install would
# require network access (npm i) which we deliberately avoid.
[ -d "app_root/server/web/node_modules" ] || { echo "ERROR: web/node_modules missing — release package changed shape" >&2; exit 1; }
[ -d "app_root/server/daemon/node_modules" ] || { echo "ERROR: daemon/node_modules missing — release package changed shape" >&2; exit 1; }

cd app_root
tar -czf ../app.tgz .
