#!/bin/bash
set -euo pipefail

APP_NAME="surface_battery_driver"
LIB="/var/apps/${APP_NAME}/cmd/surface-driver-lib.sh"

require_post_platform_request() {
  if [ "${REQUEST_METHOD:-GET}" != "POST" ]; then
    echo "Status: 405 Method Not Allowed"
    echo "Content-Type: text/plain; charset=utf-8"
    echo ""
    echo "Use POST"
    exit 0
  fi
}

action=""
IFS='&' read -ra qs <<< "${QUERY_STRING:-}"
for kv in "${qs[@]}"; do
  case "$kv" in
    action=*) action="${kv#action=}" ;;
  esac
done

send_text() {
  echo "Content-Type: text/plain; charset=utf-8"
  echo "Cache-Control: no-store"
  echo ""
  local rc=0
  "$@" 2>&1 || rc=$?
  if [ "$rc" -ne 0 ]; then
    echo ""
    echo "__exit_code=$rc"
  fi
  return 0
}

case "$action" in
  status)
    send_text bash -lc ". '$LIB'; status_driver"
    exit 0
    ;;
  deps)
    send_text bash -lc ". '$LIB'; check_deps_text"
    exit 0
    ;;
  deps_install)
    if bash -lc ". '$LIB'; ! deps_missing"; then
      send_text bash -lc ". '$LIB'; echo '编译环境完整，无需补全依赖。'; check_deps_text"
      exit 0
    fi
    require_post_platform_request
    send_text bash -lc ". '$LIB'; install_deps_text"
    exit 0
    ;;
  driver)
    send_text bash -lc ". '$LIB'; driver_install_status_text"
    exit 0
    ;;
  battery)
    send_text bash -lc ". '$LIB'; battery_status_text"
    exit 0
    ;;
  compile)
    if bash -lc ". '$LIB'; driver_modules_installed"; then
      send_text bash -lc ". '$LIB'; echo '驱动模块已全部安装；未执行重新编译。'; driver_install_status_text"
      exit 0
    fi
    require_post_platform_request
    send_text bash -lc ". '$LIB'; build_install"
    exit 0
    ;;
esac

echo "Content-Type: text/html; charset=utf-8"
echo "Cache-Control: no-store"
echo ""

