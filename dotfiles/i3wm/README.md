# i3 窗口管理器配置

i3 是一个平铺式窗口管理器，专为 Linux 系统设计，提供高效的窗口管理体验。

## 配置文件结构

```
i3wm/
├── config              # i3 主配置文件
├── install.sh          # 自动安装脚本（仅 Linux）
└── README.md           # 本文件
```

## 安装方法

### 使用安装脚本（推荐）

```bash
cd dotfiles/i3wm
chmod +x install.sh
./install.sh
```

### 手动安装

#### Arch Linux
```bash
sudo pacman -S i3-wm i3status i3lock
```

#### Ubuntu/Debian
```bash
sudo apt-get install i3 i3status i3lock
```

#### Fedora/CentOS
```bash
sudo yum install i3 i3status i3lock
```

## 配置使用

### 复制配置文件

```bash
# 方法 1: 使用安装脚本（自动处理）
./install.sh

# 方法 2: 手动复制
mkdir -p ~/.config/i3
cp dotfiles/i3wm/config ~/.config/i3/
```

### 重新加载配置

在 i3 中按：
```
Mod + Shift + R
```
（默认 Mod 键为 Super/Windows 键）

## 常用快捷键

### 窗口管理
- `Mod + Enter`: 打开新终端
- `Mod + d`: 打开应用启动器
- `Mod + Shift + q`: 关闭窗口
- `Mod + f`: 全屏切换
- `Mod + Shift + Space`: 切换浮动/平铺模式

### 窗口布局
- `Mod + h/j/k/l`: 切换焦点窗口
- `Mod + Shift + h/j/k/l`: 移动窗口
- `Mod + e`: 默认布局（平铺）
- `Mod + s`: 堆叠布局
- `Mod + w`: 标签页布局

### 工作区
- `Mod + <数字>`: 切换到指定工作区
- `Mod + Shift + <数字>`: 移动窗口到指定工作区

### 其他
- `Mod + Shift + R`: 重新加载配置
- `Mod + Shift + E`: 退出 i3
- `Mod + r`: 调整窗口大小模式

## 配置文件位置

- **主配置**: `~/.config/i3/config`
- **i3status 配置**: `~/.config/i3status/config` (可选)

## 系统要求

- **操作系统**: Linux
- **显示服务器**: X11 或 Wayland (通过 i3-gaps)

## 参考链接

- [i3 官网](https://i3wm.org/)
- [i3 用户指南](https://i3wm.org/docs/userguide.html)
- [i3 配置参考](https://i3wm.org/docs/userguide.html#configuring)
