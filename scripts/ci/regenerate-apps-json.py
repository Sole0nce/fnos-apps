#!/usr/bin/env python3
"""Regenerate apps.json for Sole0nce/fnos-apps (Windows-friendly, no jq arg limits)."""
import json, os, subprocess, sys, time, glob

REPO = "Sole0nce/fnos-apps"
ROOT = r"D:\GitHub\fnos-apps"
TOKEN = os.environ.get("GH_TOKEN", "")

def gh(*args):
    cmd = ["gh"] + list(args) + ["--repo", REPO]
    r = subprocess.run(cmd, capture_output=True, text=True, env={**os.environ, "GH_TOKEN": TOKEN})
    if r.returncode != 0:
        print("gh error:", r.stderr[:300], file=sys.stderr)
        return None
    return r.stdout

def parse_manifest(file, key):
    """key="value" format, strip quotes and CR."""
    for line in open(file, encoding="utf-8"):
        line = line.rstrip("\r\n")
        if line.startswith(key + "=") or line.startswith(key + " "):
            val = line.split("=", 1)[1].strip()
            if val.startswith('"') and val.endswith('"') and len(val) >= 2:
                val = val[1:-1]
            return val
    return ""

releases = json.loads(gh("release", "list", "--limit", "500", "--json", "tagName,publishedAt") or "[]")

apps = []
for app_dir in sorted(glob.glob(os.path.join(ROOT, "scripts", "apps", "*"))):
    meta_env = os.path.join(app_dir, "meta.env")
    if not os.path.isfile(meta_env):
        continue
    slug = os.path.basename(app_dir)
    meta = {}
    for line in open(meta_env, encoding="utf-8"):
        line = line.strip()
        if "=" in line and not line.startswith("#"):
            k, v = line.split("=", 1)
            meta[k.strip()] = v.strip().strip('"').strip("'")

    manifest = os.path.join(ROOT, "apps", slug, "fnos", "manifest")
    if not os.path.isfile(manifest):
        print(f"[WARN] no manifest for {slug}", file=sys.stderr)
        continue

    appname = parse_manifest(manifest, "appname") or slug
    display_name = parse_manifest(manifest, "display_name") or appname
    desc = parse_manifest(manifest, "desc") or ""
    service_port = parse_manifest(manifest, "service_port") or meta.get("DEFAULT_PORT", "")
    try:
        service_port = int(service_port)
    except (ValueError, TypeError):
        service_port = 0

    # latest release for this slug
    rels = [r for r in releases if r["tagName"].startswith(slug + "/")]
    if not rels:
        print(f"[WARN] no release for {slug}", file=sys.stderr)
        continue
    rels.sort(key=lambda r: r["publishedAt"])
    latest = rels[-1]
    release_tag = latest["tagName"]
    updated_at = latest["publishedAt"]

    tag_version = release_tag[len(slug) + 1:]  # strip "slug/"
    if tag_version.startswith("v"):
        tag_version = tag_version[1:]
    version = tag_version.split("-r")[0]
    fpk_version = tag_version

    icon_url = f"https://raw.githubusercontent.com/{REPO}/main_custom/apps/{slug}/fnos/ICON_256.PNG"
    app_type = "docker" if os.path.isfile(os.path.join(ROOT, "apps", slug, "fnos", "docker", "docker-compose.yaml")) else "native"

    obj = {
        "slug": slug,
        "appname": appname,
        "file_prefix": meta.get("FILE_PREFIX", slug),
        "display_name": display_name,
        "description": desc,
        "version": version,
        "fpk_version": fpk_version,
        "release_tag": release_tag,
        "service_port": service_port,
        "homepage_url": parse_manifest(manifest, "maintainer_url") or meta.get("HOMEPAGE_URL", ""),
        "icon_url": icon_url,
        "platforms": ["x86", "arm"],
        "updated_at": updated_at,
        "download_count": 0,
        "app_type": app_type,
        "category": meta.get("CATEGORY", ""),
    }
    if meta.get("POST_INSTALL_NOTE"):
        obj["post_install_note"] = meta["POST_INSTALL_NOTE"]
    apps.append(obj)
    print(f"  OK {slug} -> {release_tag}")

apps.sort(key=lambda a: a["slug"])
out = {
    "schema_version": 1,
    "generated_at": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
    "source": {"name": REPO, "url": f"https://github.com/{REPO}"},
    "apps": apps,
}
with open(os.path.join(ROOT, "apps.json"), "w", encoding="utf-8") as f:
    json.dump(out, f, ensure_ascii=False, indent=2)
print(f"\nGenerated apps.json with {len(apps)} apps")
