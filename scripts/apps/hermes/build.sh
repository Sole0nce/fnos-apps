#!/bin/bash
set -euo pipefail

VERSION="${VERSION:-}"

[ -z "$VERSION" ] && { echo "VERSION is required" >&2; exit 1; }

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
APP_FNOS_DIR="$REPO_ROOT/apps/hermes/fnos"

echo "==> Building Hermes ${VERSION}"

WORK_DIR=$(mktemp -d)
trap "rm -rf $WORK_DIR" EXIT

mkdir -p "${WORK_DIR}/docker"

# Copy docker-compose.yaml with version substitution
cp "$APP_FNOS_DIR/docker/docker-compose.yaml" "${WORK_DIR}/docker/"
sed -i "s/\${VERSION}/${VERSION}/g" "${WORK_DIR}/docker/docker-compose.yaml"

# Copy UI files
cp -a "$APP_FNOS_DIR/ui" "${WORK_DIR}/"

cd "${WORK_DIR}"
tar -czf "${REPO_ROOT}/app.tgz" .
echo "Built app.tgz for Hermes ${VERSION}"
