# 仓库编码代理指南

本文件包含面向该 shell 脚本和 dotfiles 仓库的编码代理指南。


## 项目两大组成部分

本项目包含两类完全不同的脚本，修改时必须严格区分：

### 一、独立工具脚本 (Standalone Tools)

位置：`scripts/tools/standalone_tool_script/`、`scripts/tools/project_tools/`、`scripts/tools/ffmpeg_magic/`、`scripts/tools/git_templates/`、`scripts/tools/shc/`、`scripts/tools/patch_examples/`、`scripts/tools/auto_edit_redis_config/`

- 通用独立工具，与项目部署/配置无关，每个脚本可单独使用
- 不依赖 chezmoi 或项目其他部署设施
- **永远不要删除** — 它们是项目的核心资产之一，不是冗余代码

### 二、多系统部署和配置工具 (Deployment & Configuration)

位置：`install.sh`、`deploy.sh`、`scripts/chezmoi/`、`scripts/deploy_utils/`、`.chezmoi/`

- 自动检测 OS，安装该 OS 所需的工具软件
- 通过 chezmoi 模板生成配置文件并部署到正确位置
- 中间使用 `deploy_utils/` 辅助脚本完成备份、诊断、同步等操作
- **删除冗余仅限此类**：废弃安装脚本、重复逻辑、死引用

### 核心使用场景

新操作系统 → `./install.sh` 安装该 OS 所需工具软件 → chezmoi 模板渲染配置文件 → 部署到 `~/` 正确位置 → 使用 `deploy_utils/` 完成备份、诊断、同步

- 部署只能通过 chezmoi 应用模板的方式进行。


## 项目 Agent 记忆

- **可提交记忆**（本仓库）：[`docs/PROJECT_AGENT_MEMORY.md`](docs/PROJECT_AGENT_MEMORY.md)（权威）、[`docs/PROJECT_MEMORY.md`](docs/PROJECT_MEMORY.md)（紧凑）。
- **已删除**：`openspec/`（2026-09 — CLI 从未安装、`specs/`/`changes/` 从未建立、零代码引用；如需规范驱动开发重新 `openspec init`）。
- **已删除**：`.chezmoi/run_once_92-install-deepseek.sh.tmpl`、`run_once_92-install-codewhale`（勿恢复）。**CodeWhale 已从本仓与 agent-config 移除（勿恢复）**；AI Agent 配置见 agent-config（Claude / Cursor / Codex / Pi + CodeGraph）。
- **claude-mem 运行时数据**：`.claude-mem/` 已在 `.gitignore` 中忽略（与可提交的 `PROJECT_AGENT_MEMORY.md` 分工不同）；
  注意该目录**当前在本机并不存在**（仅忽略规则存在），不要假设它已初始化。


## 构建/检查/测试命令

### 语法检查

```bash
# 单个脚本语法检查
bash -n <script>.sh

# 批量语法测试（推荐）
bash tests/test_syntax.sh

# 代理逻辑测试
bash tests/test_proxy.sh

# 验证编码和换行符
./scripts/tools/standalone_tool_script/check_and_fix_encoding.sh

# 规范化换行符为 LF（Windows 脚本除外）
./scripts/tools/standalone_tool_script/ensure_lf_line_endings.sh
```

### 配置管理

```bash
# 推荐：通过脚本封装调用 chezmoi（而非直接 chezmoi 命令）
./scripts/manage_dotfiles.sh status  # 配置状态
./scripts/manage_dotfiles.sh diff    # 配置差异
./scripts/manage_dotfiles.sh apply   # 应用更改
./scripts/chezmoi/diagnose_chezmoi.sh  # 验证配置

# Chezmoi 核心操作由 scripts/lib/chezmoi/chezmoi_core.sh 统一封装，
# install.sh 和 deploy.sh 共享此封装层。
```

### Neovim 健康检查

一键安装后可选生成 checkhealth 日志并据此修复：

```bash
./scripts/deploy_utils/nvim_checkhealth_to_log.sh   # 生成 nvim_checkhealth.log
# 查看 log 中 ERROR/WARNING，按 ~/.config/nvim 内 README 或上游 nvim 仓库「常见 checkhealth 问题与处理」修复
```

### 测试

```bash
# 统一测试：运行 tests/ 目录下的所有测试
for t in tests/test_*.sh; do bash "$t"; done

# 单测试运行示例
bash tests/test_syntax.sh      # 所有 .sh/.tmpl 语法检查 + 全角标点回归
bash tests/test_contracts.sh   # ★ 结构与命名契约（目录分层/库vs入口/链接/格式）
bash tests/test_proxy.sh       # 代理地址检测/补全逻辑测试
```

**CI**：`.github/workflows/ci.yml` 在 ubuntu + macos 上跑 `test_syntax` / `test_contracts` /
全部单元测试 / 编码检查（**硬性阻断**），shellcheck 为**软性观测**（历史存量告警，逐步收紧）。
CI **只跑只读检查**，不执行 `install.sh` 或 `chezmoi apply`。

nvim 独立化相关改动后，可按 [docs/NEOVIM_AND_THIS_REPO.md](docs/NEOVIM_AND_THIS_REPO.md) §验证清单 做手动验证。


## 安装流程

