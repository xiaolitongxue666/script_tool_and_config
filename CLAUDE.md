# script_tool_and_config

个人软件配置和常用脚本集合，使用 [chezmoi](https://www.chezmoi.io/) 统一管理 dotfiles。

## 跨平台 Shell 策略

不同平台使用不同的终端 + Shell 组合：

| 平台 | 终端 | Shell | 模板文件 |
|------|------|-------|---------|
| Windows | Windows Terminal | Git Bash | WT：`.chezmoi/dot_config/windows-terminal/settings.json.tmpl`；Shell：`.chezmoi/dot_bashrc.tmpl` + `run_on_windows/_bash_profile_windows.tmpl`；多路复用：**rmux**（`dot_rmux.conf.tmpl`，手动启动） |
| macOS | Ghostty | zsh | `.chezmoi/dot_zshrc.tmpl` |
| Linux + WSL | Alacritty | zsh | `.chezmoi/dot_zshrc.tmpl` / `.chezmoi/dot_bashrc.tmpl`；多路复用：**tmux**（`dot_tmux.conf.tmpl` + TPM） |

修改 Shell 配置时，需要根据目标平台选择对应的模板文件。Fish Shell 已不再使用。

### Windows rmux（与 tmux 分工）

- **仅 Windows**：`run_on_windows/run_once_install-rmux.sh.tmpl` 安装 rmux v0.3.1；`dot_rmux.conf.tmpl` → `~/.rmux.conf`（由 tmux 配置精简，**无插件**）。
- WT 仍默认 Git Bash；**不**改 `settings.json.tmpl` 自动进 rmux；**不**在 bashrc 里 `attach`。
- 排错与部署陷阱见 [docs/RMUX_WINDOWS.md](docs/RMUX_WINDOWS.md)。

## claude-mem 项目级记忆自动检测

项目在 Shell 配置模板中内置了 claude-mem 记忆自动检测，覆盖所有平台：

- **`dot_zshrc.tmpl`** — macOS / Linux / WSL 的 zsh 用户
- **`dot_bashrc.tmpl`** — Linux bash 与 Windows Git Bash（`OS==windows` 分支）
- **`run_on_windows/_bash_profile_windows.tmpl`** — Windows 登录 shell（include 进 `dot_bash_profile.tmpl`）

### 功能

`claude()` 命令被包装为函数，从 `$PWD` 向上递归查找 `.claude-mem/settings.json`：

- 找到 → 设置 `CLAUDE_MEM_DATA_DIR`，使用项目级记忆
- 未找到 → 使用 `~/.claude-mem` 全局记忆
- `claude-global()` → 强制使用全局记忆

### 设计原则

- 不同系统使用不同的 Shell，各模板独立维护
- macOS/Linux/WSL 的 zsh 配置共用 `dot_zshrc.tmpl`
- Windows 只通过 Git Bash 使用 bash，不涉及 zsh
- 所有模板中的 claude-mem 逻辑保持一致

## CodeWhale（终端 AI，Layer 4）

- 安装：`.chezmoi/run_once_92-install-codewhale.sh.tmpl`（`npm install -g codewhale`；已移除 `install-deepseek`）
- WSL：fnm/npm 全局安装；勿从 WSL 修改 Windows npm；部署用 `./deploy.sh` 或 `manage_dotfiles.sh apply`
- 状态：`~/.codewhale/` 默认；`~/.deepseek/` 只读回退；7890 代理
- 文档：`docs/CODEWHALE.md`、`docs/PROJECT_AGENT_MEMORY.md`

## 多 Agent 兼容

本项目同时为以下 AI 编码工具提供了项目知识文件，内容保持一致：

| Agent | 识别文件 |
|-------|---------|
| Claude Code | `CLAUDE.md`（本文件） |
| Cursor | `.cursor/rules/project-rules.mdc`、`.cursor/rules/codewhale.mdc` |
| GitHub Copilot / Codex | `.github/copilot-instructions.md` |
| 项目 Agent 记忆（可提交） | `docs/PROJECT_AGENT_MEMORY.md`（权威）、`docs/PROJECT_MEMORY.md`（紧凑） |

修改项目设计理念或模板策略时，需要同步更新以上所有文件及 `docs/PROJECT_MEMORY.md`。

## 架构概要

### 入口脚本职责

```
install.sh  ── 首次安装 ── 装chezmoi→写config→apply→验证         ← 全流程
deploy.sh   ── 增量部署 ── 锁检测→status→diff→apply               ← 增量
manage_dotfiles.sh ─ 运维入口 ─ status/diff/apply/edit            ← 日常
                ↓ 共享封装层 ↓
       scripts/chezmoi/chezmoi_core.sh
       ├── chezmoi_detect_proxy()     ← 代理检测（env→WSL→127.0.0.1:7890）
       ├── chezmoi_ensure_unlocked()  ← 锁检测与释放
       ├── chezmoi_run_apply()        ← 统一apply调用
       ├── chezmoi_verify_sync()      ← 同步验证（跨平台过滤）
```

### run_once 执行排序

层号 0-5，字母序自动排序：

```
Layer 0: run_once_00-install-version-managers      ← fnm + uv
Layer 1: install-common-tools, install-git
Layer 2: install-zsh, install-starship, install-nerd-fonts
Layer 3: install-neovim                             ← 仅安装二进制
Layer 4: run_once_90-{claude-code}, _91-{codex}, _92-{codewhale}
         run_once_93-install-cursor                 ← 仅 GUI 环境
Layer 5: install-tmux + run_on_{linux,darwin}；Windows：`install-rmux`、`install-oh-my-posh`、`install-windows-terminal`
```

### connect.exe 检测顺序（Windows）

1. `$WINDOWS_GIT_CONNECT_PATH` 环境变量
2. `git` 同级目录的 `connect.exe`（`cmd/`）
3. `git` 根目录的 `mingw64/bin/connect.exe`（Git for Windows 标准路径，本次修复）
4. `$MINGW_PREFIX/bin/connect.exe`
5. `cmd //c "if exist ..."` 回退检查 C:/ 和 D:/

## 项目规则（Agent 必须遵守）

### 输出语言

- **注释、文档、函数说明**使用中文（如本文件）
- **运行时输出**（log_info/log_success/log_warning/log_error/echo 打到屏幕的消息）统一使用**英文**

### Chezmoi 调用规则

- 日常运维通过 `./scripts/manage_dotfiles.sh` 封装调用，不直接调 `chezmoi`
- **`chezmoi apply` 须含 `--force`**（`chezmoi_run_apply` 自动注入），避免 Windows 上 `.gitconfig` 等外部修改触发交互卡住
- Windows：`diagnose_deployment.sh` 跳过 `apply --dry-run`；锁占用时用 `fix_chezmoi_lock.sh` 或 `taskkill //F //IM chezmoi.exe`
- `install.sh` 和 `deploy.sh` 共享 `scripts/chezmoi/chezmoi_core.sh` 中的 chezmoi 核心操作
- 入口职责：install.sh（首次安装）→ deploy.sh（增量）→ manage_dotfiles.sh（运维）
- **chezmoi 不读取 `CHEZMOI_SOURCE_DIR` 环境变量**；`sourceDir` 须写在 `~/.config/chezmoi/chezmoi.toml`（`chezmoi_ensure_user_config`）。配置路径映射单一来源：`scripts/chezmoi/config_mappings.sh`
- Windows：`[interpreters.sh]` 必须指向 Git Bash，否则 run_once 报 `%1 is not a valid Win32 application`

### 代理策略

- 包管理器操作（pacman/apt/brew）：使用国内源，**不**走代理
- GitHub/Git 克隆、curl 下载：走 7890 代理
- WSL 下从 `/etc/resolv.conf` 的 nameserver 推断宿主机 IP，补 :7890
- 统一入口：`chezmoi_core.sh` 的 `chezmoi_detect_proxy()`

### run_once 安装排序

Layer 0: fnm/uv（版本管理器，必须最先）
Layer 1: git + common-tools
Layer 2: zsh + OMZ + starship + nerd-fonts
Layer 3: neovim（仅安装二进制，配置由其他项目管理）
Layer 4: claude-code + codex + codewhale（AI agent CLI，仅二进制）
Layer 4+: cursor（仅 GUI 环境，Linux/WSL 检测 DISPLAY）
Layer 5: tmux + 平台特定（linux/darwin/windows 下的 run_on_*）

### Windows 无管理员权限原则

- Windows 11 通常无管理员权限，run_once 脚本**不得依赖管理员权限**
- 禁止 `cp`/`move` 到 `C:\Windows\Fonts` 或 `C:\Program Files` 等系统保护目录
- 字体安装：使用 `powershell.exe -Command "$fonts.CopyHere(...)"`（Shell.Application COM 对象），**无需管理员**
- 路径：使用 `$HOME`、`$LOCALAPPDATA`、`$APPDATA`，**不依赖绝对路径**（如 `/c/Users/Administrator/`）

### Windows Terminal 配置规则（settings.json）

**路径自动检测**：Git Bash 路径**禁止硬编码** C 盘。`.chezmoi/detect_windows_git_paths.sh` 按 D/C 盘检测；`chezmoi_run_apply` 在 Windows 下用 `--override-data-file` 注入 `windows_git_*`（源内 `chezmoi.toml [data]` 的 Go 模板**不会**自动求值）。`settings.json.tmpl` 引用 `.windows_git_bash_path` 等变量。用户可在 `~/.config/chezmoi/chezmoi.toml.local` 的 `[data]` 覆盖。

**apply 后 WT 同步**：override-data 改变渲染结果时 `run_onchange` 的 `depends` 不一定触发；`chezmoi_sync_windows_terminal_config` 在 apply 成功后复制到 WT LocalState。

**JSON 反斜杠转义**：chezmoi 的 `replace "/" "\\"` 只产生单反斜杠，JSON 要求 `\\`。模板中必须用 `replace "/" "\\\\"`（4 个反斜杠 → 输出 2 个 → JSON 解析为 1 个）。

**run_onchange 依赖声明**：`run_onchange_sync_windows_terminal_config.sh.tmpl` 必须声明 `# chezmoi:depends:source:dot_config/windows-terminal/settings.json.tmpl`，否则模板变量变更时不会自动重新同步到 WT 配置目录。

**字体验证**：模板中引用的字体名必须与实际安装的字体族名完全一致。使用 PowerShell 验证：
```powershell
[System.Reflection.Assembly]::LoadWithPartialName('System.Drawing')
(New-Object System.Drawing.Text.InstalledFontCollection).Families | Where-Object { $_.Name -match 'Nerd' }
```

### run_once 脚本失败处理

- 单个 run_once 失败（exit ≠ 0）→ `chezmoi apply` 失败 → `install.sh` 的 `set -e` 触发的 `error_exit` 终止整个安装
- **必须**：平台不适用 → `[INFO]` + `return 0`（跳过），不得 `exit 1`
- **必须**：工具已由系统提供 → 提示跳过（如 Git Bash 自带 Zsh，不重复安装）
- `[WARNING]` + `return 0` = 非致命；`[ERROR]` + `exit 1` = 致命

### stdout/stderr 规范

- 函数通过 stdout 返回值时（`result=$(func)`），内部日志**必须**输出到 stderr（`>&2`）
- 典型错误：`echo "[INFO] ..."` 混入 stdout 被 `$()` 捕获，导致变量含混合文本、后续数值比较语法错误

### 测试

- `tests/test_syntax.sh` — 批量语法检查，输出到 `logs/`
- `tests/test_proxy.sh` — 代理检测逻辑测试
- 所有测试脚本输出到 `logs/` 目录

## chezmoi 模板说明

- `.chezmoi/` — chezmoi 源目录
- `.chezmoi/dot_zshrc.tmpl` — zsh 配置模板（macOS / Linux / WSL）
- `.chezmoi/dot_bashrc.tmpl` — bash 配置模板（Linux）
- `.chezmoi/run_on_windows/` — Windows 特定配置
- 安装脚本位于 `.chezmoi/run_once_*.sh.tmpl`
- 详细文档见 `docs/` 目录
