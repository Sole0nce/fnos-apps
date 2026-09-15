#!/usr/bin/env node
// fnOS Apps 更新中心 —— 版本对比模块
// 对比“我的应用”的本地已装版本 vs fork (Sole0nce/fnos-apps) apps.json 中的最新版本。
// 用法:
//   node scripts/fnos-check-updates.mjs            # 联网拉取 apps.json，从 fnOS 读取已装版本
//   node scripts/fnos-check-updates.mjs --dry      # 本地演示模式: 使用 env 注入的“已装版本”打印表格
import { env, stdin } from 'node:process';

// 覆盖范围: 只检查“我的应用”(main_custom 分支维护的自有应用)
const MY_APPS = [
  'docker-gsmanager',        // GSManager
  'hermes',                  // Hermes-容器版
  'hermes-agent-native',     // Hermes-原生版
  'mcsmanager',              // MCSManager
  'hermes-agent-veenyi',     // Hermes Agent (veenyi)
  'hermes-agent-bbis',       // Hermes Agent (bbis)
  'hermes-studio',           // Hermes Studio
  'MSLX',
];

const GITHUB = 'Sole0nce';
const REPO = 'fnos-apps';
const BRANCH = 'main_custom';
const APPS_JSON_URL = `https://raw.githubusercontent.com/${GITHUB}/${REPO}/${BRANCH}/apps.json`;

// ---- 版本比较 (语义化 + rev后缀兼容) ----
function parseNum(s) {
  const n = Number(s);
  return Number.isFinite(n) ? n : 0;
}
// 形如: 1.6.2 、 0.21.96 、 0.19.0-50 、 1.10.34-lts-r12
// 归一化成主版本数组，末尾 rev/rN 附加比较。
function splitVer(s) {
  const base = String(s).trim();
  const revM = base.match(/[-.]r(\d+)$/i);
  const bs = revM ? base.slice(0, revM.index) : base;
  const rev = revM ? parseInt(revM[1], 10) : 0;
  const nums = bs
    .replace(/[^0-9.]+/g, '.')
    .split('.')
    .filter((t) => t !== '')
    .map(parseNum);
  return { nums, rev };
}
function cmp(a, b) {
  const A = splitVer(a);
  const B = splitVer(b);
  const n = Math.max(A.nums.length, B.nums.length);
  for (let i = 0; i < n; i++) {
    const d = (A.nums[i] ?? 0) - (B.nums[i] ?? 0);
    if (d !== 0) return d > 0 ? 1 : -1;
  }
  return A.rev - B.rev;
}

// ---- 读取已装版本。真机上从 fnOS 应用状态读取；此处预留接口 ----
//   dry 模式: 来自 env 变量, 例:
//   FNOS_INSTALLED='MSLX=1.5.9,hermes-studio=0.6.39-1' node scripts/fnos-check-updates.mjs --dry
async function readInstalled(realMode) {
  const map = {};
  if (!realMode) {
    parseEnv(map);
    return map;
  }
  // TODO(联调): 从 /usr/trim 应用数据库或 `trim_app_center` 读已装版本。
  // 当前先回退到 env。
  parseEnv(map);
  return map;
}
function parseEnv(map) {
  const raw = env.FNOS_INSTALLED;
  if (!raw) return;
  for (const pair of raw.split(',')) {
    const [k, v] = pair.trim().split('=');
    if (k && v) map[k] = v;
  }
}

// ---- 拉取 apps.json ----
async function fetchLatest() {
  const res = await fetch(APPS_JSON_URL, { signal: AbortSignal.timeout(15000) });
  if (!res.ok) throw new Error(`HTTP ${res.status} ${APPS_JSON_URL}`);
  const data = await res.json();
  const bySlug = new Map((data.apps || []).map((a) => [a.slug, a]));
  const out = {};
  for (const slug of MY_APPS) {
    const a = bySlug.get(slug);
    if (a) {
      out[slug] = { version: a.version, fpk_version: a.fpk_version, release_tag: a.release_tag, platforms: a.platforms, updated_at: a.updated_at, display_name: a.display_name };
    }
  }
  return out;
}

function pad(s, n) { s = String(s); return s.length >= n ? s : s + ' '.repeat(n - s.length); }

async function main() {
  const realMode = !process.argv.includes('--dry');
  const latest = await fetchLatest();
  const installed = await readInstalled(realMode);

  console.log(`比对源: ${APPS_JSON_URL}\n`);
  console.log(`${pad('应用', 26)}${pad('最新版(fork)', 16)}${pad('本地已装', 14)}${pad('平台', 10)}状态`);
  console.log('-'.repeat(78));
  let updates = 0;
  for (const slug of MY_APPS) {
    const L = latest[slug];
    const inst = installed[slug];
    if (!L) { console.log(`${pad(slug, 26)}${pad('(fork 未收录)', 16)}${pad(inst || '(未装)', 14)}${pad('-', 10)}-`); continue; }
    let status = '已是最新';
    if (!inst) { status = '未安装'; }
    else if (cmp(L.version, inst) > 0) { status = `⬆ 可升级 (${inst} → ${L.version})`; updates++; }
    console.log(`${pad(L.display_name || slug, 26)}${pad(L.version, 16)}${pad(inst || '(未装)', 14)}${pad((L.platforms || []).join('/'), 10)}${status}`);
  }
  console.log(`\n可升级应用: ${updates} 个`);
}

main().then(() => process.exit(0)).catch((e) => { console.error(e.message); process.exit(1); });