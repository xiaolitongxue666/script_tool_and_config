#!/bin/bash

# Alacritty 终端模拟器 macOS 安装脚本
# 参考：https://github.com/alacritty/alacritty
# 官方安装文档：https://github.com/alacritty/alacritty/blob/master/INSTALL.md

set -e

echo "=========================================="
echo "Alacritty 安装脚本 (macOS)"
echo "=========================================="

# 检查是否已安装 Homebrew
if command -v brew &> /dev/null; then
    echo ""
    echo "检测到 Homebrew，使用 Homebrew 安装（推荐）..."
    echo "执行: brew install --cask alacritty"
    echo ""
    read -p "是否使用 Homebrew 安装？(y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        brew install --cask alacritty
        INSTALL_METHOD="homebrew"
    fi
fi

# 如果未使用 Homebrew，则从源码编译
if [ "$INSTALL_METHOD" != "homebrew" ]; then
    echo ""
    echo "从源码编译安装 Alacritty..."
    echo ""
    
    # 检查 Rust 是否已安装
    if ! command -v cargo &> /dev/null; then
        echo "错误: 未找到 Rust/Cargo"
        echo "请先安装 Rust: curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh"
        exit 1
    fi
    
    # 检查 cmake 是否已安装
    if ! command -v cmake &> /dev/null; then
        echo "错误: 未找到 cmake"
        echo "请先安装 cmake: brew install cmake"
        exit 1
    fi
    
    # 创建临时目录
    TEMP_DIR=$(mktemp -d)
    cd "$TEMP_DIR"
    
    # 克隆 Alacritty 仓库
    echo "正在克隆 Alacritty 仓库..."
    git clone https://github.com/alacritty/alacritty.git
    cd alacritty
    
    # 构建应用
    echo "正在构建 Alacritty 应用..."
    make app
    
    # 复制应用到 Applications 目录
    echo "正在安装 Alacritty 到 Applications..."
    cp -r target/release/osx/Alacritty.app /Applications/
    
    # 清理临时目录
    cd /
    rm -rf "$TEMP_DIR"
fi

# 安装 Terminfo
# Terminfo 用于终端信息数据库，确保 Alacritty 能正确识别终端类型
echo ""
echo "正在安装 Terminfo..."
if [ -d "/usr/local/share/terminfo" ] || [ -d "/usr/share/terminfo" ]; then
    # 尝试从已安装的 Alacritty 获取 terminfo
    if [ -f "/Applications/Alacritty.app/Contents/Resources/alacritty.info" ]; then
        sudo tic -xe alacritty,alacritty-direct /Applications/Alacritty.app/Contents/Resources/alacritty.info
    elif [ -f "$HOME/.cargo/bin/alacritty" ]; then
        # 如果通过 cargo 安装，查找 terminfo 文件
        ALACRITTY_DIR=$(dirname $(dirname $(which alacritty)))
        if [ -f "$ALACRITTY_DIR/share/alacritty/alacritty.info" ]; then
            sudo tic -xe alacritty,alacritty-direct "$ALACRITTY_DIR/share/alacritty/alacritty.info"
        fi
    else
        echo "警告: 未找到 alacritty.info 文件，跳过 Terminfo 安装"
        echo "你可以手动安装: sudo tic -xe alacritty,alacritty-direct <path-to-alacritty.info>"
    fi
else
    echo "警告: 未找到 terminfo 目录，跳过 Terminfo 安装"
fi

# 安装 Shell 自动补全
echo ""
echo "正在安装 Shell 自动补全..."

# Fish Shell 自动补全
if command -v fish &> /dev/null; then
    echo "安装 Fish Shell 自动补全..."
    FISH_COMPLETE_DIR="$HOME/.config/fish/completions"
    mkdir -p "$FISH_COMPLETE_DIR"
    
    # 尝试从不同位置复制补全文件
    if [ -f "/Applications/Alacritty.app/Contents/Resources/completions/alacritty.fish" ]; then
        cp /Applications/Alacritty.app/Contents/Resources/completions/alacritty.fish "$FISH_COMPLETE_DIR/"
    elif [ -f "/usr/local/share/fish/vendor_completions.d/alacritty.fish" ]; then
        cp /usr/local/share/fish/vendor_completions.d/alacritty.fish "$FISH_COMPLETE_DIR/"
    else
        echo "警告: 未找到 Fish 补全文件"
    fi
fi

# Zsh 自动补全
if command -v zsh &> /dev/null; then
    echo "安装 Zsh 自动补全..."
    ZSH_COMPLETE_DIR="$HOME/.zsh/completions"
    mkdir -p "$ZSH_COMPLETE_DIR"
    
    if [ -f "/Applications/Alacritty.app/Contents/Resources/completions/_alacritty" ]; then
        cp /Applications/Alacritty.app/Contents/Resources/completions/_alacritty "$ZSH_COMPLETE_DIR/"
        # 添加到 .zshrc
        if ! grep -q "fpath.*zsh/completions" "$HOME/.zshrc" 2>/dev/null; then
            echo "" >> "$HOME/.zshrc"
            echo "# Alacritty completions" >> "$HOME/.zshrc"
            echo "fpath=(\$HOME/.zsh/completions \$fpath)" >> "$HOME/.zshrc"
        fi
    fi
fi

# Bash 自动补全
if command -v bash &> /dev/null; then
    echo "安装 Bash 自动补全..."
    BASH_COMPLETE_DIR="$HOME/.local/share/bash-completion/completions"
    mkdir -p "$BASH_COMPLETE_DIR"
    
    if [ -f "/Applications/Alacritty.app/Contents/Resources/completions/alacritty.bash" ]; then
        cp /Applications/Alacritty.app/Contents/Resources/completions/alacritty.bash "$BASH_COMPLETE_DIR/"
    fi
fi

echo ""
echo "=========================================="
echo "Alacritty 安装完成！"
echo "=========================================="
echo ""
echo "配置文件位置（按优先级顺序）："
echo "  1. \$XDG_CONFIG_HOME/alacritty/alacritty.toml"
echo "  2. \$XDG_CONFIG_HOME/alacritty.toml"
echo "  3. ~/.config/alacritty/alacritty.toml (推荐)"
echo "  4. ~/.alacritty.toml"
echo ""
echo "快速配置："
echo "  mkdir -p ~/.config/alacritty"
echo "  cp dotfiles/alacritty/alacritty.toml ~/.config/alacritty/"
echo ""
echo "注意：Alacritty 从 0.13.0 版本开始使用 TOML 格式配置文件"
echo "旧版本的 YAML 格式配置文件 (alacritty.yml) 已不再支持"
echo ""
echo "更多信息请访问: https://github.com/alacritty/alacritty"

