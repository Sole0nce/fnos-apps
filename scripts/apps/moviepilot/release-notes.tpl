> **若你当前运行的是 v2，升级前请注意**（已在 v3 上则可忽略）

- v2 → v3 是大版本升级，镜像仓库已更换（`moviepilot-v2` → `moviepilot-v3`）
- 升级后数据库会自动迁移，且**不可自动回退**，如需退回 v2 请按官方文档手动降级
- 部分插件可能与 v3 不兼容而失效，请升级后检查
- 升级前请务必备份 `/config` 目录

自动构建的 fnOS 安装包

- 基于 [MoviePilot ${VERSION}](https://github.com/jxxghp/MoviePilot)
- 基于 Docker 容器运行，需要 fnOS Docker 环境
- 平台: fnOS
- 默认端口: 3000
- 首次启动通过 Web UI 配置${REVISION_NOTE}
${CHANGELOG}
**国内镜像**:
- [${FILE_PREFIX}_${FPK_VERSION}_x86.fpk](https://ghfast.top/https://github.com/conversun/fnos-apps/releases/download/${RELEASE_TAG}/${FILE_PREFIX}_${FPK_VERSION}_x86.fpk)
- [${FILE_PREFIX}_${FPK_VERSION}_arm.fpk](https://ghfast.top/https://github.com/conversun/fnos-apps/releases/download/${RELEASE_TAG}/${FILE_PREFIX}_${FPK_VERSION}_arm.fpk)
