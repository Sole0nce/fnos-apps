自动构建的 fnOS 安装包

- 基于 [Suwayomi-Server v${VERSION}](https://github.com/Suwayomi/Suwayomi-Server/releases/tag/v${VERSION})
- 平台: fnOS
- 默认端口: ${DEFAULT_PORT}${REVISION_NOTE}
- 数据目录: `${TRIM_PKGVAR}/data` (对应容器内 `/home/suwayomi/.local/share/Tachidesk`)

**首次使用**:
1. 访问 `http://your-nas-ip:${DEFAULT_PORT}` 打开 Web 阅读界面
2. 在「设置 → 扩展」中添加漫画来源后即可搜索与阅读
3. 默认无需登录，可在设置中开启 `basic_auth` / `ui_login` 鉴权

${CHANGELOG}
**国内镜像**:
- [${FILE_PREFIX}_${FPK_VERSION}_x86.fpk](https://ghfast.top/https://github.com/conversun/fnos-apps/releases/download/${RELEASE_TAG}/${FILE_PREFIX}_${FPK_VERSION}_x86.fpk)
- [${FILE_PREFIX}_${FPK_VERSION}_arm.fpk](https://ghfast.top/https://github.com/conversun/fnos-apps/releases/download/${RELEASE_TAG}/${FILE_PREFIX}_${FPK_VERSION}_arm.fpk)
