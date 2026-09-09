#!/bin/bash
set -euo pipefail

VERSION="${1:-${VERSION:-}}"
TARBALL_ARCH="${TARBALL_ARCH:-amd64}"

[ -z "${VERSION}" ] && { echo "VERSION is required" >&2; exit 1; }

echo "==> Building tinyMediaManager ${VERSION} for ${TARBALL_ARCH} (Docker-based)"

dst=app_root
mkdir -p "$dst/docker"

cp apps/tinymediamanager/fnos/docker/docker-compose.yaml "$dst/docker/"
# Portable in-place edit: bare `sed -i` is GNU-only and aborts on macOS.
sed -i.bak "s/\${VERSION}/${VERSION}/g" "$dst/docker/docker-compose.yaml"
rm -f "$dst/docker/docker-compose.yaml.bak"

cp -a apps/tinymediamanager/fnos/ui "$dst/ui"

cd app_root
tar -czf ../app.tgz .
