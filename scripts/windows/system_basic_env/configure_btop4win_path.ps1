#Requires -RunAsAdministrator
# 永久配置 btop4win 的系统 PATH
# 使用方法：以管理员身份运行 PowerShell，然后执行此脚本
#
# 功能：
# - 将 C:\Program Files\btop4win 添加到系统 PATH（Machine 级别，永久生效）
# - 从用户 PATH 中移除 btop4win（如果存在，避免重复）
# - 刷新当前会话的 PATH
# - 验证配置是否成功
#
# 说明：
# - 系统级别的 PATH 修改后，PowerShell 和 Git Bash 都会自动继承
# - 新打开的终端窗口会自动包含 btop4win 路径
# - 当前会话会立即刷新 PATH，无需重启

$btopPath = "C:\Program Files\btop4win"
$btopExe = Join-Path $btopPath "btop4win.exe"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Configuring btop4win PATH" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 检查文件是否存在
if (-not (Test-Path $btopExe)) {
    Write-Host "ERROR: btop4win.exe not found at $btopExe" -ForegroundColor Red
    Write-Host "Please install btop4win first." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "You can install it using:" -ForegroundColor Yellow
    Write-Host "  .\install_common_tools.ps1 -ToolName btop4win" -ForegroundColor White
    exit 1
}

Write-Host "[OK] btop4win.exe found at: $btopExe" -ForegroundColor Green
Write-Host ""

# 获取当前系统 PATH
$machinePath = [System.Environment]::GetEnvironmentVariable("Path", "Machine")
$machinePathArray = $machinePath -split ';' | Where-Object { $_ -ne "" }
$btopInSystemPath = $false

Write-Host "Checking System PATH..." -ForegroundColor Yellow
foreach ($path in $machinePathArray) {
    if ($path -like "*btop4win*") {
        Write-Host "  [FOUND] $path" -ForegroundColor Green
        $btopInSystemPath = $true
    }
}

if (-not $btopInSystemPath) {
    Write-Host "  [NOT FOUND] btop4win not in System PATH" -ForegroundColor Red
    Write-Host ""
    Write-Host "Adding btop4win to System PATH..." -ForegroundColor Yellow

    # 清理 PATH（移除空项和重复项）
    $cleanPathArray = $machinePathArray | Where-Object { $_ -ne "" -and $_ -notlike "*btop4win*" } | Select-Object -Unique
    $cleanPathArray += $btopPath
    $newMachinePath = ($cleanPathArray | Where-Object { $_ -ne "" }) -join ';'

    try {
        [System.Environment]::SetEnvironmentVariable("Path", $newMachinePath, "Machine")
        Write-Host "[OK] Successfully added to System PATH" -ForegroundColor Green
        $btopInSystemPath = $true
    } catch {
        Write-Host "[ERROR] Failed to add to System PATH: $_" -ForegroundColor Red
        Write-Host "  Make sure you are running as Administrator" -ForegroundColor Yellow
        exit 1
    }
} else {
    Write-Host "[OK] btop4win already in System PATH" -ForegroundColor Green
}

Write-Host ""

# 从用户 PATH 中移除（如果存在）
Write-Host "Checking User PATH..." -ForegroundColor Yellow
$userPath = [System.Environment]::GetEnvironmentVariable("Path", "User")
$userPathArray = $userPath -split ';' | Where-Object { $_ -ne "" }
$btopInUserPath = $userPathArray | Where-Object { $_ -like "*btop4win*" }

if ($btopInUserPath) {
    Write-Host "  [FOUND] btop4win in User PATH (will be removed)" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Removing btop4win from User PATH..." -ForegroundColor Yellow
    $cleanUserPathArray = $userPathArray | Where-Object { $_ -notlike "*btop4win*" } | Select-Object -Unique
    $newUserPath = ($cleanUserPathArray | Where-Object { $_ -ne "" }) -join ';'
    try {
        [System.Environment]::SetEnvironmentVariable("Path", $newUserPath, "User")
        Write-Host "[OK] Removed from User PATH" -ForegroundColor Green
    } catch {
        Write-Host "[WARNING] Could not remove from User PATH: $_" -ForegroundColor Yellow
    }
} else {
    Write-Host "  [NOT FOUND] btop4win not in User PATH (good)" -ForegroundColor Green
}

