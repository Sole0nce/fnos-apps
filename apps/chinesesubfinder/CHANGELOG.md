## 2026-08-17

- **修复应用装得上但起不来**（issue #225）：上游是 Go 1.17.13 的 cgo 构建，其 cgo
  解析器经 NSS 调用 `getaddrinfo(3)`，在 fnOS（Debian 12 / glibc 2.36）上会
  SIGSEGV。崩溃发生在包初始化阶段、`main()` 之前，所以安装正常但服务永远拉不起来。
  启动脚本改为导出 `GODEBUG=netdns=go` 走纯 Go 解析器，绕开 `getaddrinfo`。
  上游二进制未做任何改动。
- **修复 stop / uninstall 漏掉进程**：`chinesesubfinder` 有 16 个字符，超过内核
  `comm` 的 15 字符上限（实际进程名是 `chinesesubfinde`），原先的 `pkill -x`
  永远匹配不到。改用 `pkill -f` 匹配安装目录的绝对路径。

## YYYY-MM-DD

- 首次发布
