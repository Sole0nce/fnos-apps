#!/usr/bin/env python3
"""Rewrite bin/* console scripts into relocatable sh wrappers (trim.hermes style).

pip-generated console scripts embed an absolute shebang pointing at the CI
build machine (e.g. #!/home/runner/.../bin/python3.11) which does not exist
on the fnOS NAS. This rewrites every script under <bin_dir> whose shebang
mentions python into:

    #!/bin/sh
    SELF_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
    exec "$SELF_DIR/python3" -c "...entry call..." "$@"

mirroring DavidChen's trim.hermes package, so the runtime is fully relocatable.

Entry points are read from *.dist-info/entry_points.txt under site-packages;
python stdlib tools (pip/idle/pydoc/2to3) are mapped by module name.
"""
import glob
import os
import re
import sys

SH_TEMPLATE = """#!/bin/sh
SELF_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
exec "$SELF_DIR/python3" {entry} "$@"
"""

# stdlib tools: filename stem -> python -m module
STDLIB_MODULES = {
    "2to3": "lib2to3.main",
    "2to3-3.11": "lib2to3.main",
    "idle": "idlelib",
    "idle3": "idlelib",
    "idle3.11": "idlelib",
    "pydoc": "pydoc",
    "pydoc3": "pydoc",
    "pydoc3.11": "pydoc",
    "pip": "pip",
    "pip3": "pip",
    "pip3.11": "pip",
    "wheel": "wheel",
}


def parse_entry_points(site_packages: str) -> dict:
    """Return {script_name: "from X import Y as Z; sys.exit(Z())" python snippet}."""
    entries: dict[str, str] = {}
    for ep_file in glob.glob(os.path.join(site_packages, "*.dist-info", "entry_points.txt")):
        try:
            with open(ep_file, encoding="utf-8") as fh:
                text = fh.read()
        except OSError:
            continue
        section = None
        for raw in text.splitlines():
            line = raw.strip()
            if not line or line.startswith(("#", ";")):
                continue
            if line.startswith("[") and line.endswith("]"):
                section = line[1:-1].strip().lower()
                continue
            if section != "console_scripts":
                continue
            if "=" not in line:
                continue
            name, _, target = line.partition("=")
            name = name.strip()
            target = target.strip()
            # strip extras: "module:attr [extra1,extra2]"
            target = re.sub(r"\s*\[.*\]\s*$", "", target).strip()
            if ":" in target:
                module, _, attr = target.partition(":")
                attr = attr.strip() or "main"
            else:
                module, attr = target, "main"
            if not module or not name:
                continue
            snippet = f"-c \"import sys; from {module} import {attr} as _e; sys.argv[0]='{name}'; sys.exit(_e())\""
            entries[name] = snippet
    return entries


def main() -> int:
    if len(sys.argv) != 2:
        print("usage: rewrite-console-scripts.py <python-runtime-dir>", file=sys.stderr)
        return 2
    runtime_dir = os.path.abspath(sys.argv[1])
    bin_dir = os.path.join(runtime_dir, "bin")
    site_packages = os.path.join(runtime_dir, "lib", "python3.11", "site-packages")

    entries = parse_entry_points(site_packages)
    print(f"entry points: {len(entries)}")

    rewritten = skipped = 0
    for name in sorted(os.listdir(bin_dir)):
        path = os.path.join(bin_dir, name)
        if not os.path.isfile(path) or os.path.islink(path):
            continue
        try:
            with open(path, "rb") as fh:
                first = fh.readline().decode("utf-8", "replace").strip()
        except OSError:
            continue
        if not first.startswith("#!") or "python" not in first:
            continue

        if name in entries:
            entry = entries[name]
        elif name in STDLIB_MODULES:
            entry = f"-m {STDLIB_MODULES[name]}"
        else:
            skipped += 1
            print(f"  skip (no entry): {name}")
            continue

        os.chmod(path, 0o755)
        with open(path, "w", encoding="utf-8", newline="\n") as fh:
            fh.write(SH_TEMPLATE.format(entry=entry))
        rewritten += 1
        print(f"  -> {name}: {entry}")

    print(f"rewritten {rewritten}, skipped {skipped}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
