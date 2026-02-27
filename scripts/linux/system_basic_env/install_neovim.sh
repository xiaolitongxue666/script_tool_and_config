#!/bin/bash

# 安装 neovim（Arch 仓库版本可能低于 0.11）
# 本仓库 Neovim 配置要求 0.11.0+；推荐通过 chezmoi run_once_install-neovim 安装以得到 0.11+
set -x

# 安装 neovim
pacman -S --noconfirm neovim

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
# Neovim 配置由 run_once 克隆到 ~/.config/nvim；若已存在则执行其 install.sh
NEOVIM_INSTALL_SCRIPT="${HOME}/.config/nvim/install.sh"
if [ -f "$NEOVIM_INSTALL_SCRIPT" ]; then
    echo "运行 Neovim 配置安装脚本（~/.config/nvim/install.sh）..."
    chmod +x "$NEOVIM_INSTALL_SCRIPT"
    export PROJECT_ROOT COMMON_LIB
    COMMON_LIB="${PROJECT_ROOT}/scripts/common.sh"
    bash "$NEOVIM_INSTALL_SCRIPT"
else
    echo "未找到 ~/.config/nvim/install.sh，请先执行 chezmoi apply 以触发 run_once_install-neovim-config，或手动: git clone https://github.com/xiaolitongxue666/nvim.git ~/.config/nvim && ~/.config/nvim/install.sh"
fi

# ============================================
# Windows 系统配置说明
# ============================================
# 在 Windows 上使用 Neovim 时，需要配置 XDG_CONFIG_HOME 环境变量
# 以便 Neovim 能够正确找到配置文件位置
#
# 配置步骤：
# 1. 打开系统属性：
#    - 右键单击"此电脑"或"计算机"图标，选择"属性"
#    - 在左侧菜单中，点击"高级系统设置"
#
# 2. 打开环境变量设置：
#    - 在"系统属性"窗口中，点击"环境变量"按钮
#
# 3. 添加新环境变量：
#    - 在"用户变量"或"系统变量"部分点击"新建"按钮
#
# 4. 输入变量名和变量值：
#    - 变量名：XDG_CONFIG_HOME
#    - 变量值：C:\Users\<用户名>\.config\
#      例如：C:\Users\Administrator\.config\
#    - 点击"确定"保存
#
# 5. 确认更改：
#    - 关闭所有窗口，确保更改已保存
#
# 6. 重新启动终端：
#    - 关闭并重新打开 Git Bash 或 PowerShell，以使新环境变量生效
#
# 验证环境变量：
#   在 Git Bash 中运行：echo $XDG_CONFIG_HOME
#   应该输出：C:\Users\<用户名>\.config\
#
# 配置完成后，Neovim 的配置文件路径将是：
#   %XDG_CONFIG_HOME%\nvim\  (即 ~/.config/nvim/)
# ============================================