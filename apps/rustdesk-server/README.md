# RustDesk Server (fnOS)

开源远程桌面 RustDesk 的自建服务端（hbbs 信令 + hbbr 中继），远程控制流量完全不经过第三方服务器。

- 上游：<https://github.com/rustdesk/rustdesk-server>
- 打包模式：原生（双架构 amd64/arm64；hbbs 与 hbbr 作为两条 SERVICE_COMMAND 由共享框架统一管理）
- 端口：`21115-21119/tcp` + `21116/udp`（`21117` 为中继，客户端填 `NAS IP:21116`）
- 密钥：首启在应用数据目录 `data/` 生成 `id_ed25519` / `id_ed25519.pub`，公钥内容需填入客户端「Key」字段
- 无 Web UI：`ui/config` 为空（同 nvidia-driver 先例），`health.json` 为 skip

## 本地构建

```bash
cd apps/rustdesk-server && ./update_rustdesk-server.sh            # 最新版
cd apps/rustdesk-server && ./update_rustdesk-server.sh 1.1.16     # 指定版本
```
