# SiYuan 思源笔记 (fnOS)

隐私优先的块级笔记与双向链接知识库，以内核服务器模式运行，浏览器访问即用。

- 上游：<https://github.com/siyuan-note/siyuan>（官方 Docker 镜像 `b3log/siyuan`，版本号锁定 `vX.Y.Z`）
- 打包模式：Docker
- 默认端口：`6806`
- 访问口令：安装向导设置（默认 `siyuan`），可在应用设置中修改；口令持久化在数据目录 `.access_code` 并在升级时重放
- 工作空间：应用数据目录 `workspace/`，可在飞牛文件管理中直接访问
- 说明：kernel 从 `/etc/passwd` 读取用户家目录，而 fnOS 不会为应用用户创建 `/home/<user>`，因此原生打包不可行；官方镜像内由 entrypoint 正确创建容器用户

## 本地构建

```bash
cd apps/siyuan && ./update_siyuan.sh            # 最新版
cd apps/siyuan && ./update_siyuan.sh 3.8.3      # 指定版本
```
