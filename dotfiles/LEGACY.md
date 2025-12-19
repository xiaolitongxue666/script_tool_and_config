# Legacy Dotfiles 目录

## 说明

本目录（`dotfiles/`）已标记为 **Legacy（遗留）**，保留作为参考。

## 迁移状态

所有配置文件已迁移到 `.chezmoi/` 目录，使用 [chezmoi](https://www.chezmoi.io/) 统一管理。

### 迁移时间

- 迁移日期：2024-12-12
- 迁移工具：`scripts/migration/migrate_to_chezmoi.sh`

### 迁移映射

| 原路径 | 新路径 |
|--------|--------|
| `dotfiles/bash/config.sh` | `.chezmoi/dot_bashrc.tmpl` |
| `dotfiles/zsh/.zshrc` | `.chezmoi/dot_zshrc` |
| `dotfiles/zsh/.zprofile` | `.chezmoi/dot_zprofile` |
| `dotfiles/fish/config.fish` | `.chezmoi/dot_config/fish/config.fish` |
| `dotfiles/fish/completions/` | `.chezmoi/dot_config/fish/completions/` |
| `dotfiles/fish/conf.d/` | `.chezmoi/dot_config/fish/conf.d/` |
| `dotfiles/starship/starship.toml` | `.chezmoi/dot_config/starship/starship.toml` |
| `dotfiles/tmux/tmux.conf` | `.chezmoi/dot_tmux.conf` |
| `dotfiles/alacritty/alacritty.toml` | `.chezmoi/dot_config/alacritty/alacritty.toml` |
| `dotfiles/git_bash/.bash_profile` | `.chezmoi/run_on_windows/dot_bash_profile` |
| `dotfiles/git_bash/.bashrc` | `.chezmoi/run_on_windows/dot_bashrc` |
| `dotfiles/i3wm/config` | `.chezmoi/run_on_linux/dot_config/i3/config` |
| `dotfiles/yabai/yabairc` | `.chezmoi/run_on_darwin/dot_yabairc` |
| `dotfiles/skhd/skhdrc` | `.chezmoi/run_on_darwin/dot_skhdrc` |

## 为什么保留此目录？

1. **参考价值**：保留原始配置作为参考，便于理解配置历史
2. **向后兼容**：某些工具可能仍引用此目录中的文件
3. **迁移验证**：可以对比新旧配置，确保迁移正确
4. **文档完整性**：各工具的 README 文档仍在此目录中

## 使用建议

### 新用户

**请使用新的 chezmoi 管理方式**：

```bash
# 一键安装
./install.sh

# 或使用管理脚本
./scripts/manage_dotfiles.sh install
./scripts/manage_dotfiles.sh apply
```

### 现有用户

如果您之前使用 `dotfiles/` 目录中的 `install.sh` 脚本：

1. **迁移到 chezmoi**（推荐）：
   ```bash
   # 运行迁移脚本（如果尚未运行）
   ./scripts/migration/migrate_to_chezmoi.sh

   # 使用 chezmoi 管理
   ./scripts/manage_dotfiles.sh apply
   ```

2. **继续使用传统方式**（不推荐）：
   - 可以继续使用各工具目录下的 `install.sh` 脚本
   - 但建议尽快迁移到 chezmoi

## 目录结构

```
dotfiles/
├── alacritty/          # Alacritty 终端配置（已迁移）
├── bash/               # Bash 配置（已迁移）
├── fish/               # Fish Shell 配置（已迁移）
├── zsh/                # Zsh 配置（已迁移）
├── tmux/               # Tmux 配置（已迁移）
├── starship/           # Starship 提示符配置（已迁移）
├── i3wm/               # i3wm 窗口管理器配置（已迁移）
├── yabai/              # Yabai 窗口管理器配置（已迁移）
├── skhd/               # skhd 快捷键配置（已迁移）
├── git_bash/           # Git Bash 配置（已迁移）
├── nvim/               # Neovim 配置（Git Submodule，chezmoi 管理符号链接）
├── secure_crt/         # SecureCRT 配置（Windows 特定）
└── dwm/                # dwm 窗口管理器配置（Linux 特定）
```

## 特殊说明

### Neovim 配置

Neovim 配置使用 Git Submodule 管理，chezmoi 会管理符号链接到 `~/.config/nvim`。

**使用方式**：
```bash
# 初始化 submodule
git submodule update --init dotfiles/nvim

# chezmoi 会创建符号链接
chezmoi apply
```

### SecureCRT 配置

SecureCRT 是 Windows 特定工具，配置文件保留在 `dotfiles/secure_crt/` 目录中，可以使用其 `install.sh` 脚本安装。

## 迁移检查清单

如果您想验证迁移是否完整：

- [x] Bash 配置已迁移
- [x] Zsh 配置已迁移
- [x] Fish 配置已迁移
- [x] Starship 配置已迁移
- [x] Tmux 配置已迁移
- [x] Alacritty 配置已迁移
- [x] i3wm 配置已迁移（Linux）
- [x] Yabai 配置已迁移（macOS）
- [x] skhd 配置已迁移（macOS）
- [x] Git Bash 配置已迁移（Windows）
- [x] 安装脚本已转换为 `run_once_` 脚本

## 相关文档

- [readme.md](../readme.md) - 项目主文档
- [chezmoi_use_guide.md](../chezmoi_use_guide.md) - chezmoi 使用指南
- [scripts/migration/migrate_to_chezmoi.sh](../scripts/migration/migrate_to_chezmoi.sh) - 迁移脚本

## 注意事项

1. **不要直接修改此目录中的配置文件**，修改不会同步到系统
2. **使用 chezmoi 管理配置**，所有修改应在 `.chezmoi/` 目录中进行
3. **此目录可能会在未来版本中移除**，建议尽快迁移到 chezmoi

---

**最后更新**：2024-12-12
