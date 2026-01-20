# Docker ArchLinux 开发环境

基于当前项目的 Linux 环境配置，创建一个完整的 Docker ArchLinux 开发容器，包含所有已安装的软件和配置文件。

## 特性

- 基于 ArchLinux 最新版本
- 包含项目 Linux 环境的所有软件和配置
- 多阶段构建，优化镜像大小
- 支持代理配置（构建时和运行时）
- 条件镜像源配置（有代理不修改源，无代理使用中国镜像源）
- 自动挂载项目目录
- 支持 SSH Agent Forwarding（容器可使用宿主机的 SSH 密钥，无需复制密钥文件）
- 自动备份 SSH 关键文件（启动前备份 id_rsa, id_rsa.pub, known_hosts, config）

## 前置要求

- Docker 或 Podman
- 项目根目录可访问
- Git Submodule（Neovim 配置需要）

## 快速开始

### 1. 构建镜像

```bash
cd scripts/common/container_dev_env

# 使用默认代理构建（默认: 127.0.0.1:7890，macOS/Windows 自动转换为 host.docker.internal:7890）
./build.sh

# 使用指定代理构建
./build.sh --proxy 192.168.1.76:7890

# 不使用代理构建（将使用中国镜像源）
./build.sh --no-proxy
```

### 2. 启动容器

```bash
# 使用代理启动交互式 shell
./run.sh --proxy 192.168.1.76:7890

# 不使用代理启动
./run.sh

# 执行命令
./run.sh --proxy 192.168.1.76:7890 --command "nvim"
```

## 详细使用

### 构建脚本 (build.sh)

构建 Docker 镜像。

**参数**:
- `--proxy ADDRESS`: 设置代理地址（例如: `192.168.1.76:7890`）
  - 默认: `127.0.0.1:7890`（macOS/Windows 自动转换为 `host.docker.internal:7890`）
- `--no-proxy`: 不使用代理（使用中国镜像源）
- `--image-name NAME`: 镜像名称（默认: `archlinux-dev-env`）
- `--image-tag TAG`: 镜像标签（默认: `latest`）
- `-h, --help`: 显示帮助信息

**环境变量**:
- `PROXY`: 代理地址（如果未通过参数指定，默认: `127.0.0.1:7890`）

**示例**:
```bash
# 使用默认代理（127.0.0.1:7890）
./build.sh

# 使用指定代理
./build.sh --proxy 192.168.1.76:7890

# 不使用代理
./build.sh --no-proxy

# 使用环境变量
export PROXY=192.168.1.76:7890
./build.sh

# 自定义镜像名称和标签
./build.sh --proxy 192.168.1.76:7890 --image-name my-dev-env --image-tag v1.0
```

### 启动脚本 (run.sh)

启动 Docker 容器。

**参数**:
- `--proxy ADDRESS`: 设置代理地址（例如: `192.168.1.76:7890`）
- `--image-name NAME`: 镜像名称（默认: `archlinux-dev-env`）
- `--image-tag TAG`: 镜像标签（默认: `latest`）
- `--container-name NAME`: 容器名称（默认: `archlinux-dev-env`）
- `--command COMMAND` 或 `-c COMMAND`: 要执行的命令（默认: 交互式 shell）
- `--work-dir DIR`: 工作目录（默认: `/workspace`）
- `-h, --help`: 显示帮助信息

**环境变量**:
- `PROXY`: 代理地址（如果未通过参数指定）

**示例**:
```bash
# 启动交互式 shell
./run.sh --proxy 192.168.1.76:7890

# 执行命令
./run.sh --proxy 192.168.1.76:7890 --command "nvim"
./run.sh --proxy 192.168.1.76:7890 -c "tmux"

# 使用环境变量
export PROXY=192.168.1.76:7890
./run.sh
```

## 镜像源配置策略

### 有代理时

- **不修改** mirror list
- pacman 使用代理访问官方源（通过 `XferCommand` 配置）
- 所有网络请求通过代理

### 无代理时

- 配置中国镜像源（9 个可用镜像）
- pacman 直连镜像源（不使用代理）
- 添加 archlinuxcn 源（8 个可用镜像）