### 各系统入口

| 系统 | 入口脚本 | 说明 |
|------|---------|------|
| Linux | `./install.sh` | 自动检测发行版和 WSL |
| macOS | `./install.sh` | 需先安装 Homebrew |
| Windows | `./install.sh`（Git Bash — 推荐，不需要管理员）或 `scripts/windows/install_with_chezmoi.bat` | BAT 需管理员权限（Win10）；Win11 无管理员时推荐 Git Bash 方式 |

### `./install.sh` 调用链

```
install.sh
  ├── scripts/chezmoi/install_chezmoi.sh         安装 chezmoi
  ├── scripts/lib/chezmoi/detect_platform.sh          平台/包管理器 SSOT
  ├── scripts/lib/chezmoi/common_install.sh           安装函数聚合（packages/brew/proxy）
  ├── scripts/lib/chezmoi/chezmoi_core.sh             核心封装（锁检测、apply、验证）
  ├── chezmoi apply -v --force                    核心部署
  │   ├── run_once_00-install-version-managers  版本管理器（必须最先）
  │   ├── run_once_{90,91,93}-*                 AI agent CLI
  │   ├── run_once_install-*.sh.tmpl            跨平台工具（按目标名字母序）
  │   └── run_once_{linux,macos,windows}-*.tmpl 平台专属（排序最后）
  └── scripts/chezmoi/verify_installation.sh    验证安装结果
```

### run_once 脚本分类（按模板首行的 `if` 门控）

平台归属由**模板内的 `if eq .chezmoi.os` 条件**决定；**全部 run_once 脚本都在 `.chezmoi/` 源根**，
平台专属脚本用文件名前缀 `linux-` / `macos-` / `windows-` 标识（排序上落在 `install-*` 之后）。

- **三平台通用**（linux/darwin/windows）：`run_once_00-install-version-managers`、`run_once_90-install-claude-code`、`run_once_91-install-codex`、`run_once_93-install-cursor`、`run_once_install-{clangd,common-tools,git,neovim,nerd-fonts,starship,zsh}`
- **仅 linux + darwin**：`run_once_install-tmux`（**不含 Windows**）
- **仅 linux**：`run_once_install-{alacritty,dwm,i3wm,lazyssh}`
- **仅 darwin**：`run_once_install-{maccy,skhd,yabai}`
- **仅 windows**：`run_once_install-oh-my-posh`
- **仅 linux**（`run_once_linux-*`）：`configure-pacman`、`install-arch-base-packages`、`install-aur-helper`
- **仅 macOS**（`run_once_macos-*`）：`configure-homebrew`、`install-connect`、`install-ghostty`
- **仅 windows**（`run_once_windows-*`）：`install-rmux`、`install-windows-terminal`

> 全部 run_once 脚本现均在 **`.chezmoi/` 源根**，平台专属以 `linux-`/`macos-`/`windows-` 前缀命名
> （排在 `install-*` 之后，与"平台脚本最后执行"一致）。已废止的 `run_after_*` 在本仓**不存在任何文件**。

### ⚠️ chezmoi 平台目录陷阱与平台专属配置的写法（必读）

**`run_on_linux/` `run_on_darwin/` `run_on_windows/` 从来不是 chezmoi 的平台目录**——
chezmoi 只按 **basename** 识别 `run_once_` / `run_onchange_` 脚本前缀，子目录会被当作**普通目标目录**
原样部署到 `$HOME`。曾因此产生三类问题（2026-09 全部修复）：

1. 平台专属 dotfile 落到 `~/run_on_*/` 而非真实路径 → **yabai / i3 / Ghostty 读不到配置**；
2. 含脚本的源目录会在 `$HOME` 创建同名空目录（`~/run_on_{linux,darwin,windows}/`）；
3. `.chezmoi/chezmoi.toml` 与 `.chezmoi/detect_windows_git_paths.sh` 被当作普通文件，
   在 `$HOME` 生成 `~/chezmoi.toml`、`~/detect_windows_git_paths.sh`。

**现行规则**：所有平台专属配置一律放**源根**，用下面两种机制之一做平台过滤。

**机制 A：平台专属 dotfile → 模板化 `.chezmoiignore`**（推荐）

| 原位置（错） | 现位置（对） | 过滤方式 |
|---|---|---|
| `run_on_linux/dot_config/alacritty/` | `dot_config/alacritty/` | `.chezmoiignore` 非 linux 时忽略 |
| `run_on_linux/dot_config/i3/` | `dot_config/i3/` | 同上 |
| `run_on_darwin/dot_yabairc.tmpl` | `dot_yabairc.tmpl` | 非 darwin 时忽略 |
| `run_on_darwin/dot_skhdrc.tmpl` | `dot_skhdrc.tmpl` | 同上 |
| `run_on_darwin/dot_config/ghostty/` | `dot_config/ghostty/` | 同上 |
| `run_on_windows/secure_crt/` | `secure_crt/` | 非 windows 时忽略 |
| `_bash_profile_*.tmpl` | `_bash_profile_*.tmpl`（源根） | 始终忽略（仅 include 用） |

**机制 B：平台专属脚本 → 文件名平台前缀**

