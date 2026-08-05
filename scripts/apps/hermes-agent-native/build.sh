#!/bin/bash
set -euo pipefail

# Builds the hermes-agent fnOS package:
#   - prebuilt Python venv (hermes-agent[all] @ git tag) + Node runtime
#   - Python wrapper (Unix socket gateway + dashboard supervisor)
#   - ui/config + desktop icons
# Produces app.tgz at the repo root for build-fpk.sh.
#
# Runtime layout mirrors trim.hermes (DavidChen) 0.18.x so the install
# path is zero-network: install_callback only unpacks runtime.tgz.
#
# VERSION is the point-separated date of the upstream release tag, e.g.
# "2026.8.3"; the git tag referenced is "v${VERSION}". We install from the
# tagged commit (stable) rather than a PyPI wheel, so the fnOS build tracks
# the latest official GitHub release, ahead of PyPI.

VERSION="${VERSION:-}"
[ -z "$VERSION" ] && { echo "VERSION is required" >&2; exit 1; }

NODE_VERSION="${NODE_VERSION:-v22.22.3}"
PYTHON_VER="${PYTHON_VER:-3.11}"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
APP_FNOS_DIR="$REPO_ROOT/apps/hermes-agent-native/fnos"

echo "==> Building hermes-agent ${VERSION} (node ${NODE_VERSION}, python ${PYTHON_VER})"

WORK_DIR=$(mktemp -d)
trap "rm -rf $WORK_DIR" EXIT

mkdir -p "$WORK_DIR/app/wrapper" "$WORK_DIR/app/run" "$WORK_DIR/runtime"

# ---------- 1. Python runtime: python-build-standalone (relocatable) ----------
# NOTE: do NOT use `uv venv` -- a venv's bin/python is an absolute symlink
# into the CI machine (~/.local/share/uv/python/...) which does not exist on
# the NAS. Instead we copy the whole python-build-standalone dist (the same
# artifact uv caches): bin/python3.11 is a relocatable shim, python3.11.real
# is the ELF, lib/ + system-libs/ are bundled. Mirrors trim.hermes layout.
if ! command -v uv >/dev/null 2>&1; then
  echo "==> Installing uv"
  curl -LsSf https://astral.sh/uv/install.sh | sh
  export PATH="$HOME/.local/bin:$PATH"
fi

uv python install "${PYTHON_VER}"
UV_PY_BIN="$(uv python find "${PYTHON_VER}")"
UV_PY_DIR="$(cd "$(dirname "$(dirname "$UV_PY_BIN")")" && pwd)"
# uv keeps a versionless alias symlink (cpython-3.11-linux-x86_64-gnu ->
# cpython-3.11.15-...): resolve it so we copy real content, not the link.
UV_PY_DIR_REAL="$(readlink -f "$UV_PY_DIR")"
echo "==> python-build-standalone: $UV_PY_DIR_REAL"

# Install into the ORIGINAL standalone path FIRST -- uv caches interpreter
# metadata keyed on the canonical path; installing after `cp` makes uv resolve
# scripts/bin against the CI machine path and fail with path traversal errors.
# Install from the official tagged release (stable), not PyPI. HERMES_NIX_BUILD=1
# is the upstream-sanctioned escape hatch: setup.py blocks PEP 517 wheel builds
# unless this env var is set (their own Nix packaging uses it), so uv can build
# a wheel from the git tag.
HERMES_NIX_BUILD=1 uv pip install --break-system-packages --python "$UV_PY_BIN" \
  "hermes-agent[all] @ git+https://github.com/NousResearch/hermes-agent@v${VERSION}"

# Then copy the whole (already-populated) standalone into the package.
cp -aL "$UV_PY_DIR_REAL" "$WORK_DIR/runtime/python"

# Rewrite bin/* console scripts (pip embeds CI-machine shebangs) into
# relocatable sh wrappers, trim.hermes style.
python3 "$SCRIPT_DIR/rewrite-console-scripts.py" "$WORK_DIR/runtime/python"

# Ensure python3/python symlinks exist (cmd/config resolves python3)
cd "$WORK_DIR/runtime/python/bin"
[ -e python3 ] || ln -s python3.11 python3
[ -e python ] || ln -s python3 python

PY_ACTUAL=$("$WORK_DIR/runtime/python/bin/python3.11" -c "import sys; print('.'.join(map(str, sys.version_info[:3])))")

# ---------- 2. Node runtime (bundled next to the venv) ----------
echo "==> Downloading node ${NODE_VERSION}"
curl -fsSL --retry 3 "https://nodejs.org/dist/${NODE_VERSION}/node-${NODE_VERSION}-linux-x64.tar.xz" \
  | tar -xJ -C "$WORK_DIR"
mv "$WORK_DIR/node-${NODE_VERSION}-linux-x64" "$WORK_DIR/runtime/python/node"

# ---------- 2b. Build the web frontend into the venv ----------
# The upstream wheel intentionally ships WITHOUT web_dist (setup.py: assets
# resolved at runtime; see hermes_cli/web_server.py WEB_DIST). The shell
# installer/Docker build the SPA separately; we must do the same or the
# dashboard answers {"error":"Frontend not built..."}. vite.config.ts emits
# to ../hermes_cli/web_dist, exactly where web_server.py looks by default
# (Path(__file__).parent / "web_dist"), so building the tagged source and
# copying that directory into site-packages is all that's needed.
echo "==> Building web frontend (v${VERSION})"
FRONTEND_SRC="$WORK_DIR/hermes-agent"
git clone --depth 1 --branch "v${VERSION}" \
  https://github.com/NousResearch/hermes-agent.git "$FRONTEND_SRC"
(cd "$FRONTEND_SRC/web" && \
  "$WORK_DIR/runtime/python/node/bin/npm" ci --no-audit --no-fund && \
  "$WORK_DIR/runtime/python/node/bin/npm" run build)
SITE_PACKAGES="$WORK_DIR/runtime/python/lib/python3.11/site-packages"
if [ -d "$FRONTEND_SRC/hermes_cli/web_dist" ]; then
  cp -a "$FRONTEND_SRC/hermes_cli/web_dist" "$SITE_PACKAGES/hermes_cli/"
  echo "==> web_dist copied to $SITE_PACKAGES/hermes_cli/web_dist"
else
  echo "ERROR: web frontend build produced no hermes_cli/web_dist" >&2
  exit 1
fi

# ---------- 3. BUILD-INFO.json ----------
cat > "$WORK_DIR/runtime/BUILD-INFO.json" <<EOF
{
  "name": "hermes-agent-native",
  "version": "${VERSION}",
  "built_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "source": "git+https://github.com/NousResearch/hermes-agent@v${VERSION}",
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
echo "Built app.tgz for hermes-agent-native ${VERSION}"
ls -lh "$REPO_ROOT/app.tgz"