## 包含的软件

### 基础工具
- base-devel, git, curl, wget, aria2, sudo
- openssh, iputils, file, net-tools

### 开发工具
- neovim, gcc, make, cmake, ctags
- tmux, starship, github-cli, lazygit, git-delta
- fzf, ripgrep, fd, bat, eza, trash-cli
- fastfetch, btop, tree, zsh

### 版本管理器
- uv (Python 包管理器)
- fnm (Node.js 版本管理器)

### AUR 助手
- yay

### Shell 环境
- zsh
- Oh My Zsh
- Oh My Zsh 插件:
  - zsh-autosuggestions
  - zsh-history-substring-search
  - zsh-syntax-highlighting

### 其他工具
- lazyssh (SSH 管理器)
- FiraMono Nerd Font

## 配置文件

容器包含以下配置文件（使用 chezmoi 从项目的 `.chezmoi/` 目录应用）：

- `~/.zshrc` - Zsh 配置（通过 chezmoi 模板生成）
- `~/.zprofile` - Zsh 启动配置（通过 chezmoi 模板生成）
- `~/.bashrc` - Bash 配置（通过 chezmoi 模板生成）
- `~/.tmux.conf` - Tmux 配置（通过 chezmoi 模板生成）
- `~/.config/starship/starship.toml` - Starship 提示符配置
- `~/.config/alacritty/alacritty.toml` - Alacritty 终端配置
- `~/.config/i3/config` - i3wm 配置（可选，Linux 特定）

**配置应用方式**：
- 使用 `chezmoi apply` 命令应用所有配置文件
- 自动解析模板变量（如 `{{ .chezmoi.homeDir }}`、`{{ .chezmoi.os }}` 等）
- 正确处理条件逻辑（如 `{{- if eq .chezmoi.os "linux" -}}`）
- 确保配置的正确性和完整性

## 容器配置流程

容器配置流程完全参考 `scripts/linux/system_basic_env/install_common_tools.sh`，分为以下阶段：

### Phase 1: Pacman 配置优化（对应 Linux Phase 1: Pacman operations）
- 设置代理环境变量
- 条件配置镜像源（无代理时使用中国镜像源）
- 优化 pacman 配置（`tune_pacman`）
  - 配置 HoldPkg, Architecture, CheckSpace, SigLevel
  - 启用 ParallelDownloads
  - 配置 core/extra 仓库使用镜像列表
  - 添加 archlinuxcn 源（8 个可用镜像）
  - 移除已废弃的 [community] 配置
  - 配置 pacman 代理策略（使用国内源时移除代理）

**注意**：以下操作已在 Dockerfile 中完成，Phase 1 只做配置优化：
- `update_system`: 已在 Dockerfile base stage 中完成
- `install_packages`: 已在 Dockerfile tools stage 中完成
- `ensure_aur_helper`: 已在 Dockerfile tools stage 中完成（yay）

### Phase 2: 软件配置安装（对应 Linux Phase 2: Other operations）
- 验证版本管理器（uv, fnm）- 已在 Dockerfile 中安装
- 安装 Neovim 配置（包括 Python 和 Node.js 环境）
- 验证 lazyssh（已在 Dockerfile 中安装）
- 验证可选工具（tree, ctags, file, net-tools, iputils）
- 验证字体安装（FiraMono Nerd Font，已在 Dockerfile 中安装）
- 验证 Shell 工具（zsh, Oh My Zsh 及插件，已在 Dockerfile 中安装）

### Phase 3: 配置文件应用
- 使用 `chezmoi apply` 应用所有配置文件
- 清理旧的配置文件（如果存在）
- 强制重新应用配置
- 会应用 .zshrc, .bashrc, .tmux.conf 等配置文件

### Phase 4: 验证和总结
- 验证已安装的软件包
- 验证版本管理器（uv, fnm, yay）
- 验证配置文件
- 验证 Neovim 配置

**注意**：软件包的安装已在 Dockerfile 的 `tools` stage 中完成，容器配置阶段主要负责配置优化、配置文件应用和验证。

