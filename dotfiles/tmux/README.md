# Tmux 配置

Tmux 是一个终端复用器，允许在一个终端窗口中管理多个会话、窗口和面板。

## 配置文件结构

```
tmux/
├── tmux.conf          # Tmux 配置文件
├── install.sh         # 自动安装脚本
└── README.md          # 本文件
```

## 安装方法

### 使用安装脚本（推荐）

```bash
cd dotfiles/tmux
chmod +x install.sh
./install.sh
```

### 手动安装

#### macOS
```bash
brew install tmux
```

#### Linux (Arch Linux)
```bash
sudo pacman -S tmux
```

#### Linux (Ubuntu/Debian)
```bash
sudo apt-get install tmux
```

## 配置使用

### 复制配置文件

```bash
# 方法 1: 使用安装脚本（自动处理）
./install.sh

# 方法 2: 手动复制
mkdir -p ~/.config/tmux
cp dotfiles/tmux/tmux.conf ~/.config/tmux/
# 或创建符号链接
ln -s ~/.config/tmux/tmux.conf ~/.tmux.conf
```

### 重新加载配置

在 tmux 会话中：
```bash
<Ctrl+b> + r
```

或在终端中：
```bash
tmux source-file ~/.tmux.conf
```

## 常用快捷键

### 会话管理
- `<Ctrl+b> + s`: 显示会话列表
- `<Ctrl+b> + d`: 分离当前会话
- `<Ctrl+b> + a`: 附加到上一个会话
- `tmux ls`: 列出所有会话
- `tmux kill-server`: 关闭所有会话

### 窗口管理
- `<Ctrl+b> + c`: 创建新窗口
- `<Ctrl+b> + n`: 下一个窗口
- `<Ctrl+b> + p`: 上一个窗口
- `<Ctrl+b> + <数字>`: 切换到指定窗口

### 面板管理
- `<Ctrl+b> + |`: 垂直分割窗口
- `<Ctrl+b> + -`: 水平分割窗口
- `<Ctrl+b> + h/j/k/l`: 切换面板
- `<Ctrl+b> + x`: 关闭当前面板
- `<Ctrl+b> + z`: 最大化/恢复面板

### 其他
- `<Ctrl+b> + r`: 重新加载配置文件
- `<Ctrl+b> + ?`: 显示快捷键帮助

## 配置文件位置

Tmux 会按以下顺序查找配置文件：
1. `~/.config/tmux/tmux.conf`
2. `~/.tmux.conf`

## 参考链接

- [Tmux 官网](https://tmux.github.io/)
- [Tmux 手册](https://man.openbsd.org/tmux)
- [Tmux 快捷键速查](https://tmuxcheatsheet.com/)
