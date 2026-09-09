#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
PKG_DIR="$SCRIPT_DIR/fnos"

APP_NAME="cloudreve"
APP_DISPLAY_NAME="Cloudreve"
APP_VERSION_VAR="CLOUDREVE_VERSION"
APP_VERSION="${CLOUDREVE_VERSION:-latest}"
APP_DEPS=(curl tar unzip)
APP_FPK_PREFIX="cloudreve"
APP_HELP_VERSION_EXAMPLE="3.8.3"

app_set_arch_vars() {
    case "$ARCH" in
        x86) ZIP_ARCH="amd64" ;;
        arm) ZIP_ARCH="arm64" ;;
    esac
    info "Zip arch: $ZIP_ARCH"
}

app_show_help_examples() {
    cat << EOF
  $0 --arch x86 3.8.3       # 指定版本，x86 架构
  $0 3.8.3                  # 指定版本，自动检测架构
EOF
}

app_get_latest_version() {
    # 与 scripts/apps/cloudreve/get-latest-version.sh 保持一致，固定在 3.8.3
    # ——V3 的最后一个版本。Cloudreve V4 是不兼容的重写，自动升级会清空 V3
    # 用户的数据（issue #163）。此前这里取的是 releases/latest，本地构建会打出
    # 4.x 包，与 CI 的固定版本产生分叉。要有计划地升到 V4 请显式指定版本号。
    local pinned_version="3.8.3"

    if [ "$APP_VERSION" = "latest" ]; then
        APP_VERSION="$pinned_version"
        info "使用固定版本: $APP_VERSION（V4 需显式指定，详见 issue #163）"
    fi

    [ -z "$APP_VERSION" ] && error "无法获取版本信息，请手动指定: $0 3.8.3"

    info "目标版本: $APP_VERSION"
}

app_download() {
    local download_url="https://github.com/cloudreve/cloudreve/releases/download/${APP_VERSION}/cloudreve_${APP_VERSION}_linux_${ZIP_ARCH}.tar.gz"

    info "下载 ($ARCH): $download_url"
    mkdir -p "$WORK_DIR"
    curl -L -f -o "$WORK_DIR/cloudreve.tar.gz" "$download_url" || error "下载失败"
    info "下载完成: $(du -h "$WORK_DIR/cloudreve.tar.gz" | cut -f1)"
}

app_build_app_tgz() {
    info "解压 cloudreve..."
    cd "$WORK_DIR"
    tar -xzf cloudreve.tar.gz

    info "构建 app.tgz..."
    local dst="$WORK_DIR/app_root"
    mkdir -p "$dst/bin" "$dst/ui"

    local cloudreve_bin
    cloudreve_bin=$(find . -name "cloudreve" -type f | head -1)
    [ -z "$cloudreve_bin" ] && error "在 tar.gz 中找不到 cloudreve 二进制文件"

    cp "$cloudreve_bin" "$dst/cloudreve"
    chmod +x "$dst/cloudreve"

    cp "$PKG_DIR/bin/cloudreve-server" "$dst/bin/cloudreve-server"
    chmod +x "$dst/bin/cloudreve-server"
    cp -a "$PKG_DIR/ui"/* "$dst/ui/" 2>/dev/null || true

    cd "$dst"
    tar -czf "$WORK_DIR/app.tgz" .
    info "app.tgz: $(du -h "$WORK_DIR/app.tgz" | cut -f1)"
}

source "$REPO_ROOT/scripts/lib/update-common.sh"
main_flow "$@"