```
run_once_linux-configure-pacman.sh.tmpl            → configure-pacman.sh
run_once_macos-install-ghostty.sh.tmpl             → ghostty.sh
run_once_windows-install-rmux.sh.tmpl              → rmux.sh
run_onchange_macos-sync-ghostty-config-to-app-support.sh.tmpl
```

- 排序：`'0' < '9' < 'i' < 'l' < 'm' < 'w'` → 版本管理器 → AI CLI → `install-*` → 平台专属（最后）✅
- `scripts/lib/chezmoi/install_helpers.sh` 的 `extract_software_name_from_script()` 会剥掉平台前缀，
  因此平台过滤、[5/6] 报告别名、升级策略都能正确取到 `ghostty` / `configure-pacman` 等语义名。

**硬性规则**：

1. **平台专属 dotfile 一律放源根** + `.chezmoiignore` OS 条件过滤。
2. **平台专属脚本一律放源根** + `linux-`/`macos-`/`windows-` 前缀；**禁止**再建 `run_on_*/` 子目录。
3. `.chezmoiignore` 是**模板**，可用 `.chezmoi.os`；但它**不支持 `!` 取反**
   （实测：取反会让该目录下脚本一起被忽略、**永不执行**）。
4. `include` 函数相对**源根**解析，**不是** `.chezmoitemplates/`。
5. 重命名/移动 `run_once_*` 脚本**不会**导致重跑 —— 状态键是 `sha256(渲染后内容)`，与路径无关
   （已实测验证）。改内容才会重跑。

**实测验证方式**：

```bash
# 渲染后的忽略清单（当前 OS）
chezmoi --source .chezmoi execute-template < .chezmoi/.chezmoiignore
# 实际被忽略的目标
chezmoi --source .chezmoi ignored
# 不落盘验证：复制源 + 脚本 no-op 化 + 假 HOME apply
```

### 辅助部署

- `./deploy.sh`：快速重新部署，要求 chezmoi 已安装；OMZ/插件由 `.chezmoiexternal.toml.tmpl` + apply 负责，末尾仅 `check_zsh_omz` 诊断
- `scripts/manage_dotfiles.sh`：配置管理入口（status/diff/apply/edit）

### run_once 执行排序规则（以 chezmoi 实际行为为准）

chezmoi 按**目标名（剥掉 `run_once_` 前缀与 `.tmpl` 后的名字）的字母序**执行。ASCII 序 `'0' < '9' < 'i' < 'r'`，因此实测顺序为：

```
1. 00-install-version-managers.sh     ← fnm/uv（必须最先；后续依赖 node/uv）
2. 90-install-claude-code.sh          ┐
3. 91-install-codex.sh                ├ ★ AI CLI 在 install-* 之前执行，不是之后
4. 93-install-cursor.sh               ┘
5. install-alacritty.sh               ┐
   install-clangd.sh                  │
   install-common-tools.sh            │
   install-dwm.sh                     │
   install-git.sh                     │  按字母序
   install-i3wm.sh                    │
   install-lazyssh.sh                 │
   install-maccy.sh                   │
   install-neovim.sh                  │
   install-nerd-fonts.sh              │
   install-oh-my-posh.sh              │
   install-skhd.sh                    │
   install-starship.sh                │
   install-tmux.sh                    │
   install-yabai.sh                   │
   install-zsh.sh                     ┘
6. linux-*.sh  macos-*.sh  windows-*.sh                ← 平台专属，最后
```

验证方式：`chezmoi --source .chezmoi managed | grep -E 'install-|^[0-9]' | sort`

**推论**：

- 编号脚本（`90-`/`91-`/`93-`）的数字前缀**只会让它们排到 `install-*` 之前**，不能表达"第 N 层之后"。
- 想让某脚本真正最后执行，用排在 `w` 之后的前缀（如 `z-`），或在脚本内自行等待依赖。
- 移动/重命名脚本**不触发重跑**（状态键 = `sha256(渲染后内容)`）；只有改内容才会重跑。

### 部署入口职责矩阵（必须遵守）

| 入口脚本 | 定位 | 应该做 | 不应该做 |
|------|------|------|------|
| `install.sh` | 首次安装入口 | 安装/检查 chezmoi、初始化环境、执行 `chezmoi apply -v --force`、调用安装验证脚本 | 承担日常运维命令分发 |
| `deploy.sh` | 增量部署入口 | 在 chezmoi 已可用前提下执行增量部署与修复流程（含锁处理、诊断、必要校验） | 替代首次安装流程、扩展为通用命令分发器 |
| `scripts/manage_dotfiles.sh` | 运维命令入口 | 提供 `status/diff/apply/edit/list` 等操作封装 | 内置复杂平台安装逻辑 |

- 三个入口都可触达 chezmoi，但必须保持以上职责边界，避免重复实现和分叉修复。

### Windows 安装原则（无管理员权限）

- **Windows 10**：通常拥有管理员权限，BAT/ps1 可以写入系统目录（如 `C:\Windows\Fonts`）
- **Windows 11**：无管理员权限是常见场景，**所有 run_once 脚本不得依赖管理员权限**
- **硬性规则**：
  - 禁止在 run_once 中 `cp`/`move` 文件到 `C:\Windows\Fonts` 或 `C:\Program Files` 等系统保护目录
  - 字体安装使用 `powershell.exe` 的 `Shell.Application` COM 对象（`Namespace(0x14).CopyHere()`），无需管理员权限
  - 任何需要管理员权限的操作（如注册字体、修改系统 PATH）必须提供非管理员回退方案（如用户级安装、跳过并提示）
