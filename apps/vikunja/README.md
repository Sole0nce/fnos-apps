# Vikunja (fnOS)

开源待办清单与项目看板：列表/看板/甘特/日历多视图，配全平台手机 App 与 CalDAV 同步。

- 上游：<https://github.com/go-vikunja/vikunja>（`-full` 版二进制，Web 前端已内嵌；注意上游同包还发布 `veans-*` 更名版，不使用）
- 打包模式：原生（双架构 amd64/arm64）
- 默认端口：`3456`
- 存储：SQLite（数据目录 `vikunja.db`）+ 附件目录 `files/`，全部跟随应用数据目录
- 环境变量由 `bin/vikunja-server` 注入（`VIKUNJA_SERVICE_INTERFACE` 对齐服务端口）

## 本地构建

```bash
cd apps/vikunja && ./update_vikunja.sh            # 最新版
cd apps/vikunja && ./update_vikunja.sh 2.6.0      # 指定版本
```
