自动构建的 fnOS 安装包

- 基于 [MiAir Next v${VERSION}](https://github.com/deerwan/miair-next/releases/tag/v${VERSION})
- 平台: fnOS
- 默认 Web 端口: ${DEFAULT_PORT}
- 默认 DLNA 端口: 8201（避开 fnOS 自带 DLNA 常用的 8200）${REVISION_NOTE}
- 使用 host 网络以支持 SSDP / mDNS 组播发现
- 数据目录: ${TRIM_PKGVAR}/data
${CHANGELOG}
**国内镜像**:
- [${FILE_PREFIX}_${VERSION}_x86.fpk](https://ghfast.top/https://github.com/conversun/fnos-apps/releases/download/${RELEASE_TAG}/${FILE_PREFIX}_${VERSION}_x86.fpk)
- [${FILE_PREFIX}_${VERSION}_arm.fpk](https://ghfast.top/https://github.com/conversun/fnos-apps/releases/download/${RELEASE_TAG}/${FILE_PREFIX}_${VERSION}_arm.fpk)
