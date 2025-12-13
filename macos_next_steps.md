# macOS 后续操作建议

## 📋 当前状态

✅ **已完成：**
- chezmoi 已安装并配置
- 9 个主要配置文件已被管理
- 源状态目录已设置

## 🎯 后续操作清单

### 1. 添加剩余的 Fish Shell 配置片段（可选）

如果使用 Fish Shell，可以添加配置片段：

```bash
cd ~/script_tool_and_config
export CHEZMOI_SOURCE_DIR="$(pwd)/.chezmoi"

# 添加 Fish 配置片段
chezmoi add ~/.config/fish/completions/alacritty.fish
chezmoi add ~/.config/fish/conf.d/fnm.fish
chezmoi add ~/.config/fish/conf.d/omf.fish
```

### 2. 检查并执行安装脚本

检查 run_once 安装脚本是否已执行：

```bash
# 查看已执行的脚本记录
ls -la ~/.local/share/chezmoi/run_once_* 2>/dev/null

# 如果没有记录，说明脚本还未执行，需要运行
export CHEZMOI_SOURCE_DIR="$(pwd)/.chezmoi"
chezmoi apply -v
```

**应该安装的软件：**

#### 版本管理器
```bash
# 检查是否已安装
fnm --version
uv --version
rustup --version
```

#### 终端工具
```bash
# 检查是否已安装
starship --version
tmux -V
alacritty --version
```

#### 开发工具
```bash
# 检查是否已安装
git --version
nvim --version
bat --version
eza --version
fd --version
rg --version
fzf --version
lazygit --version
delta --version
gh --version
```

#### Shell 环境
```bash
# 检查是否已安装
zsh --version
fish --version
```

### 3. 安装 macOS 特有软件（可选）

如果需要使用窗口管理器：

```bash
# 安装 yabai 和 skhd
brew install koekeishiya/formulae/yabai
brew install koekeishiya/formulae/skhd

# 添加到 chezmoi 管理
export CHEZMOI_SOURCE_DIR="$(pwd)/.chezmoi"
chezmoi add ~/.yabairc
chezmoi add ~/.skhdrc

# 启动服务
brew services start yabai
brew services start skhd

# 配置权限（首次需要）
# 系统设置 > 隐私与安全性 > 辅助功能 > 添加 Terminal
```

### 4. 安装字体（如果未安装）

```bash
# 检查字体是否已安装
ls ~/Library/Fonts/ | grep -i fira

# 如果未安装，chezmoi 的 run_once 脚本会自动安装
# 或手动安装：
brew install --cask font-fira-mono-nerd-font
```

### 5. 配置 Git（如果未配置）

```bash
# 设置 Git 用户信息
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"

# 查看配置
git config --global --list
```

### 6. 配置 Neovim（如果使用 Git Submodule）

```bash
cd ~/script_tool_and_config

# 确保 submodule 已初始化
git submodule update --init dotfiles/nvim

# Neovim 配置会自动通过 chezmoi 管理符号链接
export CHEZMOI_SOURCE_DIR="$(pwd)/.chezmoi"
chezmoi apply -v
```

### 7. 验证所有配置

```bash
cd ~/script_tool_and_config
export CHEZMOI_SOURCE_DIR="$(pwd)/.chezmoi"

# 查看所有管理的文件
chezmoi managed

# 查看配置状态
chezmoi status

# 查看配置差异
chezmoi diff

# 应用所有配置
chezmoi apply -v
```

### 8. 重新加载 Shell 配置

```bash
# 重新加载 Zsh 配置
source ~/.zshrc

# 或打开新终端窗口
```

## 🔄 日常使用建议

### 修改配置文件

```bash
# 使用 chezmoi 编辑（推荐）
./scripts/manage_dotfiles.sh edit ~/.zshrc

# 或直接编辑
chezmoi edit ~/.zshrc

# 编辑后应用
chezmoi apply ~/.zshrc
```

### 添加新配置文件

```bash
# 1. 添加文件到管理
chezmoi add ~/.new_config

# 2. 编辑配置
chezmoi edit ~/.new_config

# 3. 应用配置
chezmoi apply ~/.new_config

# 4. 提交到 Git
git add .chezmoi
git commit -m "Add new config"
git push
```

### 更新配置

```bash
# 从仓库拉取最新配置
git pull

# 更新到系统
./scripts/manage_dotfiles.sh update

# 或手动
export CHEZMOI_SOURCE_DIR="$(pwd)/.chezmoi"
chezmoi update -v
```

### 查看配置差异

```bash
# 查看所有差异
chezmoi diff

# 查看特定文件差异
chezmoi diff ~/.zshrc
```

### 备份配置

```bash
# 提交到 Git（推荐）
git add .chezmoi
git commit -m "Update configs"
git push

# 或手动备份
cp -r .chezmoi .chezmoi.backup
```

## 🛠️ 故障排除

### 如果某些软件未安装

```bash
# 检查安装脚本是否执行
ls -la ~/.local/share/chezmoi/run_once_* 2>/dev/null

# 如果脚本未执行，可以手动触发
export CHEZMOI_SOURCE_DIR="$(pwd)/.chezmoi"
chezmoi apply -v

# 或手动安装
brew install <package-name>
```

### 如果配置文件冲突

```bash
# 查看差异
chezmoi diff ~/.zshrc

# 如果确定要覆盖
chezmoi apply --force ~/.zshrc

# 或先备份
cp ~/.zshrc ~/.zshrc.backup
chezmoi apply ~/.zshrc
```

### 如果 run_once 脚本需要重新执行

```bash
# 删除执行记录（不推荐，除非必要）
chezmoi forget ~/.local/share/chezmoi/run_once_install-*.sh.tmpl

# 或直接运行脚本（需要先执行模板）
chezmoi execute-template < .chezmoi/run_once_install-zsh.sh.tmpl | bash
```

## 📚 参考文档

- [readme.md](readme.md) - 项目主文档
- [chezmoi_guide.md](chezmoi_guide.md) - chezmoi 使用指南
- [software_list.md](software_list.md) - 软件清单
- [macos_setup_guide.md](macos_setup_guide.md) - macOS 部署指南
- [macos_chezmoi_managed_files.md](macos_chezmoi_managed_files.md) - 管理文件清单

## ✅ 检查清单

完成以下检查，确保系统配置完整：

- [ ] 所有配置文件已被 chezmoi 管理
- [ ] 版本管理器已安装（fnm, uv）
- [ ] 终端工具已安装（starship, tmux, alacritty）
- [ ] 开发工具已安装（git, neovim, bat, eza, fd, ripgrep, fzf）
- [ ] Shell 环境已配置（zsh + oh-my-zsh, fish）
- [ ] 字体已安装（FiraMono Nerd Font）
- [ ] Git 用户信息已配置
- [ ] Neovim 配置已初始化（如果使用）
- [ ] yabai 和 skhd 已安装（如果需要窗口管理器）
- [ ] 所有配置已应用且无冲突

## 🎉 完成

完成以上步骤后，你的 macOS 系统应该已经完全配置好了！

