# Zsh 配置

Zsh (Z Shell) 是一个功能强大的 Shell，具有自动补全、主题支持等功能。通常与 Oh My Zsh 框架配合使用。

## 配置文件结构

```
zsh/
├── zsh_with_oh_my_zsh_config/  # Oh My Zsh 配置
│   └── .zshrc                   # Zsh 配置文件
├── how_to_config_zsh.md         # 配置指南
├── install.sh                    # 自动安装脚本
└── README.md                     # 本文件
```

## 安装方法

### 使用安装脚本（推荐）

```bash
cd dotfiles/zsh
chmod +x install.sh
./install.sh
```

### 手动安装

#### macOS
```bash
# macOS 通常已预装 Zsh
# 或使用 Homebrew
brew install zsh
```

#### Linux (Arch Linux)
```bash
sudo pacman -S zsh
```

#### Linux (Ubuntu/Debian)
```bash
sudo apt-get install zsh
```

## 安装 Oh My Zsh

Oh My Zsh 是 Zsh 的配置框架：

```bash
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
```

## 配置使用

### 复制配置文件

```bash
# 复制 Oh My Zsh 配置
cp dotfiles/zsh/zsh_with_oh_my_zsh_config/.zshrc ~/.zshrc
```

### 重新加载配置

```bash
source ~/.zshrc
```

## 设置 Zsh 为默认 Shell

```bash
# 查看 Zsh 路径
which zsh

# 设置为默认 Shell
chsh -s $(which zsh)

# 或指定完整路径
chsh -s /bin/zsh        # macOS
chsh -s /usr/bin/zsh    # Linux
```

## 配置文件位置

- **主配置**: `~/.zshrc`
- **Oh My Zsh**: `~/.oh-my-zsh/`

## 常用 Oh My Zsh 主题

```bash
# 查看可用主题
ls ~/.oh-my-zsh/themes/

# 编辑配置文件更改主题
vim ~/.zshrc
# 修改 ZSH_THEME="主题名称"
```

## 常用 Oh My Zsh 插件

```bash
# 编辑 ~/.zshrc，在 plugins 中添加插件
plugins=(
  git
  docker
  kubectl
  z
  zsh-autosuggestions
  zsh-syntax-highlighting
)
```

## 参考链接

- [Zsh 官网](https://www.zsh.org/)
- [Oh My Zsh GitHub](https://github.com/ohmyzsh/ohmyzsh)
- [Oh My Zsh 主题](https://github.com/ohmyzsh/ohmyzsh/wiki/Themes)
- [Oh My Zsh 插件](https://github.com/ohmyzsh/ohmyzsh/wiki/Plugins)

