# HandBrake for fnOS

开源视频转码工具，支持 GPU 硬件加速，Web 图形界面操作。

- 上游镜像: [jlesage/handbrake](https://github.com/jlesage/docker-handbrake) (Docker)
- 默认端口: 5800
- 打包方式: Docker
- 架构: **仅 x86 (amd64)** — 上游 `jlesage/handbrake` 目前只发布 amd64 manifest，CI 通过 `SUPPORTED_ARCH=x86` 跳过 arm 构建

## 数据目录

| 容器路径 | 宿主路径 | 说明 |
|---------|---------|------|
| `/config` | `${TRIM_PKGVAR}/config` | 配置、状态与日志 |
| `/storage` | `/vol1` (只读) | NAS 存储空间，用于选择待转码视频 |
| `/watch` | `${TRIM_PKGVAR}/watch` | 自动转码监视目录 |
| `/output` | `${TRIM_PKGVAR}/output` | 转码输出目录 |

硬件加速需要宿主机存在 `/dev/dri`，应用用户已加入 `video` / `render` 组。

## Local Build

```bash
cd apps/handbrake && ./update_handbrake.sh
```
