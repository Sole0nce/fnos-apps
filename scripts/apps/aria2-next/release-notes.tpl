自动构建的 fnOS 安装包

- 基于 [Aria2 Next v${VERSION}](https://github.com/AnInsomniacy/aria2-next/releases/tag/v${VERSION})
- 平台: fnOS
- RPC 端口: ${DEFAULT_PORT}（JSON-RPC，无内置网页）${REVISION_NOTE}
${CHANGELOG}
**使用说明**：Aria2 Next 是纯下载引擎。安装后请用 AriaNg、Motrix Next 等 RPC 前端连接 `http://NAS_IP:${DEFAULT_PORT}/jsonrpc`（默认未设 RPC 密钥，与商店其它应用一致的可信局域网默认值；如需公网暴露请在 配置 目录 aria2.conf 中设置 rpc-secret）。下载目录为应用数据共享目录 Aria2 Next。

**国内镜像**:
- [${FILE_PREFIX}_${FPK_VERSION}_x86.fpk](https://ghfast.top/https://github.com/conversun/fnos-apps/releases/download/${RELEASE_TAG}/${FILE_PREFIX}_${FPK_VERSION}_x86.fpk)
- [${FILE_PREFIX}_${FPK_VERSION}_arm.fpk](https://ghfast.top/https://github.com/conversun/fnos-apps/releases/download/${RELEASE_TAG}/${FILE_PREFIX}_${FPK_VERSION}_arm.fpk)
