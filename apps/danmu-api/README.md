# Danmu API for fnOS

自托管弹幕 API 服务器（Docker 模式打包）。基于 js 的弹幕 API 服务，支持爱优腾芒哔咪人韩巴狐乐西埋帆红弹幕直接获取，兼容弹弹play 的搜索、详情查询和弹幕获取接口规范，并提供日志记录与 Web 管理界面。

- 上游项目: https://github.com/huangxd-/danmu_api
- Docker 镜像: [`logvar/danmu-api`](https://hub.docker.com/r/logvar/danmu-api)（多架构 amd64 + arm64）
- 默认端口: 9321（容器内固定 9321，宿主机端口可在安装时修改）
- API 访问令牌: 安装向导设置 `TOKEN`，默认 `87654321`
- 数据目录: 应用数据目录下 `config`（放置 `.env` 配置后自动热更新）、`.cache`（收藏与缓存持久化）

## 使用

1. 安装后访问 `http://<NAS地址>:9321/` 打开 Web 管理界面
2. 在弹弹play 等客户端中填写 `http://<NAS地址>:9321/<TOKEN>` 作为自定义弹幕 API 地址；TOKEN 为默认值时可省略路径段
3. 进阶环境变量（B 站 Cookie、源排序、Redis 等）见[上游文档](https://github.com/huangxd-/danmu_api#环境变量列表)，写入数据目录 `config/.env` 后自动热更新

## 本地构建

```bash
cd apps/danmu-api && ./update_danmu-api.sh              # 最新版本，自动检测架构
cd apps/danmu-api && ./update_danmu-api.sh --arch arm  # 强制 ARM 架构
```
