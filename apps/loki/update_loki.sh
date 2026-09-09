#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
PKG_DIR="$SCRIPT_DIR/fnos"

APP_NAME="loki"
APP_DISPLAY_NAME="Loki"
APP_VERSION_VAR="LOKI_VERSION"
APP_VERSION="${LOKI_VERSION:-latest}"
APP_DEPS=(curl tar unzip)
APP_FPK_PREFIX="loki"
APP_HELP_VERSION_EXAMPLE="3.2.0"

app_set_arch_vars() {
    case "$ARCH" in
        x86) ZIP_ARCH="amd64" ;;
        arm) ZIP_ARCH="arm64" ;;
    esac
    info "Zip arch: $ZIP_ARCH"
}

app_show_help_examples() {
    cat << EOF
  $0 --arch x86 3.2.0       # 指定版本，x86 架构
  $0 3.2.0                  # 指定版本，自动检测架构
EOF
}

app_get_latest_version() {
    info "获取最新版本信息..."

    local tag
    tag=$(curl -sL "https://api.github.com/repos/grafana/loki/releases/latest" 2>/dev/null | \
        grep '"tag_name":' | sed -E 's/.*"v?([^"]+)".*/\1/')

    if [ "$APP_VERSION" = "latest" ]; then
        APP_VERSION="$tag"
    fi

    [ -z "$APP_VERSION" ] && error "无法获取版本信息，请手动指定: $0 3.2.0"

    info "目标版本: $APP_VERSION"
}

app_download() {
    local download_url="https://github.com/grafana/loki/releases/download/v${APP_VERSION}/loki-linux-${ZIP_ARCH}.zip"

    info "下载 ($ARCH): $download_url"
    mkdir -p "$WORK_DIR"
    curl -L -f -o "$WORK_DIR/loki.zip" "$download_url" || error "下载失败"
    info "下载完成: $(du -h "$WORK_DIR/loki.zip" | cut -f1)"
}

app_build_app_tgz() {
    info "解压 loki..."
    cd "$WORK_DIR"
    unzip -o loki.zip

    info "构建 app.tgz..."
    local dst="$WORK_DIR/app_root"
    mkdir -p "$dst/bin" "$dst/ui" "$dst/config"

    local loki_bin="$WORK_DIR/loki-linux-${ZIP_ARCH}"
    [ ! -f "$loki_bin" ] && error "在 zip 中找不到 loki-linux-${ZIP_ARCH} 二进制文件"

    cp "$loki_bin" "$dst/loki"
    chmod +x "$dst/loki"

    cp "$PKG_DIR/bin/loki-server" "$dst/bin/loki-server"
    chmod +x "$dst/bin/loki-server"
    # 上游 zip 只有二进制，需要随包投放默认配置，否则首启必挂
    cp "$PKG_DIR/config/loki-config.yaml" "$dst/config/loki-config.yaml"
    cp -a "$PKG_DIR/ui"/* "$dst/ui/" 2>/dev/null || true

    cd "$dst"
    tar -czf "$WORK_DIR/app.tgz" .
    info "app.tgz: $(du -h "$WORK_DIR/app.tgz" | cut -f1)"
}

source "$REPO_ROOT/scripts/lib/update-common.sh"
main_flow "$@"
