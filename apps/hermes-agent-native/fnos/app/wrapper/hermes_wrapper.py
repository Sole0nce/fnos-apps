#!/usr/bin/env python3
"""hermes-agent-native fnOS wrapper.

Reimplements the trim.hermes ELF gateway in pure Python:

  1. Listens on a Unix socket (fnOS gateway forwards desktop-icon requests
     here via ui/config gatewaySocket).
  2. Rewrites the Host header to 127.0.0.1:<dashboard-port> so Hermes'
     dashboard Host validation accepts the request.
  3. Injects X-Forwarded-Prefix (from --gateway-prefix) so the dashboard
     generates prefix-aware asset URLs; without it the HTML references
     "/assets/..." which the fnOS gateway cannot route back, leaving the
     desktop iframe blank.
  4. Forwards plain HTTP to the dashboard and streams WebSocket upgrades
     through unchanged.
  5. Spawns and supervises `hermes dashboard` on 127.0.0.1, restarting it
     if it dies.

Command line (mirrors trim-hermes-wrapper):
  hermes_wrapper.py --socket <path> --dashboard-host 127.0.0.1
                    --dashboard-port 19119 --app-root <dir> --data-root <dir>
                    [--gateway-prefix /app/hermes-agent-native]
"""

import argparse
import json
import logging
import os
import select
import signal
import socket
import subprocess
import sys
import threading
import time
import urllib.error
import urllib.request

LOG = logging.getLogger("hermes-wrapper")

# Keep-alive connections carry an un-rewritten Host on reuse, which the
# dashboard rejects with 400. Force close after every response instead.
HEADER_CONNECTION_CLOSE = b"Connection: close\r\n"


def setup_logging(data_root: str) -> str:
    os.makedirs(data_root, exist_ok=True)
    log_path = os.path.join(data_root, "wrapper.log")
    handler = logging.FileHandler(log_path, encoding="utf-8")
    handler.setFormatter(
        logging.Formatter("%(asctime)s [%(levelname)s] %(message)s")
    )
    LOG.addHandler(handler)
    LOG.setLevel(logging.INFO)
    return log_path


# --------------------------------------------------------------------------
# Hermes dashboard subprocess management
# --------------------------------------------------------------------------

class DashboardSupervisor:
    """Spawns `hermes dashboard` and keeps it alive."""

    def __init__(self, runtime_root: str, host: str, port: int, hermes_home: str,
                 workspace_root: str, data_root: str):
        self.runtime_root = runtime_root
        self.host = host
        self.port = port
        self.hermes_home = hermes_home
        self.workspace_root = workspace_root
        self.data_root = data_root
        self.proc: subprocess.Popen | None = None
        self.lock = threading.Lock()
        self.stop_event = threading.Event()

    @property
    def hermes_bin(self) -> str:
        return os.path.join(self.runtime_root, "python", "bin", "hermes")

    def is_up(self) -> bool:
        with self.lock:
            return self.proc is not None and self.proc.poll() is None

    def start(self) -> None:
        with self.lock:
            if self.proc is not None and self.proc.poll() is None:
                return
            env = dict(os.environ)
            env.update({
                "HERMES_HOME": self.hermes_home,
                "HERMES_WRITE_SAFE_ROOT": self.workspace_root,
                "TRIM_HERMES_DATA_ROOT": self.data_root,
                "PATH": os.pathsep.join([
                    os.path.join(self.runtime_root, "python", "bin"),
                    os.path.join(self.runtime_root, "python", "node", "bin"),
                    os.path.join(self.hermes_home, "node", "bin"),
                    env.get("PATH", ""),
                ]),
            })
            args = [
                self.hermes_bin,
                "dashboard",
                "--host", self.host,
                "--port", str(self.port),
                "--no-open",
                "--insecure",
            ]
            LOG.info("spawn dashboard: %s", " ".join(args))
            self.proc = subprocess.Popen(
                args,
                env=env,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.STDOUT,
                start_new_session=True,
            )

    def supervise(self) -> None:
        """Loop: keep dashboard alive until stop_event is set."""
        while not self.stop_event.is_set():
            if not self.is_up():
                LOG.warning("dashboard not running, respawning")
                self.start()
            try:
                self.proc.wait(timeout=2.0)
            except subprocess.TimeoutExpired:
                continue
            LOG.warning("dashboard exited with code %s", self.proc.returncode)
            self.proc = None
            if self.stop_event.is_set():
                break
            time.sleep(1)

    def stop(self) -> None:
        self.stop_event.set()
        with self.lock:
            proc = self.proc
        if proc is not None and proc.poll() is None:
            try:
                os.killpg(os.getpgid(proc.pid), signal.SIGTERM)
            except (ProcessLookupError, PermissionError):
                try:
                    proc.terminate()
                except ProcessLookupError:
                    pass
            try:
                proc.wait(timeout=10)
            except subprocess.TimeoutExpired:
                try:
                    os.killpg(os.getpgid(proc.pid), signal.SIGKILL)
                except (ProcessLookupError, PermissionError):
                    proc.kill()