- **路径原则**：不依赖绝对路径（如 `/c/Users/Administrator/`），使用 `$HOME`、`$LOCALAPPDATA`、`$APPDATA` 等环境变量

### run_once 脚本失败处理规则

- **单个 run_once 脚本失败（exit ≠ 0）会导致整个 `chezmoi apply` 失败，进而触发 `install.sh` 中 `set -e` 的 `error_exit`，终止后续步骤 [4/6]～[6/6]**
- **`install.sh [4/6]`** 调用 `ensure_platform_software.sh` 补装缺失并默认升级（`--no-upgrade` 可关）；全量补装/升级用 `install.sh`，日常 dotfiles 用 `deploy.sh`
- **必须遵守**：
  1. 平台不适用的功能 → **优雅跳过**（输出 `[INFO]` 日志、`return 0`），**不得 `exit 1`**
  2. 工具已由系统提供 → 提示并跳过（如 Windows Git Bash 自带 Zsh，无需额外安装）
  3. 下载/安装失败且非关键 → `return 0` 并输出 `[WARNING]`，**不阻断整体安装流程**
  4. 只有真实错误（如实为 macOS/Linux 却被判为 Windows）才允许 `exit 1`
- **关键词区分**：
  - `[WARNING]` + `return 0` = 非致命，继续安装
  - `[ERROR]` + `exit 1` = 致命，终止安装
- **检查清单**：每个 run_once 脚本提交前必须确认：
  - 每个 `exit 1` 是否确实为致命错误？
  - 非 Windows 平台是否有误判 Windows 并 exit？


## 代码风格指南

### 文件格式

- **编码**: UTF-8（无 BOM）
- **换行符**: LF (`\n`)，Windows 脚本（`.bat`, `.ps1`, `.cmd`）使用 CRLF
- **缩进**: 4 个空格（不用制表符）
- **末尾换行**: 所有文件必须以换行符结尾

### 库 vs 可执行：两份契约（**先分类再写代码**）

`AGENTS.md` 旧版只写了一句"所有脚本应可执行"，导致 45 个文件被误判违规。实际必须二分：

| | **库（被 source）** | **可执行脚本（独立进程）** |
|---|---|---|
| 位置 | `scripts/lib/**`（含 `lib/chezmoi/`） | `scripts/chezmoi/**`、`scripts/deploy_utils/**`、`scripts/{linux,windows}/**`、`scripts/tools/**` |
| shebang | 保留（便于语法检查），但不靠它运行 | `#!/usr/bin/env bash` **必需** |
| `set -euo pipefail` | ❌ **禁止**（会污染调用方 shell 的选项） | ✅ **必需** |
| `chmod +x` | ❌ 不设可执行位 | ✅ 必须可执行 |
| `start_script`/`end_script` | ❌ 不调用（会 `exit`） | ✅ 成对调用 |
| 副作用 | ❌ 加载时不得有副作用 | ✅ 无限制 |
| 日志 | 通过 `log_*`；被 `$(...)` 捕获的函数，结果走 stdout、**日志必须走 stderr** | 同左 |

**判断方法**：文件被别的脚本 `source` → 库；被 `bash <file>` 执行 → 可执行。
目录已按此契约分离（2026-09 P4）：**库 = `scripts/lib/`**（含 `scripts/lib/chezmoi/`），**入口 = `scripts/chezmoi/`、`scripts/deploy_utils/`、`scripts/{linux,windows}/`**。

**幂等要求**：库内 `readonly` 变量重复 source 会报错 → 加载前用独有函数探针守卫：

```bash
if ! declare -F echo_color_message >/dev/null 2>&1; then
    source "${_COMMON_SH_PATH}"
fi
```

### Shell 脚本结构

```bash
#!/usr/bin/env bash
set -euo pipefail
umask 022

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"

# 引入公共库
COMMON_LIB="${PROJECT_ROOT}/scripts/lib/common.sh"
if [[ -f "${COMMON_LIB}" ]]; then
    source "${COMMON_LIB}"
else
    function log_info() { echo "[INFO] $*"; }
    function log_success() { echo "[SUCCESS] $*"; }
    function log_warning() { echo "[WARNING] $*"; }
    function log_error() { echo "[ERROR] $*" >&2; }
    function error_exit() { log_error "$1"; exit "${2:-1}"; }
fi

start_script "脚本名称"
# ... 脚本内容 ...
end_script
```

### 命名规范

- **常量**: `UPPER_CASE_WITH_UNDERSCORES`（用 `readonly` 声明）
- **全局变量**: `lower_case_with_underscores`
- **局部变量**: `local my_var="$1"`
- **函数**: `snake_case`（公共），`_snake_case`（私有）
- **布尔检查**: `is_<condition>` 或 `has_<property>`

### 错误处理

```bash
set -euo pipefail
trap 'log_error "检测到错误，正在退出脚本"; exit 1' ERR
check_command "wget"
if [[ -z "$1" ]]; then
    error_exit "参数不能为空"
fi
```

