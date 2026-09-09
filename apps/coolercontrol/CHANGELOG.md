## 2026-08-31

- 修复安装失败（#278）：compose 中 `CC_HOST_IP6=::` 未加引号，docker compose 将其解析为 map 导致 `environment.[3]: unexpected type` 无法创建容器；已改为 `"CC_HOST_IP6=::"`

## 2026-07-07

- 首次发布