# --------------------------------------------------------------------------
# HTTP / WebSocket proxy over a Unix socket
# --------------------------------------------------------------------------

def read_request_head(conn: socket.socket, timeout: float = 30.0) -> bytes:
    """Read until \r\n\r\n, honouring a tiny initial read for keep-alive."""
    conn.settimeout(timeout)
    buf = b""
    while b"\r\n\r\n" not in buf:
        chunk = conn.recv(65536)
        if not chunk:
            return buf
        buf += chunk
        if len(buf) > 1024 * 1024:
            break
    return buf


def rewrite_request(raw: bytes, host: str, port: int,
                    gateway_prefix: str = "") -> bytes:
    """Rewrite Host header + absolute-form request line to dashboard form.

    When `gateway_prefix` is non-empty (e.g. "/app/hermes-agent-native"),
    inject an X-Forwarded-Prefix header so the dashboard generates
    prefix-aware asset URLs. Without it the served HTML references
    "/assets/..." which the fnOS gateway cannot route back to the app,
    leaving the desktop iframe blank.
    """
    try:
        head, _, rest = raw.partition(b"\r\n\r\n")
        lines = head.split(b"\r\n")
        reqline = lines[0]
        is_absolute = reqline.startswith((b"GET http://", b"POST http://",
                                          b"PUT http://", b"DELETE http://",
                                          b"OPTIONS http://", b"PATCH http://",
                                          b"HEAD http://", b"CONNECT "))
        if is_absolute:
            parts = reqline.split(b" ", 2)
            if len(parts) == 3:
                from urllib.parse import urlparse
                parsed = urlparse(parts[1].decode("latin-1"))
                reqline = b" ".join([parts[0],
                                     parsed.path.encode("latin-1") or b"/",
                                     parts[2]])
        new_headers = [reqline]
        replaced_host = False
        for line in lines[1:]:
            low = line.lower()
            if low.startswith(b"host:"):
                new_headers.append(
                    ("Host: %s:%d" % (host, port)).encode("latin-1"))
                replaced_host = True
            elif low.startswith(b"connection:"):
                continue  # we force our own Connection: close
            elif gateway_prefix and low.startswith(b"x-forwarded-prefix:"):
                continue  # replace stale prefix from upstream proxy
            else:
                new_headers.append(line)
        if not replaced_host:
            new_headers.append(
                ("Host: %s:%d" % (host, port)).encode("latin-1"))
        if gateway_prefix:
            new_headers.append(
                ("X-Forwarded-Prefix: %s" % gateway_prefix).encode("latin-1"))
        new_headers.append(HEADER_CONNECTION_CLOSE)
        return b"\r\n".join(new_headers) + b"\r\n\r\n" + rest
    except Exception as exc:  # noqa: BLE001
        LOG.warning("rewrite failed: %s", exc)
        return raw


def proxy_http(conn: socket.socket, host: str, port: int,
               gateway_prefix: str = "") -> None:
    raw = read_request_head(conn)
    if not raw:
        return
    rewritten = rewrite_request(raw, host, port, gateway_prefix)
    try:
        upstream = socket.create_connection((host, port), timeout=10)
    except OSError as exc:
        LOG.error("upstream connect failed: %s", exc)
        body = b"hermes dashboard is not reachable yet"
        conn.sendall(b"HTTP/1.1 502 Bad Gateway\r\n"
                     b"Content-Type: text/plain\r\n"
                     b"Content-Length: " + str(len(body)).encode() + b"\r\n"
                     b"Connection: close\r\n\r\n" + body)
        return
    try:
        is_upgrade = b"upgrade" in raw.lower()
        upstream.sendall(rewritten)
        if is_upgrade:
            # WebSocket: bidirectionally pump bytes until either side closes.
            sockets = [conn, upstream]
            while True:
                readable, _, _ = select.select(sockets, [], [], 30)
                if not readable:
                    continue
                for s in readable:
                    data = s.recv(65536)
                    if not data:
                        return
                    target = upstream if s is conn else conn
                    target.sendall(data)
        else:
            # Plain HTTP: read upstream response, stream to client.
            while True:
                data = upstream.recv(65536)
                if not data:
                    break
                conn.sendall(data)
    except (OSError, ConnectionError):
        pass
    finally:
        try:
            upstream.close()
        except OSError:
            pass