## Neovim 配置

Neovim 配置通过 Git Submodule 管理。构建时会自动初始化 `dotfiles/nvim` submodule。

如果 submodule 未初始化，构建可能会失败。请确保：

```bash
# 在项目根目录
git submodule update --init --recursive dotfiles/nvim
```

## 目录挂载

容器启动时，项目根目录会自动挂载到容器的 `/workspace` 目录。

你可以在容器内直接访问和编辑项目文件。

## SSH Agent Forwarding

脚本支持 SSH Agent Forwarding，使容器能够使用宿主机的 SSH 密钥进行认证，无需在容器内复制密钥文件，更安全。

### 功能说明

1. **自动备份 SSH 文件**
   - 在配置 SSH Agent Forwarding 之前，脚本会自动备份以下文件到压缩包：
     - `id_rsa` (私钥)
     - `id_rsa.pub` (公钥)
     - `known_hosts`
     - `config`
   - 备份文件保存在 `~/.ssh/ssh_backup_YYYYMMDD_HHMMSS.tar.gz`
   - 备份文件权限设置为 600，确保安全性

2. **自动加载私钥**
   - 脚本会自动检查并加载 `id_rsa` 私钥到 SSH Agent
   - Linux 系统下，如果 SSH Agent 未运行，脚本会尝试自动启动
   - macOS/Windows 系统下，需要确保 SSH Agent 已运行

3. **SSH Agent Forwarding**
   - 通过挂载 SSH Agent 套接字实现
   - macOS/Windows: 使用 `/run/host-services/ssh-auth.sock`
   - Linux: 使用 `$SSH_AUTH_SOCK` 环境变量指向的套接字
   - 容器内可通过 `ssh-add -l` 查看已加载的密钥
   - 容器内可直接使用 `ssh` 和 `git` 进行认证

### 使用方法

1. **确保 SSH Agent 运行**（macOS/Windows）
   ```bash
   # macOS 通常 SSH Agent 会自动运行
   # 如果需要手动启动
   eval $(ssh-agent)
   ```

2. **加载密钥到 SSH Agent**
   ```bash
   ssh-add ~/.ssh/id_rsa
   ```

3. **启动容器**
   ```bash
   ./run.sh
   # 脚本会自动：
   # 1. 备份 SSH 文件
   # 2. 确保私钥已加载
   # 3. 配置 SSH Agent Forwarding
   ```

4. **在容器内验证**
   ```bash
   # 检查 SSH Agent
   echo $SSH_AUTH_SOCK
   ssh-add -l

   # 测试 SSH 连接
   ssh -T git@github.com

   # 使用 Git
   git clone git@github.com:username/repo.git
   ```

### 注意事项

- 容器内的 `~/.ssh/` 目录是空的（这是正常的，因为我们只挂载了 SSH Agent 套接字）
- 密钥通过 SSH Agent 提供，不会出现在容器文件系统中，更安全
- 第一次连接新主机时，可能需要手动确认主机密钥（因为 `known_hosts` 未挂载）
- 备份和密钥加载失败不会阻止容器启动，只会记录警告信息

## 故障排除

### 镜像构建失败

1. **检查网络连接**: 确保可以访问 ArchLinux 镜像源或代理
2. **检查 Git Submodule**: 确保 `dotfiles/nvim` submodule 已初始化
3. **检查代理设置**: 如果使用代理，确保代理地址正确

### 容器启动失败

1. **检查镜像是否存在**: 运行 `docker images | grep archlinux-dev-env`
2. **检查容器名称冲突**: 使用 `--container-name` 指定不同的名称
3. **检查权限**: 确保 Docker 有权限访问项目目录

### SSH Agent Forwarding 不工作

1. **检查 SSH Agent 是否运行**
   ```bash
   # macOS/Windows
   ssh-add -l
   # 如果显示 "Could not open a connection to your authentication agent"
   # 需要启动 SSH Agent
   eval $(ssh-agent)
   ssh-add ~/.ssh/id_rsa
   ```

2. **检查密钥是否已加载**
   ```bash
   ssh-add -l
   # 应该显示已加载的密钥列表
   ```

