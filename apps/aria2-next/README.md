# Aria2 Next for fnOS

Aria2 Next 是活跃维护的 aria2 分支下载引擎（HTTP/HTTPS/SFTP/Metalink/BT/磁力/ED2K），本包以 Docker 模式交付其 JSON-RPC 服务。

- 上游：<https://github.com/AnInsomniacy/aria2-next>
- 镜像：`ghcr.io/aninsomniacy/aria2-next`
- RPC 端口：`6800`（`service_port`，防火墙已放行）
- 无内置网页：请用 AriaNg / Motrix Next 等 RPC 前端连接 `http://NAS_IP:6800/jsonrpc`
- 默认未设 RPC 密码（可信局域网默认）；如需公网暴露请在 `config/aria2.conf` 设置 `rpc-secret`
- 下载目录：应用数据共享目录 Aria2 Next（容器内 `/downloads`）

## 安装期行为

`cmd/service-setup` 在首次安装时播种 `aria2.conf`（rpc-listen-all、无 secret、`dir=/downloads`）；容器入口脚本只在配置缺失时拷贝默认值，因此播种文件优先生效，用户后续修改在升级中保留。

## 本地构建

```bash
cd apps/aria2-next && ./update_aria2-next.sh            # 最新版
cd apps/aria2-next && ./update_aria2-next.sh 2.6.8      # 指定版本
```
