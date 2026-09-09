#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
PKG_DIR="$SCRIPT_DIR/fnos"

APP_NAME="prometheus"
APP_DISPLAY_NAME="Prometheus"
APP_VERSION_VAR="PROMETHEUS_VERSION"
APP_VERSION="${PROMETHEUS_VERSION:-latest}"
APP_DEPS=(curl tar)
APP_FPK_PREFIX="prometheus"
APP_HELP_VERSION_EXAMPLE="2.54.1"

app_set_arch_vars() {
    case "$ARCH" in
        x86) ZIP_ARCH="amd64" ;;
        arm) ZIP_ARCH="arm64" ;;
    esac
    info "Zip arch: $ZIP_ARCH"
}

app_show_help_examples() {
    cat << EOF
  $0 --arch x86 2.54.1       # 指定版本，x86 架构
  $0 2.54.1                  # 指定版本，自动检测架构
EOF
}

app_get_latest_version() {
    info "获取最新版本信息..."

    local tag
    tag=$(curl -sL "https://api.github.com/repos/prometheus/prometheus/releases/latest" 2>/dev/null | \
        grep '"tag_name":' | sed -E 's/.*"v?([^"]+)".*/\1/')

    if [ "$APP_VERSION" = "latest" ]; then
        APP_VERSION="$tag"
    fi

    [ -z "$APP_VERSION" ] && error "无法获取版本信息，请手动指定: $0 2.54.1"

    info "目标版本: $APP_VERSION"
}

app_download() {
    local download_url="https://github.com/prometheus/prometheus/releases/download/v${APP_VERSION}/prometheus-${APP_VERSION}.linux-${ZIP_ARCH}.tar.gz"

    info "下载 ($ARCH): $download_url"
    mkdir -p "$WORK_DIR"
    curl -L -f -o "$WORK_DIR/prometheus.tar.gz" "$download_url" || error "下载失败"
    info "下载完成: $(du -h "$WORK_DIR/prometheus.tar.gz" | cut -f1)"
}

app_build_app_tgz() {
    info "解压 prometheus..."
    cd "$WORK_DIR"
    tar -xzf prometheus.tar.gz

    info "构建 app.tgz..."
    local dst="$WORK_DIR/app_root"
    mkdir -p "$dst/bin" "$dst/ui" "$dst/config"

    local prometheus_bin
    prometheus_bin=$(find . -path "*/prometheus-${APP_VERSION}.linux-${ZIP_ARCH}/prometheus" -type f | head -1)
    [ -z "$prometheus_bin" ] && error "在 tar.gz 中找不到 prometheus 二进制文件"

    cp "$prometheus_bin" "$dst/prometheus"
    chmod +x "$dst/prometheus"

    # 上游 tar.gz 自带默认 prometheus.yml，随包投放作为首启配置
    local prometheus_conf
    prometheus_conf=$(find . -path "*/prometheus-${APP_VERSION}.linux-${ZIP_ARCH}/prometheus.yml" -type f | head -1)
    [ -z "$prometheus_conf" ] && error "在 tar.gz 中找不到 prometheus.yml"
    cp "$prometheus_conf" "$dst/config/prometheus.yml"

    cp "$PKG_DIR/bin/prometheus-server" "$dst/bin/prometheus-server"
    chmod +x "$dst/bin/prometheus-server"
    cp -a "$PKG_DIR/ui"/* "$dst/ui/" 2>/dev/null || true

    cd "$dst"
    tar -czf "$WORK_DIR/app.tgz" .
    info "app.tgz: $(du -h "$WORK_DIR/app.tgz" | cut -f1)"
}

source "$REPO_ROOT/scripts/lib/update-common.sh"
main_flow "$@"
