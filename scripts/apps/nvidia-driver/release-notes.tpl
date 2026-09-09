> ## ⚠️ 老用户必读：本次需要手动卸载重装（仅此一次）
>
> 旧版本号是驱动版本（如 `580.178.04`）。本包已不再内置驱动，版本号改为跟随
> nvidia-container-toolkit（`${VERSION}`），**数字变小了**。应用中心会把它当作降级，
> 因此**不会提示更新**。请手动操作一次：
>
> 1. 卸载旧的 `NVIDIA Driver`（旧版卸载会自行清理它的 DKMS 内核模块）
> 2. 下载并安装下方的 `.fpk`
>
> 之后的版本升级恢复正常，不再需要手动处理。若旧版残留了 DKMS 内容，
> 新版安装时会自动检测并清理。

---

自动构建的 fnOS 安装包

- 包含 [nvidia-container-toolkit v${VERSION}](https://github.com/NVIDIA/nvidia-container-toolkit/releases/tag/v${VERSION})（Docker GPU 直通支持）
- **不编译内核模块**：直接启用飞牛系统自带的 NVIDIA 内核模块（`/usr/lib/modules_trim/<内核版本>/nvidia-gpu-*`）
- NVIDIA 用户态组件版本在设备上按内核模块版本自动匹配下载，不再由安装包固定
- 仅支持 x86_64 架构
- 安装类型: 系统分区（root）${REVISION_NOTE}

${CHANGELOG}

**安装前提**:
- 飞牛系统自带 NVIDIA 内核模块（1.2.x 已内置；系统设置中确认已识别显卡）
- 首次安装需要联网下载与内核模块版本匹配的 NVIDIA 用户态组件（约 400MB）

**安装后验证**:
\`\`\`bash
nvidia-smi
docker run --rm --gpus all ubuntu:22.04 nvidia-smi
\`\`\`

**国内镜像**:
- [${FILE_PREFIX}_${FPK_VERSION}_x86.fpk](https://ghfast.top/https://github.com/conversun/fnos-apps/releases/download/${RELEASE_TAG}/${FILE_PREFIX}_${FPK_VERSION}_x86.fpk)
