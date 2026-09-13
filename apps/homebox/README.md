# Homebox (fnOS)

家庭物品资产管理与库存系统：登记家当、拍照归档、位置/标签/保修期管理。

- 上游：<https://github.com/sysadminsmedia/homebox>
- 打包模式：原生（双架构 amd64/arm64）
- 默认端口：`7745`
- 首次使用：打开网页按向导注册管理员
- 存储：SQLite 位于数据目录 `homebox.db`，缩略图等在 `.data/`
- 密钥：0.26+ 要求 ≥32 字节的 `HBOX_AUTH_API_KEY_PEPPER`，首装生成并持久化（轮换会使已签发 API Key 失效）

## 本地构建

```bash
cd apps/homebox && ./update_homebox.sh            # 最新版
cd apps/homebox && ./update_homebox.sh 0.26.2     # 指定版本
```
