## 2026-08-23

**重大变更：不再编译内核模块。修复飞牛系统更新后 GPU 掉卡。**

**老用户需手动卸载重装一次**：版本号从驱动版本（`580.178.04`）改为跟随
nvidia-container-toolkit（`1.20.0`），数字变小，应用中心会当作降级而不提示更新。
先卸载旧版再安装新版即可；之后的升级恢复正常。

- 改为直接使用飞牛系统自带的预编译内核模块
  （`/usr/lib/modules_trim/<内核版本>/nvidia-gpu-{open,proprietary}`），彻底移除 DKMS
- NVIDIA 用户态版本不再在构建时写死，而是在设备上从内核模块读取后匹配下载安装
  （`--no-kernel-modules`），并缓存在应用数据目录
- 每次启动幂等重新对齐，飞牛系统更新换内核/换驱动版本后自动恢复
- 不再移走飞牛的内核模块替代项；仅在槽位为空时创建，且卸载时按指纹校验后才移除
- 自动迁移：升级时清理旧的 DKMS 安装，并恢复被旧版本移走的替代项
- Docker runtime 不再使用 `--set-as-default`，避免驱动异常时影响其他容器
- 无 GPU 机器上安装不再报错，进入 `pending-no-gpu` 状态
- 卸载不再触碰飞牛自带的内核模块与固件；不再使用 `fuser -k` 强杀 GPU 进程
- 安装包体积从 约 400MB 降至 约 10MB；包版本改为跟随 nvidia-container-toolkit
- 不再需要 `linux-headers` / `build-essential` / `dkms`


## 2026-03-16

- 首次发布
- 基于 NVIDIA R580 LTS 驱动（580.126.20）
- 包含 nvidia-container-toolkit，支持 Docker GPU 直通
- 仅支持 x86_64 架构
- 安装后自动配置：DKMS 内核模块、Docker GPU runtime、Persistence Mode
