# NVIDIA Driver for fnOS

NVIDIA GPU 驱动用户态组件与 nvidia-container-toolkit 安装包。

> **⚠️ 从 580.x 旧版升级：需要手动卸载重装一次。**
>
> 旧版本号是驱动版本（如 `580.178.04`），新版本号跟随 nvidia-container-toolkit
> （如 `1.20.0`）。数字变小会被应用中心当作降级，因此不会提示更新。
> 请先卸载旧的 `NVIDIA Driver`，再安装新的 `.fpk`。之后的升级恢复正常。

## 工作方式

飞牛系统镜像自带了匹配其内核的预编译 NVIDIA 内核模块：

```
/usr/lib/modules_trim/<内核版本>/nvidia-gpu-open/*.ko
/usr/lib/modules_trim/<内核版本>/nvidia-gpu-proprietary/*.ko
/usr/lib/firmware/nvidia/<驱动版本>/
```

本包**不编译任何内核模块**，而是：

1. 从飞牛自带的 `nvidia.ko` 读出驱动版本；
2. 下载并安装**版本完全匹配**的 NVIDIA 用户态组件（`--no-kernel-modules`）；
3. 启用飞牛的内核模块替代项并加载；
4. 安装 nvidia-container-toolkit，配置 Docker `nvidia` runtime 与 CDI。

上述步骤在**每次启动时幂等重跑**。因此飞牛系统更新换内核、换驱动版本后，
下次开机会自动重新对齐，GPU 不会“掉卡”。

> 旧版本使用 DKMS 编译自己的内核模块，并把飞牛的替代项移走。飞牛系统更新会整体
> 替换根文件系统，而 `linux-headers-<内核版本>` 并不在任何 apt 仓库中，DKMS 无法
> 为新内核重建；残留的用户态又与飞牛自带模块版本不符（实测 580.142 vs 580.167.08），
> 于是 `nvidia-smi` 报 Driver/library version mismatch。

## 功能

- 自动匹配并安装 NVIDIA 用户态组件（CUDA / NVML / NVENC / NVDEC）
- nvidia-container-toolkit（Docker GPU 直通支持）
- 自动配置 Docker `nvidia` runtime 与 CDI
- 自动启用 GPU Persistence Mode
- 从旧版 DKMS 安装自动迁移清理

## 前提条件

- fnOS 1.2.x（系统镜像需自带 `nvidia-gpu-*` 内核模块）
- NVIDIA GPU
- 首次安装需联网（下载约 400MB 用户态组件，缓存在应用数据目录）

不再需要内核头文件、`build-essential` 或 DKMS。

## 安装后验证

```bash
# 检查驱动
nvidia-smi

# 检查 Docker GPU 支持
docker run --rm --gpus all ubuntu:22.04 nvidia-smi
```

## 本地构建

```bash
cd apps/nvidia-driver
./update_nvidia-driver.sh                    # 自动获取最新 toolkit 版本
./update_nvidia-driver.sh 1.17.8             # 指定 toolkit 版本
```

## 注意事项

- 仅支持 x86_64 架构
- 不应与飞牛商店的 `Nvidia-Driver` 包共存。若检测到官方包已接管驱动，本包不会覆盖，
  而是在版本不一致时直接报错提示。
- 若当前飞牛内核未提供 `nvidia-gpu-*` 模块，安装会直接失败并提示升级系统
- 无 GPU 的机器上安装会成功并进入 `pending-no-gpu` 状态，插卡重启后自动生效
- 如遇 GPU 掉卡（Xid 79），建议添加内核参数 `pcie_aspm=off`
- 详细安装指南参考 `docs/fnos-tesla-p4-driver-guide.md`