### 日志函数

```bash
log_info "信息消息"          # 蓝色
log_success "成功消息"       # 绿色
log_warning "警告消息"       # 黄色（非致命）
log_error "错误消息"         # 红色
DEBUG=1 log_debug "调试信息" # 青色（仅 DEBUG=1 时）
```

### stdout/stderr 使用规范

- **函数返回值通过 stdout 传递时**（如 `result=$(some_func)`），函数内部的日志/提示信息必须输出到 **stderr**（`>&2`），**确保 stdout 只有纯结果值**
- **典型错误模式**：
  ```bash
  # ❌ 错误：日志混入 stdout，被调用方 $() 捕获
  _count_fonts() {
      echo "[INFO] Counting fonts..."  # 混入 stdout
      echo "${count}"                  # 结果
  }
  result=$(_count_fonts)  # result = "[INFO] Counting fonts...\n3"

  # ✅ 正确：日志输出到 stderr
  _count_fonts() {
      echo "[INFO] Counting fonts..." >&2
      echo "${count}"
  }
  result=$(_count_fonts)  # result = "3"
  ```
- 此规则适用于所有 run_once 脚本和部署辅助脚本

### Chezmoi 模板语法

```bash
{{- if or (eq .chezmoi.os "linux") (eq .chezmoi.os "darwin") -}}
#!/usr/bin/env bash
# Linux/macOS 特定
{{- else if eq .chezmoi.os "windows" -}}
# Windows 特定
{{- end -}}
```

### OS 检测和包管理

```bash
detect_os_and_package_manager() {
    OS="$(uname -s)"
    if [[ "$OS" == "Darwin" ]]; then
        PLATFORM="macos"; PACKAGE_MANAGER="brew"
    elif [[ "$OS" == "Linux" ]]; then
        PLATFORM="linux"
        command -v pacman &> /dev/null && PACKAGE_MANAGER="pacman"
        command -v apt-get &> /dev/null && PACKAGE_MANAGER="apt"
        command -v dnf &> /dev/null && PACKAGE_MANAGER="dnf"
    elif [[ "$OS" =~ ^(MINGW|MSYS|CYGWIN) ]]; then
        PLATFORM="windows"
        command -v winget &> /dev/null && PACKAGE_MANAGER="winget"
    fi
}

install_package() {
    local pkg="$1"
    case "$PACKAGE_MANAGER" in
        pacman) sudo pacman -S --noconfirm "$pkg" ;;
        apt) sudo apt-get install -y "$pkg" ;;
        brew) brew install "$pkg" ;;
        winget) winget install -e --id "$pkg" ;;
    esac
}
```

### 文件操作

```bash
backup_file() {
    local file="$1"
    if [[ -f "$file" ]]; then
        local backup="${file}.backup.$(date +%Y%m%d_%H%M%S)"
        cp "$file" "$backup"
        log_info "文件已备份: ${backup}"
    fi
}

ensure_directory() {
    local dir="$1"
    if [[ ! -d "$dir" ]]; then
        mkdir -p "$dir"
        log_info "目录已创建: ${dir}"
    fi
}
```

### 引入和源文件

- 始终引入 `common.sh`: `source "${PROJECT_ROOT}/scripts/lib/common.sh"`
- 引入动态路径时使用 `# shellcheck disable=SC1090`
- 引入前检查文件是否存在
- 优先使用 `${BASH_SOURCE[0]}` 而不是 `$0`

### 注释与输出语言（分而治之）

- **注释、文档、函数说明**：统一**中文**。
- **运行时输出**（`log_*` / `echo` 打到屏幕的消息）按脚本类型二分
  （旧规则一刀切要求全英文，但实测 **85/132 文件、1820 行**违反，规则本身不可执行）：

| 脚本类别 | 输出语言 | 理由 |
|---|---|---|
| **库**（`scripts/lib/common.sh`、`scripts/chezmoi/**` 库文件） | **英文** | 输出会被上层脚本/CI 解析，须稳定可 grep |
| **会被管道消费的脚本**（`tests/**`、`chezmoi` 包装层） | **英文** | 同上 |
| **面向用户的交互脚本**（`install.sh`/`deploy.sh`、`deploy_utils/**`、`container_dev_env/**`、平台脚本） | **中文可接受** | 人读终端输出，中文更友好 |

- **强制约束**：无论哪种，日志前缀必须用 `[INFO]`/`[SUCCESS]`/`[WARNING]`/`[ERROR]`（英文），
  以便与 `install.sh [4/6]` 等流程日志对齐、便于 grep。
- 主要章节分隔使用 `# ============================================`

### 变量展开与全角标点（跨平台强制）

- **规则**：`$变量` 后紧跟中文/全角字符（`【】（）`、`）`、`：` 等）时，**必须**写 `${变量}` 花括号形式。
- **原因**：macOS（BSD libc）在 UTF-8 locale 下，`isalpha()` 会把 CJK 字符首字节（如 `】` 的 `0xe3`）判为字母，Bash 将变量名错扩为 `$var` + 完整 UTF-8 字节序列，`set -u` 下报 `unbound variable` 崩溃（2026-08 实测：`install.sh [5/6]` 软件报告因此崩溃）。Linux/WSL（glibc）通常不受影响，但为跨平台一致**统一遵守**。
- **回归检查**（已固化到 `tests/test_syntax.sh`，扫全仓含根目录 `install.sh`/`deploy.sh`；勿用 `grep -P` — macOS BSD grep 不支持）：`LC_ALL=C grep -rn '\$[a-zA-Z_][a-zA-Z0-9_]*[一-龥【】（）]' . --include='*.sh' --include='*.tmpl'`（从仓库根执行）

