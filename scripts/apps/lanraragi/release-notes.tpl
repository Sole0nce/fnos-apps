自动构建的 fnOS 安装包

- 基于 [LANraragi v.${VERSION}](https://github.com/Difegue/LANraragi/releases/tag/v.${VERSION})
- 平台: fnOS
- 默认端口: ${DEFAULT_PORT}${REVISION_NOTE}
- 数据目录: `${TRIM_PKGVAR}/content` (漫画归档)、`${TRIM_PKGVAR}/database` (数据库)、`${TRIM_PKGVAR}/thumb` (缩略图)

**首次使用**:
1. 访问 `http://your-nas-ip:${DEFAULT_PORT}` 进入图书馆界面
2. 将 zip/rar/cbz/cbr/pdf 等归档文件放入 `${TRIM_PKGVAR}/content` 后在网页中扫描导入
3. 可在「Settings → Plugins」中启用元数据刮削插件

${CHANGELOG}
**国内镜像**:
- [${FILE_PREFIX}_${FPK_VERSION}_x86.fpk](https://ghfast.top/https://github.com/conversun/fnos-apps/releases/download/${RELEASE_TAG}/${FILE_PREFIX}_${FPK_VERSION}_x86.fpk)
- [${FILE_PREFIX}_${FPK_VERSION}_arm.fpk](https://ghfast.top/https://github.com/conversun/fnos-apps/releases/download/${RELEASE_TAG}/${FILE_PREFIX}_${FPK_VERSION}_arm.fpk)
