#!/bin/bash
# Behavioural test for shared/cmd/common start_daemon() readiness semantics.
#
# Root cause of GitHub issues #264 #260 #258 #253 #251 #246:
#   <App> failed during starting: appcenter-cli start <app>: code 10500
# The app actually started fine (logs prove it listens), but start_daemon
# returned BEFORE the daemon was confirmed up, so fnOS's immediate
# post-start status check raced the still-initialising process and surfaced
# a transient 10500. Worse, a command that dies instantly (e.g. /bin/true)
# still yielded start_daemon rc=0 — start "succeeded" with nothing running.
#
# Expected behaviour under test (SVC_BACKGROUND=y + SVC_WRITE_PID=y path):
#   dies_immediately_fails — command exits instantly -> start_daemon != 0
#   slow_start_waits       — slow-initialising daemon -> rc=0, but only after
#                            readiness has actually been polled (elapsed >= 1)
#   fast_start_ok          — healthy long-lived daemon -> rc=0, quickly
#
# Usage:
#   scripts/test/test-start-readiness.sh
#
# Exits 0 on all-pass, 1 on any failure.
#
# NOTE: deliberately NO `set -e` / `set -u` here:
#   - the script asserts ON non-zero return codes (set -e would abort early)
#   - shared/cmd/common references optionally-set vars (call_func's $2,
#     SVC_KEEP_LOG, ...) that would trip set -u when sourced.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./lib.sh
source "$SCRIPT_DIR/lib.sh"

COMMON="$(repo_root)/shared/cmd/common"
[ -f "$COMMON" ] || error "shared/cmd/common not found at $COMMON"

# ---------------------------------------------------------------------------
# Sandbox helpers
# ---------------------------------------------------------------------------

# sandbox_setup — run INSIDE a case subshell. Creates a mktemp sandbox,
# sources shared/cmd/common with a guard-passing fake TRIM_PKGVAR, then
# re-points every runtime path at the sandbox so nothing escapes it.
sandbox_setup() {
    SANDBOX="$(mktemp -d /tmp/fnos-start-readiness.XXXXXX)"
    # common's source-time guard only accepts /vol* or /usr/local/apps/@appdata/*.
    # This path is never actually created (mkdir is silenced with || true) —
    # all real paths are overridden below right after sourcing.
    TRIM_APPNAME="testreadiness"
    TRIM_APPDEST="$SANDBOX"
    TRIM_PKGVAR="/vol1/@appdata/${TRIM_APPNAME}"
    # shellcheck source=/dev/null
    . "$COMMON"
    # Re-point runtime state at the sandbox.
    TRIM_PKGVAR="$SANDBOX"
    LOG_FILE="$SANDBOX/app.log"
    PID_FILE="$SANDBOX/app.pid"
    OUT="$LOG_FILE"
    SVC_CWD="$SANDBOX"
    SVC_QUIET=y
    SVC_BACKGROUND=y
    SVC_WRITE_PID=y
    # SVC_WAIT_TIMEOUT intentionally left at the common default (15).
}

# sandbox_cleanup — kill any still-tracked daemon and drop the sandbox.
sandbox_cleanup() {
    if [ -f "$PID_FILE" ]; then
        for _p in $(cat "$PID_FILE" 2>/dev/null); do
            kill "$_p" 2>/dev/null
        done
    fi
    sleep 1
    rm -rf "$SANDBOX"
}

# daemon_alive_after — prints 1 if every pid in PID_FILE is alive, else 0.
daemon_alive_after() {
    local _alive=1
    if [ -f "$PID_FILE" ]; then
        for _p in $(cat "$PID_FILE" 2>/dev/null); do
            kill -0 "$_p" 2>/dev/null || _alive=0
        done
    else
        _alive=0
    fi
    echo "$_alive"
}

# ---------------------------------------------------------------------------
# Cases — each runs in a subshell and prints "rc=<n> elapsed=<s> alive=<0|1>"
# on stdout (parsed by the parent; pass/fail counters live in the parent).
# ---------------------------------------------------------------------------

case_dies_immediately() {
    (
        sandbox_setup
        SERVICE_COMMAND="/bin/true"
        SECONDS=0
        start_daemon
        _rc=$?
        _elapsed=$SECONDS
        _alive="$(daemon_alive_after)"
        sandbox_cleanup
        echo "rc=$_rc elapsed=$_elapsed alive=$_alive"
    )
}

