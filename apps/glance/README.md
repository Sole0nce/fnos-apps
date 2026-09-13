# Glance (fnOS)

高颜值自托管聚合仪表盘：RSS、书签、站点监控、Docker 状态、市场行情等数十种小组件一页呈现。

- 上游：<https://github.com/glanceapp/glance>（静态 Go 二进制）
- 打包模式：原生（双架构 amd64/arm64）
- 默认端口：`9678`
- 配置：应用数据目录 `glance.yml`，启动时自动对齐服务端口；首次安装生成含 fnOS 书签的示例配置
- 缓存：数据目录 `cache/`

## 本地构建

```bash
cd apps/glance && ./update_glance.sh            # 最新版
cd apps/glance && ./update_glance.sh 0.8.6      # 指定版本
```
