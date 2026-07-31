#!/bin/bash
set -euo pipefail

INPUT_VERSION="${1:-}"

if [ -n "$INPUT_VERSION" ]; then
  VERSION="$INPUT_VERSION"
else
  # Hermes Agent publishes to PyPI as hermes-agent; the fnOS package version
  # tracks the PyPI release directly (same scheme as trim.hermes).
  PY_BIN="python3"
  if ! python3 -c 'import json' >/dev/null 2>&1; then
    PY_BIN="python"
  fi
  VERSION=$(curl -sL "https://pypi.org/pypi/hermes-agent/json" | "${PY_BIN}" -c "import json,sys; print(json.load(sys.stdin)['info']['version'])")
fi

[ -z "$VERSION" ] || [ "$VERSION" = "null" ] && { echo "Failed to resolve version for hermes-agent" >&2; exit 1; }

echo "VERSION=$VERSION"

if [ -n "${GITHUB_OUTPUT:-}" ]; then
  echo "version=$VERSION" >> "$GITHUB_OUTPUT"
fi
