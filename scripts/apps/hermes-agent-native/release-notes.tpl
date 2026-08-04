自动构建的 fnOS 安装包（原生 package 版）

- 基于 [Hermes Agent](https://github.com/NousResearch/hermes-agent) 官方最新 release tag (v${VERSION})
- 平台: fnOS x86_64
- 安装类型: package（预构建运行时，安装零联网）
- 桌面入口: Hermes-原生版（网关 socket 直连 Dashboard）
- 包含服务: Dashboard (${DEFAULT_PORT})${REVISION_NOTE}
${CHANGELOG}
**国内镜像**:
- [${FILE_PREFIX}_${FPK_VERSION}_x86.fpk](https://ghfast.top/https://github.com/Sole0nce/fnos-apps/releases/download/${RELEASE_TAG}/${FILE_PREFIX}_${FPK_VERSION}_x86.fpk)
