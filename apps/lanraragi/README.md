# LANraragi for fnOS

自托管的漫画/存档管理服务器，支持自动元数据刮削与标签分类。

- 上游镜像: [difegue/lanraragi](https://github.com/Difegue/LANraragi) (Docker)
- 默认端口: 3000
- 打包方式: Docker

## 数据目录

| 容器路径 | 宿主路径 | 说明 |
|---------|---------|------|
| `/home/koyomi/lanraragi/content` | `${TRIM_PKGVAR}/content` | 漫画归档文件 |
| `/home/koyomi/lanraragi/thumb` | `${TRIM_PKGVAR}/thumb` | 缩略图缓存 |
| `/home/koyomi/lanraragi/database` | `${TRIM_PKGVAR}/database` | Redis/Valkey 数据库 |

## Local Build

```bash
cd apps/lanraragi && ./update_lanraragi.sh
```
