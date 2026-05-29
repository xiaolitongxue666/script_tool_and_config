# 安装指南

本指南是手动操作的一步一步流程。软件安装顺序详情见 [SOFTWARE_LIST.md](SOFTWARE_LIST.md)。

---

## 通用流程

### 第一步：克隆项目

```bash
git clone <repo-url>
cd script_tool_and_config
```

### 第二步：设置代理（可选）

如果所在网络需要代理：

```bash
# 方式一：环境变量
export PROXY=http://127.0.0.1:7890

# 方式二：参数传递
./install.sh --proxy http://127.0.0.1:7890
```

**代理规则**：
- 包管理器操作（pacman/apt/brew）→ 国内源直连，不走代理
- GitHub/Git 克隆、curl 下载 → 走代理
- WSL 下自动从 `/etc/resolv.conf` 的 nameserver 推断宿主机 IP

### 第三步：一键安装

```bash
./install.sh
```

脚本自动执行：

| 步骤 | 说明 |
|------|------|
| [1/5] | 安装 chezmoi（若未安装） |
| [2/5] | 写入 `~/.config/chezmoi/chezmoi.toml`，`sourceDir` 指向项目 `.chezmoi/` |
| [3/5] | `chezmoi apply -v --force` — 核心部署，执行所有 run_once 脚本 |
| [4/5] | 检查当前平台软件安装状态 |
| [5/5] | 运行 `verify_installation.sh` 验证字体/Shell/路径一致性 |

### 第四步：验证

```bash
# SSH 验证
ssh -T git@github.com

# 配置状态
./scripts/manage_dotfiles.sh status
./scripts/manage_dotfiles.sh diff

# 语法检查
bash tests/test_syntax.sh
bash tests/test_proxy.sh
```

---

## 各平台详细步骤

### Linux（含 WSL）

```bash
# 1. 克隆项目
git clone <repo-url>
cd script_tool_and_config

# 2. （WSL 可选）设置代理（宿主机 IP）
export PROXY=http://$(awk '/^nameserver / {print $2; exit}' /etc/resolv.conf):7890

# 3. 一键安装
./install.sh

# 4. 验证
ssh -T git@github.com          # 确认 SSH 认证通过
./scripts/manage_dotfiles.sh status   # 配置已同步
```

**WSL 注意**：
- 代理地址不能是 127.0.0.1（WSL 内指向自身），脚本会自动从 resolv.conf 获取宿主机 IP
- SSH 代理通过 `connect-proxy`（`apt install connect-proxy`）实现，run_once_install-git 脚本会自动安装

**Arch 注意**：
- 部分操作需要 root（Pacman 配置、base-devel 安装）
- 若 install.sh 在普通用户下执行时 Pacman 配置失败，可手动执行：

```bash
sudo chezmoi apply -v  # 以 root 身份应用 Pacman 配置
```

### macOS

```bash
# 1. 确保 Homebrew 已安装
command -v brew || /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 2. 克隆项目
git clone <repo-url>
cd script_tool_and_config

# 3. 设置代理（可选）
export PROXY=http://127.0.0.1:7890

# 4. 一键安装
./install.sh

# 5. 验证
ssh -T git@github.com
./scripts/manage_dotfiles.sh status
```

**macOS 注意**：
- Apple Silicon 与 Intel 的 Homebrew 路径不同（`/opt/homebrew/bin` vs `/usr/local/bin`），chezmoi 模板会自动处理
- connect 由 Homebrew 安装（与 Linux 的 `connect-proxy` 包名不同）

### Windows

```bash
# 方式一：Git Bash 中执行（推荐）
./install.sh

# 方式二：双击 scripts/windows/install_with_chezmoi.bat（需管理员权限）
```

**Windows 注意**：
- 统一在 **Git Bash** 中执行，不要在 PowerShell 或 CMD 中执行 `install.sh`
- zsh/starship/nerd-fonts 等跨平台脚本均会在 Git Bash 环境下运行
- SSH 代理使用 Git for Windows 自带的 `connect.exe`（路径自动检测）
- 包管理器优先使用 winget，回退 MSYS2 pacman
- **`chezmoi apply` 必须带 `--force`**：`manage_dotfiles.sh apply` 与 `deploy.sh` 已自动注入，避免 `.gitconfig` 等外部修改触发交互菜单卡住
- **`deploy.sh` 诊断阶段在 Windows 跳过 `apply --dry-run`**（模拟全部 run_once 会长时间无输出）

