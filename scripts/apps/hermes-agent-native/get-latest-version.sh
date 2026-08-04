#!/bin/bash
set -euo pipefail

INPUT_VERSION="${1:-}"

VERSION=""
if [ -n "$INPUT_VERSION" ]; then
  # Manual override: user passes e.g. the release-tag date already stripped.
  VERSION="${INPUT_VERSION#v}"
else
  # Follow the latest official GitHub release tag (e.g. v2026.8.3) and use its
  # date as the fnOS package version (2026.8.3). We deliberately DO NOT track
  # PyPI: the GitHub release is the authoritative stable source and is typically
  # one release ahead of PyPI. Version == tag date keeps each tag unique, so the
  # daily cron builds exactly one fpk per new release (skips otherwise).
  TAG=$(curl -sL "https://api.github.com/repos/NousResearch/hermes-agent/releases/latest" \
    | grep -oE '"tag_name"[[:space:]]*:[[:space:]]*"[^"]+"' | head -1 \
    | sed -E 's/.*"([^"]+)"$/\1/' || true)
  # Fallback if the /releases/latest JSON is unexpected: list tags via ls-remote.
  if [ -z "$TAG" ]; then
    TAG=$(git ls-remote --tags --refs https://github.com/NousResearch/hermes-agent.git \
      | awk -F/ '{print $NF}' | sort -V | tail -1 || true)
  fi
  # Strip any leading 'v' so the version is a clean point-separated date.
  VERSION="${TAG#v}"
fi

[ -z "$VERSION" ] || [ "$VERSION" = "null" ] && { echo "Failed to resolve version for hermes-agent" >&2; exit 1; }

# Fail fast if the resolved version doesn't look like a point-separated date
# (upstream release tags are date-style, e.g. 2026.8.3). Guards against tag
# naming drift producing a broken fpk or a malformed git ref in build.sh.
if ! echo "$VERSION" | grep -qE '^[0-9]{4}\.[0-9]{1,2}\.[0-9]{1,2}$'; then
  echo "[ERROR] Resolved version '$VERSION' is not a date-style tag (e.g. 2026.8.3)" >&2
  exit 1
fi

echo "VERSION=$VERSION"

if [ -n "${GITHUB_OUTPUT:-}" ]; then
  echo "version=$VERSION" >> "$GITHUB_OUTPUT"
fi
