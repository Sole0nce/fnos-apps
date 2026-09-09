自动构建的 fnOS 安装包

- 基于 [LyraNest v${VERSION}](https://github.com/WHWgogogo/LyraNest/releases/tag/v${VERSION})（Docker 镜像 `ghcr.io/whwgogogo/lyranest-server:${VERSION}`）
- 平台: fnOS
- 默认端口: ${DEFAULT_PORT}${REVISION_NOTE}
- 数据目录: 应用数据目录下的 `data`（元数据）、`cache`（缓存）、`downloads`（离线下载）
- 音乐库: 安装向导可指定已有音乐目录（只读挂载）；默认为 fnOS 文件管理器中的「LyraNest」共享文件夹

> 说明：LyraNest 官方 Release 另有其自维护的 fnOS fpk；本包基于官方 Docker 镜像重新打包，纳入本应用中心的统一生命周期与自动更新。二者请勿同时安装。

**首次使用**:
1. 访问 `http://your-nas-ip:${DEFAULT_PORT}` 打开 Web 端
2. Android / Windows / TV 客户端请在[上游 Release](https://github.com/WHWgogogo/LyraNest/releases/latest) 下载，连接同一服务器即可同步曲库与歌单

${CHANGELOG}
**国内镜像**:
- [${FILE_PREFIX}_${FPK_VERSION}_x86.fpk](https://ghfast.top/https://github.com/conversun/fnos-apps/releases/download/${RELEASE_TAG}/${FILE_PREFIX}_${FPK_VERSION}_x86.fpk)
- [${FILE_PREFIX}_${FPK_VERSION}_arm.fpk](https://ghfast.top/https://github.com/conversun/fnos-apps/releases/download/${RELEASE_TAG}/${FILE_PREFIX}_${FPK_VERSION}_arm.fpk)