---

## 两阶段部署（Agent CLI + 全局 MCP）

Phase 1 在本仓库（dotfiles + Layer 4 CLI），Phase 2 在 [agent-config](../../AI/agent-config) 仓库。详见 [DEPLOY_TWO_PHASE.md](DEPLOY_TWO_PHASE.md)。

```bash
# Phase 1（Windows Git Bash）
eval "$(fnm env)"
./deploy.sh

# Phase 2
cd /path/to/agent-config
STRICT_AGENT_PREFLIGHT=1 bash scripts/install-tools.sh
```

---

## 增量部署（已有 chezmoi）

当项目更新后，只需重新应用配置：

```bash
# 方式一：推荐
./deploy.sh

# 方式二：手动
./scripts/manage_dotfiles.sh diff   # 查看差异
./scripts/manage_dotfiles.sh apply  # 应用变更
```

**WSL + CodeWhale（DeepSeek-TUI 已迁移）**：apply 前建议 `eval "$(fnm env)"`；`run_once_92-install-codewhale` 会在 WSL fnm/npm 全局安装 `codewhale` 并迁移 `~/.deepseek` → `~/.codewhale`。勿从 WSL 修改 Windows npm。详见 [CODEWHALE.md](CODEWHALE.md) 与 [PROJECT_AGENT_MEMORY.md](PROJECT_AGENT_MEMORY.md)。

**注意**：运行 apply 时不要使用 `| head` / `| rg` 管道截断输出，否则可能 SIGPIPE 中断 chezmoi。

---

## 常见问题

### Windows Git Bash：apply / deploy 看似卡住

| 现象 | 原因 | 处理 |
|------|------|------|
| 长时间无输出 | `diagnose_deployment.sh` 的 `apply --dry-run` 模拟全部 run_once | Windows 已自动跳过；日常用 `./deploy.sh` 或 `manage_dotfiles.sh apply` |
| 停在 `.gitconfig has changed...` | chezmoi 等待交互 overwrite | 使用 `--force`（脚本已默认）；手动：`chezmoi apply -v --force` |
| `timeout obtaining persistent state lock` | 残留 `chezmoi.exe` 或锁文件 | `taskkill //F //IM chezmoi.exe` 后 `bash scripts/common/deploy_utils/fix_chezmoi_lock.sh` |
| apply 被管道中断 | `\| head` / `\| rg` 导致 SIGPIPE | 勿截断 apply 输出 |

### chezmoi 锁占用

```bash
# Windows：强制结束残留进程
taskkill //F //IM chezmoi.exe

# 修复脚本（推荐）
bash scripts/common/deploy_utils/fix_chezmoi_lock.sh

# 手动清理锁文件
rm -f ~/.local/share/chezmoi/.lock ~/.local/share/chezmoi/.chezmoi.lock
```

### run_once 脚本跳过

chezmoi 对已执行的 run_once 脚本会记录到 `~/.local/share/chezmoi/scriptstate`。如需强制重跑：

```bash
# 重置单个脚本状态
rm -f ~/.local/share/chezmoi/scriptstate/run_once_install-xxx.sh

# 重新 apply（须 --force，避免交互卡住）
./scripts/manage_dotfiles.sh apply
```

### fnm/uv 不在 PATH

新安装的版本管理器需要重新登录或 source 配置：

```bash
# fnm
eval "$(fnm env)"

# uv
source ~/.local/bin/env
```

### 代理不生效

```bash
# 查看当前代理设置
echo "$http_proxy"

# WSL：确认宿主机 IP
awk '/^nameserver / {print $2; exit}' /etc/resolv.conf

# 手动设置
export http_proxy=http://<正确IP>:7890
export https_proxy=http://<正确IP>:7890
```

### 包管理器相关

```bash
# Pacman（Arch）国内源
sudo sed -i 's/^#Server/Server/' /etc/pacman.d/mirrorlist

# Homebrew 国内源（macOS）
export HOMEBREW_BREW_GIT_REMOTE=https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/brew.git

# apt（Ubuntu/Debian）国内源
sudo sed -i 's|http://archive.ubuntu.com|https://mirrors.tuna.tsinghua.edu.cn|g' /etc/apt/sources.list
```
