自动构建的 fnOS 安装包

- 基于 [Surface 电池驱动 v${VERSION}](https://github.com/xiowo/fnos_surface_battery_driver/releases/tag/v${VERSION})
- 仅支持 x86（Intel Surface 硬件）
- 无 Web 服务端口；管理界面通过 fnOS CGI 打开
- 需要 root、当前内核头文件、gcc、make、kmod 和 python3
- 安装后请在应用内手动点击“编译并安装驱动”${REVISION_NOTE}

${CHANGELOG}

**国内镜像**:
- [${FILE_PREFIX}_${FPK_VERSION}_x86.fpk](https://ghfast.top/https://github.com/conversun/fnos-apps/releases/download/${RELEASE_TAG}/${FILE_PREFIX}_${FPK_VERSION}_x86.fpk)
