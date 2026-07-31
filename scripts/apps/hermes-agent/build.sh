#!/bin/bash
set -euo pipefail

# Builds the hermes-agent fnOS package:
#   - prebuilt Python venv (hermes-agent[all]==$VERSION) + Node runtime
#   - Python wrapper (Unix socket gateway + dashboard supervisor)
#   - ui/config + desktop icons
# Produces app.tgz at the repo root for build-fpk.sh.
#
# Runtime layout mirrors trim.hermes (DavidChen) 0.18.x so the install
# path is zero-network: install_callback only unpacks runtime.tgz.

VERSION="${VERSION:-}"
[ -z "$VERSION" ] && { echo "VERSION is required" >&2; exit 1; }

NODE_VERSION="${NODE_VERSION:-v22.22.3}"
PYTHON_VER="${PYTHON_VER:-3.11}"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
APP_FNOS_DIR="$REPO_ROOT/apps/hermes-agent/fnos"

echo "==> Building hermes-agent ${VERSION} (node ${NODE_VERSION}, python ${PYTHON_VER})"

WORK_DIR=$(mktemp -d)
trap "rm -rf $WORK_DIR" EXIT

mkdir -p "$WORK_DIR/app/wrapper" "$WORK_DIR/app/run"

# ---------- 1. Python venv with hermes-agent[all] ----------
if ! command -v uv >/dev/null 2>&1; then
  echo "==> Installing uv"
  curl -LsSf https://astral.sh/uv/install.sh | sh
  export PATH="$HOME/.local/bin:$PATH"
fi

uv venv --python "${PYTHON_VER}" "$WORK_DIR/runtime/python"
uv pip install --python "$WORK_DIR/runtime/python/bin/python" \
  "hermes-agent[all]==${VERSION}"

PY_ACTUAL=$("$WORK_DIR/runtime/python/bin/python" -c "import sys; print('.'.join(map(str, sys.version_info[:3])))")

# ---------- 2. Node runtime (bundled next to the venv) ----------
echo "==> Downloading node ${NODE_VERSION}"
curl -fsSL --retry 3 "https://nodejs.org/dist/${NODE_VERSION}/node-${NODE_VERSION}-linux-x64.tar.xz" \
  | tar -xJ -C "$WORK_DIR"
mv "$WORK_DIR/node-${NODE_VERSION}-linux-x64" "$WORK_DIR/runtime/python/node"

# ---------- 3. BUILD-INFO.json ----------
cat > "$WORK_DIR/runtime/BUILD-INFO.json" <<EOF
{
  "name": "hermes-agent",
  "version": "${VERSION}",
  "built_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "source": "https://pypi.org/project/hermes-agent",
  "python": "${PY_ACTUAL}",
  "node": "${NODE_VERSION}",
  "extras": "all",
  "builder": "uv",
  "install": "zero-network (runtime prebuilt in CI)"
}
EOF

# ---------- 4. runtime.tgz (top-level dir must be runtime/) ----------
tar -czf "$WORK_DIR/app/runtime.tgz" -C "$WORK_DIR" runtime
ls -lh "$WORK_DIR/app/runtime.tgz"

# ---------- 5. wrapper + ui + run seed dir ----------
cp "$APP_FNOS_DIR/app/wrapper/hermes_wrapper.py" "$WORK_DIR/app/wrapper/"
cp -a "$APP_FNOS_DIR/ui" "$WORK_DIR/app/ui"
touch "$WORK_DIR/app/run/.keep"

# ---------- 6. app.tgz ----------
cd "$WORK_DIR/app"
tar -czf "$REPO_ROOT/app.tgz" .
echo "Built app.tgz for hermes-agent ${VERSION}"
ls -lh "$REPO_ROOT/app.tgz"