case_slow_start() {
    (
        sandbox_setup
        # Daemon whose process stays up the whole time but only finishes
        # initialising after ~5s (simulates slow starters like JVM apps).
        cat > "$SANDBOX/slow-daemon.sh" <<'EOF'
#!/bin/bash
sleep 5
exec sleep 300
EOF
        chmod +x "$SANDBOX/slow-daemon.sh"
        SERVICE_COMMAND="$SANDBOX/slow-daemon.sh"
        SECONDS=0
        start_daemon
        _rc=$?
        _elapsed=$SECONDS
        _alive="$(daemon_alive_after)"
        sandbox_cleanup
        echo "rc=$_rc elapsed=$_elapsed alive=$_alive"
    )
}

case_fast_start() {
    (
        sandbox_setup
        SERVICE_COMMAND="sleep 300"
        SECONDS=0
        start_daemon
        _rc=$?
        _elapsed=$SECONDS
        _alive="$(daemon_alive_after)"
        sandbox_cleanup
        echo "rc=$_rc elapsed=$_elapsed alive=$_alive"
    )
}

# ---------------------------------------------------------------------------
# Assertions
# ---------------------------------------------------------------------------

note "── dies_immediately_fails ──"
note "SERVICE_COMMAND='/bin/true' (exits instantly) — start_daemon MUST return non-zero"
rc="" elapsed="" alive=""   # assigned by eval of the case subshell's stdout
eval "$(case_dies_immediately)"
info "start_daemon returned rc=$rc after ${elapsed}s (daemon alive after return: $alive)"
if [ "$rc" -ne 0 ]; then
    pass "dies_immediately_fails: start_daemon rc=$rc (non-zero) for instantly-dying command"
else
    fail "dies_immediately_fails: start_daemon returned 0 although the daemon died instantly — fnOS reports 'started' for a dead process (issues #264 #260 #258 #253 #251 #246)"
fi
if [ "$elapsed" -le 10 ]; then
    pass "dies_immediately_fails: failure detected fast (${elapsed}s <= 10s, no full-timeout stall)"
else
    fail "dies_immediately_fails: took ${elapsed}s to report a dead daemon (expected early bail-out)"
fi

note "── slow_start_waits ──"
note "SERVICE_COMMAND initialises ~5s then stays alive — start_daemon MUST poll readiness (elapsed >= 1) and return 0"
rc="" elapsed="" alive=""   # assigned by eval of the case subshell's stdout
eval "$(case_slow_start)"
info "start_daemon returned rc=$rc after ${elapsed}s (daemon alive after return: $alive)"
if [ "$rc" -eq 0 ]; then
    pass "slow_start_waits: start_daemon rc=0 for slow-but-healthy daemon (no punishment for slow start)"
else
    fail "slow_start_waits: start_daemon rc=$rc — slow starters (e.g. JVM apps like ani-rss) must NOT be failed"
fi
if [ "$elapsed" -ge 1 ]; then
    pass "slow_start_waits: readiness was actually awaited (elapsed=${elapsed}s >= 1s; old code returned instantly)"
else
    fail "slow_start_waits: start_daemon returned after ${elapsed}s without confirming the daemon is up"
fi
if [ "$alive" -eq 1 ]; then
    pass "slow_start_waits: daemon still running when start_daemon returned"
else
    fail "slow_start_waits: start_daemon rc=0 but no daemon process alive afterwards"
fi

note "── fast_start_ok ──"
note "SERVICE_COMMAND='sleep 300' (healthy long-lived) — start_daemon MUST return 0 quickly"
rc="" elapsed="" alive=""   # assigned by eval of the case subshell's stdout
eval "$(case_fast_start)"
info "start_daemon returned rc=$rc after ${elapsed}s (daemon alive after return: $alive)"
if [ "$rc" -eq 0 ]; then
    pass "fast_start_ok: start_daemon rc=0 for healthy daemon"
else
    fail "fast_start_ok: start_daemon rc=$rc for a healthy long-lived daemon"
fi
if [ "$elapsed" -le 5 ]; then
    pass "fast_start_ok: returned quickly (${elapsed}s <= 5s)"
else
    fail "fast_start_ok: took ${elapsed}s for a healthy daemon (readiness wait must not stall healthy apps)"
fi
if [ "$alive" -eq 1 ]; then
    pass "fast_start_ok: daemon still running when start_daemon returned"
else
    fail "fast_start_ok: start_daemon rc=0 but no daemon process alive afterwards"
fi

report_summary "test-start-readiness"
