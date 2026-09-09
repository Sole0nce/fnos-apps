自动构建的 fnOS 安装包

- 基于 [OpenSurge v${VERSION}](https://github.com/funchs/opensurge-fnos/releases/tag/v${VERSION})
- 旁路由透明代理网关（mihomo + dnsmasq + nftables），需 host 网络与 /dev/net/tun
- Web GUI 默认端口: ${DEFAULT_PORT}（另放行 mixed-port 7890 与 DNS 53）${REVISION_NOTE}
${CHANGELOG}
安装提示：OpenSurge 以旁路由方式工作。安装向导中的网卡名 / 局域网 IP 若保持预填占位值，安装时会按飞牛网络设置自动探测。设备侧需手动将网关 / DNS 指向 NAS IP 才会走代理，默认不接管 DHCP。

**国内镜像**:
- [${FILE_PREFIX}_${FPK_VERSION}_x86.fpk](https://ghfast.top/https://github.com/conversun/fnos-apps/releases/download/${RELEASE_TAG}/${FILE_PREFIX}_${FPK_VERSION}_x86.fpk)
- [${FILE_PREFIX}_${FPK_VERSION}_arm.fpk](https://ghfast.top/https://github.com/conversun/fnos-apps/releases/download/${RELEASE_TAG}/${FILE_PREFIX}_${FPK_VERSION}_arm.fpk)
