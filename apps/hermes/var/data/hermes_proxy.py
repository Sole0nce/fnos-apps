#!/usr/bin/env python3
"""Hermes dashboard HTTP forwarder (Host-rewriting) — with access logging."""
import socket
import threading
import sys
import time

LISTEN_HOST = "0.0.0.0"
LISTEN_PORT = 9120
TARGET_HOST = "127.0.0.1"
TARGET_PORT = 9119
REWRITE_HOST = f"{TARGET_HOST}:{TARGET_PORT}"
BUFSIZE = 65536
HEAD_LIMIT = 64 * 1024

_log_lock = threading.Lock()


def log(msg):
    with _log_lock:
        ts = time.strftime("%H:%M:%S")
        print(f"[{ts}] {msg}", flush=True)


def pipe(src, dst):
    try:
        while True:
            data = src.recv(BUFSIZE)
            if not data:
                break
            dst.sendall(data)
    except OSError:
        pass
    finally:
        try:
            dst.shutdown(socket.SHUT_WR)
        except OSError:
            pass


def rewrite_host_header(head: bytes) -> bytes:
    """Rewrite Host header AND force Connection: close.

    Forcing close is critical: the Host rewrite only applies to the FIRST
    request on each TCP connection. If keep-alive is allowed, subsequent
    requests on the same connection pass through with the original Host
    header and the dashboard rejects them with 400 Invalid Host header.
    """
    lines = head.split(b"\r\n")
    out = []
    for line in lines:
        lowered = line.lower()
        if lowered.startswith(b"host:"):
            name = line.split(b":", 1)[0]
            out.append(name + b": " + REWRITE_HOST.encode())
        elif lowered.startswith(b"connection:"):
            # Force close for plain keep-alive connections (each request
            # needs a fresh connection so the Host rewrite applies).
            # But NEVER touch Upgrade requests (WebSocket/SSE handshakes)
            # — breaking those breaks the dashboard's live connection.
            if b"upgrade" not in lowered:
                out.append(b"Connection: close")
            else:
                out.append(line)
        else:
            out.append(line)
    return b"\r\n".join(out)


def handle(conn, addr):
    peer = f"{addr[0]}:{addr[1]}"
    head = b""
    while b"\r\n\r\n" not in head and len(head) < HEAD_LIMIT:
        chunk = conn.recv(BUFSIZE)
        if not chunk:
            conn.close()
            return
        head += chunk
    if b"\r\n\r\n" not in head:
        log(f"{peer} -> head incomplete ({len(head)}B), raw pipe")
        try:
            upstream = socket.create_connection((TARGET_HOST, TARGET_PORT), timeout=10)
        except OSError:
            conn.close()
            return
        upstream.sendall(head)
        t1 = threading.Thread(target=pipe, args=(conn, upstream), daemon=True)
        t2 = threading.Thread(target=pipe, args=(upstream, conn), daemon=True)
        t1.start()
        t2.start()
        t1.join()
        t2.join()
        conn.close()
        upstream.close()
        return

    head_part, rest = head.split(b"\r\n\r\n", 1)
    # Extract request line + Host for logging
    req_line = head_part.split(b"\r\n", 1)[0].decode("utf-8", "replace")
    host_line = ""
    for line in head_part.split(b"\r\n"):
        if line.lower().startswith(b"host:"):
            host_line = line.decode("utf-8", "replace")
            break
    rewritten = rewrite_host_header(head_part) + b"\r\n\r\n" + rest
    log(f"{peer} << {req_line} | {host_line} -> Host rewritten")

    try:
        upstream = socket.create_connection((TARGET_HOST, TARGET_PORT), timeout=10)
    except OSError:
        conn.close()
        return
    upstream.sendall(rewritten)

    t1 = threading.Thread(target=pipe, args=(conn, upstream), daemon=True)
    t2 = threading.Thread(target=pipe, args=(upstream, conn), daemon=True)
    t1.start()
    t2.start()
    t1.join()
    t2.join()
    conn.close()
    upstream.close()


def main():
    srv = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    srv.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    srv.bind((LISTEN_HOST, LISTEN_PORT))
    srv.listen(128)
    log(f"listening {LISTEN_HOST}:{LISTEN_PORT} -> {TARGET_HOST}:{TARGET_PORT} (rewrite {REWRITE_HOST})")
    while True:
        conn, addr = srv.accept()
        threading.Thread(target=handle, args=(conn, addr), daemon=True).start()


if __name__ == "__main__":
    main()
