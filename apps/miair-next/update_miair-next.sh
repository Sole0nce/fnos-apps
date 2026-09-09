#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
PKG_DIR="$SCRIPT_DIR/fnos"

APP_NAME="miair-next"
APP_DISPLAY_NAME="MiAir Next"
APP_VERSION_VAR="MIAIR_NEXT_VERSION"
APP_VERSION="${MIAIR_NEXT_VERSION:-latest}"
APP_DEPS=(curl tar jq)
APP_FPK_PREFIX="miair-next"
APP_HELP_VERSION_EXAMPLE="0.5.1"

app_set_arch_vars() {
    :
}

app_show_help_examples() {
    cat << EOF
  $0 --arch x86 0.5.1      # 指定版本，x86
  $0 --arch arm 0.5.1      # 指定版本，ARM
EOF
}

app_get_latest_version() {
    info "获取最新版本信息..."

    if [ "$APP_VERSION" = "latest" ]; then
        APP_VERSION=$(curl -fsSL "https://api.github.com/repos/deerwan/miair-next/releases/latest" | \
            jq -r '.tag_name')
    fi

    APP_VERSION="${APP_VERSION#v}"
    [ -z "$APP_VERSION" ] || [ "$APP_VERSION" = "null" ] && \
        error "无法获取版本信息，请手动指定: $0 0.5.1"
    info "目标版本: $APP_VERSION"
}

app_download() {
    mkdir -p "$WORK_DIR"
}

app_build_app_tgz() {
    info "构建 app.tgz (Docker)..."
    export VERSION="$APP_VERSION"
    bash "$REPO_ROOT/scripts/apps/miair-next/build.sh"
    cp "$REPO_ROOT/app.tgz" "$WORK_DIR/app.tgz"
    info "app.tgz: $(du -h "$WORK_DIR/app.tgz" | cut -f1)"
}

source "$REPO_ROOT/scripts/lib/update-common.sh"
main_flow "$@"
