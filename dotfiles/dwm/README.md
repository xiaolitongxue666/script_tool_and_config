# dwm (Dynamic Window Manager) 配置

dwm 是一个极快、小巧、动态的 X 窗口管理器。它使用平铺、单窗口和浮动布局管理窗口，所有布局都可以动态应用。

参考: [dwm 官网](https://dwm.suckless.org/)

## 关于 dwm

dwm 是 "dynamic window manager" 的缩写，由 [suckless.org](https://suckless.org/) 开发。它是一个极简主义的窗口管理器，专注于：

- **极快的速度**: 代码量小，性能优异
- **动态布局**: 自动优化窗口布局以适应应用和任务
- **标签系统**: 使用标签（tags）而非工作区管理窗口
- **可定制**: 通过编辑源代码（C 语言）进行配置

### 主要特性

- **三种布局模式**:
  - **平铺布局 (Tiled)**: 主窗口区域和堆叠区域
  - **单窗口布局 (Monocle)**: 所有窗口最大化
  - **浮动布局 (Floating)**: 可自由调整和移动窗口

- **标签系统**: 每个窗口可以标记一个或多个标签，选择标签显示对应窗口

- **状态栏**: 显示可用标签、布局、可见窗口数、焦点窗口标题等

- **极简设计**: 仅一个二进制文件，源代码保持小巧

## 配置文件结构

```
dwm/
├── config.h              # dwm 配置文件（可选，自定义配置）
├── config.def.h          # 默认配置模板（可选）
├── install.sh            # 自动安装脚本（支持多 Linux 发行版）
└── README.md             # 本文件
```

## 安装方法

### 使用安装脚本（推荐）

```bash
cd dotfiles/dwm
chmod +x install.sh
./install.sh
```

安装脚本会自动：
- 检测 Linux 发行版（Arch、Ubuntu/Debian、Fedora/CentOS）
- 安装必要的依赖包
- 克隆 dwm 源码
- 编译并安装 dwm
- 可选安装 st (Simple Terminal)
- 创建 XSession 桌面文件

### 手动安装

#### 1. 安装依赖

**Arch Linux:**
```bash
sudo pacman -S libx11 libxt libxft libxext libxinerama git make gcc
```

**Ubuntu/Debian:**
```bash
sudo apt-get install libx11-dev libxt-dev libxft-dev libxext-dev libxinerama-dev git make gcc
```

**Fedora/CentOS:**
```bash
sudo dnf install libX11-devel libXt-devel libXft-devel libXext-devel libXinerama-devel git make gcc
```

#### 2. 克隆并编译

```bash
git clone https://git.suckless.org/dwm
cd dwm
make clean install
```

#### 3. 配置（可选）

编辑 `config.h` 文件自定义配置，然后重新编译：

```bash
# 编辑配置
vim config.h

# 重新编译安装
make clean install
```

## 配置使用

### 自定义配置

dwm 的配置通过编辑源代码完成：

1. **克隆源码**:
   ```bash
   git clone https://git.suckless.org/dwm
   cd dwm
   ```

2. **编辑配置**:
   ```bash
   cp config.def.h config.h
   vim config.h
   ```

3. **重新编译**:
   ```bash
   make clean install
   ```

### 主要配置项

在 `config.h` 中可以配置：

- **标签**: `static const char *tags[]`
- **布局**: `static const Layout layouts[]`
- **快捷键**: `static Key keys[]`
- **鼠标操作**: `static Button buttons[]`
- **规则**: `static const Rule rules[]`
- **状态栏**: `static const char *fonts[]`
- **颜色**: `static const char *colors[][]`

### 使用自定义配置文件

如果您有自定义的 `config.h` 文件：

```bash
# 将自定义配置复制到 dotfiles/dwm/
cp ~/my-dwm-config/config.h dotfiles/dwm/

# 运行安装脚本，会自动使用自定义配置
cd dotfiles/dwm
./install.sh
```

## 启动 dwm

### 方法 1: 使用登录管理器

在登录管理器中选择 "dwm" 会话。

### 方法 2: 使用 startx

在 `~/.xinitrc` 中添加：

```bash
exec dwm
```

然后运行：

```bash
startx
```

### 方法 3: 使用 xrdb 显示状态信息

在 `~/.xinitrc` 中：

```bash
# 显示状态信息（日期、系统负载等）
while xsetroot -name "`date` `uptime | sed 's/.*,//'`"
do
    sleep 1
done &
exec dwm
```

## 默认快捷键

### 窗口管理

- `Mod + Shift + q`: 关闭窗口
- `Mod + Shift + c`: 杀死窗口
- `Mod + m`: 最大化/恢复窗口
- `Mod + f`: 切换全屏
- `Mod + Shift + Space`: 切换浮动/平铺

### 布局切换

- `Mod + t`: 平铺布局
- `Mod + f`: 浮动布局
- `Mod + m`: 单窗口布局

### 标签操作

- `Mod + <1-9>`: 切换到标签
- `Mod + Shift + <1-9>`: 将窗口移动到标签
- `Mod + Ctrl + <1-9>`: 切换标签可见性

### 窗口焦点

- `Mod + j`: 下一个窗口
- `Mod + k`: 上一个窗口
- `Mod + h`: 减小主窗口区域
- `Mod + l`: 增大主窗口区域

### 其他

- `Mod + Shift + Return`: 打开终端（默认）
- `Mod + p`: 打开 dmenu（如果已安装）
- `Mod + Shift + r`: 重新编译并重启 dwm

**注意**: `Mod` 键默认为 `Alt`，可在 `config.h` 中修改。

## 配套工具

### st (Simple Terminal)

dwm 通常与 st (Simple Terminal) 配合使用：

```bash
# 安装 st
wget https://dl.suckless.org/st/st-0.9.tar.gz
tar -zxf st-0.9.tar.gz
cd st-0.9
make clean install
sudo tic -sx st.info
```

安装脚本可以选择自动安装 st。

### dmenu

dmenu 是一个动态菜单工具，可与 dwm 配合使用：

```bash
# Arch Linux
sudo pacman -S dmenu

# Ubuntu/Debian
sudo apt-get install dmenu

# Fedora/CentOS
sudo dnf install dmenu
```

## 配置文件位置

- **dwm 配置**: 编辑源码中的 `config.h` 并重新编译
- **自定义配置**: `dotfiles/dwm/config.h`（如果存在）
- **XSession**: `/usr/share/xsessions/dwm.desktop`

## 系统要求

- **操作系统**: Linux
- **显示服务器**: X11
- **依赖**: Xlib 开发库

## 与 i3 的区别

dwm 与 i3 的主要区别：

- **配置方式**: dwm 通过编辑源代码配置，i3 使用配置文件
- **工作区概念**: dwm 使用标签（tags），i3 使用工作区（workspaces）
- **代码量**: dwm 更小、更快、更简单
- **定制性**: dwm 需要 C 语言知识，i3 使用配置文件

## 参考链接

- [dwm 官网](https://dwm.suckless.org/)
- [dwm 自定义指南](https://dwm.suckless.org/customisation/)
- [dwm 教程](https://dwm.suckless.org/tutorial/)
- [dwm FAQ](https://dwm.suckless.org/faq/)
- [dwm 补丁](https://dwm.suckless.org/patches/)
- [dwm GitHub 镜像](https://github.com/Digital-Chaos/dwm)
- [suckless.org](https://suckless.org/)

## 常见问题

### Q: 如何修改默认终端？

A: 编辑 `config.h` 中的 `static const char *termcmd[]`，然后重新编译。

### Q: 如何添加新的快捷键？

A: 编辑 `config.h` 中的 `static Key keys[]` 数组，然后重新编译。

### Q: 如何更改状态栏颜色？

A: 编辑 `config.h` 中的 `static const char *colors[][]`，然后重新编译。

### Q: 如何应用补丁？

A: 在 dwm 源码目录中应用补丁：

```bash
cd dwm
patch -p1 < /path/to/patch.diff
make clean install
```

### Q: 如何重新编译并重启 dwm？

A: 按 `Mod + Shift + r`，或：

```bash
cd dwm
make clean install
# 然后重启 dwm
```