### 平台特定代码

- 项目支持多 OS（Win10、macOS Intel、Linux Ubuntu/Arch）与 WSL（Ubuntu）；WSL 视为 Linux，共用 Linux 专属脚本（`run_once_linux-*`），脚本内通过 WSL 检测区分代理与路径。
- **WSL 与 Windows 宿主机完全独立**：`$HOME`/fnm/npm/chezmoi 目标不共享。WSL 里跑 `install.sh` **只装 WSL**，与宿主机 npm **无关**（宿主机仅 Clash `:7890` 出口）。`/mnt/host/wslg/.../fnm_multishells` 是 WSL 本机 fnm；`/mnt/c`、`/mnt/host/c` 才是 Windows。禁止从 WSL 改 Windows npm 或调用 `cmd.exe`。见 `.cursor/rules/wsl-windows-isolation.mdc`。
- 平台专属**脚本**：源根 + `run_once_{linux,macos,windows}-*` 前缀；平台专属 **dotfile**：源根 +
  `.chezmoiignore` 的 OS 条件过滤。**禁止**新建 `run_on_*/` 子目录（详见上文「chezmoi 平台目录陷阱」）。
- 安装脚本中的平台特定逻辑使用模板条件判断
- Win10 下推荐在 Git Bash 中执行 `install.sh`；若使用 Alacritty，需保证其 shell 与 PATH 与 Git Bash 一致（见 [docs/INSTALL_GUIDE.md](docs/INSTALL_GUIDE.md)）。

### Git 子模块

- Neovim 配置由 run_once 克隆到 `~/.config/nvim`，本仓库不再包含 dotfiles/nvim 子模块
- 更新: `cd ~/.config/nvim && git pull && ./install.sh`

### 重要说明

- **可执行脚本**必须 `chmod +x`；**库文件不设可执行位**（见上文「库 vs 可执行：两份契约」）
- Windows 脚本必须用 CRLF，其他必须用 LF
- 绝不提交敏感数据（API 密钥、密码、私钥）
- 提交前使用 `chezmoi apply` 测试配置更改
- 修改系统配置文件前始终备份


## 架构说明

### 核心操作封装

`scripts/lib/chezmoi/chezmoi_core.sh` 为聚合入口（`chezmoi_proxy.sh` / `chezmoi_lock.sh` / `chezmoi_apply.sh`），统一封装：

| 函数 | 作用 | 使用方 |
|------|------|--------|
| `chezmoi_detect_proxy()` | 代理检测（环境变量→WSL→127.0.0.1:7890） | install.sh / deploy.sh |
| `chezmoi_setup_proxy()` | 设置代理环境变量 | 所有入口脚本 |
| `chezmoi_ensure_unlocked()` | 等待/释放 chezmoi 锁 | install.sh / deploy.sh |
| `chezmoi_run_apply()` | chezmoi apply 统一调用 | install.sh / deploy.sh |
| `chezmoi_run_status()` | chezmoi status | 安装流程 |
| `chezmoi_run_diff()` | chezmoi diff | 安装流程 |
| `chezmoi_verify_sync()` | 验证配置同步状态（含跨平台过滤） | install.sh |

三个入口脚本共享这个封装层：install.sh（首次安装）→ deploy.sh（增量）→ manage_dotfiles.sh（运维）。

**chezmoi 注意**：CLI 不读 `CHEZMOI_SOURCE_DIR`；`sourceDir` 在 `~/.config/chezmoi/chezmoi.toml`（`chezmoi_ensure_user_config`）。配置映射见 `scripts/lib/chezmoi/config_mappings.sh`。Windows Git/WT 路径 C/D 盘检测见 `docs/PROJECT_AGENT_MEMORY.md`；Windows rmux 见 `docs/RMUX_WINDOWS.md`。

### connect.exe 路径检测（Windows）

`scripts/chezmoi/ensure_ssh_prereqs.sh` 在 Windows 上的**实际**检测顺序（行号对应源码）：