def accept_loop(sock_path: str, host: str, port: int,
                supervisor: DashboardSupervisor,
                gateway_prefix: str = "") -> None:
    if os.path.exists(sock_path):
        try:
            os.unlink(sock_path)
        except OSError:
            pass
    server = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    server.bind(sock_path)
    server.listen(64)
    os.chmod(sock_path, 0o666)
    LOG.info("listening on %s -> %s:%d", sock_path, host, port)

    while True:
        conn, _ = server.accept()
        threading.Thread(target=proxy_http,
                         args=(conn, host, port, gateway_prefix),
                         daemon=True).start()


def tcp_accept_loop(listen_port: int, host: str, port: int,
                    gateway_prefix: str = "") -> None:
    """Expose the dashboard over TCP (direct browser access, e.g. fnOS
    desktop icon with ui/config type=url). Unlike the Unix-socket path this
    must NOT inject X-Forwarded-Prefix: the browser hits the dashboard
    directly, so asset URLs must stay unprefixed."""
    server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    server.bind(("0.0.0.0", listen_port))
    server.listen(64)
    LOG.info("listening on 0.0.0.0:%d -> %s:%d", listen_port, host, port)

    while True:
        conn, _ = server.accept()
        threading.Thread(target=proxy_http,
                         args=(conn, host, port, gateway_prefix),
                         daemon=True).start()


def dashboard_ready(host: str, port: int, timeout: float = 90.0) -> bool:
    deadline = time.time() + timeout
    while time.time() < deadline:
        try:
            with urllib.request.urlopen(
                    "http://%s:%d/api/health" % (host, port), timeout=3) as resp:
                if resp.status == 200:
                    return True
        except (urllib.error.URLError, OSError, ValueError):
            pass
        time.sleep(1)
    return False


def main() -> int:
    parser = argparse.ArgumentParser(description="hermes-agent-native fnOS gateway")
    parser.add_argument("--socket", required=True)
    parser.add_argument("--dashboard-host", default="127.0.0.1")
    parser.add_argument("--dashboard-port", type=int, default=19119)
    parser.add_argument("--app-root", required=True)
    parser.add_argument("--data-root", required=True)
    parser.add_argument("--gateway-prefix", default="",
                        help="e.g. /app/hermes-agent-native; injected as "
                             "X-Forwarded-Prefix so the dashboard emits "
                             "prefix-aware asset URLs for the fnOS iframe")
    parser.add_argument("--listen-port", type=int, default=0,
                        help="optional TCP port to expose the dashboard on "
                             "0.0.0.0 (direct browser access, no prefix)")
    args = parser.parse_args()

    setup_logging(args.data_root)
    hermes_home = os.path.join(args.data_root, "hermes")
    workspace_root = os.path.join(args.data_root, "workspace")
    runtime_root = os.path.join(args.app_root, "runtime")

    supervisor = DashboardSupervisor(
        runtime_root=runtime_root,
        host=args.dashboard_host,
        port=args.dashboard_port,
        hermes_home=hermes_home,
        workspace_root=workspace_root,
        data_root=args.data_root,
    )

    # Serve the socket FIRST so the desktop icon never hangs during
    # dashboard cold start; requests get 502 with a clear body until the
    # upstream is up. The supervisor thread respawns it in the background.
    supervisor.start()
    threading.Thread(target=supervisor.supervise, daemon=True).start()

    if args.listen_port:
        threading.Thread(target=tcp_accept_loop,
                         args=(args.listen_port, args.dashboard_host,
                               args.dashboard_port, ""),
                         daemon=True).start()

    def _shutdown(_sig, _frame):
        LOG.info("shutdown signal received")
        supervisor.stop()
        sys.exit(0)

    signal.signal(signal.SIGTERM, _shutdown)
    signal.signal(signal.SIGINT, _shutdown)

    try:
        accept_loop(args.socket, args.dashboard_host, args.dashboard_port,
                    supervisor, args.gateway_prefix)
    except KeyboardInterrupt:
        pass
    finally:
        supervisor.stop()
    return 0


if __name__ == "__main__":
    sys.exit(main())
