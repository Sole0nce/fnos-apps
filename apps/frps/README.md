# FRP Server (fnOS)

高性能内网穿透服务端 frps：把内网服务经 NAS/公网机暴露出去，配合任意 frpc 客户端使用。

- 上游：<https://github.com/fatedier/frp>（仅打包 frps；frpc 属客户端，按需在任意机器单独部署）
- 打包模式：原生（双架构 amd64/arm64）
- 端口：`7000`（隧道）+ `7500`（Web 管理面板）
- 配置：应用数据目录 `frps.toml`，首装自动生成；面板账号 `admin`，随机密码见应用日志（`/var/log/apps/frps.log` 与数据目录日志）
- 鉴权 token：安装向导可选填，等价于在 `frps.toml` 中启用 `auth.token`

## 本地构建

```bash
cd apps/frps && ./update_frps.sh            # 最新版
cd apps/frps && ./update_frps.sh 0.71.0     # 指定版本
```
