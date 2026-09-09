自动构建的 fnOS 安装包

- 基于 [danmu_api ${VERSION}](https://github.com/huangxd-/danmu_api)（Docker 镜像 `logvar/danmu-api:${VERSION}`）
- 平台: fnOS
- 默认端口: ${DEFAULT_PORT}${REVISION_NOTE}
- 数据目录: 应用数据目录下的 `config`（放置 `.env` 后配置热更新）、`.cache`（收藏与缓存持久化）

**首次使用**:
1. 安装向导中设置 API 访问令牌（TOKEN，默认 `87654321`）
2. 访问 `http://your-nas-ip:${DEFAULT_PORT}/` 打开 Web 管理界面
3. 在弹弹play 等客户端中填写 `http://your-nas-ip:${DEFAULT_PORT}/<TOKEN>` 作为自定义弹幕 API 地址；TOKEN 为默认值时可省略路径段
4. B 站 Cookie、源排序、Redis 等进阶配置：在应用数据目录 `config/.env` 中编写，保存后自动热更新

${CHANGELOG}
**国内镜像**:
- [${FILE_PREFIX}_${FPK_VERSION}_x86.fpk](https://ghfast.top/https://github.com/conversun/fnos-apps/releases/download/${RELEASE_TAG}/${FILE_PREFIX}_${FPK_VERSION}_x86.fpk)
- [${FILE_PREFIX}_${FPK_VERSION}_arm.fpk](https://ghfast.top/https://github.com/conversun/fnos-apps/releases/download/${RELEASE_TAG}/${FILE_PREFIX}_${FPK_VERSION}_arm.fpk)
