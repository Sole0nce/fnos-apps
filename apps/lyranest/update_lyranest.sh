#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
PKG_DIR="$SCRIPT_DIR/fnos"

APP_NAME="lyranest"
APP_DISPLAY_NAME="LyraNest"
APP_VERSION_VAR="LYRANEST_VERSION"
APP_VERSION="${LYRANEST_VERSION:-latest}"
APP_DEPS=(curl jq)
APP_FPK_PREFIX="lyranest"
APP_HELP_VERSION_EXAMPLE="0.2.4"

# Docker mode: the compose file is arch-agnostic; the upstream GHCR image is
# multi-arch (amd64 + arm64). Nothing arch-specific to set here.
app_set_arch_vars() {
    :
}

app_show_help_examples() {
    cat << 'HELP'
  $0 0.2.4                  # 指定版本
HELP
}

app_get_latest_version() {
    info "获取最新版本信息..."

    if [ "$APP_VERSION" = "latest" ]; then
        # Upstream release tags carry a "v" prefix; the GHCR image tag does not.
        APP_VERSION=$(curl -sL "https://api.github.com/repos/WHWgogogo/LyraNest/releases/latest" | \
            jq -r '.tag_name' | sed -E 's/^v//')
    fi

    [ -z "$APP_VERSION" ] && error "无法获取版本信息，请手动指定: $0 0.2.4"
    info "目标版本: $APP_VERSION"
}

app_download() {
    :
}

app_build_app_tgz() {
    info "构建 app.tgz (Docker)..."
    mkdir -p "$WORK_DIR"
    export VERSION="$APP_VERSION"
    export VERSION="$APP_VERSION"
    bash "$REPO_ROOT/scripts/apps/lyranest/build.sh"
    cp "$REPO_ROOT/app.tgz" "$WORK_DIR/app.tgz"
    info "app.tgz: $(du -h "$WORK_DIR/app.tgz" | cut -f1)"
}

source "$REPO_ROOT/scripts/lib/update-common.sh"
main_flow "$@"
