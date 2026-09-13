# Pocket ID (fnOS)

轻量 OIDC 单点登录 / Passkey 身份提供方：为 Jellyfin、Immich、Nginx Proxy Manager 等自托管应用提供指纹/Passkey 免密码统一登录。

- 上游：<https://github.com/pocket-id/pocket-id>
- 打包模式：原生（双架构 amd64/arm64）
- 默认端口：`1411`
- 首次使用：打开网页按向导创建管理员账号；作为 OIDC 提供方建议配合反向代理（Nginx Proxy Manager）使用
- 密钥：`ENCRYPTION_KEY`（加密已签发的客户端凭据）在首装时生成并持久化于数据目录 `.encryption_key`，升级不变

## 本地构建

```bash
cd apps/pocket-id && ./update_pocket-id.sh            # 最新版
cd apps/pocket-id && ./update_pocket-id.sh 2.14.0     # 指定版本
```
