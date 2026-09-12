# script_tool_and_config

个人软件配置和常用脚本集合，使用 [chezmoi](https://www.chezmoi.io/) 统一管理 dotfiles。

## 跨平台 Shell 策略

不同平台使用不同的终端 + Shell 组合：

| 平台 | 终端 | Shell | 模板文件 |
|------|------|-------|---------|
| Windows | Windows Terminal | Git Bash | WT：`.chezmoi/dot_config/windows-terminal/settings.json.tmpl`；Shell：`.chezmoi/dot_bashrc.tmpl` + `_bash_profile_windows.tmpl`（源根，仅 include 不部署）；多路复用：**rmux**（`dot_rmux.conf.tmpl`，手动启动） |
| macOS | Ghostty | zsh | `.chezmoi/dot_zshrc.tmpl` |
| Linux + WSL | Alacritty | zsh | `.chezmoi/dot_zshrc.tmpl` / `.chezmoi/dot_bashrc.tmpl`；多路复用：**tmux**（`dot_tmux.conf.tmpl` + TPM） |

修改 Shell 配置时，需要根据目标平台选择对应的模板文件。Fish Shell 已不再使用。

**变量展开（跨平台强制）**：`$var` 后紧跟中文/全角标点（如 `【】（）`）必须写 `${var}`。macOS UTF-8 locale 下 Bash 会把 CJK 字符首字节当变量名字符，`set -u` 下报 `unbound variable` 崩溃（2026-08 修 install_helpers.sh [5/6] 报告；详见 AGENTS.md「变量展开与全角标点」）。

### Windows rmux（与 tmux 分工）

- **仅 Windows**：`run_once_windows-install-rmux.sh.tmpl` 安装 rmux v0.5.0；`dot_rmux.conf.tmpl` → `~/.rmux.conf`（由 tmux 配置精简，**无插件**）。
- WT 仍默认 Git Bash；**不**改 `settings.json.tmpl` 自动进 rmux；**不**在 bashrc 里 `attach`。
- 排错与部署陷阱见 [docs/RMUX_WINDOWS.md](docs/RMUX_WINDOWS.md)。

## claude-mem 项目级记忆自动检测

项目在 Shell 配置模板中内置了 claude-mem 记忆自动检测，覆盖所有平台：

- **`dot_zshrc.tmpl`** — macOS / Linux / WSL 的 zsh 用户（含 `claude()` + `claude-global()`）
- **`dot_bashrc.tmpl`** — Linux bash 与 Windows Git Bash（`OS==windows` 分支），**仅 `claude()`**

> ⚠️ `_bash_profile_windows.tmpl`（源根，仅 include）**不含** claude-mem 逻辑（已实测 grep = 0 命中），
> 它只做登录 PATH 与 `source ~/.bashrc`。`claude-global()` **仅存在于 `dot_zshrc.tmpl`**，bash 下不可用。

### 功能

`claude()` 命令被包装为函数，从 `$PWD` 向上递归查找 `.claude-mem/settings.json`：

- 找到 → 设置 `CLAUDE_MEM_DATA_DIR`，使用项目级记忆
- 未找到 → 使用 `~/.claude-mem` 全局记忆
- `claude-global()` → 强制使用全局记忆（**仅 zsh 模板提供**）

### 设计原则

- 不同系统使用不同的 Shell，各模板独立维护
- macOS/Linux/WSL 的 zsh 配置共用 `dot_zshrc.tmpl`
- Windows 只通过 Git Bash 使用 bash，不涉及 zsh
- claude-mem 逻辑在 zsh/bash 模板中**能力不同**（zsh 多一个 `claude-global()`），并非完全一致

## CodeWhale / DeepSeek（已移除）

- **CodeWhale 已从本仓与 agent-config 移除（勿恢复）**；已删除 `run_once_92-install-codewhale`、`docs/CODEWHALE.md`、`.cursor/rules/codewhale.mdc`。
- **历史**：已删除 `run_once_92-install-deepseek.sh.tmpl`（勿恢复 cargo 安装路径）。
- AI Agent 配置见 [agent-config](../../AI/agent-config)（Claude / Cursor / Codex / Pi + CodeGraph）。

## Pi

- **不在本仓库**；见 [agent-config/docs/pi/README.md](../../AI/agent-config/docs/pi/README.md)（Phase 2：`bash scripts/install-tools.sh`）。

## 多 Agent 兼容

本项目同时为以下 AI 编码工具提供了项目知识文件，内容保持一致：

| Agent | 识别文件 |
|-------|---------|
| Claude Code | `CLAUDE.md`（本文件） |
| Cursor | `.cursor/rules/project-rules.mdc` |
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
       scripts/lib/chezmoi/chezmoi_core.sh
       ├── chezmoi_detect_proxy()     ← 代理检测（env→WSL→127.0.0.1:7890）
       ├── chezmoi_ensure_unlocked()  ← 锁检测与释放
       ├── chezmoi_run_apply()        ← 统一apply调用
       ├── chezmoi_verify_sync()      ← 同步验证（跨平台过滤）
```

### run_once 执行排序

chezmoi 按**目标名**（剥掉 `run_once_` 与 `.tmpl`）的字母序执行，ASCII 序 `'0' < '9' < 'i' < 'r'`：

```
1) 00-install-version-managers.sh   ← fnm + uv
2) 90-install-claude-code.sh        ┐
3) 91-install-codex.sh              ├ ★ AI CLI 排在 install-* 之前（不是之后）
4) 93-install-cursor.sh             ┘
5) install-*.sh（alacritty, clangd, common-tools, dwm, git, i3wm, lazyssh,
                 maccy, neovim, nerd-fonts, oh-my-posh, skhd, starship,
                 tmux, yabai, zsh）   ← 按字母序
