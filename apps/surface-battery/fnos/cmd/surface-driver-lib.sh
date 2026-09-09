#!/bin/bash
set -euo pipefail

APP_NAME="surface_battery_driver"
MODPKG="surface_aggregator_module"
MODVER="0.1-fnos"
SSAM_LOAD="surface_aggregator surface_aggregator_hub surface_acpi_notify surface_battery surface_charger surface_aggregator_registry battery ac"
SSAM_UNLOAD="surface_aggregator_registry surface_charger surface_battery surface_acpi_notify surface_aggregator_hub surface_aggregator"

log() { echo "[$APP_NAME] $*"; }
fail() { echo "[$APP_NAME] ERROR: $*" >&2; [ -n "${TRIM_TEMP_LOGFILE:-}" ] && echo "$*" > "$TRIM_TEMP_LOGFILE"; exit 1; }
krel() { uname -r; }
moddir() { echo "/lib/modules/$(krel)/updates/$MODPKG"; }
srcdir() { echo "/usr/src/${MODPKG}-${MODVER}"; }

find_driver_src() {
  local base d
  for base in \
    "${TRIM_APPDEST:-}" \
    "$(cd "$(dirname "$0")/.." && pwd)" \
    "$(cd "$(dirname "$0")/../app" 2>/dev/null && pwd || true)" \
    "/usr/local/apps/@appcenter/${APP_NAME}" \
    "/usr/local/apps/@appcenter/${APP_NAME}/app"; do
    [ -n "$base" ] || continue
    for d in "$base/driver/module" "$base/app/driver/module" "$base/module"; do
      [ -d "$d/src" ] && { echo "$d"; return 0; }
    done
  done
  return 1
}

