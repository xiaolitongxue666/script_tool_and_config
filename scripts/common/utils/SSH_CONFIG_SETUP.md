# SSH 配置管理设置说明

## 快速开始

### 首次纳入管理（当前系统）

如果当前系统已有 SSH 配置，按以下步骤将其纳入 chezmoi 管理：

```bash
# 1. 备份现有配置
./scripts/common/utils/backup_ssh_config.sh

# 2. 将配置纳入 chezmoi 管理
export CHEZMOI_SOURCE_DIR="$(pwd)/.chezmoi"
chezmoi add ~/.ssh/config

# 3. 验证配置
chezmoi diff ~/.ssh/config

# 4. 应用配置（确保权限正确）
chezmoi apply ~/.ssh/config
chmod 600 ~/.ssh/config

# 5. 提交到 Git
git add .chezmoi/dot_ssh/
git commit -m "Add SSH config to chezmoi management"
git push
```

### 新系统部署

在新系统上部署 SSH 配置：

```bash
# 使用部署脚本（推荐）
./scripts/common/utils/setup_ssh_config.sh

# 或手动部署
mkdir -p ~/.ssh
chmod 700 ~/.ssh
export CHEZMOI_SOURCE_DIR="$(pwd)/.chezmoi"
chezmoi apply ~/.ssh/config
chmod 600 ~/.ssh/config
```

## 日常使用

### 使用 lazyssh 编辑配置

1. 启动 lazyssh：`lazyssh`
2. 在界面中编辑配置
3. 保存后同步到 chezmoi：

```bash
chezmoi re-add ~/.ssh/config
git add .chezmoi/dot_ssh/config
git commit -m "Update SSH config"
git push
```

### 使用 chezmoi 编辑配置

```bash
chezmoi edit ~/.ssh/config
chezmoi apply ~/.ssh/config
```

## GitHub 走 443 + 代理（Clash）

模板已包含 GitHub 使用 `ssh.github.com:443` 及可选 ProxyCommand（经 Clash 等代理）：

- **源文件**：`.chezmoi/dot_ssh/config.tmpl`，应用后生成 `~/.ssh/config`。
- **Windows**：ProxyCommand 使用 Git 自带的 `connect.exe`，路径由 data 中 `windows_git_connect_path` 指定（默认 `C:/Program Files/Git/mingw64/bin/connect.exe`）。
- **macOS**：系统 nc 无代理转发能力，需先安装 `connect`（`brew install connect`，或首次 `chezmoi apply` 时由 `run_once_install-connect` 自动安装）；路径由 data 中 `macos_connect_path` 指定。
- **Linux**：ProxyCommand 使用 `nc -X connect -x ...`，需安装 netcat-openbsd（或发行版等价包）；若报错请安装后重试。

若当前已有 `~/.ssh/config`，请先备份再应用或手动合并模板内容。

## 更多信息

详细说明请参考：
- [chezmoi_use_guide.md](../../../../chezmoi_use_guide.md#ssh-配置管理)
- [os_setup_guide.md](../../../../os_setup_guide.md#ssh-配置管理)

