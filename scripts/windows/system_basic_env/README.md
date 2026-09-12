# Windows 系统基础环境脚本

> ⚠️ **重要：本目录不在 chezmoi 安装链路内。**
> 全仓 `grep` 证实 `install_common_tools.ps1/.bat` **零调用者**——它们不参与 `install.sh` → `chezmoi apply`
> 的部署流程。Windows 的软件安装由 `.chezmoi/run_once_windows-*.sh.tmpl` 与
> `scripts/lib/chezmoi/package_install.sh`（winget + GitHub zip 回退）负责。
>
> 本目录保留为**手动排障/临时补装**用途。若确认不再需要，可整体删除（见 `AGENTS.md` 的删除边界规则）。

## 脚本清单

| 脚本 | 用途 | 调用方式 |
|------|------|---------|
| `install_common_tools.ps1` | PowerShell 版常用工具安装（winget/choco） | 手动：`powershell -ExecutionPolicy Bypass -File install_common_tools.ps1` |
| `install_common_tools.bat` | 上者的 BAT 入口 | 双击或命令行 |
| `set_xdg_config_home.ps1` / `.bat` | 设置用户级 `XDG_CONFIG_HOME` | 手动执行 |
| `configure_btop4win_path.ps1` | 配置 btop4win 的 PATH | 手动执行 |
| `add_btop4win_to_git_bash.sh` | 把 btop4win 加入 Git Bash PATH | 手动执行 |
| `setup_ime.sh` | 输入法环境配置 | 手动执行 |

## 无管理员权限原则（Windows 11 常见场景）

- **禁止** `cp`/`move` 到 `C:\Windows\Fonts`、`C:\Program Files` 等系统保护目录
- 字体安装用 PowerShell `Shell.Application` COM 对象（`Namespace(0x14).CopyHere()`），**无需管理员**
- 路径只用 `$HOME` / `$LOCALAPPDATA` / `$APPDATA`，**不依赖绝对路径**（如 `/c/Users/Administrator/`）
- 任何需要管理员的步骤必须提供用户级回退（或跳过后提示）

## 历史文档

原 754 行手册（含大量 PowerShell 执行策略/编码修复样板，与
[ENCODING_AND_LINE_ENDINGS.md](../../../docs/ENCODING_AND_LINE_ENDINGS.md) 重复）已于 2026-09 精简。
需要时可用 `git log --oneline -- scripts/windows/system_basic_env/README.md` 回溯。

## 相关

- 安装总入口：[docs/INSTALL_GUIDE.md](../../../docs/INSTALL_GUIDE.md)
- 换行符/编码规范：[docs/ENCODING_AND_LINE_ENDINGS.md](../../../docs/ENCODING_AND_LINE_ENDINGS.md)
