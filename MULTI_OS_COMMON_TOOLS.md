# 多系统通用工具清单

> **注意**: 本文档已整合到 [SOFTWARE_LIST.md](SOFTWARE_LIST.md)。请查看该文档获取完整的软件清单和安装说明。

## 快速参考

### 多系统共有软件

**版本管理器**
- fnm (Node.js)
- uv (Python)
- rustup (Rust) - 可选

**终端工具**
- starship (所有平台)
- tmux (Linux/macOS)
- alacritty (Linux/macOS)

**文件工具**
- bat, eza, fd, ripgrep, fzf, trash-cli

**开发工具**
- git, neovim, lazygit, git-delta, gh

### 系统特有软件

**Linux/macOS 特有**
- zsh + oh-my-zsh
- fish shell
- btop, fastfetch

**Linux 特有**
- i3wm, dwm (窗口管理器)

**macOS 特有**
- yabai, skhd (窗口管理器)

**Windows 特有**
- oh-my-posh (PowerShell 提示符)
- bottom (系统监控)

## 详细清单

请查看 [SOFTWARE_LIST.md](SOFTWARE_LIST.md) 获取：
- 完整的软件列表
- 各平台支持情况
- 安装脚本位置
- 配置文件映射
- 包管理器映射

## 安装方式

所有软件通过 chezmoi 的 `run_once_` 脚本机制自动安装：

```bash
# 应用所有配置（包括安装脚本）
chezmoi apply -v
```

详细说明请参考：
- [SOFTWARE_LIST.md](SOFTWARE_LIST.md) - 软件清单和安装说明
- [README.md](README.md) - 项目主文档
- [CHEZMOI_GUIDE.md](CHEZMOI_GUIDE.md) - chezmoi 使用指南
