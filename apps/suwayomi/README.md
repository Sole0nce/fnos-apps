# Suwayomi for fnOS

免费开源的漫画阅读服务器，支持多来源扩展与 Web 阅读界面。

- 上游镜像: [ghcr.io/suwayomi/suwayomi-server](https://github.com/Suwayomi/Suwayomi-Server) (Docker)
- 默认端口: 4567
- 打包方式: Docker

## 数据目录

| 容器路径 | 宿主路径 | 说明 |
|---------|---------|------|
| `/home/suwayomi/.local/share/Tachidesk` | `${TRIM_PKGVAR}/data` | 书库、数据库、下载与扩展 |

## Local Build

```bash
cd apps/suwayomi && ./update_suwayomi.sh
```
