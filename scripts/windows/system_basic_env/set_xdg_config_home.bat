@echo off
REM ============================================
REM 设置 XDG_CONFIG_HOME 环境变量（批处理版本）
REM 用于 Neovim 等工具在 Windows 上的配置路径
REM ============================================

echo ============================================
echo 设置 XDG_CONFIG_HOME 环境变量
echo ============================================
echo.

REM 检查 PowerShell 是否可用
where powershell >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] PowerShell 未找到
    pause
    exit /b 1
)

REM 调用 PowerShell 脚本
powershell -ExecutionPolicy Bypass -File "%~dp0set_xdg_config_home.ps1"

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo [ERROR] 脚本执行失败
    pause
    exit /b 1
)

echo.
pause

