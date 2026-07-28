#!/bin/bash
set -euo pipefail

# Hermes uses rolling :latest Docker tag — use date-based version
# so the daily cron builds one fpk per day (skips if already built today)
VERSION=$(date +'%Y.%-m.%-d')

echo "VERSION=$VERSION"

if [ -n "${GITHUB_OUTPUT:-}" ]; then
  echo "version=$VERSION" >> "$GITHUB_OUTPUT"
fi
