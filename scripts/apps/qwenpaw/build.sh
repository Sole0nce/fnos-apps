#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/meta.env"

VERSION="${VERSION:-latest}"
WORK_DIR=$(mktemp -d)
trap "rm -rf $WORK_DIR" EXIT

mkdir -p "${WORK_DIR}/docker"
cp "${SCRIPT_DIR}/../../../apps/qwenpaw/fnos/docker/docker-compose.yaml" "${WORK_DIR}/docker/"
# Pin image tag: upstream Docker Hub tags carry a "v" prefix (e.g. v2.1.0)
sed -i.tmp "s/\${VERSION}/${VERSION}/g" "${WORK_DIR}/docker/docker-compose.yaml"
rm -f "${WORK_DIR}/docker/docker-compose.yaml.tmp"

cp -a "${SCRIPT_DIR}/../../../apps/qwenpaw/fnos/ui" "${WORK_DIR}/ui"

cd "${WORK_DIR}"
tar czf "${SCRIPT_DIR}/../../../app.tgz" docker/ ui/

echo "Built app.tgz for qwenpaw ${VERSION}"
