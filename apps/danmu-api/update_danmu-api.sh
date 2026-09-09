#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
PKG_DIR="$SCRIPT_DIR/fnos"

APP_NAME="danmu-api"
APP_DISPLAY_NAME="Danmu API"
APP_VERSION_VAR="DANMU_API_VERSION"
APP_VERSION="${DANMU_API_VERSION:-latest}"
APP_DEPS=(curl jq)
APP_FPK_PREFIX="danmu-api"
APP_HELP_VERSION_EXAMPLE="1.20.7"

# Docker mode: the compose file is arch-agnostic; the upstream Docker Hub image
# logvar/danmu-api is multi-arch (amd64 + arm64). Nothing arch-specific to set.
app_set_arch_vars() {
    :
}

app_show_help_examples() {
    cat << EOF
  $0 --arch x86 1.20.7      # 指定版本，x86 架构
  $0 1.20.7                 # 指定版本，自动检测架构
EOF
}

app_get_latest_version() {
    info "获取最新版本信息..."

    if [ "$APP_VERSION" = "latest" ]; then
        # Upstream publishes runtime artefacts ONLY as Docker Hub tags; GitHub
        # has no releases and git tags lag behind. Image tags are plain semver
        # without a "v" prefix; exclude "latest" and "*-test".
        APP_VERSION=$(curl -sL "https://hub.docker.com/v2/repositories/logvar/danmu-api/tags?page_size=100" | \
            jq -r '.results[].name' | grep -E '^[0-9]+\.[0-9]+\.[0-9]+$' | sort -V | tail -1)
    fi

    [ -z "$APP_VERSION" ] && error "无法获取版本信息，请手动指定: $0 1.20.7"

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
    # Pin image tag. Canonical substitution form shared by all docker apps;
    # -i.bak works with both GNU sed (CI) and BSD sed (local macOS builds).
    sed -i.bak "s/\${VERSION}/${APP_VERSION}/g" "$dst/docker/docker-compose.yaml"
    rm -f "$dst/docker/docker-compose.yaml.bak"
    cp -a "$PKG_DIR/ui"/* "$dst/ui/" 2>/dev/null || true

    cd "$dst"
    tar -czf "$WORK_DIR/app.tgz" .
    info "app.tgz: $(du -h "$WORK_DIR/app.tgz" | cut -f1)"
}

source "$REPO_ROOT/scripts/lib/update-common.sh"
main_flow "$@"