1. 环境变量 `WINDOWS_GIT_CONNECT_PATH`（`:133`）
2. `git` 命令**同级目录**的 `connect.exe`（`${git_bin}/connect.exe`，`:141`）
3. `cmd //c "if exist ..."` 探测 **C:/ 与 D:/** 盘的 `mingw64\bin\connect.exe`（`:147`）
4. `${git_root}/mingw64/bin/connect.exe` → `${git_root}/usr/bin/connect.exe` → `${MINGW_PREFIX}/bin/connect.exe`（`:158-163`）

> 该顺序以源码为准；修改此函数后请同步本节（避免再次出现文档与实现颠倒）。

部署入口职责矩阵见上文「部署入口职责矩阵（必须遵守）」。


## 项目结构

```
.
├── AGENTS.md                   # 本文件
├── README.md                   # 项目说明
├── install.sh                  # 一键安装入口（使用 chezmoi_core.sh）
├── deploy.sh                   # 快速部署入口（使用 chezmoi_core.sh）
├── .chezmoi/                   # chezmoi 源状态（配置模板）
│   ├── .chezmoiignore          # 模板：按 OS 过滤平台专属 dotfile
│   ├── _bash_profile_*.tmpl    # 仅 include 用（已 ignore，不部署）
│   ├── run_once_*.tmpl         # 全部安装脚本都在源根；按目标名字母序执行
│   │                           #   00-/90-/91-/93- → install-* → linux-/macos-/windows-*
│   ├── run_once_linux-*.tmpl   # Linux 专属（**禁止**再建 run_on_*/ 子目录）
│   ├── run_once_macos-*.tmpl   # macOS 专属
│   ├── run_once_windows-*.tmpl # Windows 专属
│   ├── dot_config/             # 含平台专属子目录（alacritty/i3/ghostty），由 ignore 按 OS 过滤
│   └── dot_*.tmpl              # 配置文件模板（含平台专属 .yabairc/.skhdrc）
├── .chezmoi.toml.tmpl          # chezmoi 用户级配置参考模板
├── scripts/                    # 所有脚本
│   ├── lib/                    # ★ 纯函数库（被 source；不设 +x、不写 set -euo pipefail）
│   │   ├── common.sh           # 公共函数库（颜色、日志、错误处理）
│   │   └── chezmoi/            # chezmoi 库：chezmoi_core/proxy/lock/apply、
│   │                           #   detect_platform、packages.conf、software_policies、
│   │                           #   package_install、install_helpers、brew_macos_network、
│   │                           #   config_mappings、helpers、common_install（聚合入口）
│   ├── chezmoi/                # chezmoi 可执行入口
│   │   ├── install_chezmoi.sh  verify_installation.sh  diagnose_chezmoi.sh
│   │   ├── ensure_ssh_prereqs.sh  ensure_platform_software.sh  audit_configs.sh
│   │   └── README.md
│   ├── deploy_utils/           # 部署辅助（备份、诊断、SSH/Zsh 同步）
│   ├── tools/                  # ★ 独立工具（**永不删除**，与部署无关）
│   │   ├── standalone_tool_script/  project_tools/  ffmpeg_magic/
│   │   ├── git_templates/  shc/  patch_examples/
│   │   └── auto_edit_redis_config/  cursor_clangd/  container_dev_env/
│   ├── linux/                  # Linux 专属（system_basic_env、network）
│   ├── windows/                # Windows 专属（system_basic_env、windows_scripts）
│   ├── manage_dotfiles.sh      # dotfiles 运维入口
│   └── README.md
├── tests/                      # 测试目录（8 个；全部纳入 CI 硬性阻断）
│   ├── test_contracts.sh       # ★ 结构与命名契约（目录分层/库vs入口/+x/链接/格式/部署入口）
│   ├── test_syntax.sh          # 全仓 .sh/.tmpl 语法检查 + 全角标点回归
│   ├── test_proxy.sh           # 代理地址检测/补全逻辑
│   ├── test_semver_compare.sh  # 版本号比较
│   ├── test_software_policies.sh    # software_policies 策略与脚本发现
│   ├── test_install_report_status.sh # install [5/6] 软件报告状态
│   ├── test_winget_msix_fallback.sh # winget MSIX sideload 回退与主包选择
│   └── test_bashrc_prompt_guard.sh  # bashrc 提示符 / TERM 守卫
├── docs/                       # 文档目录
│   └── PROJECT_STRUCTURE.md    # 项目结构权威文档
```


## 版本控制与提交规范

**提交信息格式：Conventional Commits**（与本仓 `git log` 实际风格一致）

```
<type>(<scope>): <简短描述>

<可选正文，说明「为什么」而非「做了什么」>

