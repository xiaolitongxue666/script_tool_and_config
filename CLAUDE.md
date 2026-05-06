# script_tool_and_config

个人软件配置和常用脚本集合，使用 [chezmoi](https://www.chezmoi.io/) 统一管理 dotfiles。

## 跨平台 Shell 策略

不同平台使用不同的默认 Shell，模板文件按平台分别维护：

| 平台 | 默认 Shell | 模板文件 |
|------|-----------|---------|
| macOS | zsh | `.chezmoi/dot_zshrc.tmpl` |
| Linux | zsh（主）/ bash（备） | `.chezmoi/dot_zshrc.tmpl` / `.chezmoi/dot_bashrc.tmpl` |
| WSL | zsh | `.chezmoi/dot_zshrc.tmpl` |
| Windows (Git Bash) | bash | `.chezmoi/run_on_windows/dot_bashrc.tmpl` |

修改 Shell 配置时，需要根据目标平台选择对应的模板文件。

## claude-mem 项目级记忆自动检测

项目在 Shell 配置模板中内置了 claude-mem 记忆自动检测，覆盖所有平台：

- **`dot_zshrc.tmpl`** — macOS / Linux / WSL 的 zsh 用户
- **`dot_bashrc.tmpl`** — Linux bash 用户
- **`run_on_windows/dot_bashrc.tmpl`** — Windows Git Bash 用户

### 功能

`claude()` 命令被包装为函数，从 `$PWD` 向上递归查找 `.claude-mem/settings.json`：

- 找到 → 设置 `CLAUDE_MEM_DATA_DIR` 和 `CLAUDE_MEM_SETTINGS_PATH`，使用项目级记忆
- 未找到 → 使用 `~/.claude-mem` 全局记忆
- `claude-global()` → 强制使用全局记忆

### 设计原则

- 不同系统使用不同的 Shell，各模板独立维护
- macOS/Linux/WSL 的 zsh 配置共用 `dot_zshrc.tmpl`
- Windows 只通过 Git Bash 使用 bash，不涉及 zsh
- 所有模板中的 claude-mem 逻辑保持一致

## 多 Agent 兼容

本项目同时为以下 AI 编码工具提供了项目知识文件，内容保持一致：

| Agent | 识别文件 |
|-------|---------|
| Claude Code | `CLAUDE.md`（本文件） |
| Cursor | `.cursor/rules/project-rules.mdc` |
| GitHub Copilot / Codex | `.github/copilot-instructions.md` |

修改项目设计理念或模板策略时，需要同步更新以上所有文件。

## chezmoi 模板说明

- `.chezmoi/` — chezmoi 源目录
- `.chezmoi/dot_zshrc.tmpl` — zsh 配置模板（macOS / Linux / WSL）
- `.chezmoi/dot_bashrc.tmpl` — bash 配置模板（Linux）
- `.chezmoi/run_on_windows/` — Windows 特定配置
- 安装脚本位于 `.chezmoi/run_once_*.sh.tmpl`
- 详细文档见 `docs/` 目录
