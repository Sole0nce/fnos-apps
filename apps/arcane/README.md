# Arcane for fnOS

[Arcane](https://github.com/getarcaneapp/arcane) 是现代化的 Docker 管理界面（Modern Docker Management），可视化管理容器、镜像、Compose 项目、存储卷与网络。

- 上游镜像: [ghcr.io/getarcaneapp/manager](https://github.com/getarcaneapp/arcane) (Docker)
- 默认端口: **3552**
- 架构支持: amd64 / arm64

## ⚠️ 权限说明（docker.sock）

Arcane 是 Docker 管理工具，必须挂载宿主机 **`/var/run/docker.sock`** 才能工作。这意味着 Arcane 容器拥有与 Docker 守护进程等同的权限（可创建/删除任意容器）。请务必：

- 安装时设置强随机的 **加密密钥（ENCRYPTION_KEY）** 与 **JWT 密钥（JWT_SECRET）**（均至少 32 位，可用 `openssl rand -base64 32` 生成）
- 首次访问 Web UI 后立即创建管理员账号
- 不要将 3552 端口直接暴露到公网；如需外网访问请通过反向代理 + HTTPS

## 数据持久化

应用数据（SQLite 数据库、设置等）存储在 `${TRIM_PKGVAR}/data`（容器内 `/app/data`），卸载时默认保留。

## 本地构建

## Local Build

```bash
cd apps/arcane && ./update_arcane.sh              # 最新版本
cd apps/arcane && ./update_arcane.sh 2.8.0        # 指定版本
```
cd apps/arcane && bash ../../scripts/build-fpk.sh . app.tgz
```
