# PROJECT KNOWLEDGE BASE

**Updated:** 2026-08-16

## OVERVIEW

Monorepo packaging **155** third-party apps as `.fpk` installers for fnOS NAS. Pure bash — downloads
upstream release artifacts (or references upstream Docker images), merges them with a shared lifecycle
framework, and emits `.fpk` tarballs. Daily CI tracks upstream versions and publishes per-app GitHub
releases; `apps.json` is regenerated from those releases and is what the app store reads.

Two packaging modes:

| Mode | Count | Shape |
|---|---:|---|
| **Docker** | 102 | `apps/<slug>/fnos/docker/docker-compose.yaml`; `app.tgz` holds only the compose file + UI |
| **Native** | 53 | upstream binary repackaged into `app.tgz`; driven by `cmd/service-setup` |

## STRUCTURE

```
fnos-apps/
├── shared/
│   ├── cmd/             # Lifecycle framework all apps inherit (see shared/cmd/AGENTS.md)
│   └── wizard/          # Default uninstall wizard (JSON) — the canonical correct shape
├── apps/<slug>/
│   ├── fnos/            # Everything that ends up in the .fpk
│   │   ├── manifest     # appname, version, platform, service_port, checksum, install_type
│   │   ├── cmd/         # Overlays shared/cmd/ — override ONLY what differs
│   │   ├── config/      # privilege (run-as user) + resource (docker-project | systemd-unit)
│   │   ├── docker/      # Docker mode only: docker-compose.yaml
│   │   ├── wizard/      # install (install-time form) / uninstall / config (post-install settings)
│   │   ├── ui/          # Desktop launcher entry + icons
│   │   ├── health.json  # Probe used by the L3 test runner
│   │   └── <Name>.sc    # fnOS firewall rules
│   └── update_<slug>.sh # Local build (mirrors what CI does)
├── scripts/
│   ├── build-fpk.sh     # Generic packager: shared + app-specific -> .fpk
│   ├── new-app.sh       # Scaffold: ./scripts/new-app.sh <slug> "<display>" <port>
│   ├── apps/<slug>/     # Build contract: meta.env, build.sh, get-latest-version.sh, release-notes.tpl
│   ├── lib/             # update-common.sh: info/warn/error, cleanup trap, main_flow
│   ├── ci/              # resolve-release-tag.sh (-r2/-r3 auto-increment)
│   └── test/            # L1/L2/L3 test ladder (see TESTING)
├── test/                # Harness that drives a real fnOS VM (lib.sh, rpc.sh, run-all.sh, ...)
└── .github/workflows/   # build-apps.yml + reusable-build-app.yml + test-static/test-fpk + apps.json
```

## WHERE TO LOOK

| Task | Location | Notes |
|------|----------|-------|
| Add a new app | `scripts/new-app.sh` | Scaffolds with TODO markers; then follow the fnos-new-app skill |
| App lifecycle | `shared/cmd/common` | Daemon start/stop/status, install/upgrade/uninstall hooks |
| Service entry point | `shared/cmd/main` | start/stop/status dispatcher; sources `common` + `service-setup` |
| Per-app service config | `apps/*/fnos/cmd/service-setup` | `SERVICE_COMMAND`, PID/LOG paths, lifecycle hooks |
| Docker status override | `apps/*/fnos/cmd/main` | Docker apps only — start/stop are no-ops, status uses `docker inspect` |
| Build locally | `apps/*/update_*.sh` | `--arch x86｜arm` |
| CI build contract | `scripts/apps/<slug>/` | meta.env, build.sh, get-latest-version.sh, release-notes.tpl |
| Single-platform apps | `scripts/apps/<slug>/meta.env` | `SUPPORTED_ARCH=x86` (default `"x86 arm"`) |
| Categories | `scripts/apps/<slug>/meta.env` | ai, automation, browser, content, download, media, network, store, system |

## CONVENTIONS

