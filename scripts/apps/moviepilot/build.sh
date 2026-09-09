#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/meta.env"

VERSION="${VERSION:-latest}"
# Upstream publishes each major to its own Docker Hub repo (moviepilot-v2, moviepilot-v3),
# so the image name carries the major while the tag stays bare (v3 tags have no `v` prefix).
VERSION_MAJOR="${VERSION%%.*}"
WORK_DIR=$(mktemp -d)
trap "rm -rf $WORK_DIR" EXIT

mkdir -p "${WORK_DIR}/docker"
cp "${SCRIPT_DIR}/../../../apps/moviepilot/fnos/docker/docker-compose.yaml" "${WORK_DIR}/docker/"
# Portable in-place edit: bare `sed -i` is GNU-only and aborts on macOS.
# Order matters: ${VERSION_MAJOR} must be substituted BEFORE ${VERSION}, otherwise the
# ${VERSION} pattern also matches the prefix inside ${VERSION_MAJOR} and corrupts the output.
sed -i.bak "s/\${VERSION_MAJOR}/${VERSION_MAJOR}/g" "${WORK_DIR}/docker/docker-compose.yaml"
sed -i.bak "s/\${VERSION}/${VERSION}/g" "${WORK_DIR}/docker/docker-compose.yaml"
rm -f "${WORK_DIR}/docker/docker-compose.yaml.bak"


cp -a "${SCRIPT_DIR}/../../../apps/moviepilot/fnos/ui" "${WORK_DIR}/ui"

cd "${WORK_DIR}"
tar czf "${SCRIPT_DIR}/../../../app.tgz" docker/ ui/

echo "Built app.tgz for moviepilot ${VERSION}"
