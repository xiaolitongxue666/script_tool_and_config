@echo off
REM Windows Common Tools Installer Launcher
REM Auto-handles execution policy issues

echo ============================================
echo Windows Common Tools Installer Launcher
echo ============================================
echo.

REM Check administrator privileges
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [ERROR] This script requires administrator privileges
    echo Please right-click this file and select "Run as administrator"
    pause
    exit /b 1
)

echo [INFO] Administrator privileges detected
echo.

REM Run PowerShell script with Bypass execution policy
echo [INFO] Starting installation script...
echo.

REM Set code page to UTF-8 and run PowerShell script
chcp 65001 >nul 2>&1
cd /d "%~dp0"
powershell.exe -ExecutionPolicy Bypass -NoProfile -File "install_common_tools.ps1" %*

if %errorLevel% neq 0 (
    echo.
    echo [ERROR] Script execution failed
    pause
    exit /b %errorLevel%
)

exit /b 0

