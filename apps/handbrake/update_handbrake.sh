#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
PKG_DIR="$SCRIPT_DIR/fnos"

APP_NAME="handbrake"
APP_DISPLAY_NAME="HandBrake"
APP_VERSION_VAR="HANDBRAKE_VERSION"
APP_VERSION="${HANDBRAKE_VERSION:-latest}"
APP_DEPS=(curl jq)
APP_FPK_PREFIX="handbrake"
APP_HELP_VERSION_EXAMPLE="26.07.2"

app_set_arch_vars() {
    case "$ARCH" in
        arm)
            error "jlesage/handbrake 上游镜像当前仅发布 amd64 manifest，本应用不构建 arm 包。"
            ;;
    esac
}

app_show_help_examples() {
    cat << 'HELP'
  $0 26.07.2               # 指定版本
HELP
}

app_get_latest_version() {
    info "获取最新版本信息..."

    if [ "$APP_VERSION" = "latest" ]; then
        APP_VERSION=$(curl -sL "https://api.github.com/repos/jlesage/docker-handbrake/releases/latest" | \
            jq -r '.tag_name' | sed -E 's/^v//')
    fi

    [ -z "$APP_VERSION" ] && error "无法获取版本信息，请手动指定: $0 26.07.2"
    info "目标版本: $APP_VERSION"
}

app_download() {
    :
}

app_build_app_tgz() {
    info "构建 app.tgz (Docker)..."
    export VERSION="$APP_VERSION"
    bash "$REPO_ROOT/scripts/apps/handbrake/build.sh"
    cp "$REPO_ROOT/app.tgz" "$WORK_DIR/app.tgz"
    info "app.tgz: $(du -h "$WORK_DIR/app.tgz" | cut -f1)"
}

source "$REPO_ROOT/scripts/lib/update-common.sh"
main_flow "$@"
