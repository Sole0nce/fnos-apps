# Surface 电池驱动

将 [xiowo/fnos_surface_battery_driver](https://github.com/xiowo/fnos_surface_battery_driver) 重新打包为 fnOS 应用，用于在 Microsoft Surface 设备上编译并安装 Surface Aggregator 电池驱动。

## 使用前提

- **仅支持 x86（Intel Surface 硬件）**，不提供 ARM 安装包。
- 应用需要以 **root** 权限运行，才能编译、安装和加载内核模块。
- 系统必须具备当前内核对应的头文件：`/lib/modules/$(uname -r)/build`。
- 编译需要 `gcc`、`make`、`kmod` 和 `python3`；应用界面可检查并尝试补全依赖。
- 安装 FPK 后不会自动编译驱动。请从 fnOS 桌面打开应用，在应用内手动点击“编译并安装驱动”。

驱动编译针对当前正在运行的内核现场完成，因此内核升级后可能需要重新编译。

## 本地构建

```bash
cd apps/surface-battery
./update_surface-battery.sh --arch x86
```

构建过程只下载并重新打包上游 release tag 源码归档，不修改上游驱动源码或二进制文件。
