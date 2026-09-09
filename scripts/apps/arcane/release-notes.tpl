自动构建的 fnOS 安装包

- 基于 [Arcane v${VERSION}](https://github.com/getarcaneapp/arcane/releases/tag/v${VERSION})
- 基于 Docker 容器运行（镜像 `ghcr.io/getarcaneapp/manager`），需要 fnOS Docker 环境
- 平台: fnOS
- 默认端口: ${DEFAULT_PORT}${REVISION_NOTE}
- 数据目录: `${TRIM_PKGVAR}/data` (对应容器内 `/app/data`)

**安装须知**:
1. Arcane 通过挂载宿主机 `/var/run/docker.sock` 管理 Docker，拥有与 Docker 守护进程等同的权限
2. 安装时必须设置 **加密密钥 (ENCRYPTION_KEY)** 与 **JWT 密钥 (JWT_SECRET)**，均要求至少 32 位随机字符（可用 `openssl rand -base64 32` 生成）
3. 镜像托管在 ghcr.io，Docker 镜像加速器可能不生效；拉取失败请确保 NAS 能直连 ghcr.io
4. 首次访问 `http://your-nas-ip:${DEFAULT_PORT}` 按引导创建管理员账号

${CHANGELOG}
**国内镜像**:
- [${FILE_PREFIX}_${FPK_VERSION}_x86.fpk](https://ghfast.top/https://github.com/conversun/fnos-apps/releases/download/${RELEASE_TAG}/${FILE_PREFIX}_${FPK_VERSION}_x86.fpk)
- [${FILE_PREFIX}_${FPK_VERSION}_arm.fpk](https://ghfast.top/https://github.com/conversun/fnos-apps/releases/download/${RELEASE_TAG}/${FILE_PREFIX}_${FPK_VERSION}_arm.fpk)
