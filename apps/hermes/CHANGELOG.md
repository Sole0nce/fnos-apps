# Changelog

## 2026.9.6

- 修复宿主机端口冲突：`service_port` 由 9119 改为 9120，避免与 Hermes-原生版（hermes-agent-native，9119）同时安装时容器启动失败（错误 10330/10350）

## 2026.7.28

- Initial fnOS release: Docker-based Hermes AI Agent
- Gateway service (port 8642)
- Dashboard Web UI (port 9119)
