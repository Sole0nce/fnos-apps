#!/bin/bash
# End-to-end regression test for the hermes-agent fnOS package.
#
# Runs against a real fnOS NAS via SSH. Prereqs:
#   - NAS reachable as $NAS_HOST (default 192.168.0.3), passwordless sudo
#   - The package has been extracted to /tmp/hagent-test/app (see steps below)
#
# Usage:  bash test.sh [NAS_HOST]
# Steps it covers:
#   1. install_callback: unpack runtime.tgz + seed config.yaml/.env/workspace
#   2. main start: wrapper spawns dashboard, creates Unix socket
#   3. socket gateway: 502 fallback while dashboard cold-starts
#   4. browser flow: GET / -> extract __HERMES_SESSION_TOKEN__ -> /api/status 200
#   5. main stop: clean shutdown

set -euo pipefail
NAS_HOST="${1:-192.168.0.3}"
SSH="ssh admin@${NAS_HOST}"
SUDO_SSH="ssh admin@${NAS_HOST} sudo"

echo "==> NAS=${NAS_HOST}"
${SSH} "test -d /tmp/hagent-test/app && echo 'test dir ok' || { echo 'missing /tmp/hagent-test/app - build & extract first'; exit 1; }"

# Point mock runtime at the real hermes venv if present (best-effort)
${SUDO_SSH} "bash -c '
REAL_VENV=/var/apps/hermes-agent/home/data/venv
MOCK_RT=/tmp/hagent-test/app/runtime/python
if [ -x \${REAL_VENV}/bin/hermes ]; then
  ln -sf \${REAL_VENV}/bin/python3 \${MOCK_RT}/bin/python3
  ln -sf \${REAL_VENV}/bin/hermes \${MOCK_RT}/bin/hermes
  echo \"using real venv: \${REAL_VENV}\"
fi
'"

${SUDO_SSH} "bash -c '
set -x
export TRIM_APPNAME=hermes-agent
export TRIM_APPDEST=/tmp/hagent-test/app
export TRIM_PKGVAR=/tmp/hagent-test/data
export TRIM_PKGETC=/tmp/hagent-test/etc
export TRIM_PKGHOME=/tmp/hagent-test/home
export TRIM_RUN_USERNAME=root
export TRIM_RUN_GROUPNAME=root
export TRIM_APP_STATUS=INSTALL
chmod +x /tmp/hagent-test/cmd/*

echo \"=== 1. install_callback ===\"
/tmp/hagent-test/cmd/install_callback
test -f /tmp/hagent-test/data/hermes/config.yaml && echo \"config.yaml seeded\"
test -f /tmp/hagent-test/app/runtime/BUILD-INFO.json && echo \"runtime unpacked\"

echo \"=== 2. start ===\"
/tmp/hagent-test/cmd/main start
sleep 2
test -S /tmp/hagent-test/app/run/hermes-agent.sock && echo \"socket created\"
/tmp/hagent-test/cmd/main status

echo \"=== 3. socket 502 fallback (cold start) ===\"
curl -s --unix-socket /tmp/hagent-test/app/run/hermes-agent.sock http://localhost/ -o /dev/null -w \"http=%{http_code}\\n\" --max-time 3 || echo \"(dashboard may be up already)\"

echo \"=== 4. browser flow ===\"
sleep 8
curl -s --unix-socket /tmp/hagent-test/app/run/hermes-agent.sock http://localhost/ -o /tmp/dash-index.html --max-time 10
TOKEN=\$(grep -o '\''__HERMES_SESSION_TOKEN__=\"[^\"]*\"'\'' /tmp/dash-index.html | head -1 | sed '\''s/.*\"\\(.*\\)\"/\\1/'\'')
echo \"token_len=\${#TOKEN}\"
grep -o \"__HERMES_AUTH_REQUIRED__=[a-z]*\" /tmp/dash-index.html | head -1
curl -s --unix-socket /tmp/hagent-test/app/run/hermes-agent.sock http://localhost/api/status -H \"X-Hermes-Session-Token: \${TOKEN}\" --max-time 10 | head -c 200; echo

echo \"=== 5. stop ===\"
/tmp/hagent-test/cmd/main stop
/tmp/hagent-test/cmd/main status
'" 2>&1

echo "==> done"
