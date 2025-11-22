# Yabai 配置

Yabai 是 macOS 的平铺式窗口管理器，提供类似 Linux i3 的窗口管理体验。

## 配置文件结构

```
yabai/
├── yabairc            # Yabai 配置文件
├── install.sh          # 自动安装脚本（仅 macOS）
└── README.md          # 本文件
```

## 安装方法

### 使用安装脚本（推荐）

```bash
cd dotfiles/yabai
chmod +x install.sh
./install.sh
```

### 手动安装

```bash
brew install koekeishiya/formulae/yabai
```

## 配置使用

### 复制配置文件

```bash
# 方法 1: 使用安装脚本（自动处理）
./install.sh

# 方法 2: 手动复制
mkdir -p ~/.config/yabai
cp dotfiles/yabai/yabairc ~/.config/yabai/
```

### 设置权限

Yabai 需要辅助功能权限：

1. 打开"系统设置" > "隐私与安全性" > "辅助功能"
2. 添加 Yabai 并授予权限
3. 如果已运行，需要重启 Yabai

### 启动和管理

```bash
# 启动 Yabai 服务
brew services start yabai

# 停止 Yabai 服务
brew services stop yabai

# 重启 Yabai 服务（重新加载配置）
yabai --restart-service

# 查看 Yabai 状态
yabai --check-service
```

## 配置文件位置

- **配置文件**: `~/.config/yabai/yabairc`

## 系统要求

- **操作系统**: macOS
- **依赖**: Homebrew

## 与 skhd 配合使用

Yabai 通常与 skhd (Simple Hotkey Daemon) 配合使用来设置快捷键。

## 参考链接

- [Yabai GitHub](https://github.com/koekeishiya/yabai)
- [Yabai 文档](https://github.com/koekeishiya/yabai/wiki)

