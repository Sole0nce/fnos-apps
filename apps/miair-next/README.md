# MiAir Next for fnOS

MiAir Next 可将小米小爱音箱转换为 DLNA 渲染器与 AirPlay 接收器，并提供现代化 Web 管理后台。本包使用 Docker host 网络，以满足 SSDP 与 mDNS 组播发现要求。

## 端口说明

- Web 管理后台：默认 `8300/tcp`，可在安装或应用设置向导中修改。
- DLNA HTTP 服务：默认 `8201/tcp`，可在安装或应用设置向导中修改。
- SSDP 发现：`1900/udp`。
- mDNS 发现：`5353/udp`。

fnOS 自带 DLNA 服务可能占用上游默认端口 `8200`。本包会在首次安装时将持久化配置 `/app/data/conf/config.json` 中的 `dlna_port` 预设为 `8201`，然后重启容器使配置生效，因此不会默认抢占 `8200`。

如需改用其他 DLNA 端口：

1. 打开 fnOS「系统设置 → 应用设置 → MiAir Next」。
2. 修改「DLNA 服务端口」，确认该端口未被其他服务占用。
3. 保存设置；应用会更新持久化配置并自动重启容器。
4. Web 管理后台仍通过单独的「Web 管理端口」访问。

首次打开 Web 管理后台后，请按页面引导创建管理员账号，并在「账号配置」中填写小米账号或 Cookie、选择音箱。

## 本地构建

```bash
cd apps/miair-next
./update_miair-next.sh --arch x86
./update_miair-next.sh --arch arm
```
