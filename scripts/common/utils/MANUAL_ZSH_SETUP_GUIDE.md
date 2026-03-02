# Zsh + Oh My Zsh 手动安装和配置指南

## 概述

本指南提供完整的手动操作流程，用于安装和配置 Zsh + Oh My Zsh，参考 `deploy.sh` 的流程。

## 使用方法

### 方法 1: 使用自动化脚本（推荐）

```bash
# 在项目根目录运行
./scripts/common/utils/manual_zsh_setup.sh
```

### 方法 2: 手动执行步骤

如果自动化脚本遇到问题，可以按照以下步骤手动执行：

## 完整操作流程

### 步骤 1: 检查当前 zsh 配置和插件

```bash
# 1.1 检查 Zsh 安装
zsh --version
which zsh
echo $SHELL

# 1.2 检查 Oh My Zsh 安装
ls -la ~/.oh-my-zsh

# 1.3 检查 .zshrc 文件
ls -la ~/.zshrc
cat ~/.zshrc | grep -E "ZSH=|plugins=" | head -20

# 1.4 检查已安装的插件
ls -la ~/.oh-my-zsh/custom/plugins/
```

### 步骤 2: 安装 zsh + omz + 插件

```bash
# 2.1 安装 Zsh（如果未安装）
# Linux (Arch)
sudo pacman -S --noconfirm zsh

# Linux (Ubuntu/Debian)
sudo apt-get update && sudo apt-get install -y zsh

# macOS
brew install zsh

# 2.2 安装 Oh My Zsh（如果未安装）
export RUNZSH=no
export KEEP_ZSHRC=yes
export CHSH=no
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# 2.3 安装插件
ZSH_CUSTOM="$HOME/.oh-my-zsh/custom/plugins"
mkdir -p "$ZSH_CUSTOM"

# 安装 zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/zsh-autosuggestions"

# 安装 zsh-history-substring-search
git clone https://github.com/zsh-users/zsh-history-substring-search "$ZSH_CUSTOM/zsh-history-substring-search"

# 安装 zsh-syntax-highlighting
git clone https://github.com/zsh-users/zsh-syntax-highlighting "$ZSH_CUSTOM/zsh-syntax-highlighting"

# 安装 zsh-completions
git clone https://github.com/zsh-users/zsh-completions "$ZSH_CUSTOM/zsh-completions"
```

### 步骤 3: 通过模板生成配置（有日志）

```bash
# 3.1 设置环境变量
export CHEZMOI_SOURCE_DIR="$(pwd)/.chezmoi"

# 3.2 备份现有文件（如果存在）
if [ -f ~/.zshrc ]; then
    cp ~/.zshrc ~/.zshrc.backup.$(date +%Y%m%d_%H%M%S)
fi

# 3.3 删除旧文件
rm -f ~/.zshrc

# 3.4 从模板生成配置（方法 1: 使用 chezmoi apply）
chezmoi apply ~/.zshrc -v

# 如果方法 1 失败，使用方法 2: 使用 chezmoi execute-template
# chezmoi execute-template < .chezmoi/dot_zshrc.tmpl > ~/.zshrc

# 如果方法 2 也失败，使用方法 3: 直接复制模板（.zshrc.tmpl 中没有模板变量）
# cp .chezmoi/dot_zshrc.tmpl ~/.zshrc

# 3.5 验证生成的文件
ls -lh ~/.zshrc
head -20 ~/.zshrc
```

### 步骤 4: 手动部署

```bash
# 4.1 添加到 chezmoi 管理
chezmoi add --force ~/.zshrc

# 4.2 应用配置（确保最新）
chezmoi apply ~/.zshrc --force -v

# 4.3 验证管理状态
chezmoi managed | grep zshrc
chezmoi status ~/.zshrc
```

### 步骤 5: 验证

```bash
# 5.1 验证文件存在
ls -la ~/.zshrc
ls -la ~/.oh-my-zsh
ls -la ~/.oh-my-zsh/custom/plugins/

# 5.2 验证 .zshrc 配置
grep -E "^export ZSH=" ~/.zshrc
grep -A 15 "^plugins=" ~/.zshrc

# 5.3 验证 chezmoi 管理状态
chezmoi managed | grep zshrc
chezmoi status ~/.zshrc

# 5.4 测试配置
source ~/.zshrc
# 或
exec zsh
```

## 常见问题

### Q1: chezmoi apply 超时

**解决**：
```bash
# 清理锁文件
rm -f ~/.local/share/chezmoi/.chezmoi.lock

# 或使用备用方法
chezmoi execute-template < .chezmoi/dot_zshrc.tmpl > ~/.zshrc
```

### Q2: 文件冲突

**解决**：
```bash
# 使用 --force 强制覆盖
chezmoi add --force ~/.zshrc
chezmoi apply ~/.zshrc --force
```

### Q3: 插件未生效

**解决**：
```bash
# 1. 检查插件是否已安装
ls ~/.oh-my-zsh/custom/plugins/

# 2. 检查 .zshrc 中的插件配置
grep -A 15 "^plugins=" ~/.zshrc

# 3. 重新加载配置
source ~/.zshrc
```

### Q4: 模板变量未解析

**解决**：
```bash
# .zshrc.tmpl 中没有模板变量，可以直接复制
cp .chezmoi/dot_zshrc.tmpl ~/.zshrc
```

## 参考

- `deploy.sh` - 主部署脚本
- `scripts/common/utils/check_zsh_omz.sh` - 检查脚本
- [INSTALL_GUIDE.md](../../../docs/INSTALL_GUIDE.md) - Oh My Zsh 插件未安装时的故障排除与补救命令（手动 clone 四插件）

