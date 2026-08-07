自动构建的 fnOS 安装包

- 基于 [jlesage/handbrake v${VERSION}](https://github.com/jlesage/docker-handbrake/releases/tag/v${VERSION})
- 平台: fnOS / x86 (amd64) only（上游镜像当前仅发布 amd64 manifest）
- 默认端口: ${DEFAULT_PORT}${REVISION_NOTE}
- 支持 Intel/AMD 核显硬件加速 (VA-API / QSV，需宿主机存在 `/dev/dri`)

**首次使用**:
1. 访问 `http://your-nas-ip:${DEFAULT_PORT}` 打开 HandBrake Web 图形界面
2. 存储空间 `/vol1` 以只读方式挂载到容器内 `/storage`，可从此处选择待转码视频
3. 自动转码监视目录为 `/watch`，转码结果输出到 `/output`

${CHANGELOG}
**国内镜像**:
- [${FILE_PREFIX}_${FPK_VERSION}_x86.fpk](https://ghfast.top/https://github.com/conversun/fnos-apps/releases/download/${RELEASE_TAG}/${FILE_PREFIX}_${FPK_VERSION}_x86.fpk)
