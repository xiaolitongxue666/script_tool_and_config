# ============================================
# 设置 XDG_CONFIG_HOME 环境变量
# 用于 Neovim 等工具在 Windows 上的配置路径
# ============================================

# 设置错误处理
$ErrorActionPreference = "Stop"

# 获取当前用户名
$username = $env:USERNAME
if (-not $username) {
    $username = $env:USER
    if (-not $username) {
        Write-Host "[ERROR] 无法获取用户名" -ForegroundColor Red
        exit 1
    }
}

# 构建 XDG_CONFIG_HOME 路径
$xdgConfigHome = "C:\Users\$username\.config"

# 检查路径是否存在，不存在则创建
if (-not (Test-Path $xdgConfigHome)) {
    Write-Host "[INFO] 创建目录: $xdgConfigHome" -ForegroundColor Yellow
    New-Item -ItemType Directory -Path $xdgConfigHome -Force | Out-Null
}

# 检查环境变量是否已设置
$currentValue = [Environment]::GetEnvironmentVariable("XDG_CONFIG_HOME", "User")

if ($currentValue -eq $xdgConfigHome) {
    Write-Host "[SUCCESS] XDG_CONFIG_HOME 已正确设置: $xdgConfigHome" -ForegroundColor Green
} elseif ($currentValue) {
    Write-Host "[WARNING] XDG_CONFIG_HOME 已设置为其他值: $currentValue" -ForegroundColor Yellow
    Write-Host "[INFO] 是否要更新为: $xdgConfigHome ?" -ForegroundColor Cyan
    $response = Read-Host "输入 Y 确认，其他键取消"
    if ($response -eq "Y" -or $response -eq "y") {
        [Environment]::SetEnvironmentVariable("XDG_CONFIG_HOME", $xdgConfigHome, "User")
        Write-Host "[SUCCESS] XDG_CONFIG_HOME 已更新为: $xdgConfigHome" -ForegroundColor Green
    } else {
        Write-Host "[INFO] 已取消，保持原值: $currentValue" -ForegroundColor Cyan
        exit 0
    }
} else {
    # 设置用户级环境变量（永久生效）
    Write-Host "[INFO] 设置 XDG_CONFIG_HOME 环境变量..." -ForegroundColor Cyan
    [Environment]::SetEnvironmentVariable("XDG_CONFIG_HOME", $xdgConfigHome, "User")
    Write-Host "[SUCCESS] XDG_CONFIG_HOME 已设置为: $xdgConfigHome" -ForegroundColor Green
}

# 同时设置当前会话的环境变量（立即生效）
$env:XDG_CONFIG_HOME = $xdgConfigHome

# 验证设置
$verifyValue = [Environment]::GetEnvironmentVariable("XDG_CONFIG_HOME", "User")
if ($verifyValue -eq $xdgConfigHome) {
    Write-Host ""
    Write-Host "===========================================" -ForegroundColor Green
    Write-Host "环境变量设置成功！" -ForegroundColor Green
    Write-Host "===========================================" -ForegroundColor Green
    Write-Host "变量名: XDG_CONFIG_HOME" -ForegroundColor Cyan
    Write-Host "变量值: $xdgConfigHome" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "注意：" -ForegroundColor Yellow
    Write-Host "  1. 环境变量已设置为用户级（永久生效）" -ForegroundColor Yellow
    Write-Host "  2. 当前会话已立即生效" -ForegroundColor Yellow
    Write-Host "  3. 其他已打开的终端需要重新打开才能看到新变量" -ForegroundColor Yellow
    Write-Host "  4. 在 Git Bash 中验证: echo `$XDG_CONFIG_HOME" -ForegroundColor Yellow
    Write-Host "  5. 在 PowerShell 中验证: `$env:XDG_CONFIG_HOME" -ForegroundColor Yellow
    Write-Host ""
} else {
    Write-Host "[ERROR] 环境变量设置失败" -ForegroundColor Red
    exit 1
}