- **Language**: 100% bash. No package managers, no compiled languages.
- **Manifest format**: fixed-width alignment at column 16 (`appname         = value`).
- **fpk = tar.gz** containing `app.tgz` + `cmd/` + `config/` + `wizard/` + `manifest` + icons + `ui/`.
- **Overlay pattern**: `shared/cmd/*` is copied first, then `apps/*/fnos/cmd/*` overwrites it.
- **Architecture**: dual-build x86 + arm by default. Opt out per app with `SUPPORTED_ARCH` in `meta.env`
  (currently: clamav, handbrake, melody-hub, nvidia-driver, surface-battery, vibenvr).
- **Version tags**: namespaced — `plex/v1.42.2.10156`, `qbittorrent/v5.1.4-r2`.
- **Revision suffix**: `-r2`, `-r3` auto-incremented for same-version re-releases.
- **Chinese** for user-facing strings (manifest `desc`, wizard labels, README, script info/warn/error);
  **English** for code comments.
- **TRIM_\* env vars** are injected by fnOS at runtime: `TRIM_APPNAME`, `TRIM_APPDEST`, `TRIM_PKGVAR`,
  `TRIM_PKGETC`, `TRIM_PKGHOME`, `TRIM_SERVICE_PORT`, `TRIM_APP_STATUS`, `TRIM_DATA_SHARE_PATHS`.
- **install_type = root** apps (nvidia-driver, surface-battery, 1panel) are installed to
  `/usr/local/apps`, NOT to a `/volN` storage volume. Only their `meta` symlink resolves onto a volume.
- **Hooks run as the app's `run-as` user, never implicitly as root.** `config/privilege`'s
  `"username"` overrides `"run-as": "root"`, so an app needing root must declare `run-as: root`
  with NO `username`/`groupname` (see nvidia-driver, 1panel). This bit 1panel: it had to write
  `/usr/local/bin/1pctl` from `service_preinst` but ran as the `1panel` user, so the write failed
  with `Permission denied` and the app panicked on every start.

## ANTI-PATTERNS (THIS PROJECT)

- **NEVER modify upstream binaries** — download and repackage only. Transparency is the core principle.
- **NEVER hardcode architecture** — use the `--arch` flag / CI matrix variables.
- **DO NOT duplicate shared/cmd/ logic** in an app's `cmd/` — override only what differs.
- **DO NOT skip the checksum** — `app.tgz` md5 must land in the manifest (`build-fpk.sh` handles it).
- **DO NOT create per-app build scripts in `scripts/ci/`** — use `scripts/apps/<slug>/build.sh`.
- **DO NOT create per-app workflow files** — `build-apps.yml` auto-discovers from `apps/`.

### Three packaging bugs that reached users — do not repeat them

1. **Version substitution must use this exact sed.** Anything else risks corrupting the compose file:
   ```bash
   sed -i.bak "s/\${VERSION}/${VERSION}/g" "${WORK_DIR}/docker/docker-compose.yaml"
   rm -f "${WORK_DIR}/docker/docker-compose.yaml.bak"
   ```
   `perl -0pi -e "s/\Q\${VERSION}\E/${VERSION}/g"` looks equivalent but is not: in double quotes bash
   turns `\$` into a literal `$`, perl then interpolates its OWN undefined `$VERSION` to an empty
   string, the regex collapses to `s//X/g`, and the version is injected between every character of the
   file. fnOS rejects the result with `top-level object must be a mapping`. Shipped in songloft.

2. **Wizard `initValue` must be a STRING.** A boolean (`"initValue": false`) makes fnOS refuse to parse
   the package at all — `cannot unmarshal bool into Go struct field WizardConfig.items.initValue of
   type string` — so the store cannot read the install wizard, installs with no answers, and the user
   sees a misleading `19000: wizard required field <x> not found`. Copy `shared/wizard/uninstall`
   (radio + string-valued options). Shipped in feigram.

