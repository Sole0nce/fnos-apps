#!/bin/bash
set -euo pipefail

#
# get-latest-version.sh for nvidia-driver
#
# Resolves the latest nvidia-container-toolkit release.
#
# The package version tracks nvidia-container-toolkit, NOT the NVIDIA driver.
# The driver version is a runtime property of the user's fnOS image: fnOS ships
# prebuilt nvidia*.ko under /usr/lib/modules_trim/<kver>/nvidia-gpu-*/ and the
# matching userspace is resolved on the device by cmd/service-setup. Pinning a
# driver version at build time is exactly what made the GPU vanish after an
# fnOS system update.
#

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/meta.env"

INPUT_VERSION="${1:-}"

# Hardcoded fallback — used when the GitHub API is unreachable
FALLBACK_VERSION="${NCT_FALLBACK_VERSION:-1.17.8}"

toolkit_asset_exists() {
    local v="$1" status
    status=$(curl -sIL -o /dev/null -w "%{http_code}" --connect-timeout 10 --max-time 20 \
        "https://github.com/NVIDIA/nvidia-container-toolkit/releases/download/v${v}/nvidia-container-toolkit_${v}_deb_amd64.tar.gz" 2>/dev/null) || true
    [ "$status" = "200" ]
}

resolve_latest_toolkit() {
    local version=""

    version=$(curl -sL --connect-timeout 10 --max-time 30 \
        -H "Accept: application/vnd.github+json" \
        "https://api.github.com/repos/NVIDIA/nvidia-container-toolkit/releases/latest" 2>/dev/null \
        | grep -oE '"tag_name"[[:space:]]*:[[:space:]]*"v?[0-9]+\.[0-9]+\.[0-9]+"' \
        | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' \
        | head -1) || true

    if [ -n "$version" ] && toolkit_asset_exists "$version"; then
        echo "$version"
        return 0
    fi

    # Fall back to the pinned version regardless of reachability so CI still
    # produces a deterministic build when GitHub is throttling us.
    echo "$FALLBACK_VERSION"
}

if [ -n "$INPUT_VERSION" ]; then
    VERSION="$INPUT_VERSION"
else
    VERSION=$(resolve_latest_toolkit)
fi

[ -z "$VERSION" ] && { echo "Failed to resolve nvidia-container-toolkit version" >&2; exit 1; }

echo "VERSION=$VERSION"

if [ -n "${GITHUB_OUTPUT:-}" ]; then
    echo "version=$VERSION" >> "$GITHUB_OUTPUT"
fi