6) linux-*.sh  macos-*.sh  windows-*.sh                ← 平台专属，最后
```

验证：`chezmoi --source .chezmoi managed | grep -E 'install-|^[0-9]' | sort`
详见 `AGENTS.md` §「run_once 执行排序规则」。

### connect.exe 检测顺序（Windows）

1. `$WINDOWS_GIT_CONNECT_PATH` 环境变量（`:133`）
2. `git` 同级目录的 `connect.exe`（`${git_bin}/connect.exe`，`:141`）
3. `cmd //c "if exist ..."` 探测 **C:/ 与 D:/** 盘（`:147`）
4. `${git_root}/mingw64/bin/connect.exe` → `${git_root}/usr/bin/connect.exe` → `$MINGW_PREFIX/bin/connect.exe`（`:158-163`）

> 以 `scripts/chezmoi/ensure_ssh_prereqs.sh` 源码为准。

## 项目规则（Agent 必须遵守）

### 输出语言（分而治之）

- **注释、文档、函数说明**：统一**中文**（如本文件）。
- **运行时输出**：按脚本类型二分 ——
  **库 / 被管道消费的脚本**（`scripts/lib/common.sh`、`scripts/chezmoi/**` 库、`tests/**`）用**英文**；
  **面向用户的交互脚本**（`install.sh`/`deploy.sh`、`deploy_utils/**`、平台脚本）**中文可接受**。
- **强制**：日志前缀一律 `[INFO]`/`[SUCCESS]`/`[WARNING]`/`[ERROR]`（英文），保证可 grep。
- 完整契约见 `AGENTS.md` §「注释与输出语言（分而治之）」与 §「库 vs 可执行：两份契约」。

### Chezmoi 调用规则

- 日常运维通过 `./scripts/manage_dotfiles.sh` 封装调用，不直接调 `chezmoi`
- **`chezmoi apply` 须含 `--force`**（`chezmoi_run_apply` 自动注入），避免 Windows 上 `.gitconfig` 等外部修改触发交互卡住
- Windows：`diagnose_deployment.sh` 跳过 `apply --dry-run`；锁占用时用 `fix_chezmoi_lock.sh` 或 `taskkill //F //IM chezmoi.exe`
- `install.sh` 和 `deploy.sh` 共享 `scripts/lib/chezmoi/chezmoi_core.sh` 中的 chezmoi 核心操作
- 入口职责：install.sh（首次安装）→ deploy.sh（增量）→ manage_dotfiles.sh（运维）
- **chezmoi 不读取 `CHEZMOI_SOURCE_DIR` 环境变量**；`sourceDir` 须写在 `~/.config/chezmoi/chezmoi.toml`（`chezmoi_ensure_user_config`）。配置路径映射单一来源：`scripts/lib/chezmoi/config_mappings.sh`
- Windows：`[interpreters.sh]` 必须指向 Git Bash，否则 run_once 报 `%1 is not a valid Win32 application`

### WSL 与 Windows 隔离