path_under() {
  local child="$1" parent="$2"
  [ -n "$parent" ] || return 1
  child="$(cd "$child" 2>/dev/null && pwd -P)" || return 1
  parent="$(cd "$parent" 2>/dev/null && pwd -P)" || return 1
  case "$child" in "$parent"|"$parent"/*) return 0 ;; *) return 1 ;; esac
}

validate_driver_src() {
  local src="$1" app_root legacy_root legacy_app_root
  app_root="${TRIM_APPDEST:-}"
  legacy_root="/usr/local/apps/@appcenter/${APP_NAME}"
  legacy_app_root="/usr/local/apps/@appcenter/${APP_NAME}/app"

  [ ! -L "$src" ] || fail "驱动源码目录不能是符号链接：$src"
  [ -f "$src/Makefile" ] && [ -d "$src/src" ] && [ -d "$src/include" ] || fail "驱动源码目录结构不完整：$src"

  if path_under "$src" "$app_root" || path_under "$src" "$legacy_root" || path_under "$src" "$legacy_app_root"; then
    return 0
  fi
  fail "驱动源码目录不在预期应用路径内：$src"
}

need_root() { [ "$(id -u)" = 0 ] || fail "需要 root 权限安装内核模块。"; }

ensure_deps() {
  local miss=0
  for c in make gcc modprobe depmod sed grep xargs find python3; do command -v "$c" >/dev/null 2>&1 || miss=1; done
  [ -d "/lib/modules/$(krel)/build" ] || miss=1
  if [ "$miss" = 0 ]; then return 0; fi
  if command -v apt-get >/dev/null 2>&1; then
    export DEBIAN_FRONTEND=noninteractive
    apt-get update || true
    apt-get install -y --no-install-recommends gcc make kmod xz-utils python3 "linux-headers-$(krel)" || \
      apt-get install -y --no-install-recommends gcc make kmod xz-utils python3 linux-headers-amd64 || true
  fi
  command -v make >/dev/null 2>&1 || fail "缺少 make。"
  command -v gcc >/dev/null 2>&1 || fail "缺少 gcc。"
  command -v python3 >/dev/null 2>&1 || fail "缺少 python3。"
  [ -d "/lib/modules/$(krel)/build" ] || fail "缺少当前内核头文件：/lib/modules/$(krel)/build。"
}

deps_missing() {
  for c in make gcc modprobe depmod sed grep xargs find python3; do command -v "$c" >/dev/null 2>&1 || return 0; done
  [ -d "/lib/modules/$(krel)/build" ] || return 0
  return 1
}

install_deps_text() {
  need_root
  if ! deps_missing; then
    echo "编译环境完整，无需补全依赖。"
    check_deps_text
    return 0
  fi
  echo "开始检查并补全依赖..."
  ensure_deps
  echo "依赖补全完成。"
  check_deps_text
}

patch_tree() {
  local s="$1"
  grep -RIl '<asm/unaligned.h>' "$s/src" "$s/include" 2>/dev/null | xargs -r sed -i 's#<asm/unaligned.h>#<linux/unaligned.h>#g'
  cat > "$s/src/clients/Kbuild" <<'EOF_KBUILD'
obj-m += surface_acpi_notify.o
obj-m += surface_aggregator_hub.o
obj-m += surface_aggregator_registry.o
obj-m += surface_battery.o
obj-m += surface_charger.o
EOF_KBUILD
  grep -q 'DCONFIG_SURFACE_AGGREGATOR_BUS' "$s/src/Kbuild" || printf '\nccflags-y += -DCONFIG_SURFACE_AGGREGATOR_BUS\n' >> "$s/src/Kbuild"
  python3 - "$s" <<'PY'
from pathlib import Path
import sys
root = Path(sys.argv[1])

p = root / 'include/linux/surface_aggregator/serial_hub.h'
t = p.read_text()
i = t.find('static inline u16 ssh_crc(const u8 *buf, size_t len)')
if i >= 0:
    b = t.find('{', i); depth = 0; e = b
    for n in range(b, len(t)):
        if t[n] == '{': depth += 1
        elif t[n] == '}':
            depth -= 1
            if depth == 0:
                e = n + 1; break
    repl = '''static inline u16 ssh_crc(const u8 *buf, size_t len)
{
\tu16 crc = 0xffff;
\tsize_t i;

\tfor (i = 0; i < len; i++) {
\t\tint bit;

\t\tcrc ^= (u16)buf[i] << 8;
\t\tfor (bit = 0; bit < 8; bit++)
\t\t\tcrc = (crc & 0x8000) ? (crc << 1) ^ 0x1021 : crc << 1;
\t}

\treturn crc;
}'''
    t = t[:i] + repl + t[e:]
p.write_text(t)

p = root / 'src/core.c'
t = p.read_text().replace('static int ssam_receive_buf(struct serdev_device *dev, const unsigned char *buf,', 'static size_t ssam_receive_buf(struct serdev_device *dev, const unsigned char *buf,')
p.write_text(t)

p = root / 'src/bus.c'
t = p.read_text()
t = t.replace('static int ssam_bus_match(struct device *dev, struct device_driver *drv)', 'static int ssam_bus_match(struct device *dev, const struct device_driver *drv)')
t = t.replace('struct ssam_device_driver *sdrv = to_ssam_device_driver(drv);', 'struct ssam_device_driver *sdrv = to_ssam_device_driver((struct device_driver *)drv);')
p.write_text(t)

for p in (root / 'src').rglob('*.c'):
    p.write_text(p.read_text().replace('no_llseek', 'noop_llseek'))

for rel, funcs in {
    'src/clients/surface_acpi_notify.c': ['san_remove'],
    'src/clients/surface_aggregator_registry.c': ['ssam_platform_hub_remove'],
}.items():
    p = root / rel
    if not p.exists():
        continue
    t = p.read_text()
    for fn in funcs:
        t = t.replace(f'static int {fn}(struct platform_device *pdev)', f'static void {fn}(struct platform_device *pdev)')
        i = t.find(f'static void {fn}(struct platform_device *pdev)')
        if i < 0: continue
        e = t.find('\n}\n\nstatic', i)
        if e < 0: e = t.find('\n}\n\nMODULE', i)
        if e < 0: continue
        e += 3
        t = t[:i] + t[i:e].replace('\n\treturn 0;', '') + t[e:]
    p.write_text(t)
PY
}

check_deps_text() {
  echo "kernel=$(krel)"
  for c in make gcc modprobe depmod sed grep xargs find python3; do
    if command -v "$c" >/dev/null 2>&1; then echo "$c=ok"; else echo "$c=missing"; fi
  done
  if [ -d "/lib/modules/$(krel)/build" ]; then echo "kernel_headers=ok"; else echo "kernel_headers=missing:/lib/modules/$(krel)/build"; fi
  if find_driver_src >/dev/null 2>&1; then echo "driver_source=$(find_driver_src)"; else echo "driver_source=missing"; fi
}

driver_install_status_text() {
  local md="$(moddir)" sd="$(srcdir)" conf="/etc/modules-load.d/surface-aggregator-module.conf"
  local ac_path
  echo "kernel=$(krel)"
  echo "module_dir=$md"
  echo "source_cache=$sd"
  [ -d "$sd" ] && echo "source_cache_status=ok" || echo "source_cache_status=missing"
  [ -f "$conf" ] && echo "autoload_config=ok:$conf" || echo "autoload_config=missing:$conf"
  for m in surface_aggregator surface_acpi_notify surface_aggregator_hub surface_aggregator_registry surface_battery surface_charger; do
    if find "$md" -type f \( -name "$m.ko" -o -name "$m.ko.*" \) 2>/dev/null | grep -q .; then
      echo "module_file_$m=ok"
    else
      echo "module_file_$m=missing"
    fi
  done
  if [ -r /sys/class/power_supply/BAT1/capacity ]; then echo "battery_device=ok:BAT1"; else echo "battery_device=missing:BAT1"; fi
  ac_path="$(find_ac_supply | head -n1)"
  if [ -n "$ac_path" ]; then echo "ac_device=ok:$(basename "$ac_path")"; else echo "ac_device=missing"; fi
}

driver_modules_installed() {
  local md="$(moddir)" m
  for m in surface_aggregator surface_acpi_notify surface_aggregator_hub surface_aggregator_registry surface_battery surface_charger; do
    find "$md" -type f \( -name "$m.ko" -o -name "$m.ko.*" \) 2>/dev/null | grep -q . || return 1
  done
  return 0
}

battery_status_text() {
  for d in /sys/class/power_supply/*; do
    [ -d "$d" ] || continue
    n="$(basename "$d")"
    t="$(cat "$d/type" 2>/dev/null || true)"
    case "$t" in Battery|Mains|USB|USB_C|USB_PD) ;; *) continue ;; esac
    echo "[$n]"
    echo "type=$t"
    for f in status capacity online present voltage_now power_now energy_now energy_full energy_full_design cycle_count time_to_full_now time_to_empty_now manufacturer model_name serial_number technology; do
      if [ -r "$d/$f" ]; then
        if [ "$f" = "serial_number" ]; then
          echo "$f=<redacted>"
        else
          echo "$f=$(cat "$d/$f" 2>/dev/null || true)"
        fi
      fi
    done
  done
}

build_install() {
  need_root
  if driver_modules_installed; then
    echo "驱动模块已全部安装；未执行重新编译。"
    driver_install_status_text
    return 0
  fi
  ensure_deps
  local src build="" md="$(moddir)" sd="$(srcdir)" backup="/root/${APP_NAME}-backup-$(date +%Y%m%d_%H%M%S)"
  build="$(mktemp -d -t "${APP_NAME}-build-$(krel)-XXXXXX")"
  trap "rm -rf '$build'" EXIT
  src="$(find_driver_src)" || fail "找不到驱动源码目录。"
  validate_driver_src "$src"
  log "使用驱动源码目录：$src"
  cp -a "$src/." "$build/"
  patch_tree "$build"
  make -C "$build" clean || true
  make -C "$build" all KVERSION="$(krel)"
  mkdir -p "$md" "$sd" "$backup"
  if find "$md" -type f -name '*.ko*' | grep -q .; then cp -a "$md" "$backup/updates-surface_aggregator_module"; fi
  install -m 0644 "$build/src/surface_aggregator.ko" "$md/"
  for m in surface_acpi_notify surface_aggregator_hub surface_aggregator_registry surface_battery surface_charger; do install -m 0644 "$build/src/clients/$m.ko" "$md/"; done
  rm -rf "$sd"/*; cp -a "$build/." "$sd/"
  depmod -a "$(krel)"
  cat > /etc/modules-load.d/surface-aggregator-module.conf <<'EOF_LOAD'
# Surface battery support via SSAM
surface_aggregator
surface_aggregator_hub
surface_acpi_notify
surface_battery
surface_charger
surface_aggregator_registry
battery
ac
EOF_LOAD
  load_driver
  [ -r /sys/class/power_supply/BAT1/capacity ] || fail "模块已安装但未检测到 BAT1。请查看 dmesg。"
  log "BAT1 $(cat /sys/class/power_supply/BAT1/capacity)% $(cat /sys/class/power_supply/BAT1/status 2>/dev/null || true)"
  if [ -n "$(find_ac_supply)" ]; then
    log "AC online=$(read_ac_online) supply=$(find_ac_supply)"
  else
    log "警告：未检测到 ADP1/AC 的 online 状态；系统可能无法判断是否接入直流电源。"
  fi
}

load_driver() { for m in $SSAM_LOAD; do modprobe "$m" 2>/dev/null || true; done; sleep 3; }
unload_driver() { for m in $SSAM_UNLOAD; do modprobe -r "$m" 2>/dev/null || true; done; }
remove_driver() { log "卸载管理器时保留已安装模块、源码缓存和开机加载配置不变。"; }
find_ac_supply() { for p in /sys/class/power_supply/ADP1 /sys/class/power_supply/AC /sys/class/power_supply/ACAD; do [ -r "$p/online" ] && { echo "$p"; return 0; }; done; find /sys/class/power_supply -maxdepth 2 -name online 2>/dev/null | while read -r f; do d="$(dirname "$f")"; t="$(cat "$d/type" 2>/dev/null || true)"; [ "$t" = "Mains" ] && { echo "$d"; break; }; done; }
read_ac_online() { local p; p="$(find_ac_supply | head -n1)"; [ -n "$p" ] && cat "$p/online" || echo "未知"; }
status_driver() { check_deps_text; echo; battery_status_text; [ -r /sys/class/power_supply/BAT1/capacity ] && exit 0; lsmod | grep -q '^surface_aggregator' && exit 1 || exit 3; }
