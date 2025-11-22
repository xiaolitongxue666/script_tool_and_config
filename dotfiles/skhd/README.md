# skhd 配置

skhd (Simple Hotkey Daemon) 是 macOS 的全局快捷键守护进程，通常与 Yabai 窗口管理器配合使用。

## 配置文件结构

```
skhd/
├── skhdrc              # skhd 配置文件
├── install.sh          # 自动安装脚本（仅 macOS）
└── README.md           # 本文件
```

## 安装方法

### 使用安装脚本（推荐）

```bash
cd dotfiles/skhd
chmod +x install.sh
./install.sh
```

### 手动安装

```bash
brew install koekeishiya/formulae/skhd
```

## 配置使用

### 复制配置文件

```bash
# 方法 1: 使用安装脚本（自动处理）
./install.sh

# 方法 2: 手动复制
mkdir -p ~/.config/skhd
cp dotfiles/skhd/skhdrc ~/.config/skhd/
```

### 设置权限

skhd 需要辅助功能权限：

1. 打开"系统设置" > "隐私与安全性" > "辅助功能"
2. 添加 skhd 并授予权限
3. 如果已运行，需要重启 skhd

### 启动和管理

```bash
# 启动 skhd 服务
brew services start skhd

# 停止 skhd 服务
brew services stop skhd

# 重新加载配置
skhd --reload

# 查看 skhd 状态
skhd --check-service
```

## 配置文件位置

- **配置文件**: `~/.config/skhd/skhdrc`

## 与 Yabai 配合使用

skhd 通常与 Yabai 窗口管理器配合使用，为 Yabai 提供快捷键支持。

## 参考链接

- [skhd GitHub](https://github.com/koekeishiya/skhd)
- [skhd 文档](https://github.com/koekeishiya/skhd/wiki)

