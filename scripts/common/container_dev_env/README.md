# Docker ArchLinux 开发环境

基于当前项目的 Linux 环境配置，创建一个完整的 Docker ArchLinux 开发容器，包含所有已安装的软件和配置文件。

## 特性

- 基于 ArchLinux 最新版本
- 包含项目 Linux 环境的所有软件和配置
- 多阶段构建，优化镜像大小
- 支持代理配置（构建时和运行时）
- 条件镜像源配置（有代理不修改源，无代理使用中国镜像源）
- 自动挂载项目目录

## 前置要求

- Docker 或 Podman
- 项目根目录可访问
- Git Submodule（Neovim 配置需要）

## 快速开始

### 1. 构建镜像

```bash
cd scripts/common/container_dev_env

# 使用代理构建
./build.sh --proxy 192.168.1.76:7890

# 不使用代理构建（将使用中国镜像源）
./build.sh
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
- `--image-name NAME`: 镜像名称（默认: `archlinux-dev-env`）
- `--image-tag TAG`: 镜像标签（默认: `latest`）
- `-h, --help`: 显示帮助信息

**环境变量**:
- `PROXY`: 代理地址（如果未通过参数指定）

**示例**:
```bash
# 使用参数
./build.sh --proxy 192.168.1.76:7890

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

容器包含以下配置文件（从项目的 `.chezmoi/` 目录复制）：

- `~/.zshrc` - Zsh 配置
- `~/.zprofile` - Zsh 启动配置
- `~/.bashrc` - Bash 配置
- `~/.tmux.conf` - Tmux 配置
- `~/.config/starship/starship.toml` - Starship 提示符配置
- `~/.config/alacritty/alacritty.toml` - Alacritty 终端配置
- `~/.config/i3/config` - i3wm 配置（可选）

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

## 故障排除

### 镜像构建失败

1. **检查网络连接**: 确保可以访问 ArchLinux 镜像源或代理
2. **检查 Git Submodule**: 确保 `dotfiles/nvim` submodule 已初始化
3. **检查代理设置**: 如果使用代理，确保代理地址正确

### 容器启动失败

1. **检查镜像是否存在**: 运行 `docker images | grep archlinux-dev-env`
2. **检查容器名称冲突**: 使用 `--container-name` 指定不同的名称
3. **检查权限**: 确保 Docker 有权限访问项目目录

### 代理不工作

1. **检查代理地址格式**: 应该是 `IP:PORT` 或 `http://IP:PORT`
2. **检查代理服务**: 确保代理服务正在运行
3. **检查网络**: 确保容器可以访问代理服务器

## 注意事项

1. **Neovim Submodule**: 需要确保 `dotfiles/nvim` submodule 已初始化
2. **配置文件模板**: 模板文件会进行简单处理（移除模板标记），可能不完全匹配 chezmoi 模板
3. **字体安装**: 字体文件较大，构建时从网络下载
4. **AUR 包**: 在容器中构建 AUR 包需要 base-devel 组（已包含）
5. **权限**: 容器使用 root 用户，简化权限管理
6. **持久化**: 容器删除后配置会丢失，项目文件通过挂载持久化

## 后续优化

- 支持创建普通用户（dev）
- 支持 Docker Compose
- 支持持久化配置（volume）
- 支持热重载配置

## 许可证

详见项目根目录的 LICENSE 文件。

