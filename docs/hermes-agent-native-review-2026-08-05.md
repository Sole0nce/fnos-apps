# hermes-agent-native 审查报告（2026-08-05）

**审查对象**：`Sole0nce/fnos-apps` `main_custom` 分支 hermes-agent-native 应用从方案设计到 NAS 实装的完整闭环
**审查时间**：2026-08-05
**结论**：✅ **端到端可用** — 版本跟踪、CI 构建、商店发布、NAS 安装、Web 前端渲染全链路验证通过

---

## 1. 目标回顾

| 目标 | 状态 |
|------|------|
| 跟随官方 GitHub release tag 构建（非 PyPI、非 main） | ✅ 已落地 |
| 版本号 = tag 日期点号格式（`2026.8.3`） | ✅ 已落地 |
| 每日 cron `0 8 * * *` 自动构建 | ✅ 沿用既有流水线（未改） |
| 零联网安装（CI 预打包 runtime.tgz） | ✅ 已落地 |
| 在这台 NAS（192.168.0.3，QEMU VM）真正装上、能用 | ✅ 已实装 2026.8.3-r2 且 Web UI 正常 |

## 2. 提交链（main_custom，5 个核心 commit）

```
6f9d878 [verified] hermes-agent-native: track official GitHub release tag instead of PyPI
defecab [verified] hermes-agent-native: set HERMES_NIX_BUILD=1 for git-tag wheel build
1e90748 [verified] hermes-agent-native: run-as root so it installs on this fnOS
1da7bd8 [verified] hermes-agent-native: build web frontend into venv
（穿插 3 个 CI 自动 "chore: update apps.json [skip ci]"）
```

## 3. 核心决策链

### 3.1 版本源：B' 方案（官方 release tag，不走 PyPI）

- 上游 `setup.py` 明确声明 wheel 已不再受支持的分发方式，PyPI 同步滞后（v2026.8.3 = 0.20.0，PyPI 最新仍 0.19.0）
- **决定**：`get-latest-version.sh` 解析 `api.github.com/releases/latest` 的 `tag_name`，纯 grep/sed（零 python 依赖），`^[0-9]{4}\.[0-9]{1,2}\.[0-9]{1,2}$` fail-fast 校验 + `ls-remote` 兜底
- `build.sh` 安装命令改为 `uv pip install "hermes-agent[all] @ git+...@v${VERSION}"`

### 3.2 构建门卫：`HERMES_NIX_BUILD=1`（官方预留后门）

- **撞墙**：上游 `setup.py` 对 `bdist_wheel`/`sdist` 硬性 guard（`RuntimeError: Building wheels or sdists for hermes-agent is not supported`），CI 首次构建失败（#30926752385）
- **发现**：guard 逻辑 `_IN_NIX_BUILD = os.environ.get("HERMES_NIX_BUILD") == "1"` — 上游 Nix 打包自己就用这个环境变量
- **先本地双向实测再改**：不设变量复现失败；设 `HERMES_NIX_BUILD=1 uv build --wheel` 成功产出 `hermes_agent-0.20.0-py3-none-any.whl`
- CI #30929123503 全绿 → release `v2026.8.3` + fpk 产出

### 3.3 run-as: root（本 NAS 安装硬约束，用户拍板方案 B）

- 本 NAS（QEMU VM）所有 `run-as: package` 应用必装失败（`APP_INSTALL_FAILED_INSTALL_INIT_EXCEPTION`、`APP_USERNAME=""`）；成功安装的 turbo/1Panel/Sun-Panel 全为 root
- **决定**：仅改 `apps/hermes-agent-native/fnos/config/privilege` → `"run-as":"root"`（全仓库方案 A 与 NAS 打补丁方案 C 弃用；用户知悉并同意偏离官方安全设计）
- 同 tag 重发走 `resolve-release-tag.sh` 的 `-rN` 修订机制 → `v2026.8.3-r1`（CI #30932295218 全绿）

### 3.4 Web 前端：wheel 不带 web_dist，必须自己构建（本次焦点）

- **根因**：上游 setup.py 注释明确 — wheel **故意不打包** web_dist/tui_dist 等运行时资源（"resolved at runtime"）；`web_server.py` 的 `WEB_DIST = Path(__file__).parent / "web_dist"` 找不到产物即返回 `{"error":"Frontend not built. Run: cd web && npm run build"}`
- **修复**（build.sh 新增 2b 步）：浅克隆 tag → 用打包的 node 在 `web/` 执行 `npm ci && npm run build` → vite outDir 正好是 `../hermes_cli/web_dist`（与后端查找路径天然吻合）→ 复制进 `$WORK_DIR/runtime/python/lib/python3.11/site-packages/hermes_cli/`
- **两个坑**（都曾踩中）：node 必须在 web 构建**之前**下载就位；复制目标是 `$WORK_DIR/runtime/...` 的**打包副本**而非 `$UV_PY_DIR_REAL`（后者不进 runtime.tgz）
- CI 日志实证：`==> Building web frontend (v2026.8.3)` → vite 输出 web_dist assets → 构建成功
- 重发 → `v2026.8.3-r2`（154,179,431 B）

## 4. 安装链路问题排查（用户侧现象 → 根因）

### 4.1 "商店一直显示 v0.19.0-r11" → 旧 release 已被清理 + 构建失败无产物

