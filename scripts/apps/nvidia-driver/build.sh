#!/bin/bash
set -euo pipefail

#
# build.sh for nvidia-driver
#
# Downloads the nvidia-container-toolkit .deb bundle and packages it into
# app.tgz.
#
# The NVIDIA driver .run installer is deliberately NOT bundled. fnOS ships
# prebuilt nvidia*.ko for its own kernel under
# /usr/lib/modules_trim/<kver>/nvidia-gpu-{open,proprietary}/, and the required
# userspace version is whatever those modules report at that moment — a runtime
# property that changes with every fnOS system update. cmd/service-setup
# resolves and caches the matching .run on the device.
#
# Inputs (environment variables):
#   VERSION — nvidia-container-toolkit version (e.g., 1.17.8)
#
# Output: app.tgz in current directory
#

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/meta.env"

VERSION="${VERSION:-}"

[ -z "$VERSION" ] && { echo "VERSION is required" >&2; exit 1; }

NCT_VERSION="$VERSION"

echo "==> Building NVIDIA Driver package (nvidia-container-toolkit ${NCT_VERSION})"

# ============================================================
# 1. Download nvidia-container-toolkit .deb bundle (~10MB)
# ============================================================

NCT_URL="https://github.com/NVIDIA/nvidia-container-toolkit/releases/download/v${NCT_VERSION}/nvidia-container-toolkit_${NCT_VERSION}_deb_amd64.tar.gz"
NCT_ARCHIVE="nvidia-container-toolkit_${NCT_VERSION}_deb_amd64.tar.gz"

echo "==> Downloading nvidia-container-toolkit: ${NCT_URL}"
curl -fL --progress-bar -o "$NCT_ARCHIVE" "$NCT_URL"

# ============================================================
# 2. Extract toolkit .deb files
# ============================================================

echo "==> Extracting nvidia-container-toolkit packages..."
mkdir -p nct_extracted
tar -xzf "$NCT_ARCHIVE" -C nct_extracted

# Find the .deb files (they're in a nested directory structure)
# Pattern: release-v*/packages/ubuntu18.04/amd64/*.deb
NCT_DEB_DIR=$(find nct_extracted -type d -name "amd64" | head -1)
if [ -z "$NCT_DEB_DIR" ]; then
    echo "ERROR: Could not find .deb files in toolkit archive" >&2
    exit 1
fi

# ============================================================
# 3. Assemble app.tgz
# ============================================================

echo "==> Building app.tgz..."
mkdir -p app_root/nvidia-container-toolkit

# Copy required toolkit .deb files (skip -dev, -dbg, -operator-extensions)
for deb in "$NCT_DEB_DIR"/libnvidia-container1_*.deb \
           "$NCT_DEB_DIR"/libnvidia-container-tools_*.deb \
           "$NCT_DEB_DIR"/nvidia-container-toolkit-base_*.deb \
           "$NCT_DEB_DIR"/nvidia-container-toolkit_1*.deb; do
    if [ -f "$deb" ]; then
        cp "$deb" app_root/nvidia-container-toolkit/
        echo "  Included: $(basename "$deb")"
    fi
done

# Copy ui/ directory
cp -a "apps/nvidia-driver/fnos/ui" app_root/ui

# Create app.tgz
cd app_root
tar -czf ../app.tgz .
cd ..

APP_SIZE=$(stat -f%z app.tgz 2>/dev/null || stat -c%s app.tgz 2>/dev/null)
echo "==> Built app.tgz: $(( APP_SIZE / 1048576 )) MB"

# Clean up
rm -rf app_root nct_extracted "$NCT_ARCHIVE"

echo "==> Done"