Write-Host ""

# 使用 Win32 API 广播环境变量更改
Write-Host "Broadcasting environment variable changes..." -ForegroundColor Yellow
try {
    Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public class Win32 {
    [DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Auto)]
    public static extern IntPtr SendMessageTimeout(
        IntPtr hWnd, uint Msg, UIntPtr wParam, string lParam,
        uint fuFlags, uint uTimeout, out UIntPtr lpdwResult);
    public static readonly IntPtr HWND_BROADCAST = new IntPtr(0xffff);
    public static readonly uint WM_SETTINGCHANGE = 0x001a;
    public static readonly UIntPtr SMTO_ABORTIFHUNG = new UIntPtr(0x0002);
}
"@
    $result = 0
    [Win32]::SendMessageTimeout(
        [Win32]::HWND_BROADCAST,
        [Win32]::WM_SETTINGCHANGE,
        [UIntPtr]::Zero,
        "Environment",
        [Win32]::SMTO_ABORTIFHUNG,
        5000,
        [ref]$result
    ) | Out-Null
    Write-Host "[OK] Environment changes broadcasted" -ForegroundColor Green
} catch {
    Write-Host "[WARNING] Could not broadcast changes (non-critical)" -ForegroundColor Yellow
}

Write-Host ""

# 刷新当前会话的 PATH
Write-Host "Refreshing current session PATH..." -ForegroundColor Yellow
$env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
Write-Host "[OK] Current session PATH refreshed" -ForegroundColor Green

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Verification" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 验证
if (Get-Command btop4win -ErrorAction SilentlyContinue) {
    Write-Host "[SUCCESS] btop4win is now available!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Version: " -NoNewline
    btop4win --version
    Write-Host ""
    Write-Host "You can now run: btop4win" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Note: If you have other PowerShell or Git Bash windows open," -ForegroundColor Yellow
    Write-Host "      please close and reopen them to use btop4win." -ForegroundColor Yellow
} else {
    Write-Host "[ERROR] btop4win still not found in current session" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please try the following:" -ForegroundColor Yellow
    Write-Host "1. Close this PowerShell window" -ForegroundColor White
    Write-Host "2. Open a new PowerShell window (as Administrator)" -ForegroundColor White
    Write-Host "3. Run: btop4win --version" -ForegroundColor White
    Write-Host ""
    Write-Host "Or use the full path:" -ForegroundColor Yellow
    Write-Host "  & 'C:\Program Files\btop4win\btop4win.exe'" -ForegroundColor White
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. btop4win has been added to System PATH (permanent)" -ForegroundColor Green
Write-Host "2. Current session PATH has been refreshed" -ForegroundColor Green
Write-Host ""
Write-Host "The PATH configuration is now permanent and will be available in:" -ForegroundColor Cyan
Write-Host "  - All new PowerShell sessions" -ForegroundColor White
Write-Host "  - All new Git Bash sessions (restart Git Bash to take effect)" -ForegroundColor White
Write-Host "  - All other terminal applications" -ForegroundColor White
Write-Host ""
Write-Host "For Git Bash:" -ForegroundColor Yellow
Write-Host "  - The PATH is configured in .bash_profile (chezmoi managed)" -ForegroundColor White
Write-Host "  - Run 'chezmoi apply' to update your Git Bash configuration" -ForegroundColor White
Write-Host "  - Or manually run: bash scripts/windows/system_basic_env/add_btop4win_to_git_bash.sh" -ForegroundColor White
Write-Host "  - Then restart Git Bash to use btop4win" -ForegroundColor White
Write-Host ""