- 根因链：CI 构建失败（上游 guard）无新产物 → 旧 `v0.19.0-r11` release 被 CI 版本清理（MAX_VERSIONS=3）删除 → 缓存 apps.json 指向已删 release
- 修复：`HERMES_NIX_BUILD=1` 后新 release 产出；`POST /api/check` 刷新商店缓存（非破坏性，替代 pkill/删缓存）

### 4.2 "点安装一直加载" → 152MB fpk 下载极慢，不是卡死

- 真相：SSE 流实测 `total: 152,676,883` 正在下载，gh-proxy 默认镜像仅 ~26-104KB/s → 25-90 分钟，UI 表现为永远 loading
- 镜像吞吐实测（14s 采样）：`direct ~147KB/s > ghproxy-net ~142 > ghfast ~138 > gh-ddlc ~78 > gh-proxy ~26-104`
- 切 `direct` 后全量下载实测 **~255-280KB/s**（连接升温后约为采样的 1.5-2 倍），152MB ≈ 9 分钟
- 注意：SSE 安装流绑定发起者连接，curl 断开即取消 — 长连接后台 curl 可完整驱动安装/升级（本报告 4.4 即以此完成）

### 4.3 "执行应用初始化脚本异常" → run-as=package 必失败（已修，见 3.3）

### 4.4 "应用安装存储空间不可用" → 默认卷 vol2 已删

- NAS 只有 vol1（vol2 errno 65280 不存在）；fnOS 原生应用中心路径报此错
- 商店路径 `install_volume:0` 自动 fallback 到唯一挂载卷 vol1，不受影响

### 4.5 "上次为什么没装成功" → 静默失败 + 一次重试即成功

- 证据链：未安装、系统日志无安装记录、`@appdata/hermes-agent-native/` 空目录、`appcenter-downloads` 残留 279KB app.tgz（≠152MB 发布包，即下载中断残留）
- 结论：安装尝试在应用中心静默中止（无失败日志）；**长连接 curl 重试一次即完整成功**（downloading 100% → installing → verifying → starting → done，系统日志 `应用 Hermes-原生版 启用成功`）

## 5. 最终验证（全部实测）

| 验证项 | 结果 |
|--------|------|
| CI 构建（web 步骤） | ✅ 日志确认 vite 产出 web_dist assets |
| GitHub release | ✅ `hermes-agent-native/v2026.8.3-r2` + `hermes-agent-native_2026.8.3-r2_x86.fpk`（154,179,431 B） |
| apps.json | ✅ `fpk_version: 2026.8.3-r2`（gh api 直读，非 CDN） |
| 商店识别 | ✅ `updates_available: 1`、`installed: 2026.8.3` |
| NAS 升级安装 | ✅ SSE `{"step":"done","new_version":"2026.8.3-r2"}`；系统日志 `更新成功` + `启用成功` |
| 应用状态 | ✅ Hermes-原生版 2026.8.3 已启用（isOpen: True） |
| **Web 前端** | ✅ 返回完整 Dashboard HTML（`<title>Hermes Agent - Dashboard</title>` + assets 正常引用），不再报 Frontend not built |

## 6. 遗留风险（知悉即可）

| 风险 | 说明 | 处置 |
|------|------|------|
| run-as: root | 偏离官方安全设计（应用以 root 运行） | 用户知情同意；单机自用可接受 |
| `platform:"x86,arm"` 声明 vs 仅 x86 asset | arm 安装将 404 | 本 NAS 为 x86，不影响；如未来有 arm NAS 需补 arm 构建 |
| 商店 `release_url` 硬编码 conversun 仓库 | 仅显示用，下载 base 实为 Sole0nce | 已知坑，不动 |
| 152MB @ ~255KB/s 仍需 ~9 分钟 | NAS 到国际带宽墙（QEMU VM），任何镜像无法突破 | 已切 direct 最优；大包下载需耐心或换用本机下载 fpk 后离线安装 |
| CI 全量重建触发 rate limit | 修改 shared/ 或 scripts/ 会重建 148 应用 | 本次全程只改 apps/hermes-agent-native + scripts/apps/hermes-agent-native，未触碰共享路径 |
| 上游 web 前端随版本演进 | 每次新 tag 构建自动重编前端（build.sh 2b 步） | 已内建，无需手工干预 |

## 7. 经验沉淀

1. **先本地复现再改 CI**：guard 撞墙后先本地 `HERMES_NIX_BUILD=1 uv build --wheel` 双向实测，避免再推一次失败构建
2. **读取权威源**：apps.json 用 `gh api .../contents/...` base64 直读，raw.githubusercontent CDN 缓存滞后会误导判断
3. **"一直加载"先测吞吐再怀疑包**：`curl -sN` SSE 探针读取真实 `speed` 字段，镜像排名用吞吐不用延迟
4. **SSE 连接即安装生命线**：长连接后台 curl 可完整驱动安装/升级（agent 不需要用户手动点 UI）
5. **wheel 不带 web_dist 是上游设计**：凡 pip/uv 从源码安装 hermes，必须自行构建 SPA 并放进 `hermes_cli/web_dist/`
6. **静默安装失败先重试**：无日志的安装中止，一次重试往往直接成功，再深挖不迟

---

*报告由 Hermes Agent 于 2026-08-05 生成，所有验证项均为实际工具输出。*