- 各 OS / WSL 的 `$HOME`、fnm、npm global **完全独立**，须在对应环境各跑一遍 install/apply
- WSL 里跑 `install.sh` **只装 WSL**，与宿主机 Windows npm **无关**（`:7890` 只是网络出口）
- 当前在 WSL：只用 WSL fnm/npm。`/mnt/host/wslg/runtime-dir/fnm_multishells` 是 **WSL 本机**，不是 Windows
- `/mnt/c`、`/mnt/host/c`、`C:\`、`AppData/Roaming/npm` 在 WSL 里不算已装；禁止从 WSL 改 Windows npm 或调用 `cmd.exe`
- 规则文件：`.cursor/rules/wsl-windows-isolation.mdc`

### 代理策略

- 包管理器操作（pacman/apt/brew）：使用国内源，**不**走代理
- GitHub/Git 克隆、curl 下载：走 7890 代理
- WSL 下从 `/etc/resolv.conf` 的 nameserver 推断宿主机 IP，补 :7890
- 统一入口：`chezmoi_core.sh` 的 `chezmoi_detect_proxy()`

### run_once 安装排序

排序以 chezmoi 目标名字母序为准（见上文「run_once 执行排序」），**不存在 0-5 的层级语义**：

- 最先：`00-install-version-managers`（fnm/uv，后续依赖它）
- 紧随其后：`90/91/93` 三个 AI CLI（claude-code / codex / cursor）
- 然后：`install-*` 按字母序（git、common-tools、zsh、starship、nerd-fonts、neovim、clangd、tmux…）
- 最后：`linux-*` / `macos-*` / `windows-*` 平台专属脚本
- 编号前缀只影响"排在 `install-*` 之前/之后"，**不能表达"N 层之后"**；
  `run_once_install-tmux` 为 **linux+darwin 专属**（不含 Windows）

### Windows 无管理员权限原则

- Windows 11 通常无管理员权限，run_once 脚本**不得依赖管理员权限**
- 禁止 `cp`/`move` 到 `C:\Windows\Fonts` 或 `C:\Program Files` 等系统保护目录
- 字体安装：使用 `powershell.exe -Command "$fonts.CopyHere(...)"`（Shell.Application COM 对象），**无需管理员**
- 路径：使用 `$HOME`、`$LOCALAPPDATA`、`$APPDATA`，**不依赖绝对路径**（如 `/c/Users/Administrator/`）

### Windows Terminal 配置规则（settings.json）

**路径自动检测**：Git Bash 路径**禁止硬编码** C 盘。`.chezmoi/detect_windows_git_paths.sh` 按 D/C 盘检测；`chezmoi_run_apply` 在 Windows 下用 `--override-data-file` 注入 `windows_git_*`（源内 `chezmoi.toml [data]` 的 Go 模板**不会**自动求值）。`settings.json.tmpl` 引用 `.windows_git_bash_path` 等变量。用户可在 `~/.config/chezmoi/chezmoi.toml.local` 的 `[data]` 覆盖。

**apply 后 WT 同步**：override-data 改变渲染结果时 `run_onchange` 的 `depends` 不一定触发；`chezmoi_sync_windows_terminal_config` 在 apply 成功后复制到 WT LocalState。

**JSON 反斜杠转义**：chezmoi 的 `replace "/" "\\"` 只产生单反斜杠，JSON 要求 `\\`。模板中必须用 `replace "/" "\\\\"`（4 个反斜杠 → 输出 2 个 → JSON 解析为 1 个）。

**run_onchange 依赖声明**：`run_onchange_windows-sync-terminal-config.sh.tmpl` 必须声明 `# chezmoi:depends:source:dot_config/windows-terminal/settings.json.tmpl`，否则模板变量变更时不会自动重新同步到 WT 配置目录。

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

`tests/` 共 **8 个**测试，全部纳入 CI 硬性阻断：

- `tests/test_contracts.sh` — ★ 结构与命名契约（目录分层 / 库 vs 入口 / `+x` / 文档链接 / 格式 / 部署入口唯一性）
- `tests/test_syntax.sh` — 全仓 `.sh`/`.tmpl` 语法检查 + 全角标点回归，输出到 `logs/`
- `tests/test_proxy.sh` — 代理地址检测/补全逻辑
- `tests/test_semver_compare.sh` — 版本号比较
- `tests/test_software_policies.sh` — software_policies 策略与脚本发现
- `tests/test_install_report_status.sh` — `install.sh [5/6]` 软件报告状态
- `tests/test_winget_msix_fallback.sh` — winget MSIX sideload 回退与主包选择
- `tests/test_bashrc_prompt_guard.sh` — bashrc 提示符 / TERM 守卫

- 统一入口：`for t in tests/test_*.sh; do bash "$t"; done`
- 测试的临时目录写在 `logs/` 下（自身 `mkdir -p`，故 `logs/` 可安全删除，会自动重建）
- **新增测试须与宿主环境解耦**（不要断言 `uname -m`/宿主路径等；CI 的 `macos-latest` 已是 arm64）

## chezmoi 模板说明

- `.chezmoi/` — chezmoi 源目录
- `.chezmoi/dot_zshrc.tmpl` — zsh 配置模板（macOS / Linux / WSL）
- `.chezmoi/dot_bashrc.tmpl` — bash 配置模板（Linux）
- `.chezmoi/_bash_profile_{darwin,windows}.tmpl` — 登录 shell 片段（仅 include，已 ignore）
- `scripts/lib/` — 纯函数库（被 source，不设 +x、不写 set -euo pipefail）；`scripts/chezmoi/` — 可执行入口；`scripts/tools/` — 独立工具（**永不删除**）；`scripts/deploy_utils/` — 部署辅助
- `.chezmoi/.chezmoiignore` — **模板**，按 OS 过滤平台专属 dotfile（`.yabairc`/`.skhdrc`/`.config/{ghostty,alacritty,i3}`/`secure_crt`）
- 安装脚本位于 `.chezmoi/run_once_*.sh.tmpl`
- 详细文档见 `docs/` 目录
