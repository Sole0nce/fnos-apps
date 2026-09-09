#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
PKG_DIR="$SCRIPT_DIR/fnos"

APP_NAME="surface-battery"
APP_DISPLAY_NAME="Surface 电池驱动"
APP_VERSION_VAR="SURFACE_BATTERY_VERSION"
APP_VERSION="${SURFACE_BATTERY_VERSION:-latest}"
APP_DEPS=(curl tar jq)
APP_FPK_PREFIX="surface-battery"
APP_HELP_VERSION_EXAMPLE="1.0.1"

app_set_arch_vars() {
    case "$ARCH" in
        x86) export TARBALL_ARCH="amd64" ;;
        arm) error "Surface 电池驱动仅支持 x86（Intel Surface 硬件）" ;;
    esac
}

app_show_help_examples() {
    cat << EOF
  $0 --arch x86 1.0.1       # 指定版本，仅 x86
  $0 --arch x86             # 最新版本，仅 x86
EOF
}

app_get_latest_version() {
    info "获取最新版本..."
    if [ "$APP_VERSION" = "latest" ]; then
        APP_VERSION=$(bash "$REPO_ROOT/scripts/apps/surface-battery/get-latest-version.sh" \
            | grep '^VERSION=' | cut -d= -f2)
    else
        APP_VERSION="${APP_VERSION#v}"
    fi
    [ -z "$APP_VERSION" ] && error "无法获取版本，请手动指定: $0 --arch x86 1.0.1"
    info "目标版本: $APP_VERSION"
}

app_download() {
    local url="https://github.com/xiowo/fnos_surface_battery_driver/archive/refs/tags/v${APP_VERSION}.tar.gz"
    mkdir -p "$WORK_DIR"
    info "下载上游 release tag 源码: $url"
    curl -fL --progress-bar -o "$WORK_DIR/source.tar.gz" "$url" || error "下载失败"
}

app_build_app_tgz() {
    local dst="$WORK_DIR/app_root"
    mkdir -p "$dst"
    info "提取并原样打包上游内容..."
    tar -xzf "$WORK_DIR/source.tar.gz" -C "$dst" --strip-components=1
    tar -czf "$WORK_DIR/app.tgz" -C "$dst" .
    info "app.tgz: $(du -h "$WORK_DIR/app.tgz" | cut -f1)"
}

source "$REPO_ROOT/scripts/lib/update-common.sh"
main_flow "$@"
