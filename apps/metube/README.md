# MeTube (fnOS)

网页版 yt-dlp 下载器：粘贴链接即下载，支持 YouTube/B 站等上千站点、多任务队列与音视频格式选择。

- 上游：<https://github.com/alexta69/metube>（官方镜像 `alexta69/metube`，滚动 `latest` 标签）
- 打包模式：Docker
- 默认端口：`8281`（容器内 8081，可在安装/设置向导改端口）
- 下载目录：应用数据目录 `downloads/`，在飞牛文件管理中可直接访问
- 版本跟踪：上游无版本资产，fpk 版本为 `latest-<构建日期>` 哨兵（与 transmission 相同契约），容器镜像跟随 `latest`

## 本地构建

```bash
cd apps/metube && ./update_metube.sh
```
