# OpenSurge for fnOS

OpenSurge 是面向飞牛 fnOS 的旁路由透明代理网关（mihomo + dnsmasq + nftables），提供 TUN 透明代理、按设备分流与 Web 控制面。

- 上游（fnOS 移植）：<https://github.com/funchs/opensurge-fnos>
- 镜像：`ghcr.io/funchs/opensurge-fnos`
- Web GUI 端口：`61767`（另放行 mixed-port `7890` 与 DNS `53`）
- 需要 host 网络与 `/dev/net/tun`，安装向导支持网卡/IP 自动探测
- 本包直接采用上游的 fnOS 生命周期脚本（`fnos/cmd` 自包含），仅将 distributor 改为本仓库

## 使用提示

OpenSurge 以旁路由方式工作：设备侧需手动将网关/DNS 指向 NAS IP 才会走代理，默认不接管 DHCP。详见上游 [FPK-USER-GUIDE](https://github.com/funchs/opensurge-fnos/blob/main/docs/fnos-port/FPK-USER-GUIDE.md)。

## 本地构建

```bash
cd apps/opensurge && ./update_opensurge.sh            # 最新版
cd apps/opensurge && ./update_opensurge.sh 0.1.1      # 指定版本
