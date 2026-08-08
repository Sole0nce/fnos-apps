#!/bin/bash
set -euo pipefail

# Repackages the upstream fnos-hermes-agent fpk published by veenyi/Fnos-Hermes-Studio.
#
# The upstream repo ships a complete, tested .fpk. We download their release
# fpk, extract the app.tgz (runtime payload), and let build-fpk.sh merge it
# with our fnos/ layer. The appname is suffixed with "-bbis" to avoid
# colliding with the upstream's stock "hermes-agent" appname, our own
# hermes-agent-native app, and the veenyi repackage.
#
# VERSION is the upstream release tag with the leading "v" stripped, e.g.
# "0.19.0-50". The fpk asset name is fnos-hermes-agent_v${VERSION}.fpk.

VERSION="${VERSION:-}"
[ -z "$VERSION" ] && { echo "VERSION is required" >&2; exit 1; }

UPSTREAM_REPO="veenyi/Fnos-Hermes-Studio"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

echo "==> Repackaging Hermes Studio ${VERSION} from upstream fpk"
# NOTE: on Windows/git-bash, curl.exe is a native binary and cannot write to
# MSYS virtual paths (/tmp, /d/...) — it errors with curl: (23). Use a real
# Windows path under the repo root. On Linux CI the same path is valid.
WORK_DIR_MSYS="$REPO_ROOT/.tmp-build-hermes-studio"
WORK_DIR_WIN=$(cygpath -m "$WORK_DIR_MSYS" 2>/dev/null || echo "$WORK_DIR_MSYS")
rm -rf "$WORK_DIR_MSYS"
mkdir -p "$WORK_DIR_MSYS"
trap "rm -rf $WORK_DIR_MSYS" EXIT
WORK_DIR="$WORK_DIR_MSYS"

# Upstream release tags are not consistent across repos (v0.21.92 vs
# fnos-hermes-agent_v0.21.92 vs v0.6.39-1), so never guess the URL — always
# resolve via the GitHub API, then download. Direct releases/download links are
# also routinely reset to 404 by GFW-style interference even when the asset
# exists (HEAD shows 302->200 but GET returns 404); the API asset endpoint
# (Accept: application/octet-stream) is NOT affected. Strategy:
#   1. GitHub API: resolve release by tag or latest, grab the fpk asset's
#      browser_download_url (direct) + api url (reliable)
#   2. try direct link, then API asset endpoint, then ghfast.top mirror
resolve_release() {
  local api_base="https://api.github.com/repos/${UPSTREAM_REPO}/releases"
  local json_file="$WORK_DIR_WIN/release.json"
  rm -f "$WORK_DIR_MSYS/release.json"
  curl -fsSL --retry 2 --connect-timeout 20 "$api_base/tags/v${VERSION}" -o "$json_file" 2>/dev/null || true
  # A 404 from GitHub writes '{"message":"Not Found"}' (non-empty) to the file,
  # which passes [ -s ] but has no assets. Validate before falling back.
  if ! grep -q '"assets"' "$WORK_DIR_MSYS/release.json" 2>/dev/null; then
    rm -f "$WORK_DIR_MSYS/release.json"
    curl -fsSL --retry 2 --connect-timeout 20 "$api_base/latest" -o "$json_file" 2>/dev/null || true
  fi
  grep -q '"assets"' "$WORK_DIR_MSYS/release.json" 2>/dev/null || { echo "ERROR: cannot resolve upstream release for v${VERSION}" >&2; exit 1; }
}

pick_asset() {
  local key="$1"
  local out=""
  # python3 on Windows often points to the Microsoft Store stub (WindowsApps)
  # which fails on -c; verify it actually runs, then fall back to python/jq.
  # Pick the LARGEST .fpk asset (upstreams sometimes ship a tiny trimmed
  # variant, e.g. iranee's *_.trimcli.fpk, which must be ignored).
  if command -v python3 >/dev/null 2>&1 && python3 -c 'pass' >/dev/null 2>&1; then
    out=$(python3 -c '
import json,sys
d=json.load(open(sys.argv[1]))
best=None
for x in d.get("assets",[]):
    n=x.get("name","")
    if n.endswith(".fpk") and ".trimcli" not in n:
        if best is None or x.get("size",0) > best.get("size",0):
            best=x
if best: print(best.get(sys.argv[2],""))
' "$WORK_DIR_WIN/release.json" "$key" 2>/dev/null || true)
  fi
  if [ -z "$out" ] && command -v python >/dev/null 2>&1 && python -c 'pass' >/dev/null 2>&1; then
    out=$(python -c '
import json,sys
d=json.load(open(sys.argv[1]))
best=None
for x in d.get("assets",[]):
    n=x.get("name","")
    if n.endswith(".fpk") and ".trimcli" not in n:
        if best is None or x.get("size",0) > best.get("size",0):
            best=x
if best: print(best.get(sys.argv[2],""))
' "$WORK_DIR_WIN/release.json" "$key" 2>/dev/null || true)
  fi
  if [ -z "$out" ] && command -v jq >/dev/null 2>&1; then
    out=$(jq -r '.assets[]? | select(.name|endswith(".fpk")) | select(.name|contains(".trimcli")|not) | .'"$key" "$WORK_DIR_WIN/release.json" 2>/dev/null | head -1 || true)
  fi
  echo "$out"
}

resolve_release
DIRECT_URL=$(pick_asset "browser_download_url")
API_URL=$(pick_asset "url")
echo "==> Resolved: ${DIRECT_URL:-<none>}"

fetch_upstream() {
  local out="$1"
  # 1. direct browser_download_url
  if [ -n "$DIRECT_URL" ] && curl -fsSL --retry 2 --connect-timeout 20 -o "$out" "$DIRECT_URL"; then
    return 0
  fi
  # 2. API asset endpoint
  if [ -n "$API_URL" ]; then
    echo "==> Direct link failed, trying GitHub API asset endpoint"
    if curl -fsSL --retry 3 --connect-timeout 20 -H "Accept: application/octet-stream" \
        -o "$out" "$API_URL"; then
      return 0
    fi
  fi
  # 3. mirror
  local mirror="https://ghfast.top/${DIRECT_URL:-}"
  echo "==> API asset failed, trying mirror: ${mirror}"
  curl -fsSL --retry 3 --connect-timeout 20 -o "$out" "$mirror"
}

fetch_upstream "$WORK_DIR_WIN/upstream.fpk"

ls -lh "$WORK_DIR_MSYS/upstream.fpk"

tar xzf "$WORK_DIR_MSYS/upstream.fpk" -C "$WORK_DIR_MSYS" app.tgz

[ -s "$WORK_DIR_MSYS/app.tgz" ] || { echo "ERROR: app.tgz missing/empty in upstream fpk" >&2; exit 1; }

cp "$WORK_DIR_MSYS/app.tgz" "$REPO_ROOT/app.tgz"
echo "==> Extracted app.tgz ($(du -h "$REPO_ROOT/app.tgz" | cut -f1)) to repo root"
