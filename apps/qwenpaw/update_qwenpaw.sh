#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
PKG_DIR="$SCRIPT_DIR/fnos"

APP_NAME="qwenpaw"
APP_DISPLAY_NAME="QwenPaw"
APP_VERSION_VAR="QWENPAW_VERSION"
APP_VERSION="${QWENPAW_VERSION:-latest}"
APP_DEPS=(curl)
APP_FPK_PREFIX="qwenpaw"
APP_HELP_VERSION_EXAMPLE="2.1.0"

app_set_arch_vars() {
    case "$ARCH" in
        x86) DOCKER_PLATFORM="linux/amd64" ;;
        arm) DOCKER_PLATFORM="linux/arm64" ;;
    esac
    info "Docker platform: $DOCKER_PLATFORM"
}

app_show_help_examples() {
    cat << EOF
  $0 --arch x86 2.1.0       # 指定版本，x86 架构
  $0 2.1.0                  # 指定版本，自动检测架构
EOF
}

app_get_latest_version() {
    info "获取最新版本信息..."

    local tag
    tag=$(curl -sL "https://api.github.com/repos/agentscope-ai/QwenPaw/releases/latest" 2>/dev/null | \
        grep '"tag_name":' | sed -E 's/.*"v?([^"]+)".*/\1/')

    if [ "$APP_VERSION" = "latest" ]; then
        APP_VERSION="$tag"
    fi

    [ -z "$APP_VERSION" ] && error "无法获取版本信息，请手动指定: $0 2.1.0"

    info "目标版本: $APP_VERSION"
}

app_download() {
    info "Docker 模式，无需下载二进制文件"
    mkdir -p "$WORK_DIR"
}

app_build_app_tgz() {
    info "构建 app.tgz (Docker 模式)..."
    cd "$WORK_DIR"
    local dst="$WORK_DIR/app_root"
    mkdir -p "$dst/docker" "$dst/ui"

    cp "$PKG_DIR/docker/docker-compose.yaml" "$dst/docker/"
    # Pin image tag: upstream Docker Hub tags carry a "v" prefix (e.g. v2.1.0)
    sed -i.tmp "s/\${VERSION}/${APP_VERSION}/g" "$dst/docker/docker-compose.yaml"
    rm -f "$dst/docker/docker-compose.yaml.tmp"
    cp -a "$PKG_DIR/ui"/* "$dst/ui/" 2>/dev/null || true

    cd "$dst"
    tar -czf "$WORK_DIR/app.tgz" .
    info "app.tgz: $(du -h "$WORK_DIR/app.tgz" | cut -f1)"
}

source "$REPO_ROOT/scripts/lib/update-common.sh"
main_flow "$@"
