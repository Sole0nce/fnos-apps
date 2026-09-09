#!/bin/bash
# Behavioural test for the PATH guarantee in shared/cmd/common.
#
# Root cause of GitHub issue #268:
#   FileBrowser installed fine but died the instant it was started —
#   `Error: exec: "getent": executable file not found in $PATH`
# /usr/bin/getent was present the whole time. fnOS starts app lifecycle scripts
# with a curated TRIM_* environment that contains NO PATH, and bash papers over
# that by substituting a compiled-in default for its OWN command lookups without
# ever exporting it. So the shell scripts kept working while every process they
# spawned inherited an environment with PATH unset — and any app that shells out
# (Go's exec.LookPath, python subprocess, JVM ProcessBuilder, ffmpeg probes)
# failed to find binaries that were sitting in /usr/bin all along.
#
# Expected behaviour under test:
#   path_reaches_daemon  — a daemon started by start_daemon() must find PATH in
#                          its own environment, not just in the launching shell
#   path_is_usable       — that PATH must actually resolve real binaries
#                          (getent is the one that broke filebrowser)
#   path_excludes_cwd    — `.` must NOT be exported: SVC_CWD is the app's
#                          user-writable data dir, so a `.` entry would let an
#                          uploaded file hijack a daemon's command lookup
#
# Usage:
#   scripts/test/test-path-export.sh
#
# Exits 0 on all-pass, 1 on any failure.
#
# NOTE: deliberately NO `set -e` / `set -u` (same reasoning as
# test-start-readiness.sh): shared/cmd/common references optionally-set vars.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./lib.sh
source "$SCRIPT_DIR/lib.sh"

COMMON="$(repo_root)/shared/cmd/common"
[ -f "$COMMON" ] || error "shared/cmd/common not found at $COMMON"

# ---------------------------------------------------------------------------
# Harness
# ---------------------------------------------------------------------------

# run_daemon_env_capture — reproduce the production launch condition and report
# what the daemon actually inherited.
#
# `env -u PATH bash` is exactly what fnOS's dsmgr does to our scripts: bash comes
# up with PATH absent from its environment. Inside it we source shared/cmd/common
# and let start_daemon() spawn a daemon that dumps its own environment with
# `env` — env prints the real inherited environment, so a missing PATH= line
# means the daemon was launched without one.
#
# Prints the daemon's PATH value, or the literal string UNSET.
run_daemon_env_capture() {
    local sandbox="$1"

    cat > "$sandbox/daemon.sh" <<EOF
#!/bin/sh
env > "$sandbox/daemon.env"
exec sleep 300
EOF
    chmod +x "$sandbox/daemon.sh"

    env -u PATH bash <<EOF >/dev/null 2>&1
# common's source-time guard only accepts /vol* or /usr/local/apps/@appdata/*.
TRIM_APPNAME="testpathexport"
TRIM_APPDEST="$sandbox"
TRIM_PKGVAR="/vol1/@appdata/testpathexport"
. "$COMMON"
# Re-point every runtime path at the sandbox.
TRIM_PKGVAR="$sandbox"
LOG_FILE="$sandbox/app.log"
PID_FILE="$sandbox/app.pid"
OUT="\$LOG_FILE"
SVC_CWD="$sandbox"
SVC_QUIET=y
SVC_BACKGROUND=y
SVC_WRITE_PID=y
SERVICE_COMMAND="$sandbox/daemon.sh"
start_daemon
EOF

    # start_daemon's readiness gate already waited for the daemon, but the env
    # dump races the exec by a hair on a loaded box.
    local i=0
    while [ ! -s "$sandbox/daemon.env" ] && [ "$i" -lt 10 ]; do
        sleep 1
        i=$((i + 1))
    done

    if grep -q '^PATH=' "$sandbox/daemon.env" 2>/dev/null; then
        grep '^PATH=' "$sandbox/daemon.env" | head -1 | cut -d= -f2-
    else
        echo "UNSET"
    fi
}

SANDBOX="$(mktemp -d /tmp/fnos-path-export.XXXXXX)"
cleanup() {
    if [ -f "$SANDBOX/app.pid" ]; then
        for _p in $(cat "$SANDBOX/app.pid" 2>/dev/null); do
            kill "$_p" 2>/dev/null
        done
    fi
    rm -rf "$SANDBOX"
}
trap cleanup EXIT

note "── path_reaches_daemon ──"
note "Launching start_daemon() from a bash with PATH absent from its environment (what fnOS does)"
DAEMON_PATH="$(run_daemon_env_capture "$SANDBOX")"
info "daemon inherited PATH=[$DAEMON_PATH]"

if [ "$DAEMON_PATH" != "UNSET" ] && [ -n "$DAEMON_PATH" ]; then
    pass "path_reaches_daemon: daemon environment carries PATH"
else
    fail "path_reaches_daemon: daemon was started with no PATH in its environment — anything it shells out to fails with 'executable file not found in \$PATH' (issue #268)"
fi

note "── path_is_usable ──"
note "The inherited PATH must resolve the binaries apps actually call (getent broke filebrowser)"
if [ "$DAEMON_PATH" = "UNSET" ]; then
    fail "path_is_usable: no PATH to check (see path_reaches_daemon)"
else
    _missing=""
    for _dir in /usr/bin /bin /usr/sbin /sbin; do
        case ":${DAEMON_PATH}:" in
            *":${_dir}:"*) ;;
            *) _missing="${_missing} ${_dir}" ;;
        esac
    done
    if [ -z "$_missing" ]; then
        pass "path_is_usable: PATH covers the standard system dirs (/usr/bin /bin /usr/sbin /sbin)"
    else
        fail "path_is_usable: PATH is missing${_missing} — binaries living there stay unreachable"
    fi

    # The concrete regression: getent must resolve using ONLY the exported PATH.
    if env -i PATH="$DAEMON_PATH" sh -c 'command -v getent' >/dev/null 2>&1; then
        pass "path_is_usable: getent resolves via the exported PATH (the exact lookup filebrowser failed)"
    elif [ ! -x /usr/bin/getent ] && [ ! -x /bin/getent ]; then
        # macOS and slim containers have no getent at all; not a PATH defect.
        info "getent not installed on this host — skipping the resolution check"
    else
        fail "path_is_usable: getent exists on this host but does NOT resolve via the exported PATH"
    fi
fi

note "── path_excludes_cwd ──"
note "SVC_CWD is the app's user-writable data dir; a '.' entry would let an uploaded file hijack lookups"
if [ "$DAEMON_PATH" = "UNSET" ]; then
    fail "path_excludes_cwd: no PATH to check (see path_reaches_daemon)"
else
    case ":${DAEMON_PATH}:" in
        *":.:"*|*"::"*)
            fail "path_excludes_cwd: exported PATH contains a cwd entry ('.' or an empty component) — a file dropped in the app data dir could be executed by the daemon"
            ;;
        *)
            pass "path_excludes_cwd: exported PATH has no cwd entry"
            ;;
    esac
fi

report_summary "test-path-export"