3. **Wizard values reach a container ONLY through compose substitution.** fnOS drives Docker through
   its API, not the compose CLI, and creates the container BEFORE `install_callback` runs. So
   `env_file:`, a `.env` file, and `sed`-patching the compose in `service_postinst` are all silently
   ineffective. Reference the field directly, with a fallback:
   ```yaml
   environment:
     - APP_PASSWORD=${wizard_password:-changeme}
   ```
   (Exception: images that re-read credentials from a file on the data volume at start, e.g. jlesage/*.)
   See issue #146.

## TESTING

There IS test infrastructure — three local layers plus a real-VM harness.

| Layer | Command | Covers |
|---|---|---|
| **L1 static** | `bash scripts/test/static-check.sh <slug>` | manifest keys/values, icon dimensions, leftover scaffold TODOs, port consistency, **shellcheck**, compose YAML lint, health.json schema |
| **L2 contract** | `bash scripts/test/verify-fpk.sh dist/<f>.fpk` | fpk structure, md5 vs manifest, ELF arch (x86↔x86-64 / arm↔aarch64), **built compose inside app.tgz is a valid `services:` mapping**, docker image reachable |
| **L3 install cycle** | `bash scripts/test/run-fpk-tests.sh dist/<f>.fpk` | install → start → probe → stop → uninstall → assert-clean, inside a container |
| **shared framework** | `bash scripts/test/test-start-readiness.sh` | `start_daemon` readiness gate |
| **shared framework** | `bash scripts/test/test-path-export.sh` | `PATH` is exported to spawned daemons |
| **real VM** | `test/run-all.sh`, `test/test-upgrade.sh`, ... | drives an actual fnOS box over SSH |

**L3 cannot boot Docker apps** — the runner container has no Docker daemon. Docker apps therefore set
`health.json` to `{"type":"skip"}` (the schema requires a non-empty `note` explaining why). Their real
functional proof is installing on an actual fnOS box. CI's `test-fpk.yml` WHITELIST contains only
native apps for the same reason.

## COMMANDS

```bash
# Scaffold
./scripts/new-app.sh <slug> "<Display Name>" <port>

# Build one app locally
cd apps/<slug> && ./update_<slug>.sh                 # latest, auto-detect arch
cd apps/<slug> && ./update_<slug>.sh --arch arm      # force ARM

# CI-style build
VERSION=<ver> bash scripts/apps/<slug>/build.sh
bash scripts/build-fpk.sh apps/<slug> app.tgz <ver> x86

# Test ladder
bash scripts/test/static-check.sh <slug>
bash scripts/test/verify-fpk.sh dist/<slug>_<ver>_x86.fpk
bash scripts/test/run-fpk-tests.sh dist/<slug>_<ver>_x86.fpk
```

## NOTES

- **CI triggers**: push to `apps/*/` or `shared/`, daily cron, manual dispatch. Markdown-only changes ignored.
- **CI is idempotent** — skips if the release tag already exists.
- **apps.json** is generated by `update-apps-json.yml` from published releases; the store reads it.
  It is CI-owned — never hand-edit it.
- **China mirror links** (ghfast.top) are auto-included in release notes.
- **fnOS runtime paths**: apps install to `/var/apps/<appname>/` with `target`/`var`/`meta` symlinks
  pointing at the volume that holds the payload, data and metadata respectively.
- `shared/cmd/common` includes a bounded start-readiness wait: after the PID is written it polls up to
  `SVC_WAIT_TIMEOUT` (default 15s) so fnOS cannot observe a not-yet-listening daemon; a process that
  dies immediately now fails the start, while a slow-but-alive one still succeeds.
- `shared/cmd/common` exports a standard `PATH`. fnOS hands lifecycle scripts a TRIM_*-only environment
  with **no `PATH` at all**; bash substitutes a compiled-in default for its own lookups but never exports
  it, so every spawned daemon used to inherit an unset `PATH` and anything that shelled out failed with
  `executable file not found in $PATH` (filebrowser died on `getent`, issue #268). Do not remove the
  export, and do not derive it from the inherited value — bash's default ends in `.`, which would put the
  app's user-writable data dir on the daemon's search path. Apps needing extra dirs prepend them in
  their own `cmd/service-setup` or wrapper (see emby).
