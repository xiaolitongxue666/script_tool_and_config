#!/bin/bash

# Alacritty 重复项清理脚本
# 用于清理 macOS 上可能存在的重复 Alacritty 安装和缓存

set -e

# 加载通用脚本函数
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/../../scripts/common.sh" ]; then
    source "$SCRIPT_DIR/../../scripts/common.sh"
else
    function log_info() { echo "[信息] $*"; }
    function log_success() { echo "[成功] $*"; }
    function log_warning() { echo "[警告] $*"; }
    function log_error() { echo "[错误] $*" >&2; }
fi

start_script "Alacritty 重复项清理"

echo ""
log_info "正在检查 Alacritty 的安装位置..."

# ============================================
# 1. 检查应用程序安装位置
# ============================================
echo ""
echo "=== 应用程序位置 ==="
ALACRITTY_APPS=$(find /Applications -name "*Alacritty*" -type d 2>/dev/null)
if [ -n "$ALACRITTY_APPS" ]; then
    echo "$ALACRITTY_APPS" | while read app; do
        if [ -d "$app" ]; then
            VERSION=$(plutil -extract CFBundleShortVersionString raw "$app/Contents/Info.plist" 2>/dev/null || echo "未知版本")
            MODIFIED=$(stat -f "%Sm" -t "%Y-%m-%d %H:%M:%S" "$app" 2>/dev/null || echo "未知时间")
            echo "  ✓ $app"
            echo "    版本: $VERSION"
            echo "    修改时间: $MODIFIED"
        fi
    done
else
    log_warning "未找到 Alacritty.app"
fi

# ============================================
# 2. 检查 Spotlight 索引
# ============================================
echo ""
echo "=== Spotlight 索引结果 ==="
SPOTLIGHT_APPS=$(mdfind "kMDItemKind == 'Application' && kMDItemFSName == '*alacritty*'" 2>/dev/null)
if [ -n "$SPOTLIGHT_APPS" ]; then
    echo "$SPOTLIGHT_APPS" | while read app; do
        echo "  ✓ $app"
    done
else
    log_info "Spotlight 中未找到 Alacritty 应用程序"
fi

# ============================================
# 3. 检查 Homebrew 安装
# ============================================
echo ""
echo "=== Homebrew 安装 ==="
if command -v brew &> /dev/null; then
    if brew list --cask alacritty &>/dev/null; then
        log_info "通过 Homebrew 安装:"
        brew info --cask alacritty 2>/dev/null | head -5
    else
        log_info "未通过 Homebrew 安装"
    fi
else
    log_info "未安装 Homebrew"
fi

# ============================================
# 4. 检查 terminfo 文件
# ============================================
echo ""
echo "=== Terminfo 文件 ==="
TERMINFO_FILES=$(find ~/.terminfo /usr/local/share/terminfo /usr/share/terminfo -name "*alacritty*" 2>/dev/null | head -10)
if [ -n "$TERMINFO_FILES" ]; then
    echo "$TERMINFO_FILES" | while read file; do
        OWNER=$(stat -f "%Su" "$file" 2>/dev/null || echo "unknown")
        echo "  - $file (所有者: $OWNER)"
    done
else
    log_info "未找到 terminfo 文件"
fi

# ============================================
# 5. 检查符号链接
# ============================================
echo ""
echo "=== 符号链接 ==="
SYMLINKS=$(find /usr/local -type l -name "*alacritty*" 2>/dev/null)
if [ -n "$SYMLINKS" ]; then
    echo "$SYMLINKS" | while read link; do
        TARGET=$(readlink "$link" 2>/dev/null || echo "broken")
        echo "  - $link -> $TARGET"
    done
else
    log_info "未找到符号链接"
fi

# ============================================
# 6. 清理选项
# ============================================
echo ""
echo "=========================================="
echo "清理选项"
echo "=========================================="
echo ""
echo "如果发现重复项，可以执行以下清理操作："
echo ""
echo "1. 删除旧版本备份："
echo "   rm -rf /Applications/Alacritty.app.backup.*"
echo ""
echo "2. 删除 terminfo 文件（需要 sudo）："
echo "   sudo rm -f ~/.terminfo/61/alacritty*"
echo ""
echo "3. 重建 Spotlight 索引（需要管理员权限）："
echo "   sudo mdutil -E /"
echo "   注意：这会重建整个系统的 Spotlight 索引，可能需要较长时间"
echo ""
echo "4. 清理 Launchpad 缓存："
echo "   killall Dock"
echo "   注意：这会重启 Dock，所有打开的窗口会重新排列"
echo ""
echo "5. 清理 Homebrew 缓存（如果通过 Homebrew 安装）："
echo "   brew cleanup alacritty"
echo ""

# ============================================
# 7. 交互式清理
# ============================================
echo "是否执行自动清理？"
read -p "删除旧版本备份和 terminfo 文件？(y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    # 删除旧版本备份
    OLD_BACKUPS=$(find /Applications -name "Alacritty.app.backup.*" -type d 2>/dev/null)
    if [ -n "$OLD_BACKUPS" ]; then
        echo "$OLD_BACKUPS" | while read backup; do
            rm -rf "$backup" && log_success "已删除: $backup"
        done
    fi
    
    # 尝试删除 terminfo 文件
    if [ -f "$HOME/.terminfo/61/alacritty" ]; then
        if sudo rm -f "$HOME/.terminfo/61/alacritty" 2>/dev/null; then
            log_success "已删除: $HOME/.terminfo/61/alacritty"
        else
            log_warning "无法删除 $HOME/.terminfo/61/alacritty（需要 sudo 权限）"
        fi
    fi
    
    if [ -f "$HOME/.terminfo/61/alacritty-direct" ]; then
        if sudo rm -f "$HOME/.terminfo/61/alacritty-direct" 2>/dev/null; then
            log_success "已删除: $HOME/.terminfo/61/alacritty-direct"
        else
            log_warning "无法删除 $HOME/.terminfo/61/alacritty-direct（需要 sudo 权限）"
        fi
    fi
    
    # 重建 Spotlight 索引（可选）
    read -p "重建 Spotlight 索引？(y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log_info "正在重建 Spotlight 索引（这可能需要几分钟）..."
        sudo mdutil -E / 2>/dev/null && log_success "Spotlight 索引重建已启动" || log_warning "需要管理员权限"
    fi
    
    # 清理 Launchpad 缓存
    read -p "清理 Launchpad 缓存（重启 Dock）？(y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        killall Dock 2>/dev/null && log_success "Dock 已重启" || log_warning "无法重启 Dock"
    fi
fi

end_script

echo ""
log_success "清理完成！"
echo ""
echo "如果启动后台仍然显示两个 Alacritty，请尝试："
echo "1. 重启 Mac（最彻底的方法）"
echo "2. 等待几分钟让 Spotlight 索引更新"
echo "3. 手动清理 Launchpad: 打开 Launchpad，按住 Option 键，点击应用程序上的 X 删除重复项"

