@echo off
REM ============================================
REM Windows 新系统完整安装脚本（chezmoi 流程）
REM 自动执行：安装 chezmoi -> 安装软件 -> 配置软件 -> 纳入管理
REM ============================================

REM 检查管理员权限
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [ERROR] 此脚本需要管理员权限
    echo 请右键点击此文件，选择"以管理员身份运行"
    pause
    exit /b 1
)

REM 获取脚本目录
set "SCRIPT_DIR=%~dp0"
set "PROJECT_ROOT=%SCRIPT_DIR%..\.."

REM 切换到项目根目录
cd /d "%PROJECT_ROOT%"

REM 检查 Git Bash
where bash >nul 2>&1
if %errorLevel% neq 0 (
    echo [ERROR] 未找到 Git Bash
    echo 请先安装 Git for Windows: https://git-scm.com/download/win
    pause
    exit /b 1
)

echo [INFO] 开始执行 Windows 新系统完整安装脚本...
echo [INFO] 项目目录: %PROJECT_ROOT%
echo.

REM 执行 Bash 脚本
bash "%SCRIPT_DIR%install_with_chezmoi.sh"

if %errorLevel% equ 0 (
    echo.
    echo [SUCCESS] 安装完成！
) else (
    echo.
    echo [ERROR] 安装过程中出现错误
)

echo.
pause

