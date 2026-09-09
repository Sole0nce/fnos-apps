#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
PKG_DIR="$SCRIPT_DIR/fnos"

APP_NAME="arcane"
APP_DISPLAY_NAME="Arcane"
APP_VERSION_VAR="ARCANE_VERSION"
APP_VERSION="${ARCANE_VERSION:-latest}"
APP_DEPS=(curl jq)
APP_FPK_PREFIX="arcane"
APP_HELP_VERSION_EXAMPLE="2.8.0"

app_set_arch_vars() {
    :
}

app_show_help_examples() {
    cat << 'HELP'
  $0 2.8.0                  # 指定版本
HELP
}

app_get_latest_version() {
    info "获取最新版本信息..."

    if [ "$APP_VERSION" = "latest" ]; then
        APP_VERSION=$(curl -sL "https://api.github.com/repos/getarcaneapp/arcane/releases/latest" | \
            jq -r '.tag_name' | sed -E 's/^v//')
    fi

    [ -z "$APP_VERSION" ] && error "无法获取版本信息，请手动指定: $0 2.8.0"
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
    bash "$REPO_ROOT/scripts/apps/arcane/build.sh"
    cp "$REPO_ROOT/app.tgz" "$WORK_DIR/app.tgz"
    info "app.tgz: $(du -h "$WORK_DIR/app.tgz" | cut -f1)"
}

source "$REPO_ROOT/scripts/lib/update-common.sh"
main_flow "$@"
