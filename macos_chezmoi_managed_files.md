# macOS chezmoi 管理文件清单

## ✅ 当前管理的文件（已修复）

通过 `chezmoi add` 命令，以下文件现在已被 chezmoi 管理：

```
.config
.config/alacritty
.config/alacritty/alacritty.toml
.config/fish
.config/fish/config.fish
.config/starship
.config/starship/starship.toml
.tmux.conf
.zprofile
.zshrc
```

## 📋 详细文件列表

### Shell 配置
- ✅ `~/.zshrc` - Zsh 配置
- ✅ `~/.zprofile` - Zsh 启动配置

### 终端和工具配置
- ✅ `~/.tmux.conf` - Tmux 配置
- ✅ `~/.config/starship/starship.toml` - Starship 提示符配置
- ✅ `~/.config/alacritty/alacritty.toml` - Alacritty 终端配置

### Fish Shell 配置
- ✅ `~/.config/fish/config.fish` - Fish Shell 主配置

## ⚠️ 需要安装软件后才能管理的文件

以下文件需要先安装对应软件，然后通过 `chezmoi add` 添加：

### macOS 特有配置
- ⏳ `~/.yabairc` - Yabai 窗口管理器配置（需要先安装 yabai）
- ⏳ `~/.skhdrc` - skhd 快捷键配置（需要先安装 skhd）

**安装命令：**
```bash
# 安装 yabai 和 skhd
brew install koekeishiya/formulae/yabai
brew install koekeishiya/formulae/skhd

# 然后添加到管理
chezmoi add ~/.yabairc
chezmoi add ~/.skhdrc
```

## 🔧 应该安装的软件（通过 run_once 脚本）

### 版本管理器
- `run_once_install-version-managers.sh.tmpl`
  - fnm (Node.js 版本管理)
  - uv (Python 包管理器)
  - rustup (Rust 工具链，可选)

### 终端工具
- `run_once_install-starship.sh.tmpl` → starship
- `run_once_install-tmux.sh.tmpl` → tmux
- `run_once_install-alacritty.sh.tmpl` → alacritty

### 开发工具
- `run_once_install-git.sh.tmpl` → git
- `run_once_install-neovim.sh.tmpl` → neovim
- `run_once_install-common-tools.sh.tmpl` → bat, eza, fd, ripgrep, fzf, lazygit, git-delta, gh

### Shell 环境
- `run_once_install-zsh.sh.tmpl` → zsh + oh-my-zsh
- `run_once_install-fish.sh.tmpl` → fish shell

### macOS 特有
- `run_once_install-yabai.sh.tmpl` → yabai
- `run_once_install-skhd.sh.tmpl` → skhd
- `run_on_darwin/run_once_configure-homebrew.sh.tmpl` → 配置 Homebrew

### 字体
- `run_once_install-nerd-fonts.sh.tmpl` → FiraMono Nerd Font

## 📊 对比总结

### 应该管理的配置文件（源文件在 .chezmoi/）

| 配置文件 | 源文件路径 | 目标路径 | 状态 |
|---------|-----------|---------|------|
| Zsh 配置 | `dot_zshrc` | `~/.zshrc` | ✅ 已管理 |
| Zsh Profile | `dot_zprofile` | `~/.zprofile` | ✅ 已管理 |
| Tmux 配置 | `dot_tmux.conf` | `~/.tmux.conf` | ✅ 已管理 |
| Starship 配置 | `dot_config/starship/starship.toml` | `~/.config/starship/starship.toml` | ✅ 已管理 |
| Alacritty 配置 | `dot_config/alacritty/alacritty.toml` | `~/.config/alacritty/alacritty.toml` | ✅ 已管理 |
| Fish 配置 | `dot_config/fish/config.fish` | `~/.config/fish/config.fish` | ✅ 已管理 |
| Fish 补全 | `dot_config/fish/completions/alacritty.fish` | `~/.config/fish/completions/alacritty.fish` | ⚠️ 需要添加 |
| Fish 配置片段 | `dot_config/fish/conf.d/fnm.fish` | `~/.config/fish/conf.d/fnm.fish` | ⚠️ 需要添加 |
| Fish 配置片段 | `dot_config/fish/conf.d/omf.fish` | `~/.config/fish/conf.d/omf.fish` | ⚠️ 需要添加 |
| Yabai 配置 | `run_on_darwin/dot_yabairc` | `~/.yabairc` | ⏳ 需先安装 yabai |
| skhd 配置 | `run_on_darwin/dot_skhdrc` | `~/.skhdrc` | ⏳ 需先安装 skhd |

### 应该安装的软件（通过 run_once 脚本）

| 软件类别 | 软件列表 | 安装脚本 |
|---------|---------|---------|
| 版本管理器 | fnm, uv, rustup | `run_once_install-version-managers.sh.tmpl` |
| 终端工具 | starship, tmux, alacritty | 各自的 `run_once_install-*.sh.tmpl` |
| 文件工具 | bat, eza, fd, ripgrep, fzf, trash-cli | `run_once_install-common-tools.sh.tmpl` |
| 开发工具 | git, neovim, lazygit, git-delta, gh | 各自的 `run_once_install-*.sh.tmpl` |
| Shell 环境 | zsh + oh-my-zsh, fish | 各自的 `run_once_install-*.sh.tmpl` |
| 窗口管理器 | yabai, skhd | 各自的 `run_once_install-*.sh.tmpl` |
| 字体 | FiraMono Nerd Font | `run_once_install-nerd-fonts.sh.tmpl` |

## 🔍 问题原因

### 为什么之前只管理了 `.zshrc`？

**原因：**
1. 其他文件虽然源文件存在于 `.chezmoi/` 目录中，但还没有被 `chezmoi add` 添加到管理
2. chezmoi 需要先"添加"文件到管理，然后才会跟踪这些文件
3. 如果文件已经存在，需要先 `chezmoi add` 才能被管理

**解决方案：**
```bash
# 添加现有文件到管理
chezmoi add ~/.zprofile
chezmoi add ~/.tmux.conf
chezmoi add ~/.config/starship/starship.toml
chezmoi add ~/.config/alacritty/alacritty.toml
chezmoi add ~/.config/fish/config.fish
```

## ✅ 修复后的状态

现在所有主要配置文件都已被 chezmoi 管理：

- ✅ 9 个配置文件已管理
- ⏳ 2 个配置文件需要先安装软件（yabai, skhd）
- ⚠️ 3 个 Fish 配置片段可以后续添加

## 📝 后续操作建议

1. **添加 Fish 配置片段**（可选）：
   ```bash
   chezmoi add ~/.config/fish/completions/alacritty.fish
   chezmoi add ~/.config/fish/conf.d/fnm.fish
   chezmoi add ~/.config/fish/conf.d/omf.fish
   ```

2. **安装 yabai 和 skhd**（如果需要）：
   ```bash
   brew install koekeishiya/formulae/yabai
   brew install koekeishiya/formulae/skhd
   chezmoi add ~/.yabairc
   chezmoi add ~/.skhdrc
   ```

3. **检查 run_once 安装脚本**：
   ```bash
   # 查看哪些安装脚本已执行
   ls -la ~/.local/share/chezmoi/run_once_* 2>/dev/null

   # 如果需要重新执行，可以删除记录后重新 apply
   ```

4. **验证配置同步**：
   ```bash
   # 查看配置状态
   chezmoi status

   # 查看配置差异
   chezmoi diff

   # 应用所有配置
   chezmoi apply -v
   ```

