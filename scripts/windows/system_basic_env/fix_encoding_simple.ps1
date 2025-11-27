# Fix PowerShell script encoding to UTF-8 with BOM
# 修复 PowerShell 脚本编码为 UTF-8 with BOM

$scriptPath = Join-Path $PSScriptRoot "install_common_tools.ps1"
$backupPath = "$scriptPath.backup"

if (-not (Test-Path $scriptPath)) {
    Write-Host "Script file not found: $scriptPath" -ForegroundColor Red
    exit 1
}

Write-Host "Backing up original file..." -ForegroundColor Yellow
Copy-Item -Path $scriptPath -Destination $backupPath -Force

Write-Host "Reading file content..." -ForegroundColor Yellow
# Try to read with different encodings
$content = $null
try {
    $content = Get-Content -Path $scriptPath -Raw -Encoding UTF8
} catch {
    try {
        $content = Get-Content -Path $scriptPath -Raw -Encoding Default
    } catch {
        $content = [System.IO.File]::ReadAllText($scriptPath)
    }
}

Write-Host "Writing file with UTF-8 BOM encoding..." -ForegroundColor Yellow
$utf8WithBom = New-Object System.Text.UTF8Encoding $true
[System.IO.File]::WriteAllText($scriptPath, $content, $utf8WithBom)

# Verify BOM
$bytes = [System.IO.File]::ReadAllBytes($scriptPath)
if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
    Write-Host "UTF-8 BOM verified: YES" -ForegroundColor Green
} else {
    Write-Host "UTF-8 BOM verified: NO - trying again..." -ForegroundColor Yellow
    $utf8WithBom = New-Object System.Text.UTF8Encoding $true
    [System.IO.File]::WriteAllText($scriptPath, $content, $utf8WithBom)
}

Write-Host "Done! Original file backed up as: $backupPath" -ForegroundColor Green
Write-Host "You can now run install_common_tools.bat" -ForegroundColor Green

