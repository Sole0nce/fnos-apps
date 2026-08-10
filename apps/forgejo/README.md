# Forgejo for fnOS

每日自动同步 [Forgejo 官方](https://codeberg.org/forgejo/forgejo) 最新版本并构建 `.fpk` 安装包。

## 下载

从 [Releases](https://github.com/conversun/fnos-apps/releases?q=forgejo) 下载最新的 `.fpk` 文件。

## 安装

1. 根据设备架构下载对应的 `.fpk` 文件
2. fnOS 应用管理 -> 手动安装 -> 上传

**访问地址**: `http://<NAS-IP>:3006`

## 说明

- Forgejo 是社区驱动的轻量级 Git 托管服务
- 支持 HTTP 访问和 SSH 克隆（额外端口 `2223`）
- 数据与配置存储在应用数据目录中

## 本地构建

```bash
./update_forgejo.sh                        # 最新版本，自动检测架构
./update_forgejo.sh --arch arm             # 指定架构
./update_forgejo.sh --arch arm 9.0.4       # 指定版本
./update_forgejo.sh --help                 # 查看帮助
```

## Credits

- [Forgejo](https://codeberg.org/forgejo/forgejo) - Beyond coding. We forge.
