#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
PKG_DIR="$SCRIPT_DIR/fnos"

APP_NAME="picoclaw"
APP_DISPLAY_NAME="PicoClaw"
APP_VERSION_VAR="PICOCLAW_VERSION"
APP_VERSION="${PICOCLAW_VERSION:-latest}"
APP_DEPS=(curl tar)
APP_FPK_PREFIX="picoclaw"
APP_HELP_VERSION_EXAMPLE="0.2.3"

app_set_arch_vars() {
    case "$ARCH" in
        x86) ASSET_ARCH="x86_64" ;;
        arm) ASSET_ARCH="arm64" ;;
    esac
    info "Asset arch: $ASSET_ARCH"
}

app_show_help_examples() {
    cat << EOF
  $0 --arch x86 0.2.3       # 指定版本，x86 架构
  $0 0.2.3                  # 指定版本，自动检测架构
EOF
}

app_get_latest_version() {
    info "获取最新版本信息..."
    local tag
    tag=$(curl -sL "https://api.github.com/repos/sipeed/picoclaw/releases/latest" 2>/dev/null | \
        grep '"tag_name":' | sed -E 's/.*"v?([^"]+)".*/\1/')
    if [ "$APP_VERSION" = "latest" ]; then
        APP_VERSION="$tag"
    fi
    [ -z "$APP_VERSION" ] && error "无法获取版本信息，请手动指定: $0 0.2.3"
    info "目标版本: $APP_VERSION"
}

app_download() {
    local download_url="https://github.com/sipeed/picoclaw/releases/download/v${APP_VERSION}/picoclaw_Linux_${ASSET_ARCH}.tar.gz"
    info "下载 ($ARCH): $download_url"
    mkdir -p "$WORK_DIR"
    curl -L -f -o "$WORK_DIR/picoclaw.tar.gz" "$download_url" || error "下载失败"
    info "下载完成: $(du -h "$WORK_DIR/picoclaw.tar.gz" | cut -f1)"
}

app_build_app_tgz() {
    info "解压 picoclaw..."
    cd "$WORK_DIR"
    mkdir -p extracted
    tar -xzf picoclaw.tar.gz -C extracted

    info "构建 app.tgz..."
    local dst="$WORK_DIR/app_root"
    mkdir -p "$dst/bin" "$dst/ui" "$dst/config"

    local picoclaw_bin
    picoclaw_bin=$(find extracted -name "picoclaw" -type f ! -name "picoclaw-launcher*" | head -1)
    [ -z "$picoclaw_bin" ] && error "在 tarball 中找不到 picoclaw 二进制文件"

    cp "$picoclaw_bin" "$dst/picoclaw"
    chmod +x "$dst/picoclaw"

    cp "$PKG_DIR/bin/picoclaw-server" "$dst/bin/picoclaw-server"
    # 首启种子配置，缺了 gateway 会因为没有 model_list 直接退出
    cp "$PKG_DIR/config/picoclaw-config.json" "$dst/config/picoclaw-config.json"
    chmod +x "$dst/bin/picoclaw-server"
    cp -a "$PKG_DIR/ui"/* "$dst/ui/" 2>/dev/null || true

    cd "$dst"
    tar -czf "$WORK_DIR/app.tgz" .
    info "app.tgz: $(du -h "$WORK_DIR/app.tgz" | cut -f1)"
}

source "$REPO_ROOT/scripts/lib/update-common.sh"
main_flow "$@"
