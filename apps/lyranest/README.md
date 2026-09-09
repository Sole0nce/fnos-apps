# LyraNest（律巢音乐）for fnOS

自托管多端音乐服务：Web、Windows、Android 客户端共用服务端曲库、收藏、歌单与播放队列。支持歌词逐曲偏移、桌面歌词、离线下载（歌曲/封面/歌词）、每日推荐、听歌统计与热力图、曲库搜索/排序/批量操作、专辑与艺术家浏览、元数据刮削。

- 上游: https://github.com/WHWgogogo/LyraNest
- Docker 镜像: `ghcr.io/whwgogogo/lyranest-server`（多架构 amd64/arm64）
- 默认端口: 8080

> 说明：LyraNest 官方 Release 另有其自维护的 fnOS fpk；本包基于官方 Docker 镜像重新打包，纳入本应用中心的统一生命周期与自动更新。二者请勿同时安装。

## 目录说明

| 容器路径 | 宿主机位置 | 说明 |
|---|---|---|
| `/music` | 安装向导指定的音乐目录（只读），默认「LyraNest」共享文件夹 | 音乐库 |
| `/downloads` | 应用数据目录 `downloads/` | 离线下载 |
| `/data` | 应用数据目录 `data/` | 元数据/数据库 |
| `/cache` | 应用数据目录 `cache/` | 封面等缓存 |
## 本地构建
```bash
cd apps/lyranest && ./update_lyranest.sh            # 最新版，自动检测架构
./update_lyranest.sh --arch x86 0.2.4               # 指定版本与架构
```