<可选 footer>
```

- **type**：`feat` `fix` `refactor` `perf` `docs` `style` `test` `chore` `build` `ci`
- **scope**：受影响的子系统，如 `macos` `windows` `linux` `install` `dotfiles` `chezmoi` `docs` `tests`
- 例：`fix(macos): skip Intel brew upgrades that rebuild ImageMagick`

**分支命名**：`feature/<名称>`、`fix/<描述>`、`docs/<说明>`

**换行符**：已由 `.gitattributes` 统一（见 `docs/ENCODING_AND_LINE_ENDINGS.md`），
**不要**再单独 `git config core.autocrlf`——会与 `.gitattributes` 叠加产生二次转换。

⚠️ **`.gitattributes` 规则顺序陷阱**：catch-all 规则 `* text=auto eol=lf`
**必须写在文件最前面**。它若排在末尾，会覆盖其后所有更具体的规则
（如 Windows 脚本的 `*.bat text eol=crlf`），把 `.bat`/`.ps1`/`.cmd` 静默转成 LF。
（2026-09 实测踩坑：catch-all 置尾导致 8 个 Windows 文件被误转，需重新规范化。）

改完 `.gitattributes` 后用 `git check-attr` 逐类验证，不要只看文件内容：

```bash
git check-attr text eol -- install.sh deploy.sh scripts/windows/windows_scripts/open_multi_vlc.bat
# 期望：.sh → eol: lf；.bat → eol: crlf
```


## 开发工作流程

### 1. 新建脚本

```bash
# 位置按类型选择：库 → scripts/lib/；入口 → scripts/chezmoi/ 或 scripts/deploy_utils/；
#             独立工具 → scripts/tools/<类别>/；平台脚本 → scripts/{linux,windows}/
touch scripts/linux/system_basic_env/install_new_software.sh
chmod +x scripts/linux/system_basic_env/install_new_software.sh
```

### 2. 套用头部模板

见上文「Shell 脚本结构」与「库 vs 可执行：两份契约」——**先判断属于哪一类**，
再套用对应模板。注意 `PROJECT_ROOT` 的向上层数随脚本深度变化，**不要照抄**。

### 3. 验证（三步都必需）

```bash
bash -n <script>.sh                 # 1) 语法
bash <script>.sh                    # 2) 实际跑：确认能加载到 common.sh（12 个脚本曾因此 100% 崩溃）
bash tests/test_syntax.sh           # 3) 全仓回归（含全角标点 + 编码 + 换行符）
```

### 4. 编码 / 换行符

```bash
./scripts/tools/standalone_tool_script/check_and_fix_encoding.sh
./scripts/tools/standalone_tool_script/ensure_lf_line_endings.sh
```

### 5. 提交

见上文「版本控制与提交规范」。改动 chezmoi 模板后先 `./scripts/manage_dotfiles.sh diff` 预演。


## 详细目录结构

项目完整目录结构见 [docs/PROJECT_STRUCTURE.md](docs/PROJECT_STRUCTURE.md)。

脚本目录概览：`scripts/lib/`（库）、`scripts/chezmoi/`（chezmoi 入口）、`scripts/deploy_utils/`（部署辅助）、`scripts/tools/`（独立工具，永不删除）、`scripts/{linux,windows}/`（平台专属）；macOS 平台脚本为 `.chezmoi/run_once_macos-*.sh.tmpl`。


## 脚本分类和命名规范


| 类别         | 目录                         | 命名模式                 | 示例                            |
| ---------- | -------------------------- | -------------------- | ----------------------------- |
| 系统安装       | `linux/system_basic_env/`  | `install_<软件名>.sh`   | `install_new_software.sh`  |
| 系统配置       | `linux/system_basic_env/`  | `configure_<配置名>.sh` | `configure_china_mirrors.sh`  |
| 工具脚本       | `tools/standalone_tool_script/` | `<动作>_<对象>.sh`       | `get_directory_name.sh`       |
| 项目工具       | `tools/project_tools/`    | `<动作>_<对象>.sh`       | `generate_cmake_lists.sh`     |
| FFmpeg 工具    | `tools/ffmpeg_magic/`      | 见目录内脚本             | `open_multiple_ffmpeg_srt.sh`  |
| 测试脚本       | 各目录                        | `test_<功能>.sh`       | `test_mirrors.sh`             |
| Windows 脚本 | `windows/windows_scripts/` | `<功能描述>.bat`         | `open_multi_vlc.bat`          |

### 命名边界（普通脚本区 vs 模板区）

- 普通脚本区（`scripts/**`、`ai-unified-config/scripts/**`（已移除））统一使用 snake_case 文件名，不新增 kebab-case 脚本名。
- 普通脚本推荐前缀：`install_`、`configure_`、`test_`、`verify_`、`sync_`、`backup_`。
- 模板执行区（`.chezmoi/`）保留 chezmoi 约定的连字符风格：`run_once_install-xxx.sh.tmpl`；
  平台专属脚本用 `run_once_{linux,macos,windows}-<语义>.sh.tmpl`（如 `run_once_macos-install-ghostty.sh.tmpl`）。
  `run_on_*/` 子目录**已废弃**（不是 chezmoi 平台目录，详见上文「chezmoi 平台目录陷阱」）。
- 普通脚本区与模板区命名规则分离管理，禁止跨区混用。

### 命名治理落地节奏

1. **第 1 阶段（文档约束）**：先固化命名规则与边界，不改历史文件名。
2. **第 2 阶段（新增止血）**：仅对新脚本启用命名检查（告警模式）。
3. **第 3 阶段（分批迁移）**：按目录小批量重命名历史文件，并同步调用路径与文档引用。
4. **第 4 阶段（规则收敛）**：命名检查从告警升级为阻断，防止回归。



## 参考资源

### 官方文档

- [Chezmoi 文档](https://www.chezmoi.io/) - Chezmoi 官方文档
- [Bash 手册](https://www.gnu.org/software/bash/manual/) - Bash 官方手册
- [ShellCheck](https://www.shellcheck.net/) - Shell 脚本静态分析工具

### 编程规范

- [Google Shell Style Guide](https://google.github.io/styleguide/shellguide.html) - Google Shell 脚本规范
- [Bash Best Practices](https://github.com/alexanderepstein/Bash-Snippets) - Bash 最佳实践示例

### 相关工具

- [Git 文档](https://git-scm.com/doc) - Git 版本控制
- [Arch Wiki](https://wiki.archlinux.org/) - Arch Linux 官方文档
- [Homebrew 文档](https://docs.brew.sh/) - macOS 包管理器