cat <<'EOF_HTML'
<!doctype html>
<html lang="zh-CN">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <title>Surface 电池驱动</title>
  <style>
    :root{font-family:Inter,-apple-system,BlinkMacSystemFont,"Segoe UI",sans-serif;color:#111827;background:#eef3fb;--bg:#eef3fb;--panel:#ffffff;--muted:#64748b;--line:#dbe4f0;--blue:#2563eb;--cyan:#06b6d4;--green:#10b981;--amber:#f59e0b;--red:#ef4444;--ink:#0f172a;--shadow:0 24px 60px rgba(15,23,42,.12)}
    *{box-sizing:border-box}body{margin:0;min-height:100vh;background:radial-gradient(circle at top left,#dbeafe,transparent 34%),linear-gradient(135deg,#f8fbff,#eef3fb);color:var(--ink)}
    .mobileBar,.scrim{display:none}.app{display:grid;grid-template-columns:250px 1fr;min-height:100vh}.side{padding:24px 18px;background:rgba(255,255,255,.72);backdrop-filter:blur(18px);border-right:1px solid rgba(219,228,240,.85);position:sticky;top:0;height:100vh;display:flex;flex-direction:column}.brand{display:flex;align-items:center;margin-bottom:28px}
    .brand b{display:block;font-size:16px}.brand span{display:block;color:var(--muted);font-size:12px;margin-top:2px}.nav{display:grid;gap:10px}.nav button{width:100%;border:0;border-radius:16px;padding:14px 15px;text-align:left;background:transparent;color:#334155;font-weight:750;cursor:pointer}.nav button.active{background:#0f172a;color:white;box-shadow:0 12px 24px rgba(15,23,42,.18)}.nav small{display:block;font-weight:600;opacity:.72;margin-top:4px}
    .main{padding:clamp(18px,2vw,30px);overflow:auto;min-width:0}.main>*{max-width:100%}.sideActions{margin-top:auto;display:grid;gap:10px}.sideActions .btn{width:100%;justify-content:center}.btn{border:0;border-radius:14px;padding:12px 16px;background:#e8eef8;color:#1e293b;font-weight:800;cursor:pointer}.btn.primary{background:linear-gradient(135deg,#2563eb,#06b6d4);color:white;box-shadow:0 14px 28px rgba(37,99,235,.25)}.btn:disabled{opacity:.55;cursor:not-allowed}
    .page{display:none}.page.active{display:block}.hero{display:grid;grid-template-columns:minmax(280px,.9fr) minmax(0,1.25fr);gap:18px;align-items:stretch;max-width:100%;min-height:calc(100vh - 220px)}.card{background:rgba(255,255,255,.86);border:1px solid rgba(219,228,240,.95);border-radius:28px;padding:clamp(18px,1.4vw,24px);box-shadow:var(--shadow);min-width:0}.batteryCard{display:grid;place-items:center;min-height:0;height:100%}.batteryShell{width:clamp(190px,15vw,270px);height:clamp(98px,7.7vw,134px);border:8px solid #0f172a;border-radius:26px;position:relative;background:#f8fafc}.batteryShell:after{content:"";position:absolute;right:-24px;top:31px;width:15px;height:34px;border-radius:0 10px 10px 0;background:#0f172a}.batteryFill{height:100%;width:0%;border-radius:17px;background:linear-gradient(90deg,#22c55e,#06b6d4);transition:.35s}.batteryPct{font-size:clamp(54px,5vw,84px);font-weight:900;letter-spacing:-.08em;margin-top:24px}.statusLine{display:flex;align-items:center;gap:10px;color:var(--muted);font-weight:750}.dot{width:11px;height:11px;border-radius:50%;background:var(--muted);box-shadow:0 0 0 6px rgba(100,116,139,.13)}.dot.ok{background:var(--green);box-shadow:0 0 0 6px rgba(16,185,129,.16)}.dot.warn{background:var(--amber);box-shadow:0 0 0 6px rgba(245,158,11,.18)}
    .grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(200px,1fr));gap:14px}.metric{padding:18px;border-radius:20px;background:#f8fafc;border:1px solid #e2e8f0}.metric label{display:block;color:var(--muted);font-size:12px;font-weight:800;text-transform:uppercase;letter-spacing:.06em}.metric strong{display:block;font-size:24px;margin-top:8px;overflow-wrap:anywhere}.sectionTitle{display:flex;align-items:center;justify-content:space-between;margin-bottom:14px}.sectionTitle h2{margin:0;font-size:18px}.pill{display:inline-flex;align-items:center;gap:7px;padding:7px 10px;border-radius:999px;background:#eff6ff;color:#1d4ed8;font-size:12px;font-weight:800}.live{background:#ecfdf5;color:#047857}.live:before{content:"";width:7px;height:7px;border-radius:50%;background:#10b981;box-shadow:0 0 0 5px rgba(16,185,129,.14)}.statusGrid{display:grid;grid-template-columns:repeat(auto-fit,minmax(230px,1fr));gap:14px}.check{padding:16px;border-radius:18px;background:#f8fafc;border:1px solid #e2e8f0}.check.ok{border-color:#a7f3d0;background:#ecfdf5}.check.bad{border-color:#fecaca;background:#fef2f2}.check.info{border-color:#cbd5e1;background:#f8fafc}.check b{display:block;margin-bottom:5px;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}.check span{color:var(--muted);font-size:13px;word-break:break-all}pre{white-space:pre-wrap;background:#0b1220;color:#dbeafe;border-radius:18px;padding:16px;min-height:90px;overflow:auto;font-size:13px;line-height:1.55}.statusCard{display:flex;flex-direction:column;min-height:0}.statusCard .grid{flex:0 0 auto}.statusCard .rawPreview{flex:1 1 auto;min-height:96px;max-height:none;margin-top:14px;overflow:hidden}.logCard{margin-top:18px}.modal{position:fixed;inset:0;background:rgba(15,23,42,.48);display:none;align-items:center;justify-content:center;padding:18px;z-index:50}.modal.show{display:flex}.modalPanel{width:min(920px,96vw);max-height:90vh;background:white;border-radius:26px;box-shadow:0 30px 90px rgba(15,23,42,.35);padding:18px 22px;border:1px solid #e2e8f0;display:flex;flex-direction:column;overflow:hidden}.modalHead{display:flex;align-items:center;justify-content:space-between;gap:16px;margin-bottom:10px;flex:0 0 auto}.modalHead h2{margin:0}.modalPanel pre{flex:1 1 auto;max-height:calc(90vh - 118px);overflow:auto;min-height:180px;margin:0;padding:14px 16px;line-height:1.35}.rawPreview{max-height:118px;min-height:92px;cursor:pointer;position:relative;overflow:hidden}.rawPreview:after{content:"";display:none}.systemPage pre{max-height:none;overflow:visible}.systemPage .rawPreview{cursor:default}.systemPage .rawPreview:after{display:none}.toast{position:fixed;left:24px;bottom:24px;z-index:70;display:grid;gap:10px}.toastItem{background:rgba(15,23,42,.94);color:white;border:1px solid rgba(255,255,255,.1);border-radius:18px;box-shadow:0 18px 45px rgba(15,23,42,.28);padding:14px 16px;min-width:300px;transform:translateY(12px) scale(.98);opacity:0;animation:toastIn .24s ease forwards}.toastItem.leaving{animation:toastOut .22s ease-in forwards}.toastItem div{color:#cbd5e1!important}@keyframes toastIn{to{transform:translateY(0) scale(1);opacity:1}}@keyframes toastOut{from{transform:translateY(0) scale(1);opacity:1}to{transform:translateY(10px) scale(.98);opacity:0}}.confirmActions{display:flex;gap:10px;justify-content:flex-end;margin-top:14px}.hidden{display:none!important}@media(max-width:1100px){.hero{grid-template-columns:1fr;min-height:0}.batteryCard{min-height:360px;height:auto}}@media(max-width:900px){body.drawerOpen{overflow:hidden}.mobileBar{display:flex;position:sticky;top:0;z-index:35;align-items:center;justify-content:space-between;gap:12px;padding:12px 14px;background:rgba(255,255,255,.86);backdrop-filter:blur(16px);border-bottom:1px solid rgba(219,228,240,.9)}.mobileBrand b{display:block;font-size:15px}.mobileBrand span{display:block;color:var(--muted);font-size:11px;margin-top:2px}.menuBtn{border:0;border-radius:14px;padding:10px 12px;background:#0f172a;color:#fff;font-weight:900;box-shadow:0 10px 24px rgba(15,23,42,.18)}.scrim{position:fixed;inset:0;background:rgba(15,23,42,.44);z-index:39;opacity:0;pointer-events:none;transition:.2s}.scrim.show{display:block;opacity:1;pointer-events:auto}.app{display:block;min-height:100vh}.side{position:fixed;left:0;top:0;bottom:0;width:min(82vw,300px);height:100vh;z-index:40;transform:translateX(-105%);transition:transform .22s ease;border-right:1px solid rgba(219,228,240,.95);box-shadow:28px 0 70px rgba(15,23,42,.22);background:rgba(255,255,255,.96);padding:22px 18px}.side.open{transform:translateX(0)}.sideActions{margin-top:auto}.main{padding:14px}.hero{grid-template-columns:1fr;gap:14px;min-height:0}.card{border-radius:22px;padding:16px}.batteryCard{min-height:280px;height:auto}.batteryShell{width:190px;height:96px;border-width:7px}.batteryShell:after{right:-20px;top:29px;width:13px;height:30px}.batteryPct{font-size:56px;margin-top:18px}.grid,.statusGrid{grid-template-columns:1fr}.metric strong{font-size:22px}.sectionTitle{align-items:flex-start;gap:10px}.pill{font-size:11px}.modalPanel{width:96vw;border-radius:22px;padding:16px}.toast{left:14px;right:14px;bottom:14px}.toastItem{min-width:0;width:100%}}
  </style>
</head>
<body>
<div class="mobileBar"><button class="menuBtn" onclick="openDrawer()">☰ 菜单</button><div class="mobileBrand"><b>Surface 电池驱动</b><span>SSAM Battery Manager</span></div></div>
<div id="drawerScrim" class="scrim" onclick="closeDrawer()"></div>
<div class="app">
  <aside id="sidebar" class="side">
    <div class="brand"><div><b>Surface 电池驱动</b><span>SSAM Battery Manager</span></div></div>
    <nav class="nav">
      <button id="navBattery" class="active" onclick="switchPage('batteryPage')">电池状态<small>容量、充放电、供电来源</small></button>
      <button id="navSystem" onclick="switchPage('systemPage')">依赖与驱动<small>依赖状态、编译安装状态</small></button>
    </nav>
    <div class="sideActions"><button class="btn" onclick="refreshAll()">刷新状态</button><button id="compileBtn" class="btn primary" onclick="compileInstall()">编译并安装驱动</button></div>
  </aside>
  <main class="main">
    <section id="batteryPage" class="page batteryPageFull active">
      <div class="hero">
        <div class="card batteryCard"><div><div class="batteryShell"><div id="batteryFill" class="batteryFill"></div></div><div id="batteryPct" class="batteryPct">--%</div><div class="statusLine"><i id="powerDot" class="dot"></i><span id="powerText">读取中...</span></div></div></div>
        <div class="card statusCard"><div class="sectionTitle"><h2>电池状态</h2><span id="liveText" class="pill live">实时刷新 5s</span></div><div class="grid"><div class="metric"><label>电池健康度</label><strong id="metricHealth">--</strong></div><div class="metric"><label>供电来源</label><strong id="metricPower">--</strong></div><div class="metric"><label>电池设备</label><strong id="metricBattery">--</strong></div><div class="metric"><label>型号</label><strong id="metricModel">--</strong></div><div class="metric"><label>厂商</label><strong id="metricVendor">--</strong></div><div class="metric"><label>技术类型</label><strong id="metricTech">--</strong></div><div class="metric"><label>当前能量</label><strong id="metricEnergyNow">--</strong></div><div class="metric"><label>当前满电容量</label><strong id="metricFullWh">--</strong></div><div class="metric"><label>设计容量</label><strong id="metricDesignWh">--</strong></div><div class="metric"><label>电压</label><strong id="metricVoltage">--</strong></div><div class="metric"><label>充放电功率</label><strong id="metricRate">--</strong></div><div class="metric"><label>循环次数</label><strong id="metricCycles">--</strong></div><div class="metric"><label>续航估算</label><strong id="metricRuntime">--</strong></div></div><pre id="batteryRaw" class="rawPreview">加载中...</pre></div>
      </div>
    </section>
    <section id="systemPage" class="page systemPage">
      <div class="card"><div class="sectionTitle"><h2>所需依赖状态</h2><button id="depsBtn" class="btn primary" onclick="installDeps()">补全依赖</button></div><div id="depsCards" class="statusGrid"></div><pre id="depsRaw" class="rawFull">加载中...</pre></div>
      <div class="card logCard"><div class="sectionTitle"><h2>驱动编译 / 安装状态</h2><span class="pill">SSAM battery + charger</span></div><div id="driverCards" class="statusGrid"></div><pre id="driverRaw" class="rawFull">加载中...</pre></div>
    </section>
  </main>
</div>
<div id="compileModal" class="modal" onclick="if(event.target===this) closeCompileModal()">
  <div class="modalPanel">
    <div class="modalHead"><h2 id="logTitle">编译安装日志</h2><button class="btn" onclick="closeCompileModal()">关闭</button></div>
    <pre id="log">尚未执行。</pre>
  </div>
</div>
<div id="confirmModal" class="modal" onclick="if(event.target===this) closeConfirmModal(false)">
  <div class="modalPanel" style="max-width:520px">
    <div class="modalHead"><h2>确认首次编译安装？</h2></div>
    <p style="color:#64748b;margin:0">编译安装会以 root 权限安装内核模块并写入开机加载配置，可能影响系统稳定性。请确认已了解风险后继续。</p>
    <div class="confirmActions"><button class="btn" onclick="closeConfirmModal(false)">取消</button><button class="btn primary" onclick="closeConfirmModal(true)">确认安装</button></div>
  </div>
</div>
<div id="toast" class="toast"></div>
<script>
const base = location.pathname.endsWith('/') ? location.pathname : location.pathname + '/';
async function api(action, opts={}){ const init={cache:'no-store',credentials:'same-origin',...opts}; const r = await fetch(base + '?action=' + encodeURIComponent(action), init); return await r.text(); }
async function apiStream(action, opts={}, onChunk=()=>{}){ const init={cache:'no-store',credentials:'same-origin',...opts}; const r=await fetch(base+'?action='+encodeURIComponent(action),init); if(!r.body){ const text=await r.text(); onChunk(text,text); return text; } const reader=r.body.getReader(); const decoder=new TextDecoder(); let out=''; while(true){ const {done,value}=await reader.read(); if(done) break; const chunk=decoder.decode(value,{stream:true}); if(chunk){ out+=chunk; onChunk(chunk,out); } } const tail=decoder.decode(); if(tail){ out+=tail; onChunk(tail,out); } return out; }
function parseKV(text){ const out={sections:{}}; let sec='root'; text.split(/\r?\n/).forEach(line=>{ if(!line.trim())return; const m=line.match(/^\[(.+)\]$/); if(m){sec=m[1]; out.sections[sec]={}; return;} const i=line.indexOf('='); if(i>0){(out.sections[sec] ||= {})[line.slice(0,i)] = line.slice(i+1); out[line.slice(0,i)] = line.slice(i+1);}}); return out; }
function esc(v){ return String(v).replace(/[&<>"']/g,ch=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[ch])); }
function friendlyLabel(label){ return label.replace('module_file_','文件 · ').replace('source_cache_status','源码缓存').replace('autoload_config','开机加载配置').replace('battery_device','电池设备').replace('ac_device','适配器设备').replace(/_/g,' '); }
function card(label,value){ const cls=value.includes('ok')||value.includes('=ok')?'ok':(value.includes('missing')||value.includes('缺少')?'bad':'info'); return `<div class="check ${cls}" title="${esc(label)}: ${esc(value)}"><b>${esc(friendlyLabel(label))}</b><span>${esc(value)}</span></div>`; }
function openDrawer(){ document.body.classList.add('drawerOpen'); document.getElementById('sidebar').classList.add('open'); document.getElementById('drawerScrim').classList.add('show'); }
function closeDrawer(){ document.body.classList.remove('drawerOpen'); document.getElementById('sidebar').classList.remove('open'); document.getElementById('drawerScrim').classList.remove('show'); }
function switchPage(id){ document.querySelectorAll('.page').forEach(p=>p.classList.toggle('active',p.id===id)); document.getElementById('navBattery').classList.toggle('active',id==='batteryPage'); document.getElementById('navSystem').classList.toggle('active',id==='systemPage'); closeDrawer(); }
let driverInstalled=false;
let depsReady=false;
function openCompileModal(title='编译安装日志'){ document.getElementById('logTitle').textContent=title; document.getElementById('compileModal').classList.add('show'); }
function closeCompileModal(){ document.getElementById('compileModal').classList.remove('show'); }
function toast(title,detail='',ms=2800){ const box=document.getElementById('toast'); const el=document.createElement('div'); el.className='toastItem'; const b=document.createElement('b'); b.textContent=title; el.appendChild(b); if(detail){ const d=document.createElement('div'); d.style.marginTop='4px'; d.textContent=detail; el.appendChild(d); } box.appendChild(el); setTimeout(()=>{ el.classList.add('leaving'); setTimeout(()=>el.remove(),260); },ms); }
function askFirstCompile(){ return new Promise(resolve=>{ window.__confirmCompile=resolve; document.getElementById('confirmModal').classList.add('show'); }); }
function closeConfirmModal(ok){ document.getElementById('confirmModal').classList.remove('show'); if(window.__confirmCompile){ window.__confirmCompile(ok); window.__confirmCompile=null; } }
function rawWh(v){ const n=parseFloat(v||'0'); return n>0?n/1000000:0; }
function whText(v){ const wh=rawWh(v); return wh>0?wh.toFixed(1)+' Wh':'未知'; }
function voltageText(v){ const n=parseFloat(v||'0'); return n>0?(n/1000000).toFixed(2)+' V':'未知'; }
function powerW(bat){ const p=parseFloat(bat.power_now||'0'); return p>0?p/1000000:0; }
function rateText(bat){ const w=powerW(bat); return w>0?w.toFixed(1)+' W':'未知'; }
function energyNowText(bat){ return whText(bat.energy_now); }
function cyclesText(v){ const n=parseInt(v||'0',10); return n>0?String(n):'未知'; }
function cleanText(v){ return v&&v!=='<redacted>'?v:'未知'; }
const powerSamples=[];
function avgPowerW(sample){ const now=Date.now(); if(sample>0) powerSamples.push({t:now,w:sample}); while(powerSamples.length && now-powerSamples[0].t>60000) powerSamples.shift(); if(!powerSamples.length) return sample; return powerSamples.reduce((sum,x)=>sum+x.w,0)/powerSamples.length; }
function runtimeText(bat, online){ const p=avgPowerW(powerW(bat)); const now=rawWh(bat.energy_now); if(p<=0||now<=0) return '未知'; const h=now/p; if(!isFinite(h)||h<=0) return '未知'; const hr=Math.floor(h), min=Math.round((h-hr)*60); return `${hr}h ${String(min).padStart(2,'0')}m`; }
function powerStatusText(hasBattery, hasAc, online, status){ if(!hasBattery && !hasAc) return '未知'; const s=(status||'').toLowerCase(); if(hasAc && online){ if(s==='charging') return '正在充电'; if(s==='full') return '已充满 / 外接电源'; if(s==='not charging') return '外接供电（未充电）'; return '外接电源'; } if(hasBattery){ if(s==='discharging') return '电池供电 / 放电中'; if(!hasAc) return '未知'; return '电池供电'; } return '未知'; }
function calcHealth(bat){ const full=parseFloat(bat.energy_full||'0'); const design=parseFloat(bat.energy_full_design||'0'); if(full>0&&design>0) return Math.max(0,Math.min(100,Math.round(full/design*100)))+'%'; return '未知'; }
async function batterySummary(){ const text=await api('battery'); const data=parseKV(text); const batName=Object.keys(data.sections).find(k=>(data.sections[k].type||'').toLowerCase()==='battery')||'BAT1'; const bat=data.sections[batName]||{}; const acName=Object.keys(data.sections).find(k=>['mains','usb','usb_c','usb_pd'].includes((data.sections[k].type||'').toLowerCase())); const ac=acName?data.sections[acName]:{}; return `${bat.capacity?bat.capacity+'%':'电量未知'} · ${ac.online==='1'?'已连接电源':'未连接电源'}`; }
async function loadBattery(){ const text=await api('battery'); const rawEl=document.getElementById('batteryRaw'); rawEl.textContent=text||'未检测到 power_supply 数据。'; const data=parseKV(text); const batName=Object.keys(data.sections).find(k=>(data.sections[k].type||'').toLowerCase()==='battery'); const hasBattery=!!batName; const bat=hasBattery?data.sections[batName]:{}; const acName=Object.keys(data.sections).find(k=>['mains','usb','usb_c','usb_pd'].includes((data.sections[k].type||'').toLowerCase())); const hasAc=!!acName; const ac=hasAc?data.sections[acName]:{}; const cap=Math.max(0,Math.min(100,parseInt(bat.capacity||'0',10)||0)); const status=bat.status||''; const online=ac.online==='1'; document.getElementById('batteryFill').style.width=hasBattery&&bat.capacity?cap+'%':'0%'; document.getElementById('batteryPct').textContent=hasBattery&&bat.capacity?cap+'%':'--%'; document.getElementById('metricHealth').textContent=calcHealth(bat); document.getElementById('metricPower').textContent=hasAc?(online?'外接电源':(hasBattery?'电池供电':'未知')):'未知'; document.getElementById('metricBattery').textContent=hasBattery?batName:'未检测到'; document.getElementById('metricModel').textContent=cleanText(bat.model_name); document.getElementById('metricVendor').textContent=cleanText(bat.manufacturer); document.getElementById('metricTech').textContent=cleanText(bat.technology); document.getElementById('metricEnergyNow').textContent=energyNowText(bat); document.getElementById('metricFullWh').textContent=whText(bat.energy_full); document.getElementById('metricDesignWh').textContent=whText(bat.energy_full_design); document.getElementById('metricVoltage').textContent=voltageText(bat.voltage_now); document.getElementById('metricRate').textContent=rateText(bat); document.getElementById('metricCycles').textContent=cyclesText(bat.cycle_count); document.getElementById('metricRuntime').textContent=hasBattery?runtimeText(bat, online):'未知'; const pText=powerStatusText(hasBattery,hasAc,online,status); document.getElementById('powerText').textContent=pText; document.getElementById('powerDot').className='dot '+(pText==='未知'?'':(online?'ok':'warn')); refreshCountdown=5; updateLiveText(); }
async function loadDeps(){ const text=await api('deps'); document.getElementById('depsRaw').textContent=text; const data=parseKV(text); const labels=['make','gcc','modprobe','depmod','sed','grep','xargs','find','python3','kernel_headers','driver_source']; document.getElementById('depsCards').innerHTML=labels.map(k=>card(k,data[k]||'missing')).join(''); depsReady=depsAllOk(text); const btn=document.getElementById('depsBtn'); btn.textContent=depsReady?'依赖完整':'补全依赖'; btn.disabled=depsReady; }
function depsAllOk(text){ const data=parseKV(text); const labels=['make','gcc','modprobe','depmod','sed','grep','xargs','find','python3','kernel_headers','driver_source']; return labels.every(k=>(data[k]||'').includes('ok') || (k==='driver_source' && data[k] && !data[k].includes('missing'))); }
async function installDeps(){ if(depsReady){ toast('编译环境完整','依赖和驱动源码均已就绪。'); return; } const current=await api('deps'); if(depsAllOk(current)){ document.getElementById('depsRaw').textContent=current; toast('编译环境完整','依赖和驱动源码均已就绪。'); await loadDeps(); return; } openCompileModal('补全依赖日志'); const log=document.getElementById('log'); log.textContent='开始补全依赖，请等待...\n'; document.querySelectorAll('button').forEach(b=>b.disabled=true); try{ await apiStream('deps_install',{method:'POST'},chunk=>{ log.textContent+=chunk; log.scrollTop=log.scrollHeight; }); await loadDeps(); if(depsReady){ toast('依赖补全完成','编译环境已就绪。'); } else { toast('依赖补全结束','仍有缺失项，请查看日志。'); } } finally{ document.querySelectorAll('button').forEach(b=>b.disabled=false); } }
async function loadDriver(){ const text=await api('driver'); document.getElementById('driverRaw').textContent=text; const data=parseKV(text); const required=['surface_aggregator','surface_acpi_notify','surface_aggregator_hub','surface_aggregator_registry','surface_battery','surface_charger']; driverInstalled=required.every(m=>(data['module_file_'+m]||'').includes('ok')); const btn=document.getElementById('compileBtn'); btn.textContent=driverInstalled?'驱动已安装':'编译并安装驱动'; btn.disabled=driverInstalled; const keys=Object.keys(data).filter(k=>k!=='sections'&&(/source_cache_status|autoload_config|battery_device|ac_device|module_file_surface_(aggregator|acpi_notify|aggregator_hub|aggregator_registry|battery|charger)$/.test(k))); document.getElementById('driverCards').innerHTML=keys.map(k=>card(k,data[k])).join(''); }
async function refreshAll(){ await Promise.all([loadBattery(), loadDeps(), loadDriver()]); }
async function compileInstall(){
  if(driverInstalled){ toast('驱动已安装','模块齐全，无需重新编译。'); return; }
  if(!(await askFirstCompile())) return;
  openCompileModal('编译安装日志');
  const log=document.getElementById('log'); log.textContent='开始编译安装，请等待...';
  document.querySelectorAll('button').forEach(b=>b.disabled=true);
  try{ await apiStream('compile',{method:'POST'},chunk=>{ log.textContent+=chunk; log.scrollTop=log.scrollHeight; }); await refreshAll(); if(driverInstalled){ toast('驱动安装完成', await batterySummary()); } else { toast('编译安装结束','仍有异常，请查看日志。'); } }
  finally{ document.querySelectorAll('button').forEach(b=>b.disabled=false); }
}
let refreshCountdown=5;
function updateLiveText(){ document.getElementById('liveText').textContent='实时刷新 · '+refreshCountdown+'s'; }
refreshAll();
setInterval(()=>{ if(document.hidden) return; refreshCountdown=Math.max(0, refreshCountdown-1); updateLiveText(); if(refreshCountdown===0) loadBattery(); }, 1000);
document.addEventListener('visibilitychange',()=>{ if(!document.hidden){ refreshCountdown=1; updateLiveText(); } });
document.addEventListener('keydown',e=>{ if(e.key==='Escape') closeDrawer(); });
</script>
</body>
</html>
EOF_HTML