3. **在容器内检查**
   ```bash
   # 检查环境变量
   echo $SSH_AUTH_SOCK
   # 应该显示套接字路径

   # 检查密钥
   ssh-add -l
   # 应该显示宿主机 SSH Agent 中的密钥
   ```

4. **检查套接字文件**（Linux）
   ```bash
   ls -la $SSH_AUTH_SOCK
   # 应该显示套接字文件存在
   ```

### 代理不工作

1. **检查代理地址格式**: 应该是 `IP:PORT` 或 `http://IP:PORT`
2. **检查代理服务**: 确保代理服务正在运行
3. **检查网络**: 确保容器可以访问代理服务器

## 注意事项

1. **Neovim Submodule**: 需要确保 `dotfiles/nvim` submodule 已初始化
2. **chezmoi 配置**: 使用 chezmoi 正确解析和应用所有模板文件，确保配置的正确性
3. **字体安装**: 字体文件较大，构建时从网络下载
4. **AUR 包**: 在容器中构建 AUR 包需要 base-devel 组（已包含）
5. **权限**: 容器使用 root 用户，简化权限管理
6. **持久化**: 容器删除后配置会丢失，项目文件通过挂载持久化

## 故障排除

### Neovim 配置安装失败

如果 Neovim 配置安装失败，可能的原因：

1. **换行符问题**: 文件包含 CRLF 换行符
   - 解决：运行 `./scripts/common/utils/ensure_lf_line_endings.sh` 规范化换行符
   - 或在 Dockerfile 中添加换行符转换

2. **Git Submodule 未初始化**
   ```bash
   git submodule update --init --recursive dotfiles/nvim
   ```

3. **网络问题**: 安装 Python 包或 Node.js 包时网络超时
   - 解决：使用代理构建镜像

### btop 无法执行

如果 btop 出现 "operation not permitted" 错误：

- 已在 Dockerfile 中清除 btop 的 capabilities，应该可以正常执行
- 如果仍有问题，检查容器是否缺少必要的权限

### Zsh 配置未生效

如果 zsh 配置（主题、插件）没有生效，可能的原因：

1. **.zshrc 文件太小（只有 26 字节）**
   ```bash
   # 在容器内检查
   ls -lh ~/.zshrc
   # 如果只有 26 字节，说明 chezmoi 没有正确应用配置
   ```

2. **chezmoi 配置未正确应用**
   ```bash
   # 检查构建日志中的 chezmoi apply 输出
   # 或者手动在容器内执行
   export CHEZMOI_SOURCE_DIR=/tmp/project/.chezmoi
   export HOME=/root
   export CHEZMOI_PAGER=""
   chezmoi apply --force --verbose
   ```

3. **手动应用配置（如果 chezmoi apply 失败）**
   ```bash
   # 在容器内执行
   export CHEZMOI_SOURCE_DIR=/tmp/project/.chezmoi
   export HOME=/root
   export CHEZMOI_PAGER=""
   # 手动解析模板
   chezmoi execute-template < /tmp/project/.chezmoi/dot_zshrc.tmpl > ~/.zshrc
   # 检查文件大小
   ls -lh ~/.zshrc
   ```

4. **Oh My Zsh 未正确安装**
   ```bash
   # 在容器内检查
   ls -la ~/.oh-my-zsh
   ```

5. **插件未安装**
   ```bash
   # 检查插件目录
   ls -la ~/.oh-my-zsh/custom/plugins/
   ```

6. **重新加载配置**
   ```bash
   # 在容器内执行
   source ~/.zshrc
   # 或重新启动 shell
   exec zsh
   ```

7. **检查 Oh My Zsh 路径**
   ```bash
   # 确认 ZSH 变量
   echo $ZSH
   # 应该是 /root/.oh-my-zsh
   ```

## 后续优化

- 支持创建普通用户（dev）
- 支持 Docker Compose
- 支持持久化配置（volume）
- 支持热重载配置
- 在 Dockerfile 中添加换行符转换（dos2unix 或 sed）

## 许可证

详见项目根目录的 LICENSE 文件。

