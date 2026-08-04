# cursor_clangd

跨平台安装 / 校验 **clangd** 与 Cursor **clangd 扩展**。完整说明见 [docs/CURSOR_CLANGD.md](../../../docs/CURSOR_CLANGD.md)。

| 脚本 | 作用 |
|------|------|
| `install_clangd.sh` | 安装 clangd 二进制（不装 Cursor） |
| `install_cursor_clangd_extension.sh` | 有 `cursor` CLI 时安装扩展；否则跳过 |
| `setup_cursor_clangd.sh` | 上述两步 + `verify_clangd.sh` |
| `verify_clangd.sh` | 冒烟检查 |

chezmoi：`run_once_install-clangd.sh.tmpl` 调用 `install_clangd.sh`。  
`run_once_93-install-cursor` 仍负责 Cursor GUI，无 DISPLAY/WAYLAND 时跳过。
