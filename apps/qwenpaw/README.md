# QwenPaw for fnOS

每日自动同步 [QwenPaw 官方](https://github.com/agentscope-ai/QwenPaw) 最新版本并构建 `.fpk` 安装包。

## 下载

从 [Releases](https://github.com/conversun/fnos-apps/releases?q=qwenpaw) 下载最新的 `.fpk` 文件。

## 安装

1. 根据设备架构下载对应的 `.fpk` 文件
2. fnOS 应用管理 → 手动安装 → 上传

**访问地址**: `http://<NAS-IP>:8088`

## 磁盘空间要求

QwenPaw 镜像较大（18 层，压缩后约 0.9 GiB，解压后包含完整 Python 运行环境与依赖）。

**请确保 Docker 存储卷至少有 8 GB 可用空间再安装。**

实测：在仅剩 5.1 GB 可用空间的存储卷上安装会在解压 `site-packages` 阶段失败，
报错 `failed to register layer: no space left on device`，安装随后自动回滚。
可在 fnOS 中通过「存储空间」查看 Docker 所在卷的剩余容量。

## 说明

- QwenPaw 是部署在自有环境中的个人助理型产品，数据全部保存在本地，不依赖第三方托管
- 多通道对话 — 支持通过钉钉、飞书、Discord、Telegram 等渠道对话
- 多智能体协作 — 可创建多个独立智能体，各自拥有独立配置、记忆与技能，并可互相通信协作
- 定时执行 — 按配置自动运行任务
- 能力由 Skills 决定 — 内置定时任务、PDF 与表单、Word/Excel/PPT 文档处理、新闻摘要、文件阅读等，
  并可在 [Skills](https://qwenpaw.agentscope.io/docs/skills) 中自定义扩展
- 支持本地模型 — 可完全离线运行，无需 API Key
- 多层安全防护 — 内置工具防护、文件访问控制、技能安全扫描

由 [AgentScope 团队](https://github.com/agentscope-ai) 基于
[AgentScope](https://github.com/agentscope-ai/agentscope)、
[AgentScope Runtime](https://github.com/agentscope-ai/agentscope-runtime) 与
[ReMe](https://github.com/agentscope-ai/ReMe) 构建。

## 本地构建

```bash
cd apps/qwenpaw && ./update_qwenpaw.sh
```
