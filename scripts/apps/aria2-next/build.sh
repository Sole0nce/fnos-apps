#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/meta.env"

VERSION="${VERSION:-latest}"
WORK_DIR=$(mktemp -d)
trap "rm -rf $WORK_DIR" EXIT

mkdir -p "${WORK_DIR}/docker"
cp "${SCRIPT_DIR}/../../../apps/aria2-next/fnos/docker/docker-compose.yaml" "${WORK_DIR}/docker/"
# The image tag carries a literal v prefix (ghcr.io/aninsomniacy/aria2-next:v2.6.8),
# so substitute only the ${VERSION} placeholder and keep the v.
sed -i.bak "s/\${VERSION}/${VERSION}/g" "${WORK_DIR}/docker/docker-compose.yaml"
rm -f "${WORK_DIR}/docker/docker-compose.yaml.bak"

cp -a "${SCRIPT_DIR}/../../../apps/aria2-next/fnos/ui" "${WORK_DIR}/ui"

cd "${WORK_DIR}"
tar czf "${SCRIPT_DIR}/../../../app.tgz" docker/ ui/

echo "Built app.tgz for aria2-next ${VERSION}"
