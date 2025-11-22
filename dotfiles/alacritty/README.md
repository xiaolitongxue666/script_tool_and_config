# Alacritty 配置

Alacritty 是一款使用 GPU 加速的跨平台终端模拟器，具有高性能和可定制性。

**参考**: [Alacritty GitHub 仓库](https://github.com/alacritty/alacritty)

## 重要提示

⚠️ **配置文件格式变更**: 从 Alacritty 0.13.0 版本开始，配置文件格式从 YAML 改为 **TOML**。

- ✅ **新格式**: `alacritty.toml` (当前使用)
- ❌ **旧格式**: `alacritty.yml` (已废弃，不再支持)

## 配置文件位置

Alacritty 会按以下顺序查找配置文件（按优先级）：

1. `$XDG_CONFIG_HOME/alacritty/alacritty.toml`
2. `$XDG_CONFIG_HOME/alacritty.toml`
3. `$HOME/.config/alacritty/alacritty.toml` ⭐ **推荐**
4. `$HOME/.alacritty.toml`
5. `/etc/alacritty/alacritty.toml` (系统级配置)

**Windows**:
- `%APPDATA%\alacritty\alacritty.toml`

## 安装方法

### macOS

#### 方法 1: Homebrew (推荐)
```bash
brew install --cask alacritty
```

#### 方法 2: 使用安装脚本
```bash
cd scripts
./auto_install_alacritty_for_macos.sh
```

#### 方法 3: 从 GitHub 下载预编译版本
从 [GitHub Releases](https://github.com/alacritty/alacritty/releases) 下载 `.dmg` 文件安装

### Linux

#### Arch Linux
```bash
sudo pacman -S alacritty
```

#### Ubuntu/Debian
```bash
sudo apt install alacritty
```

#### 其他发行版
参考 [官方安装文档](https://github.com/alacritty/alacritty/blob/master/INSTALL.md)

### Windows

从 [GitHub Releases](https://github.com/alacritty/alacritty/releases) 下载 `.exe` 安装程序

**要求**: Windows 10 版本 1809 或更高（需要 ConPTY 支持）

## 使用方法

### 1. 复制配置文件

```bash
# macOS/Linux
mkdir -p ~/.config/alacritty
cp dotfiles/alacritty/alacritty.toml ~/.config/alacritty/

# Windows
mkdir %APPDATA%\alacritty
copy dotfiles\alacritty\alacritty.toml %APPDATA%\alacritty\
```

### 2. 安装 Terminfo (可选但推荐)

确保终端类型正确识别：

```bash
# macOS/Linux
# 如果通过 Homebrew 安装，通常已自动配置
# 如果从源码编译，需要手动安装：
sudo tic -xe alacritty,alacritty-direct <path-to-alacritty.info>
```

### 3. 重启 Alacritty

配置更改后重启 Alacritty 以应用新设置。

## 配置说明

配置文件 (`alacritty.toml`) 包含以下主要部分：

- **环境变量** (`[env]`): TERM 等环境变量设置
- **窗口设置** (`[window]`): 尺寸、位置、填充、装饰、透明度等
- **滚动设置** (`[scrolling]`): 历史记录行数、滚动倍数
- **字体配置** (`[font]`): 字体族、大小、偏移等
- **颜色主题** (`[colors]`): Tomorrow Night 主题配色
- **光标设置** (`[cursor]`): 样式、闪烁等
- **Shell 设置** (`[shell]`): 默认 Shell 和启动目录
- **键盘绑定** (`[[key_bindings]]`): 快捷键配置（大部分已注释，可按需启用）
- **鼠标配置** (`[mouse]`): 鼠标行为设置

## 主题配置

### 使用官方主题库

1. 克隆主题库：
```bash
mkdir -p ~/.config/alacritty/themes
git clone https://github.com/alacritty/alacritty-theme ~/.config/alacritty/themes
```

2. 在 `alacritty.toml` 中导入主题：
```toml
import = [
  "~/.config/alacritty/themes/themes/catppuccin_mocha.toml",
]
```

### 自定义主题

可以直接在 `[colors]` 部分修改颜色值，或创建单独的主题文件通过 `import` 导入。

## 系统要求

- **OpenGL**: 至少需要 OpenGL ES 2.0 支持
- **Windows**: Windows 10 版本 1809 或更高（需要 ConPTY 支持）

## 参考链接

- [Alacritty 官方仓库](https://github.com/alacritty/alacritty)
- [官方安装文档](https://github.com/alacritty/alacritty/blob/master/INSTALL.md)
- [配置文件文档](https://github.com/alacritty/alacritty/blob/master/alacritty.toml)
- [Alacritty 主题库](https://github.com/alacritty/alacritty-theme)
- [官方网站](https://alacritty.org)

## 故障排除

### 配置文件不生效

1. 检查配置文件路径是否正确
2. 确认文件名为 `alacritty.toml`（不是 `.yml`）
3. 检查 TOML 语法是否正确
4. 查看 Alacritty 日志：`alacritty --print-events`

### Terminfo 问题

如果遇到终端类型识别问题：
```bash
# 检查 terminfo 是否安装
infocmp alacritty

# 如果未安装，手动安装
sudo tic -xe alacritty,alacritty-direct <path-to-alacritty.info>
```

