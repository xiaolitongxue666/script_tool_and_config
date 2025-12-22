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

## 更多信息

详细说明请参考：
- [chezmoi_use_guide.md](../../../../chezmoi_use_guide.md#ssh-配置管理)
- [os_setup_guide.md](../../../../os_setup_guide.md#ssh-配置管理)

