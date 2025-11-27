#Requires -RunAsAdministrator
# PowerShell 脚本编码：UTF-8 with BOM

<#
.SYNOPSIS
    Windows 基础工具安装脚本
    
.DESCRIPTION
    用于在新装 Windows 系统上安装基础开发工具，支持 winget 和 chocolatey 两种包管理器。
    参考 winutil 的安装方式实现。
    
.PARAMETER Interactive
    启用交互式模式，让用户选择要安装的工具
    
.PARAMETER PackageManager
    指定包管理器：winget 或 chocolatey（默认：自动选择，优先使用 winget）
    
.PARAMETER SkipFonts
    跳过字体安装
    
.PARAMETER Action
    操作类型：Install（安装）、Update（更新）、Uninstall（卸载）。默认：Install
    
.PARAMETER ToolName
    指定要操作的工具名称（用于单独操作某个工具）
    
.EXAMPLE
    .\install_common_tools.ps1
    
.EXAMPLE
    .\install_common_tools.ps1 -Interactive
    
.EXAMPLE
    .\install_common_tools.ps1 -PackageManager winget
    
.EXAMPLE
    .\install_common_tools.ps1 -Action Update
    
.EXAMPLE
    .\install_common_tools.ps1 -Action Update -ToolName fnm
#>

[CmdletBinding()]
param(
    [switch]$Interactive,
    [ValidateSet("winget", "chocolatey", "auto")]
    [string]$PackageManager = "auto",
    [switch]$SkipFonts,
    [ValidateSet("Install", "Update", "Uninstall")]
    [string]$Action = "Install",
    [string]$ToolName = "",
    [string]$Msys2Mirror = "",
    [ValidateSet("toolchain", "minimal")]
    [string]$GccPreset = "minimal"
)

# 设置编码（在 param 块之后）
$PSDefaultParameterValues['*:Encoding'] = 'utf8'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

# ============================================
# 全局变量
# ============================================
$ErrorActionPreference = "Continue"
$ProgressPreference = "SilentlyContinue"

$Script:InstalledCount = 0
$Script:FailedCount = 0
$Script:FailedPackages = @()
$Script:SelectedPackages = @()
$Script:InstallationReport = @()  # 安装报告：@{Name, Version, Status, InstallMethod}
$Script:CurrentAction = "Install"  # 当前操作类型
$Script:PathBackedUp = $false  # PATH 是否已备份
$Script:Msys2MirrorApplied = $false  # 自定义 MSYS2 镜像是否已经生效
$Script:GccPreset = $GccPreset
$Script:Msys2Mirror = $Msys2Mirror

# 日志文件路径（与脚本同目录）
$Script:LogFile = Join-Path $PSScriptRoot "log"
$Script:LogSyncRoot = New-Object System.Object

# ============================================
# 日志记录函数（类似 tee，同时输出到控制台和文件）
# ============================================
function Write-Log {
    <#
    .SYNOPSIS
        写入日志文件（类似 bash 的 tee，与控制台输出完全一致）
        不添加时间戳，保持与控制台输出一致
    #>
    param(
        [string]$Message,
        [string]$LogFile = $Script:LogFile,
        [switch]$NoNewline
    )
    
    # 追加到日志文件（不带时间戳，与控制台输出一致）
    try {
        if ($NoNewline) {
            # 不换行（用于进度显示）
            [System.IO.File]::AppendAllText($LogFile, $Message, [System.Text.Encoding]::UTF8)
        } else {
            Add-Content -Path $LogFile -Value $Message -Encoding UTF8 -ErrorAction SilentlyContinue
        }
    } catch {
        # 如果写入失败，忽略错误（避免影响主流程）
    }
}

# ============================================
# 颜色输出函数（带日志记录）
# ============================================
# 注意：所有输出使用英文，注释使用中文
function Write-Info {
    param([string]$Message)
    $formattedMessage = "[INFO] $Message"
    Write-Host $formattedMessage -ForegroundColor Cyan
    Write-Log $formattedMessage
}

function Write-Success {
    param([string]$Message)
    $formattedMessage = "[SUCCESS] $Message"
    Write-Host $formattedMessage -ForegroundColor Green
    Write-Log $formattedMessage
}

function Write-Warning {
    param([string]$Message)
    $formattedMessage = "[WARNING] $Message"
    Write-Host $formattedMessage -ForegroundColor Yellow
    Write-Log $formattedMessage
}

function Write-Error {
    param([string]$Message)
    $formattedMessage = "[ERROR] $Message"
    Write-Host $formattedMessage -ForegroundColor Red
    Write-Log $formattedMessage
}

# 包装 Write-Host，同时记录到日志
function Write-Host-Log {
    <#
    .SYNOPSIS
        同时输出到控制台和日志文件（类似 tee）
    #>
    param(
        [string]$Message,
        [switch]$NoNewline,
        [string]$ForegroundColor
    )
    
    # 构建 Write-Host 的参数（排除 NoNewline，因为要单独处理）
    $hostParams = @{}
    if ($ForegroundColor) {
        $hostParams['ForegroundColor'] = $ForegroundColor
    }
    
    # 输出到控制台
    if ($NoNewline) {
        Write-Host $Message -NoNewline @hostParams
        Write-Log $Message -NoNewline
    } else {
        Write-Host $Message @hostParams
        Write-Log $Message
    }
}

# ============================================
# 代理检测和设置函数
# ============================================
function Test-IsMainlandChina {
    <#
    .SYNOPSIS
        检测是否在中国大陆
        
    .DESCRIPTION
        通过检查系统区域设置、时区和语言来判断是否在中国大陆
    #>
    
    try {
        # 方法1: 检查系统区域设置
        $region = [System.Globalization.RegionInfo]::CurrentRegion
        if ($region.TwoLetterISORegionName -eq "CN") {
            return $true
        }
        
        # 方法2: 检查时区（中国标准时间 UTC+8）
        $timeZone = [System.TimeZoneInfo]::Local
        if ($timeZone.Id -like "*China*" -or $timeZone.Id -like "*Beijing*" -or $timeZone.Id -like "*Shanghai*") {
            return $true
        }
        
        # 方法3: 检查系统语言
        $culture = [System.Globalization.CultureInfo]::CurrentCulture
        if ($culture.Name -eq "zh-CN") {
            return $true
        }
        
        return $false
    } catch {
        return $false
    }
}

function Set-ProxySettings {
    <#
    .SYNOPSIS
        设置代理环境变量
    #>
    param(
        [string]$ProxyUrl = "http://127.0.0.1:7890"
    )
    
    $env:http_proxy = $ProxyUrl
    $env:https_proxy = $ProxyUrl
    $env:HTTP_PROXY = $ProxyUrl
    $env:HTTPS_PROXY = $ProxyUrl
    
    Write-Info "Proxy set to: $ProxyUrl"
}

function Get-WebRequestParams {
    <#
    .SYNOPSIS
        获取 Invoke-WebRequest 的参数（包含代理设置）
    #>
    param(
        [string]$ProxyUrl = "http://127.0.0.1:7890"
    )
    
    $params = @{
        UseBasicParsing = $true
    }
    
    # 如果设置了代理环境变量，使用代理
    if ($env:http_proxy) {
        try {
            $proxyUri = [System.Uri]$env:http_proxy
            $params.Proxy = $proxyUri
        } catch {
            # 代理 URL 格式错误，忽略
        }
    }
    
    return $params
}

function Invoke-WebRequestWithProgress {
    <#
    .SYNOPSIS
        带进度条和下载速度显示的下载函数
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Uri,
        
        [Parameter(Mandatory)]
        [string]$OutFile,
        
        [string]$ProxyUrl = ""
    )
    
    try {
        # 创建 WebClient 对象
        $webClient = New-Object System.Net.WebClient
        
        # 设置代理
        if ($env:http_proxy) {
            try {
                $proxyUri = [System.Uri]$env:http_proxy
                $webClient.Proxy = [System.Net.WebProxy]::new($proxyUri)
            } catch {
                # 代理设置失败，继续
            }
        }
        
        # 获取文件大小（使用 script 作用域变量，以便在事件处理程序中访问）
        $webClient.Headers.Add("User-Agent", "Mozilla/5.0")
        $script:totalBytes = 0
        try {
            $response = $webClient.OpenRead($Uri)
            $script:totalBytes = [System.Convert]::ToInt64($webClient.ResponseHeaders["Content-Length"])
            $response.Close()
        } catch {
            # 无法获取文件大小，继续下载
        }
        
        # 下载进度跟踪（使用 script 作用域变量，以便在事件处理程序中访问）
        $script:downloadedBytes = 0
        $script:lastUpdateTime = Get-Date
        $script:lastDownloadedBytes = 0
        $script:speed = 0
        
        # 注册进度事件
        $webClient.add_DownloadProgressChanged({
            param($sender, $e)
            
            $script:downloadedBytes = $e.BytesReceived
            $currentTime = Get-Date
            $timeElapsed = ($currentTime - $script:lastUpdateTime).TotalSeconds
            
            # 计算下载速度（每秒更新一次）
            if ($timeElapsed -ge 1.0) {
                $bytesDownloaded = $script:downloadedBytes - $script:lastDownloadedBytes
                $script:speed = $bytesDownloaded / $timeElapsed
                $script:lastUpdateTime = $currentTime
                $script:lastDownloadedBytes = $script:downloadedBytes
            }
            
            # 格式化速度
            $speedFormatted = if ($script:speed -gt 1MB) {
                "{0:N2} MB/s" -f ($script:speed / 1MB)
            } elseif ($script:speed -gt 1KB) {
                "{0:N2} KB/s" -f ($script:speed / 1KB)
            } else {
                "{0:N0} B/s" -f $script:speed
            }
            
            # 格式化已下载大小
            $downloadedFormatted = if ($script:downloadedBytes -gt 1MB) {
                "{0:N2} MB" -f ($script:downloadedBytes / 1MB)
            } elseif ($script:downloadedBytes -gt 1KB) {
                "{0:N2} KB" -f ($script:downloadedBytes / 1KB)
            } else {
                "{0:N0} B" -f $script:downloadedBytes
            }
            
            # 格式化总大小
            $totalFormatted = if ($script:totalBytes -gt 1MB) {
                "{0:N2} MB" -f ($script:totalBytes / 1MB)
            } elseif ($script:totalBytes -gt 1KB) {
                "{0:N2} KB" -f ($script:totalBytes / 1KB)
            } else {
                "{0:N0} B" -f $script:totalBytes
            }
            
            # 计算百分比
            $percent = if ($script:totalBytes -gt 0) {
                [Math]::Min(100, [int](($script:downloadedBytes / $script:totalBytes) * 100))
            } else {
                0
            }
            
            # 显示进度条
            $progressBarLength = 50
            $filledLength = [Math]::Floor($percent / 100 * $progressBarLength)
            $bar = "█" * $filledLength + "▒" * ($progressBarLength - $filledLength)
            
            # 更新进度显示（在同一行）
            $progressText = "`r  [$bar] $percent% - $downloadedFormatted / $totalFormatted - $speedFormatted"
            Write-Host -NoNewline $progressText
            # 注意：日志中不记录每行的进度更新，只记录最终完成状态
        })
        
        # 开始下载
        Write-Info "Downloading from: $Uri"
        if ($script:totalBytes -gt 0) {
            Write-Info "File size: $([Math]::Round($script:totalBytes / 1MB, 2)) MB"
        }
        
        $webClient.DownloadFile($Uri, $OutFile)
        
        # 下载完成，换行
        Write-Host ""
        Write-Log ""
        
        Write-Success "Download completed: $OutFile"
        return $true
        
    } catch {
        Write-Host ""
        Write-Log ""
        Write-Error "Download failed: $_"
        Write-Log "Download failed: $_"
        return $false
    } finally {
        if ($webClient) {
            $webClient.Dispose()
        }
    }
}

# ============================================
# 包管理器检测函数
# ============================================
function Test-PackageManager {
    <#
    .SYNOPSIS
        检测包管理器是否已安装
        
    .PARAMETER Manager
        包管理器名称：winget 或 chocolatey
    #>
    param(
        [Parameter(Mandatory)]
        [ValidateSet("winget", "chocolatey")]
        [string]$Manager
    )
    
    $status = "not-installed"
    
    if ($Manager -eq "winget") {
        try {
            $wingetInfo = winget --info 2>&1
            if ($LASTEXITCODE -eq 0) {
                $status = "installed"
            }
        } catch {
            $status = "not-installed"
        }
    } elseif ($Manager -eq "chocolatey") {
        if ((Get-Command -Name choco -ErrorAction SilentlyContinue) -and 
            (Test-Path "$env:ChocolateyInstall\choco.exe")) {
            $status = "installed"
        }
    }
    
    return $status
}

# ============================================
# 包管理器安装函数
# ============================================
function Install-Winget {
    <#
    .SYNOPSIS
        安装或更新 Winget
    #>
    Write-Info "Checking Winget installation status..."
    
    $wingetStatus = Test-PackageManager -Manager "winget"
    
    if ($wingetStatus -eq "installed") {
        Write-Success "Winget is already installed"
        return $true
    }
    
    Write-Info "Installing Winget..."
    
    try {
        # 尝试通过 Microsoft Store 安装
        $wingetCmd = Get-Command winget -ErrorAction SilentlyContinue
        if ($wingetCmd) {
            Write-Info "Attempting to update Winget using itself..."
            $result = Start-Process -FilePath "winget" -ArgumentList "install -e --accept-source-agreements --accept-package-agreements Microsoft.AppInstaller" -Wait -NoNewWindow -PassThru
            if ($result.ExitCode -eq 0) {
                Write-Success "Winget updated successfully"
                return $true
            }
        }
        
        # 尝试从 Microsoft Store 安装
        Write-Info "Attempting to install App Installer from Microsoft Store..."
        Start-Process "ms-windows-store://pdp/?ProductId=9NBLGGH4NNS1" -ErrorAction SilentlyContinue
        Write-Warning "Please install App Installer from Microsoft Store, then run this script again"
        return $false
        
    } catch {
        Write-Error "Failed to install Winget: $_"
        return $false
    }
}

function Install-Chocolatey {
    <#
    .SYNOPSIS
        安装 Chocolatey
    #>
    Write-Info "Checking Chocolatey installation status..."
    
    $chocoStatus = Test-PackageManager -Manager "chocolatey"
    
    if ($chocoStatus -eq "installed") {
        Write-Success "Chocolatey is already installed"
        return $true
    }
    
    Write-Info "Installing Chocolatey..."
    
    try {
        Set-ExecutionPolicy Bypass -Scope Process -Force
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
        
        # 如果在中国大陆，设置代理
        if (Test-IsMainlandChina) {
            Set-ProxySettings
            $webClient = New-Object System.Net.WebClient
            if ($env:http_proxy) {
                $proxyUri = [System.Uri]$env:http_proxy
                $webClient.Proxy = [System.Net.WebProxy]::new($proxyUri)
            }
            Invoke-Expression ($webClient.DownloadString('https://community.chocolatey.org/install.ps1'))
        } else {
            Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
        }
        
        # 刷新环境变量
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
        
        if (Test-PackageManager -Manager "chocolatey" -eq "installed") {
            Write-Success "Chocolatey installed successfully"
            return $true
        } else {
            Write-Error "Chocolatey installation failed"
            return $false
        }
    } catch {
        Write-Error "Failed to install Chocolatey: $_"
        return $false
    }
}

# ============================================
# 工具检测函数
# ============================================
function Test-ProgramInstalled {
    <#
    .SYNOPSIS
        检测程序是否已安装
        
    .PARAMETER PackageId
        包 ID（winget 或 chocolatey）
        
    .PARAMETER PackageName
        包名称
        
    .PARAMETER Manager
        包管理器类型
    #>
    param(
        [Parameter(Mandatory)]
        [string]$PackageId,
        
        [Parameter(Mandatory)]
        [string]$PackageName,
        
        [Parameter(Mandatory)]
        [ValidateSet("winget", "chocolatey")]
        [string]$Manager
    )
    
    # 特殊处理：gcc 使用 MSYS2 检测方式
    if ($PackageName -eq "gcc") {
        $msys2Check = Test-MSYS2Installed
        if ($msys2Check.Installed) {
            try {
                $gccVersion = & $msys2Check.GccPath --version 2>&1 | Select-Object -First 1
                $versionMatch = $gccVersion | Select-String -Pattern "(\d+\.\d+\.\d+[^\s]*)"
                $version = if ($versionMatch) { $versionMatch.Matches[0].Groups[1].Value } else { "Unknown" }
                return @{ Installed = $true; Version = $version }
            } catch {
                return @{ Installed = $true; Version = "Unknown" }
            }
        }
        return @{ Installed = $false; Version = $null }
    }
    
    try {
        if ($Manager -eq "winget") {
            $guid = [System.Guid]::NewGuid().ToString('N').Substring(0,8)
            $stdoutFile = Join-Path $env:TEMP "winget_list_$guid.json"
            $stderrFile = Join-Path $env:TEMP "winget_list_$guid.err"
            $arguments = @(
                "list",
                "--id", $PackageId,
                "--exact",
                "--accept-source-agreements",
                "--disable-interactivity",
                "--output", "json"
            )
            try {
                $process = Start-Process -FilePath "winget" -ArgumentList $arguments -Wait -NoNewWindow -PassThru -RedirectStandardOutput $stdoutFile -RedirectStandardError $stderrFile
            } catch {
                $process = $null
            }
            $jsonText = ""
            if (Test-Path $stdoutFile) {
                $jsonText = Get-Content -Path $stdoutFile -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
                Remove-Item -Path $stdoutFile -Force -ErrorAction SilentlyContinue
            }
            if (Test-Path $stderrFile) {
                # 记录但不影响逻辑
                $stderrContent = Get-Content -Path $stderrFile -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
                Remove-Item -Path $stderrFile -Force -ErrorAction SilentlyContinue
                if ($stderrContent) {
                    Write-Log "winget list stderr: $stderrContent"
                }
            }
            if ($jsonText) {
                try {
                    $parsed = $jsonText | ConvertFrom-Json
                    $packages = @()
                    if ($parsed -is [System.Collections.IEnumerable]) {
                        $packages = $parsed
                    } elseif ($parsed.Packages) {
                        $packages = $parsed.Packages
                    } elseif ($parsed.Sources) {
                        foreach ($source in $parsed.Sources) {
                            if ($source.Packages) {
                                $packages += $source.Packages
                            }
                        }
                    }
                    foreach ($pkg in $packages) {
                        if ($pkg.PackageIdentifier -eq $PackageId -or $pkg.Name -eq $PackageName) {
                            $version = if ($pkg.InstalledVersion) { $pkg.InstalledVersion } else { "Unknown" }
                            return @{ Installed = $true; Version = $version }
                        }
                    }
                } catch {
                    # JSON 解析失败时回退到文本方式
                }
            }
            # 回退：使用 where 检测可执行文件位置，避免语言差异
            $pathCheck = Test-ProgramInPath -ProgramName $PackageName
            if ($pathCheck.Available) {
                $version = Get-ProgramVersion -PackageName $PackageName -PackageId $PackageId
                return @{ Installed = $true; Version = $version }
            }
        } elseif ($Manager -eq "chocolatey") {
            # 使用 choco list --local-only 检测
            $result = choco list --local-only $PackageId --exact 2>&1
            if ($LASTEXITCODE -eq 0 -and $result -match $PackageId) {
                # 尝试获取版本号
                $versionMatch = $result | Select-String -Pattern "(\d+\.\d+\.\d+[^\s]*)"
                $version = if ($versionMatch) { $versionMatch.Matches[0].Groups[1].Value } else { "Unknown" }
                return @{ Installed = $true; Version = $version }
            }
        }
    } catch {
        # 检测失败，假设未安装
    }
    
    return @{ Installed = $false; Version = $null }
}

function Get-ProgramVersion {
    <#
    .SYNOPSIS
        获取已安装程序的版本号
        
    .PARAMETER PackageName
        程序名称
        
    .PARAMETER PackageId
        包ID（用于从 winget 获取版本）
    #>
    param(
        [Parameter(Mandatory)]
        [string]$PackageName,
        
        [string]$PackageId = ""
    )
    
    # 首先尝试从 winget list 获取版本（最可靠）
    if ($PackageId) {
        try {
            $wingetList = winget list --id $PackageId --exact 2>&1
            if ($LASTEXITCODE -eq 0 -and $wingetList) {
                $versionMatch = $wingetList | Select-String -Pattern "(\d+\.\d+\.\d+[^\s]*)" | Select-Object -First 1
                if ($versionMatch) {
                    return $versionMatch.Matches[0].Groups[1].Value
                }
            }
        } catch {
            # 忽略错误，继续尝试其他方法
        }
    }
    
    # 刷新 PATH 环境变量（从注册表重新加载）
    try {
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
    } catch {
        # 忽略错误
    }
    
    # 尝试通过命令获取版本
    try {
        $commands = @(
            "$PackageName --version",
            "$PackageName -v",
            "$PackageName -V",
            "$PackageName version"
        )
        
        foreach ($cmd in $commands) {
            try {
                $result = & cmd /c $cmd 2>&1
                if ($LASTEXITCODE -eq 0 -or $result) {
                    $versionMatch = $result | Select-String -Pattern "(\d+\.\d+\.\d+[^\s]*)" | Select-Object -First 1
                    if ($versionMatch) {
                        return $versionMatch.Matches[0].Groups[1].Value
                    }
                }
            } catch {
                continue
            }
        }
    } catch {
        # 忽略错误
    }
    
    return "Unknown"
}

# ============================================
# 工具安装函数
# ============================================
function Install-ProgramWinget {
    <#
    .SYNOPSIS
        使用 Winget 安装程序
    #>
    param(
        [Parameter(Mandatory)]
        [string]$PackageId,
        
        [Parameter(Mandatory)]
        [string]$PackageName
    )
    
    # 检测是否已安装
    $checkResult = Test-ProgramInstalled -PackageId $PackageId -PackageName $PackageName -Manager "winget"
    
    if ($checkResult.Installed) {
        Write-Info "$PackageName is already installed (version: $($checkResult.Version))"
        $version = Get-ProgramVersion -PackageName $PackageName -PackageId $PackageId
        $Script:InstallationReport += @{
            Name = $PackageName
            Version = $version
            Status = "AlreadyExists"
            InstallMethod = "Detected"
        }
        return $true
    }
    
    Write-Info "Installing $PackageName..."
    
    try {
        # 构建参数（添加 --source winget 以避免 msstore 源问题）
        $arguments = "install --id $PackageId --source winget --silent --accept-source-agreements --accept-package-agreements"
        
        # 捕获 winget 的输出（包括中文输出）
        # 注意：RedirectStandardOutput 和 RedirectStandardError 不能指向同一个文件
        $guid = [System.Guid]::NewGuid().ToString('N').Substring(0,8)
        $stdoutFile = Join-Path $env:TEMP "winget_stdout_$guid.txt"
        $stderrFile = Join-Path $env:TEMP "winget_stderr_$guid.txt"
        
        try {
            $process = Start-Process -FilePath "winget" -ArgumentList $arguments -Wait -NoNewWindow -PassThru -RedirectStandardOutput $stdoutFile -RedirectStandardError $stderrFile
        } catch {
            # 如果重定向失败，回退到不使用重定向的方式
            Write-Warning "Failed to redirect output, using direct execution: $_"
            $process = Start-Process -FilePath "winget" -ArgumentList $arguments -Wait -NoNewWindow -PassThru
            $process = @{ ExitCode = $process.ExitCode }
        }
        
        # 读取并记录 winget 的输出（合并 stdout 和 stderr）
        $allOutput = @()
        if (Test-Path $stdoutFile) {
            $stdoutContent = Get-Content -Path $stdoutFile -Encoding UTF8 -ErrorAction SilentlyContinue
            if ($stdoutContent) {
                $allOutput += $stdoutContent
            }
            Remove-Item -Path $stdoutFile -Force -ErrorAction SilentlyContinue
        }
        if (Test-Path $stderrFile) {
            $stderrContent = Get-Content -Path $stderrFile -Encoding UTF8 -ErrorAction SilentlyContinue
            if ($stderrContent) {
                $allOutput += $stderrContent
            }
            Remove-Item -Path $stderrFile -Force -ErrorAction SilentlyContinue
        }
        
        # 记录所有输出到日志
        foreach ($line in $allOutput) {
            if ($line -and $line.Trim()) {
                Write-Log $line
            }
        }
        
        # 获取退出代码（处理不同的返回类型）
        $exitCode = if ($process -is [System.Diagnostics.Process]) {
            $process.ExitCode
        } elseif ($null -ne $process.ExitCode) {
            $process.ExitCode
        } else {
            $LASTEXITCODE
        }
        
        if ($exitCode -eq 0 -or $exitCode -eq -1978335189) {
            # 0 = 成功, -1978335189 = 已安装或无需更新
            Write-Success "$PackageName installed successfully"
            Write-Log "True"  # 记录返回值
            $Script:InstalledCount++
            
            # 备份 PATH（首次安装时，如果尚未备份）
            if (-not $Script:PathBackedUp) {
                Write-Info "Backing up current PATH to path.bak..."
                if (Backup-EnvironmentPath) {
                    $Script:PathBackedUp = $true
                }
            }
            
            # 刷新 PATH 环境变量（使用 winutil 风格的多重刷新）
            Write-Info "Refreshing PATH environment variable..."
            $refreshResult = Refresh-EnvironmentPath -SkipBackup
            if ($refreshResult) {
                Write-Info "PATH refreshed successfully"
            } else {
                Write-Warning "PATH refresh had issues, but continuing..."
            }
            
            # 等待系统更新 PATH
            Start-Sleep -Milliseconds 1000  # 给系统更多时间更新
            
            # 验证工具是否在 PATH 中（使用改进的检测方法）
            $pathCheck = Test-ProgramInPath -ProgramName $PackageName
            if ($pathCheck.Available) {
                Write-Success "$PackageName is available in PATH (found via $($pathCheck.Method))"
                if ($pathCheck.Path) {
                    Write-Info "  Location: $($pathCheck.Path)"
                }
            } else {
                Write-Warning "$PackageName may not be in PATH yet. You may need to restart your terminal (PowerShell/Git Bash)."
                Write-Info "  Note: Some tools may require a system restart or new terminal session to be available."
            }
            
            # 获取版本号
            $version = Get-ProgramVersion -PackageName $PackageName -PackageId $PackageId
            $Script:InstallationReport += @{
                Name = $PackageName
                Version = $version
                Status = "NewInstalled"
                InstallMethod = "Winget"
            }
            Write-Log "True"  # 记录返回值
            return $true
        } else {
            $errorMsg = "$PackageName installation failed (exit code: $exitCode)"
            Write-Error $errorMsg
            Write-Log $errorMsg  # 记录错误信息到日志
            $Script:FailedCount++
            $Script:FailedPackages += $PackageName
            $Script:InstallationReport += @{
                Name = $PackageName
                Version = "InstallationFailed"
                Status = "Failed"
                InstallMethod = "Winget"
            }
            Write-Log "False"  # 记录返回值
            return $false
        }
    } catch {
        $errorMsg = "$PackageName installation failed: $_"
        Write-Error $errorMsg
        Write-Log $errorMsg  # 记录错误信息到日志
        $Script:FailedCount++
        $Script:FailedPackages += $PackageName
        $Script:InstallationReport += @{
            Name = $PackageName
            Version = "InstallationFailed"
            Status = "Failed"
            InstallMethod = "Winget"
        }
        Write-Log "False"  # 记录返回值
        return $false
    }
}

function Update-ProgramWinget {
    <#
    .SYNOPSIS
        使用 Winget 更新程序
    #>
    param(
        [Parameter(Mandatory)]
        [string]$PackageId,
        
        [Parameter(Mandatory)]
        [string]$PackageName
    )
    
    # 检测是否已安装
    $checkResult = Test-ProgramInstalled -PackageId $PackageId -PackageName $PackageName -Manager "winget"
    
    if (-not $checkResult.Installed) {
        Write-Warning "$PackageName is not installed, cannot update"
        return $false
    }
    
    Write-Info "Updating $PackageName (current version: $($checkResult.Version))..."
    
    try {
        $arguments = "upgrade --id $PackageId --silent --accept-source-agreements --accept-package-agreements"
        $process = Start-Process -FilePath "winget" -ArgumentList $arguments -Wait -NoNewWindow -PassThru
        
        if ($process.ExitCode -eq 0 -or $process.ExitCode -eq -1978335189) {
            # 0 = 成功, -1978335189 = 已是最新版本
            if ($process.ExitCode -eq -1978335189) {
                Write-Info "$PackageName is already up to date"
            } else {
                Write-Success "$PackageName updated successfully"
            }
            
            Start-Sleep -Milliseconds 500  # 等待 PATH 更新
            $version = Get-ProgramVersion -PackageName $PackageName -PackageId $PackageId
            $Script:InstallationReport += @{
                Name = $PackageName
                Version = $version
                Status = if ($process.ExitCode -eq -1978335189) { "AlreadyLatest" } else { "Updated" }
                InstallMethod = "Winget"
            }
            return $true
        } else {
            Write-Error "$PackageName update failed (exit code: $($process.ExitCode))"
            $Script:FailedCount++
            $Script:FailedPackages += $PackageName
            return $false
        }
    } catch {
        Write-Error "$PackageName update failed: $_"
        $Script:FailedCount++
        $Script:FailedPackages += $PackageName
        return $false
    }
}

function Update-ProgramChoco {
    <#
    .SYNOPSIS
        使用 Chocolatey 更新程序
    #>
    param(
        [Parameter(Mandatory)]
        [string]$PackageId,
        
        [Parameter(Mandatory)]
        [string]$PackageName
    )
    
    # 检测是否已安装
    $checkResult = Test-ProgramInstalled -PackageId $PackageId -PackageName $PackageName -Manager "chocolatey"
    
    if (-not $checkResult.Installed) {
        Write-Warning "$PackageName is not installed, cannot update"
        return $false
    }
    
    Write-Info "Updating $PackageName (current version: $($checkResult.Version))..."
    
    try {
        $arguments = "upgrade $PackageId -y"
        $process = Start-Process -FilePath "choco" -ArgumentList $arguments -Wait -NoNewWindow -PassThru
        
        if ($process.ExitCode -eq 0) {
            Write-Success "$PackageName updated successfully"
            
            Start-Sleep -Milliseconds 500  # 等待 PATH 更新
            $version = Get-ProgramVersion -PackageName $PackageName
            $Script:InstallationReport += @{
                Name = $PackageName
                Version = $version
                Status = "Updated"
                InstallMethod = "Chocolatey"
            }
            return $true
        } else {
            Write-Error "$PackageName update failed (exit code: $($process.ExitCode))"
            $Script:FailedCount++
            $Script:FailedPackages += $PackageName
            return $false
        }
    } catch {
        Write-Error "$PackageName update failed: $_"
        $Script:FailedCount++
        $Script:FailedPackages += $PackageName
        return $false
    }
}

function Uninstall-ProgramWinget {
    <#
    .SYNOPSIS
        使用 Winget 卸载程序
    #>
    param(
        [Parameter(Mandatory)]
        [string]$PackageId,
        
        [Parameter(Mandatory)]
        [string]$PackageName
    )
    
    # 检测是否已安装
    $checkResult = Test-ProgramInstalled -PackageId $PackageId -PackageName $PackageName -Manager "winget"
    
    if (-not $checkResult.Installed) {
        Write-Warning "$PackageName is not installed, cannot uninstall"
        return $false
    }
    
    Write-Info "Uninstalling $PackageName..."
    
    try {
        $arguments = "uninstall --id $PackageId --silent --accept-source-agreements"
        $process = Start-Process -FilePath "winget" -ArgumentList $arguments -Wait -NoNewWindow -PassThru
        
        if ($process.ExitCode -eq 0) {
            Write-Success "$PackageName uninstalled successfully"
            $Script:InstallationReport += @{
                Name = $PackageName
                Version = "Uninstalled"
                Status = "Uninstalled"
                InstallMethod = "Winget"
            }
            return $true
        } else {
            Write-Error "$PackageName uninstall failed (exit code: $($process.ExitCode))"
            $Script:FailedCount++
            $Script:FailedPackages += $PackageName
            return $false
        }
    } catch {
        Write-Error "$PackageName uninstall failed: $_"
        $Script:FailedCount++
        $Script:FailedPackages += $PackageName
        return $false
    }
}

function Uninstall-ProgramChoco {
    <#
    .SYNOPSIS
        使用 Chocolatey 卸载程序
    #>
    param(
        [Parameter(Mandatory)]
        [string]$PackageId,
        
        [Parameter(Mandatory)]
        [string]$PackageName
    )
    
    # 检测是否已安装
    $checkResult = Test-ProgramInstalled -PackageId $PackageId -PackageName $PackageName -Manager "chocolatey"
    
    if (-not $checkResult.Installed) {
        Write-Warning "$PackageName is not installed, cannot uninstall"
        return $false
    }
    
    Write-Info "Uninstalling $PackageName..."
    
    try {
        $arguments = "uninstall $PackageId -y"
        $process = Start-Process -FilePath "choco" -ArgumentList $arguments -Wait -NoNewWindow -PassThru
        
        if ($process.ExitCode -eq 0) {
            Write-Success "$PackageName uninstalled successfully"
            $Script:InstallationReport += @{
                Name = $PackageName
                Version = "Uninstalled"
                Status = "Uninstalled"
                InstallMethod = "Chocolatey"
            }
            return $true
        } else {
            Write-Error "$PackageName uninstall failed (exit code: $($process.ExitCode))"
            $Script:FailedCount++
            $Script:FailedPackages += $PackageName
            return $false
        }
    } catch {
        Write-Error "$PackageName uninstall failed: $_"
        $Script:FailedCount++
        $Script:FailedPackages += $PackageName
        return $false
    }
}

function Install-ProgramChoco {
    <#
    .SYNOPSIS
        使用 Chocolatey 安装程序
    #>
    param(
        [Parameter(Mandatory)]
        [string]$PackageId,
        
        [Parameter(Mandatory)]
        [string]$PackageName
    )
    
    # 检测是否已安装
    $checkResult = Test-ProgramInstalled -PackageId $PackageId -PackageName $PackageName -Manager "chocolatey"
    
    if ($checkResult.Installed) {
        Write-Info "$PackageName is already installed (version: $($checkResult.Version))"
        $version = Get-ProgramVersion -PackageName $PackageName
        $Script:InstallationReport += @{
            Name = $PackageName
            Version = $version
            Status = "AlreadyExists"
            InstallMethod = "Detected"
        }
        return $true
    }
    
    Write-Info "Installing $PackageName..."
    
    try {
        $arguments = "install $PackageId -y"
        $process = Start-Process -FilePath "choco" -ArgumentList $arguments -Wait -NoNewWindow -PassThru
        
        if ($process.ExitCode -eq 0) {
            Write-Success "$PackageName installed successfully"
            $Script:InstalledCount++
            
            # 备份 PATH（首次安装时，如果尚未备份）
            if (-not $Script:PathBackedUp) {
                Write-Info "Backing up current PATH to path.bak..."
                if (Backup-EnvironmentPath) {
                    $Script:PathBackedUp = $true
                }
            }
            
            # 刷新 PATH 环境变量（使用 winutil 风格的多重刷新）
            Write-Info "Refreshing PATH environment variable..."
            $refreshResult = Refresh-EnvironmentPath -SkipBackup
            if ($refreshResult) {
                Write-Info "PATH refreshed successfully"
            } else {
                Write-Warning "PATH refresh had issues, but continuing..."
            }
            
            # 等待系统更新 PATH
            Start-Sleep -Milliseconds 1000  # 给系统更多时间更新
            
            # 验证工具是否在 PATH 中（使用改进的检测方法）
            $pathCheck = Test-ProgramInPath -ProgramName $PackageName
            if ($pathCheck.Available) {
                Write-Success "$PackageName is available in PATH (found via $($pathCheck.Method))"
                if ($pathCheck.Path) {
                    Write-Info "  Location: $($pathCheck.Path)"
                }
            } else {
                Write-Warning "$PackageName may not be in PATH yet. You may need to restart your terminal (PowerShell/Git Bash)."
                Write-Info "  Note: Some tools may require a system restart or new terminal session to be available."
            }
            
            # 获取版本号
            $version = Get-ProgramVersion -PackageName $PackageName
            $Script:InstallationReport += @{
                Name = $PackageName
                Version = $version
                Status = "NewInstalled"
                InstallMethod = "Chocolatey"
            }
            return $true
        } else {
            Write-Error "$PackageName installation failed (exit code: $($process.ExitCode))"
            $Script:FailedCount++
            $Script:FailedPackages += $PackageName
            $Script:InstallationReport += @{
                Name = $PackageName
                Version = "InstallationFailed"
                Status = "Failed"
                InstallMethod = "Chocolatey"
            }
            return $false
        }
    } catch {
        Write-Error "$PackageName installation failed: $_"
        $Script:FailedCount++
        $Script:FailedPackages += $PackageName
        $Script:InstallationReport += @{
            Name = $PackageName
            Version = "InstallationFailed"
            Status = "Failed"
            InstallMethod = "Chocolatey"
        }
        return $false
    }
}

function Install-Program {
    <#
    .SYNOPSIS
        安装程序（自动选择包管理器）
    #>
    param(
        [Parameter(Mandatory)]
        [hashtable]$Package
    )
    
    $packageName = $Package.Name
    $wingetId = $Package.WingetId
    $chocoId = $Package.ChocoId
    
    # 特殊处理：gcc 使用 MSYS2 安装方式
    if ($packageName -eq "gcc") {
        return Install-MSYS2AndGCC -PackageName $packageName
    }
    
    # 确定使用的包管理器
    $useWinget = $false
    $useChoco = $false
    
    if ($Script:PackageManager -eq "winget") {
        $useWinget = $true
    } elseif ($Script:PackageManager -eq "chocolatey") {
        $useChoco = $true
    } else {
        # 自动选择：优先使用 winget
        if ($wingetId -and (Test-PackageManager -Manager "winget") -eq "installed") {
            $useWinget = $true
        } elseif ($chocoId -and (Test-PackageManager -Manager "chocolatey") -eq "installed") {
            $useChoco = $true
        } else {
            Write-Warning "${packageName}: No available package manager or package ID"
            return $false
        }
    }
    
    # 执行安装
    if ($useWinget -and $wingetId) {
        return Install-ProgramWinget -PackageId $wingetId -PackageName $packageName
    } elseif ($useChoco -and $chocoId) {
        return Install-ProgramChoco -PackageId $chocoId -PackageName $packageName
    } else {
        Write-Warning "${packageName}: Missing package ID"
        return $false
    }
}

function Update-Program {
    <#
    .SYNOPSIS
        更新程序（自动选择包管理器）
    #>
    param(
        [Parameter(Mandatory)]
        [hashtable]$Package
    )
    
    $packageName = $Package.Name
    $wingetId = $Package.WingetId
    $chocoId = $Package.ChocoId
    
    # 特殊处理：gcc 使用 MSYS2 更新方式
    if ($packageName -eq "gcc") {
        return Update-MSYS2AndGCC -PackageName $packageName
    }
    
    # 确定使用的包管理器
    $useWinget = $false
    $useChoco = $false
    
    if ($Script:PackageManager -eq "winget") {
        $useWinget = $true
    } elseif ($Script:PackageManager -eq "chocolatey") {
        $useChoco = $true
    } else {
        # 自动选择：优先使用 winget
        if ($wingetId -and (Test-PackageManager -Manager "winget") -eq "installed") {
            $useWinget = $true
        } elseif ($chocoId -and (Test-PackageManager -Manager "chocolatey") -eq "installed") {
            $useChoco = $true
        } else {
            Write-Warning "${packageName}: No available package manager or package ID"
            return $false
        }
    }
    
    # 执行更新
    if ($useWinget -and $wingetId) {
        return Update-ProgramWinget -PackageId $wingetId -PackageName $packageName
    } elseif ($useChoco -and $chocoId) {
        return Update-ProgramChoco -PackageId $chocoId -PackageName $packageName
    } else {
        Write-Warning "${packageName}: Missing package ID"
        return $false
    }
}

function Uninstall-Program {
    <#
    .SYNOPSIS
        卸载程序（自动选择包管理器）
    #>
    param(
        [Parameter(Mandatory)]
        [hashtable]$Package
    )
    
    $packageName = $Package.Name
    $wingetId = $Package.WingetId
    $chocoId = $Package.ChocoId
    
    # 特殊处理：gcc 使用 MSYS2 卸载方式
    if ($packageName -eq "gcc") {
        return Uninstall-MSYS2AndGCC -PackageName $packageName
    }
    
    # 确定使用的包管理器
    $useWinget = $false
    $useChoco = $false
    
    if ($Script:PackageManager -eq "winget") {
        $useWinget = $true
    } elseif ($Script:PackageManager -eq "chocolatey") {
        $useChoco = $true
    } else {
        # 自动选择：优先使用 winget
        if ($wingetId -and (Test-PackageManager -Manager "winget") -eq "installed") {
            $useWinget = $true
        } elseif ($chocoId -and (Test-PackageManager -Manager "chocolatey") -eq "installed") {
            $useChoco = $true
        } else {
            Write-Warning "${packageName}: No available package manager or package ID"
            return $false
        }
    }
    
    # 执行卸载
    if ($useWinget -and $wingetId) {
        return Uninstall-ProgramWinget -PackageId $wingetId -PackageName $packageName
    } elseif ($useChoco -and $chocoId) {
        return Uninstall-ProgramChoco -PackageId $chocoId -PackageName $packageName
    } else {
        Write-Warning "${packageName}: Missing package ID"
        return $false
    }
}

# ============================================
# PATH 管理函数
# ============================================
# 添加 Win32 API 声明（用于广播环境变量更改）
# 必须在函数之前声明，以便在函数中使用
try {
    Add-Type @"
using System;
using System.Runtime.InteropServices;
public class Win32 {
    [DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Auto)]
    public static extern IntPtr SendMessageTimeout(
        IntPtr hWnd,
        uint Msg,
        IntPtr wParam,
        string lParam,
        uint fuFlags,
        uint uTimeout,
        ref IntPtr lpdwResult
    );
}
"@ -ErrorAction SilentlyContinue
} catch {
    # 如果类型已存在，忽略错误
}

function Backup-EnvironmentPath {
    <#
    .SYNOPSIS
        备份当前 PATH 环境变量到文件
        参考 winutil 的实现，在修改 PATH 前先备份
        备份文件保存在脚本所在目录（与 install_common_tools.bat 相同路径）
    #>
    try {
        # 获取脚本所在目录（与 install_common_tools.bat 相同路径）
        # 优先使用 PSScriptRoot（脚本文件所在目录）
        if ($PSScriptRoot) {
            $scriptDir = $PSScriptRoot
        } elseif ($MyInvocation.PSCommandPath) {
            # 备用方案：从调用路径获取
            $scriptDir = Split-Path -Parent $MyInvocation.PSCommandPath
        } else {
            # 最后的备用方案：使用当前工作目录
            $scriptDir = (Get-Location).Path
        }
        
        # 确保路径存在
        if (-not (Test-Path $scriptDir)) {
            Write-Warning "Script directory not found, using current directory"
            $scriptDir = (Get-Location).Path
        }
        
        $backupFile = Join-Path $scriptDir "path.bak"
        
        # 获取当前 PATH
        $machinePath = [System.Environment]::GetEnvironmentVariable("Path", "Machine")
        $userPath = [System.Environment]::GetEnvironmentVariable("Path", "User")
        $currentPath = $env:Path
        
        # 构建备份内容
        $backupContent = @"
# PATH Environment Variable Backup
# Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
# Script: install_common_tools.ps1

# Machine PATH (System-wide)
[Machine]
$machinePath

# User PATH (User-specific)
[User]
$userPath

# Current Process PATH (Combined)
[Current]
$currentPath

# Backup completed successfully
"@
        
        # 写入备份文件
        $backupContent | Out-File -FilePath $backupFile -Encoding UTF8 -Force
        
        Write-Info "PATH backed up to: $backupFile"
        return $true
    } catch {
        Write-Warning "Failed to backup PATH: $_"
        return $false
    }
}

function Refresh-EnvironmentPath {
    <#
    .SYNOPSIS
        刷新环境变量 PATH，确保新安装的工具可用
        参考 winutil 的实现方式，使用多种方法确保 PATH 更新生效
    #>
    param(
        [switch]$SkipBackup  # 是否跳过备份（用于避免重复备份）
    )
    
    # 备份 PATH（如果尚未备份）
    if (-not $SkipBackup) {
        Backup-EnvironmentPath | Out-Null
    }
    
    try {
        # 方法 1: 从注册表重新加载 PATH（最可靠）
        $machinePath = [System.Environment]::GetEnvironmentVariable("Path", "Machine")
        $userPath = [System.Environment]::GetEnvironmentVariable("Path", "User")
        
        # 清理 PATH（移除重复项和空项）
        $allPaths = @()
        if ($machinePath) {
            $allPaths += $machinePath -split ';' | Where-Object { $_ -and $_.Trim() }
        }
        if ($userPath) {
            $allPaths += $userPath -split ';' | Where-Object { $_ -and $_.Trim() }
        }
        
        # 去重并保持顺序
        $uniquePaths = @()
        $seenPaths = @{}
        foreach ($path in $allPaths) {
            $normalizedPath = $path.TrimEnd('\').ToLower()
            if (-not $seenPaths.ContainsKey($normalizedPath)) {
                $seenPaths[$normalizedPath] = $true
                $uniquePaths += $path
            }
        }
        
        # 更新当前进程的 PATH
        $env:Path = $uniquePaths -join ';'
        
        # 方法 2: 通知系统环境变量已更改（广播 WM_SETTINGCHANGE）
        # 这会让其他程序（如 Git Bash、新打开的 PowerShell）知道 PATH 已更新
        try {
            $HWND_BROADCAST = [IntPtr]0xffff
            $WM_SETTINGCHANGE = 0x1a
            $SMTO_ABORTIFHUNG = 0x2
            $result = [IntPtr]::Zero
            $null = [Win32]::SendMessageTimeout(
                $HWND_BROADCAST,
                $WM_SETTINGCHANGE,
                [IntPtr]::Zero,
                "Environment",
                $SMTO_ABORTIFHUNG,
                5000,
                [ref]$result
            )
        } catch {
            # Win32 API 调用失败，继续使用基本方法
        }
        
        # 方法 3: 使用 .NET 方法刷新环境变量（备用）
        try {
            [System.Environment]::SetEnvironmentVariable("Path", $env:Path, "Process")
        } catch {
            # 忽略错误
        }
        
        return $true
    } catch {
        # 如果出错，至少刷新当前进程的 PATH
        try {
            $machinePath = [System.Environment]::GetEnvironmentVariable("Path", "Machine")
            $userPath = [System.Environment]::GetEnvironmentVariable("Path", "User")
            if ($machinePath -or $userPath) {
                $env:Path = "$machinePath;$userPath"
            }
        } catch {
            # 最后的备用方案
        }
        return $false
    }
}

function Test-ProgramInPath {
    <#
    .SYNOPSIS
        检查程序是否在 PATH 中可用
        参考 winutil 的实现，使用多种方法检测
        
    .PARAMETER ProgramName
        程序名称
        
    .OUTPUTS
        返回哈希表：@{Available = bool; Path = string; Method = string}
    #>
    param(
        [Parameter(Mandatory)]
        [string]$ProgramName
    )
    
    # 刷新 PATH（跳过备份，避免重复备份）
    Refresh-EnvironmentPath -SkipBackup | Out-Null
    
    # 方法 1: 使用 Get-Command（PowerShell 原生方法）
    try {
        $programPath = Get-Command -Name $ProgramName -ErrorAction SilentlyContinue
        if ($programPath) {
            return @{
                Available = $true
                Path = $programPath.Source
                Method = "Get-Command"
            }
        }
    } catch {
        # 继续尝试其他方法
    }
    
    # 方法 2: 使用 where.exe（Windows 标准方法，Git Bash 也支持）
    try {
        $result = & cmd /c "where $ProgramName" 2>&1
        if ($LASTEXITCODE -eq 0 -and $result -and $result -notmatch "INFO:") {
            $path = ($result | Select-Object -First 1).ToString().Trim()
            if ($path -and (Test-Path $path)) {
                return @{
                    Available = $true
                    Path = $path
                    Method = "where.exe"
                }
            }
        }
    } catch {
        # 继续尝试其他方法
    }
    
    # 方法 3: 检查常见安装位置
    $commonPaths = @(
        "$env:ProgramFiles\$ProgramName",
        "$env:ProgramFiles(x86)\$ProgramName",
        "$env:LOCALAPPDATA\$ProgramName",
        "$env:APPDATA\$ProgramName",
        "$env:USERPROFILE\.local\bin\$ProgramName.exe",
        "$env:USERPROFILE\AppData\Local\Microsoft\WindowsApps\$ProgramName.exe"
    )
    
    foreach ($commonPath in $commonPaths) {
        if (Test-Path $commonPath) {
            return @{
                Available = $true
                Path = $commonPath
                Method = "CommonPath"
            }
        }
    }
    
    # 方法 4: 检查 PATH 中的每个目录
    try {
        $pathDirs = $env:Path -split ';' | Where-Object { $_ -and $_.Trim() }
        foreach ($dir in $pathDirs) {
            $testPath = Join-Path $dir "$ProgramName.exe"
            if (Test-Path $testPath) {
                return @{
                    Available = $true
                    Path = $testPath
                    Method = "PATHScan"
                }
            }
        }
    } catch {
        # 忽略错误
    }
    
    return @{
        Available = $false
        Path = $null
        Method = "NotFound"
    }
}

# ============================================
# MSYS2 和 GCC 安装函数
# ============================================
function Invoke-Msys2Pacman {
    <#
    .SYNOPSIS
        执行 MSYS2 pacman 命令的辅助函数
    #>
    param(
        [Parameter(Mandatory)]
        [string]$BashPath,
        
        [Parameter(Mandatory)]
        [string]$Command
    )
    
    return Invoke-Msys2CommandStreaming -BashPath $BashPath -Command $Command -DisplayName "pacman command" -DisableProxy
}

function Set-MSYS2MirrorConfiguration {
    <#
    .SYNOPSIS
        配置 MSYS2 使用自定义镜像源
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Msys2Root,
        [Parameter(Mandatory)]
        [string]$MirrorUrl
    )

    if (-not (Test-Path $Msys2Root)) {
        Write-Warning "MSYS2 root path not found when configuring mirror: $Msys2Root"
        return
    }

    $cleanMirror = if ($MirrorUrl.EndsWith("/")) { $MirrorUrl.TrimEnd("/") } else { $MirrorUrl }
    $mirrorFiles = @(
        @{ Path = "etc\pacman.d\mirrorlist.mingw64"; Suffix = "/mingw/x86_64" },
        @{ Path = "etc\pacman.d\mirrorlist.mingw32"; Suffix = "/mingw/i686" },
        @{ Path = "etc\pacman.d\mirrorlist.msys";     Suffix = "/msys/$arch" }
    )

    foreach ($entry in $mirrorFiles) {
        $target = Join-Path $Msys2Root $entry.Path
        if (-not (Test-Path $target)) {
            continue
        }

        try {
            $backupPath = "$target.backup"
            if (-not (Test-Path $backupPath)) {
                Copy-Item -Path $target -Destination $backupPath -Force -ErrorAction SilentlyContinue
            }

            $suffix = $entry.Suffix.Replace("$arch", "x86_64")
            $content = @()
            $content += "## Generated by install_common_tools.ps1"
            $content += "## Original file backed up to $backupPath"
            $content += "Server = $cleanMirror$suffix"
            Set-Content -Path $target -Value $content -Encoding UTF8
            Write-Info "Configured MSYS2 mirror for $($entry.Path) -> $cleanMirror$suffix"
        } catch {
            Write-Warning "Failed to configure MSYS2 mirror for $($entry.Path): $_"
        }
    }
}

function Apply-MSYS2Mirror {
    <#
    .SYNOPSIS
        在需要时应用自定义 MSYS2 镜像（只执行一次）
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Msys2Root
    )

    if (-not $Script:Msys2Mirror) {
        return $false
    }

    if ($Script:Msys2MirrorApplied) {
        return $false
    }

    Write-Info "Applying MSYS2 mirror: $Script:Msys2Mirror"
    Set-MSYS2MirrorConfiguration -Msys2Root $Msys2Root -MirrorUrl $Script:Msys2Mirror
    $Script:Msys2MirrorApplied = $true
    return $true
}

function Invoke-Msys2CommandStreaming {
    <#
    .SYNOPSIS
        执行 MSYS2 命令并实时输出到控制台与日志
    #>
    param(
        [Parameter(Mandatory)]
        [string]$BashPath,

        [Parameter(Mandatory)]
        [string]$Command,

        [string]$DisplayName = "MSYS2 command",

        [switch]$DisableProxy
    )

    Write-Log "Executing ($DisplayName): $Command"

    $finalCommand = $Command
    if ($DisableProxy) {
        $proxyUnset = @("env", "-u", "http_proxy", "-u", "https_proxy", "-u", "HTTP_PROXY", "-u", "HTTPS_PROXY")
        $finalCommand = ($proxyUnset + $Command) -join " "
    }

    $escapedCommand = $finalCommand.Replace('"', '\"')
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $BashPath
    $psi.Arguments = "-lc ""$escapedCommand"""
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true
    $psi.StandardOutputEncoding = [System.Text.Encoding]::UTF8
    $psi.StandardErrorEncoding = [System.Text.Encoding]::UTF8

    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = $psi

    $logPath = $Script:LogFile
    $syncRoot = $Script:LogSyncRoot

    try {
        $null = $process.Start()
        $stdout = $process.StandardOutput
        $stderr = $process.StandardError

        while (-not $process.HasExited -or -not $stdout.EndOfStream -or -not $stderr.EndOfStream) {
            while (-not $stdout.EndOfStream) {
                $line = $stdout.ReadLine()
                if ($null -ne $line) {
                    [Console]::WriteLine($line)
                    [System.Threading.Monitor]::Enter($syncRoot)
                    try {
                        [System.IO.File]::AppendAllText($logPath, $line + [Environment]::NewLine, [System.Text.Encoding]::UTF8)
                    } finally {
                        [System.Threading.Monitor]::Exit($syncRoot)
                    }
                }
            }
            while (-not $stderr.EndOfStream) {
                $line = $stderr.ReadLine()
                if ($null -ne $line) {
                    [Console]::WriteLine($line)
                    [System.Threading.Monitor]::Enter($syncRoot)
                    try {
                        [System.IO.File]::AppendAllText($logPath, $line + [Environment]::NewLine, [System.Text.Encoding]::UTF8)
                    } finally {
                        [System.Threading.Monitor]::Exit($syncRoot)
                    }
                }
            }
            Start-Sleep -Milliseconds 50
        }

        $process.WaitForExit()
        Write-Log "($DisplayName) exited with code: $($process.ExitCode)"
        return $process.ExitCode
    } catch {
        Write-Error ("Failed to execute {0}: {1}" -f $DisplayName, $_)
        Write-Log ("Failed to execute {0}: {1}" -f $DisplayName, $_)
        return 1
    } finally {
        if ($process) {
            $process.Dispose()
        }
    }
}

function Invoke-Msys2FirstTimeSetup {
    <#
    .SYNOPSIS
        MSYS2 首次初始化（解决残缺 pacman 问题）
        这是 MSYS2 安装后必须执行的一次性初始化流程
    #>
    param(
        [string]$Msys2Root = "C:\msys64"
    )
    
    $bash = Join-Path $Msys2Root "usr\bin\bash.exe"
    if (-not (Test-Path $bash)) {
        Write-Error "MSYS2 bash not found at $bash"
        Write-Log "MSYS2 bash not found at $bash"
        return $false
    }
    
    Write-Info "Running official MSYS2 first-time initialization (this may take 3-8 minutes)..."
    Write-Log "Running official MSYS2 first-time initialization (this may take 3-8 minutes)..."
    
    # Step 1: pacman -Syuu --noconfirm
    $step1Cmd = "yes | pacman -Syuu"
    $step1Exit = Invoke-Msys2CommandStreaming -BashPath $bash -Command $step1Cmd -DisplayName "pacman -Syuu" -DisableProxy
    if ($step1Exit -ne 0 -and (Apply-MSYS2Mirror -Msys2Root $Msys2Root)) {
        Write-Warning "Step 1 failed with proxy, retrying using custom mirror..."
        $step1Exit = Invoke-Msys2CommandStreaming -BashPath $bash -Command $step1Cmd -DisplayName "pacman -Syuu (mirror)" -DisableProxy
    }
    if ($step1Exit -ne 0) {
        Write-Warning "Step 1 still failed (pacman -Syuu). Continuing, but MSYS2 may already be up to date."
    }
    
    # Step 2: pacman -Su --noconfirm
    Write-Info "Waiting for pacman update to take effect (restarting bash process)..."
    Start-Sleep -Seconds 5
    
    $step2Cmd = "yes | pacman -Su"
    $step2Exit = Invoke-Msys2CommandStreaming -BashPath $bash -Command $step2Cmd -DisplayName "pacman -Su" -DisableProxy
    if ($step2Exit -ne 0 -and (Apply-MSYS2Mirror -Msys2Root $Msys2Root)) {
        Write-Warning "Step 2 failed with proxy, retrying using custom mirror..."
        $step2Exit = Invoke-Msys2CommandStreaming -BashPath $bash -Command $step2Cmd -DisplayName "pacman -Su (mirror)" -DisableProxy
    }
    if ($step2Exit -ne 0) {
        Write-Warning "Step 2 still failed (pacman -Su). Continuing, but packages may already be up to date."
    }
    
    Write-Success "MSYS2 first-time setup completed (proxy first, mirror fallback if needed)"
    Write-Log "MSYS2 first-time setup completed (proxy first, mirror fallback if needed)"
    return $true
}

function Test-MSYS2Installed {
    <#
    .SYNOPSIS
        检查 MSYS2 是否已安装
        返回：@{ Installed = bool; Path = string; GccInstalled = bool; GccPath = string }
    #>
    $msys2Paths = @(
        "C:\msys64",
        "C:\msys32",
        "${env:ProgramFiles}\msys64",
        "${env:ProgramFiles(x86)}\msys64"
    )
    
    foreach ($path in $msys2Paths) {
        if (Test-Path $path) {
            # 检查 MSYS2 目录是否存在关键文件（确认是有效的 MSYS2 安装）
            $msys2Bash = Join-Path $path "usr\bin\bash.exe"
            if (Test-Path $msys2Bash) {
                # MSYS2 已安装，检查 GCC 是否已安装
                $gccPath = Join-Path $path "mingw64\bin\gcc.exe"
                $gccInstalled = Test-Path $gccPath
                
                return @{ 
                    Installed = $true
                    Path = $path
                    GccInstalled = $gccInstalled
                    GccPath = if ($gccInstalled) { $gccPath } else { $null }
                }
            }
        }
    }
    
    return @{ Installed = $false; Path = $null; GccInstalled = $false; GccPath = $null }
}

function Install-MSYS2AndGCC {
    <#
    .SYNOPSIS
        安装 MSYS2 和 GCC（使用 MSYS2 方式）
        参考：https://www.msys2.org/
    #>
    param(
        [Parameter(Mandatory)]
        [string]$PackageName
    )
    
    # 检查是否已安装
    $msys2Check = Test-MSYS2Installed
    
    # 如果 MSYS2 已安装且 GCC 已安装，直接返回
    if ($msys2Check.Installed -and $msys2Check.GccInstalled) {
        Write-Info "$PackageName (MSYS2 GCC) is already installed"
        Write-Info "  MSYS2 Path: $($msys2Check.Path)"
        Write-Info "  GCC Path: $($msys2Check.GccPath)"
        
        # 检查 GCC 版本
        try {
            $gccVersion = & $msys2Check.GccPath --version 2>&1 | Select-Object -First 1
            if ($gccVersion) {
                Write-Info "  GCC Version: $gccVersion"
            }
        } catch {
            # 忽略错误
        }
        
        # 确保 PATH 中包含 MSYS2 的 mingw64\bin
        $mingw64Bin = Join-Path $msys2Check.Path "mingw64\bin"
        $userPath = [System.Environment]::GetEnvironmentVariable("Path", "User")
        if ($userPath -notlike "*$mingw64Bin*") {
            Write-Info "Adding MSYS2 GCC to PATH..."
            [System.Environment]::SetEnvironmentVariable("Path", "$userPath;$mingw64Bin", "User")
            $env:Path += ";$mingw64Bin"
            Write-Success "MSYS2 GCC added to PATH"
        }
        
        $version = Get-ProgramVersion -PackageName "gcc"
        $Script:InstallationReport += @{
            Name = $PackageName
            Version = $version
            Status = "AlreadyExists"
            InstallMethod = "MSYS2"
        }
        Write-Log "True"
        return $true
    }
    
    # 确定 MSYS2 根目录
    $msys2Root = if ($msys2Check.Installed) { $msys2Check.Path } else { "C:\msys64" }
    $bashPath = Join-Path $msys2Root "usr\bin\bash.exe"
    
    # 如果 MSYS2 未安装，需要完整安装
    if (-not $msys2Check.Installed) {
        Write-Info "Installing MSYS2 and GCC..."
        Write-Info "This will install MSYS2 (a software distribution and building platform for Windows) and GCC compiler."
        
        $msys2InstallerUrl = "https://github.com/msys2/msys2-installer/releases/latest/download/msys2-x86_64-latest.exe"
        $installerPath = "$env:TEMP\msys2-installer.exe"
        
        try {
            # 下载 MSYS2 安装程序（带进度条）
            if (-not (Invoke-WebRequestWithProgress -Uri $msys2InstallerUrl -OutFile $installerPath)) {
                Write-Error "Failed to download MSYS2 installer"
                Write-Log "Failed to download MSYS2 installer"
                return $false
            }
            
            # 安装 MSYS2（静默安装）
            Write-Info "Installing MSYS2 (this may take a few minutes)..."
            $installArgs = "install --root `"$msys2Root`" --confirm-command"
            $installProcess = Start-Process -FilePath $installerPath -ArgumentList $installArgs -Wait -NoNewWindow -PassThru
            
            if ($installProcess.ExitCode -ne 0 -and $installProcess.ExitCode -ne 3010) {
                Write-Error "MSYS2 installation failed (exit code: $($installProcess.ExitCode))"
                Write-Log "MSYS2 installation failed (exit code: $($installProcess.ExitCode))"
                Remove-Item -Path $installerPath -Force -ErrorAction SilentlyContinue
                return $false
            }
            
            # 等待 MSYS2 安装完成
            Start-Sleep -Seconds 5
            
            # 检查 MSYS2 是否安装成功
            if (-not (Test-Path $msys2Root)) {
                Write-Error "MSYS2 installation directory not found: $msys2Root"
                Write-Log "MSYS2 installation directory not found: $msys2Root"
                Remove-Item -Path $installerPath -Force -ErrorAction SilentlyContinue
                return $false
            }
            
            # 清理安装程序
            Remove-Item -Path $installerPath -Force -ErrorAction SilentlyContinue
        } catch {
            $errorMsg = "MSYS2 installation failed: $_"
            Write-Error $errorMsg
            Write-Log $errorMsg
            Remove-Item -Path $installerPath -Force -ErrorAction SilentlyContinue
            return $false
        }
    }
    
    # 检查 bash 是否存在
    if (-not (Test-Path $bashPath)) {
        Write-Error "MSYS2 bash not found: $bashPath"
        Write-Log "MSYS2 bash not found: $bashPath"
        return $false
    }
    
    # 关键修复：无论是否已安装 GCC，都先强制执行一次「首次初始化流程」
    if (-not (Invoke-Msys2FirstTimeSetup -Msys2Root $msys2Root)) {
        Write-Error "MSYS2 initialization failed"
        Write-Log "MSYS2 initialization failed"
        return $false
    }
    
    # 第3步：安装 GCC 工具链（现在 pacman 应该正常工作了）
    if ($Script:GccPreset -eq "minimal") {
        $minimalPackages = @(
            "mingw-w64-x86_64-gcc",
            "mingw-w64-x86_64-gcc-libs",
            "mingw-w64-x86_64-binutils",
            "mingw-w64-x86_64-make",
            "mingw-w64-x86_64-gdb"
        )
        Write-Info "Step 3/3: Installing GCC toolchain (preset: minimal)..."
        Write-Info "  Packages: $($minimalPackages -join ', ')"
        $gccCommand = "pacman -S --needed --noconfirm " + ($minimalPackages -join " ")
    } else {
        Write-Info "Step 3/3: Installing GCC toolchain (preset: toolchain)..."
        $gccCommand = "pacman -S --needed --noconfirm mingw-w64-x86_64-toolchain"
    }
    $gccExit = Invoke-Msys2CommandStreaming -BashPath $bashPath -Command $gccCommand -DisplayName "pacman -S (gcc)" -DisableProxy
    if ($gccExit -ne 0 -and (Apply-MSYS2Mirror -Msys2Root $msys2Root)) {
        Write-Warning "GCC installation failed with proxy, retrying using custom mirror..."
        $gccExit = Invoke-Msys2CommandStreaming -BashPath $bashPath -Command $gccCommand -DisplayName "pacman -S (gcc mirror)" -DisableProxy
    }
    if ($gccExit -ne 0) {
        Write-Error "GCC toolchain installation failed (exit code: $gccExit)"
        Write-Log "GCC toolchain installation failed (exit code: $gccExit)"
        return $false
    }
    
    # 验证 GCC 是否真的装好了
    $gccPath = Join-Path $msys2Root "mingw64\bin\gcc.exe"
    if (-not (Test-Path $gccPath)) {
        Write-Error "GCC installation completed but gcc.exe not found at $gccPath"
        Write-Log "GCC installation completed but gcc.exe not found at $gccPath"
        return $false
    }
    
    # 添加到 PATH（保持你原来的逻辑）
    $mingwBin = Join-Path $msys2Root "mingw64\bin"
    $userPath = [System.Environment]::GetEnvironmentVariable("Path", "User")
    if ($userPath -notlike "*$mingwBin*") {
        Write-Info "Adding MSYS2 GCC to PATH..."
        [System.Environment]::SetEnvironmentVariable("Path", "$userPath;$mingwBin", "User")
        $env:Path += ";$mingwBin"
        Write-Success "MSYS2 GCC added to PATH"
    }
    
    Write-Success "$PackageName (MSYS2 GCC) installed successfully"
    Write-Info "  MSYS2 Path: $msys2Root"
    Write-Info "  GCC Path: $mingwBin"
    Write-Log "True"
    
    $Script:InstalledCount++
    
    # 备份 PATH（首次安装时，如果尚未备份）
    if (-not $Script:PathBackedUp) {
        Write-Info "Backing up current PATH to path.bak..."
        if (Backup-EnvironmentPath) {
            $Script:PathBackedUp = $true
        }
    }
    
    # 刷新 PATH 环境变量
    Write-Info "Refreshing PATH environment variable..."
    $refreshResult = Refresh-EnvironmentPath -SkipBackup
    if ($refreshResult) {
        Write-Info "PATH refreshed successfully"
    } else {
        Write-Warning "PATH refresh had issues, but continuing..."
    }
    
    # 等待系统更新 PATH
    Start-Sleep -Milliseconds 1000
    
    # 验证工具是否在 PATH 中
    $pathCheck = Test-ProgramInPath -ProgramName "gcc"
    if ($pathCheck.Available) {
        Write-Success "$PackageName is available in PATH (found via $($pathCheck.Method))"
        if ($pathCheck.Path) {
            Write-Info "  Location: $($pathCheck.Path)"
        }
    } else {
        Write-Warning "$PackageName may not be in PATH yet. You may need to restart your terminal (PowerShell/Git Bash)."
        Write-Info "  Note: Some tools may require a system restart or new terminal session to be available."
    }
    
    # 获取版本号
    $version = Get-ProgramVersion -PackageName "gcc"
    $Script:InstallationReport += @{
        Name = $PackageName
        Version = $version
        Status = "NewInstalled"
        InstallMethod = "MSYS2"
    }
    Write-Log "True"
    return $true
}

function Update-MSYS2AndGCC {
    <#
    .SYNOPSIS
        更新 MSYS2 和 GCC（使用 MSYS2 方式）
    #>
    param(
        [Parameter(Mandatory)]
        [string]$PackageName
    )
    
    # 检查是否已安装
    $msys2Check = Test-MSYS2Installed
    if (-not $msys2Check.Installed) {
        Write-Warning "$PackageName (MSYS2 GCC) is not installed, cannot update"
        return $false
    }
    
    Write-Info "Updating MSYS2 and GCC..."
    Write-Info "This will update MSYS2 system and GCC toolchain."
    
    $msys2Root = $msys2Check.Path
    $bashPath = Join-Path $msys2Root "usr\bin\bash.exe"
    
    if (-not (Test-Path $bashPath)) {
        Write-Error "MSYS2 bash not found: $bashPath"
        return $false
    }

    try {
        # 先初始化 MSYS2（确保 pacman 支持 --noconfirm）
        Initialize-MSYS2 -BashPath $bashPath
        
        # 更新 MSYS2 系统和 GCC 工具链（使用 --noconfirm 参数实现非交互式更新）
        Write-Info "Updating MSYS2 system and GCC toolchain (this may take several minutes)..."
        $exitCode = Invoke-Msys2Pacman -BashPath $bashPath -Command "pacman --noconfirm -S --needed base-devel mingw-w64-x86_64-toolchain"
        Write-Log "MSYS2 & GCC update process exited with code: $exitCode"
        
        if ($exitCode -eq 0) {
            Write-Success "$PackageName (MSYS2 GCC) updated successfully"
            
            # 刷新 PATH 环境变量
            Write-Info "Refreshing PATH environment variable..."
            $refreshResult = Refresh-EnvironmentPath -SkipBackup
            if ($refreshResult) {
                Write-Info "PATH refreshed successfully"
            }
            
            Start-Sleep -Milliseconds 500
            $version = Get-ProgramVersion -PackageName "gcc"
            $Script:InstallationReport += @{
                Name = $PackageName
                Version = $version
                Status = "Updated"
                InstallMethod = "MSYS2"
            }
            Write-Log "True"
            return $true
        } else {
            $errMsg = "$PackageName update failed (pacman exit code: $exitCode)"
            Write-Error $errMsg
            Write-Log $errMsg
            $Script:FailedCount++
            $Script:FailedPackages += $PackageName
            Write-Log "False"
            return $false
        }
    } catch {
        Write-Error "Unexpected error during MSYS2/GCC update: $_"
        Write-Log "Exception: $_"
        $Script:FailedCount++
        $Script:FailedPackages += $PackageName
        return $false
    }
}

function Uninstall-MSYS2AndGCC {
    <#
    .SYNOPSIS
        卸载 MSYS2 和 GCC（使用 MSYS2 方式）
        注意：这会卸载整个 MSYS2 系统
    #>
    param(
        [Parameter(Mandatory)]
        [string]$PackageName
    )
    
    # 检查是否已安装
    $msys2Check = Test-MSYS2Installed
    if (-not $msys2Check.Installed) {
        Write-Warning "$PackageName (MSYS2 GCC) is not installed, cannot uninstall"
        return $false
    }
    
    Write-Warning "Uninstalling MSYS2 will remove the entire MSYS2 installation, including GCC and all other MSYS2 packages."
    $confirm = Read-Host "Are you sure you want to uninstall MSYS2? (Y/N)"
    
    if ($confirm -ne "Y" -and $confirm -ne "y") {
        Write-Info "Uninstallation cancelled"
        return $false
    }
    
    $msys2Root = $msys2Check.Path
    
    try {
        # 从 PATH 中移除 MSYS2 GCC
        $mingw64Bin = Join-Path $msys2Root "mingw64\bin"
        $userPath = [System.Environment]::GetEnvironmentVariable("Path", "User")
        if ($userPath -like "*$mingw64Bin*") {
            Write-Info "Removing MSYS2 GCC from PATH..."
            $newPath = ($userPath -split ';' | Where-Object { $_ -ne $mingw64Bin }) -join ';'
            [System.Environment]::SetEnvironmentVariable("Path", $newPath, "User")
            $env:Path = ($env:Path -split ';' | Where-Object { $_ -ne $mingw64Bin }) -join ';'
            Write-Success "MSYS2 GCC removed from PATH"
        }
        
        # 删除 MSYS2 目录
        Write-Info "Removing MSYS2 installation directory..."
        Remove-Item -Path $msys2Root -Recurse -Force -ErrorAction SilentlyContinue
        
        if (-not (Test-Path $msys2Root)) {
            Write-Success "$PackageName (MSYS2 GCC) uninstalled successfully"
            $Script:InstallationReport += @{
                Name = $PackageName
                Version = "Uninstalled"
                Status = "Uninstalled"
                InstallMethod = "MSYS2"
            }
            Write-Log "True"
            return $true
        } else {
            Write-Warning "MSYS2 directory still exists. You may need to manually remove: $msys2Root"
            Write-Log "MSYS2 directory still exists: $msys2Root"
            return $false
        }
    } catch {
        $errorMsg = "$PackageName (MSYS2 GCC) uninstall failed: $_"
        Write-Error $errorMsg
        Write-Log $errorMsg
        $Script:FailedCount++
        $Script:FailedPackages += $PackageName
        Write-Log "False"
        return $false
    }
}

# ============================================
# 字体安装函数
# ============================================
function Test-NerdFontsInstalled {
    <#
    .SYNOPSIS
        检查 Nerd Fonts FiraMono 是否已安装
        检查更具体的字体文件名模式
    #>
    $fontsDir = "$env:WINDIR\Fonts"
    
    # 检查更具体的字体文件名（Nerd Fonts 的命名模式）
    $fontPatterns = @(
        "*FiraMono*Nerd*",
        "*Fira*Mono*Nerd*",
        "FiraMono*.ttf",
        "Fira Mono*.ttf"
    )
    
    foreach ($pattern in $fontPatterns) {
        $fonts = Get-ChildItem -Path $fontsDir -Filter $pattern -ErrorAction SilentlyContinue
        if ($fonts -and $fonts.Count -gt 0) {
            return $true
        }
    }
    
    # 额外检查：通过字体名称查找（更可靠）
    try {
        $installedFonts = Get-ChildItem -Path $fontsDir -Filter "*.ttf" -ErrorAction SilentlyContinue | 
            Where-Object { $_.Name -like "*FiraMono*" -or $_.Name -like "*Fira*Mono*" }
        if ($installedFonts -and $installedFonts.Count -gt 0) {
            return $true
        }
    } catch {
        # 忽略错误，继续使用文件名检查
    }
    
    return $false
}

function Install-NerdFonts {
    <#
    .SYNOPSIS
        安装 Nerd Fonts FiraMono（如果未安装）
    #>
    
    # 检查是否已安装
    if (Test-NerdFontsInstalled) {
        Write-Info "Nerd Fonts FiraMono is already installed, skipping..."
        Write-Log "True"  # 记录返回值
        return $true
    }
    
    Write-Info "Installing Nerd Fonts FiraMono..."
    
    $fontUrl = "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/FiraMono.zip"
    $tempDir = "$env:TEMP\NerdFonts"
    $zipFile = "$tempDir\FiraMono.zip"
    $fontsDir = "$env:WINDIR\Fonts"
    
    try {
        # 创建临时目录
        if (-not (Test-Path $tempDir)) {
            New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
        }
        
        # 下载字体文件（带进度条）
        if (-not (Invoke-WebRequestWithProgress -Uri $fontUrl -OutFile $zipFile)) {
            Write-Error "Failed to download font files"
            Write-Log "Failed to download font files"
            return $false
        }
        
        # 解压字体文件
        Write-Info "Extracting font files..."
        Expand-Archive -Path $zipFile -DestinationPath $tempDir -Force
        
        # 安装字体
        Write-Info "Installing fonts to system..."
        $fontFiles = Get-ChildItem -Path $tempDir -Filter "*.ttf" -Recurse
        $installedCount = 0
        
        foreach ($fontFile in $fontFiles) {
            $fontName = $fontFile.Name
            $destPath = Join-Path $fontsDir $fontName
            
            if (-not (Test-Path $destPath)) {
                Copy-Item -Path $fontFile.FullName -Destination $destPath -Force
                Write-Success "Font installed: $fontName"
                $installedCount++
            } else {
                Write-Info "Font already exists: $fontName"
            }
        }
        
        # 清理临时文件
        Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
        
        if ($installedCount -gt 0) {
            Write-Success "Nerd Fonts FiraMono installation completed ($installedCount fonts installed)"
        } else {
            Write-Info "Nerd Fonts FiraMono already installed"
        }
        Write-Log "True"  # 记录返回值
        return $true
        
    } catch {
        Write-Error "Font installation failed: $_"
        Write-Log "False"  # 记录返回值
        return $false
    }
}

# ============================================
# 工具列表定义
# ============================================
$Script:Tools = @{
    "Version Managers" = @(
        @{ Name = "fnm"; WingetId = "Schniz.fnm"; ChocoId = "fnm"; Description = "Fast Node Manager" }
        @{ Name = "uv"; WingetId = "astral-sh.uv"; ChocoId = ""; Description = "Python package manager" }
        @{ Name = "rustup"; WingetId = "Rustlang.Rustup"; ChocoId = "rust"; Description = "Rust toolchain" }
    )
    "Terminal Tools" = @(
        @{ Name = "alacritty"; WingetId = "Alacritty.Alacritty"; ChocoId = "alacritty"; Description = "GPU-accelerated terminal" }
        # tmux 在 Windows 上不支持，使用 Windows Terminal 或 WSL
        # @{ Name = "tmux"; WingetId = "tmux.tmux"; ChocoId = "tmux"; Description = "Terminal multiplexer" }
    )
    "System Monitoring" = @(
        # btop 在 Windows 上不支持，使用 bottom 作为替代（跨平台系统监控工具）
        @{ Name = "bottom"; WingetId = "Clement.bottom"; ChocoId = "bottom"; Description = "Cross-platform system monitor (btop alternative for Windows)" }
        @{ Name = "fastfetch"; WingetId = "fastfetch-cli.fastfetch"; ChocoId = "fastfetch"; Description = "System information display" }
        @{ Name = "eza"; WingetId = "eza-community.eza"; ChocoId = "eza"; Description = "Modern ls replacement" }
    )
    "File Tools" = @(
        @{ Name = "bat"; WingetId = "sharkdp.bat"; ChocoId = "bat"; Description = "Modern cat replacement" }
        # trash-cli 在 Windows 上可能不可用，Windows 有 Recycle Bin
        # @{ Name = "trash-cli"; WingetId = "trash-cli.trash-cli"; ChocoId = "trash-cli"; Description = "Safe rm replacement" }
        @{ Name = "fd"; WingetId = "sharkdp.fd"; ChocoId = "fd"; Description = "Fast find replacement" }
        @{ Name = "ripgrep"; WingetId = "BurntSushi.ripgrep.MSVC"; ChocoId = "ripgrep"; Description = "Fast grep replacement" }
        @{ Name = "fzf"; WingetId = "junegunn.fzf"; ChocoId = "fzf"; Description = "Fuzzy finder" }
    )
    "Prompt Tools" = @(
        @{ Name = "oh-my-posh"; WingetId = "JanDeDobbeleer.OhMyPosh"; ChocoId = "oh-my-posh"; Description = "PowerShell prompt tool" }
    )
    "Development Tools" = @(
        @{ Name = "gcc"; WingetId = ""; ChocoId = ""; Description = "MinGW-w64 GCC compiler (C/C++ development, installed via MSYS2)" }
        @{ Name = "make"; WingetId = "GnuWin32.Make"; ChocoId = "make"; Description = "GNU Make for Windows (build automation)" }
        @{ Name = "cmake"; WingetId = "Kitware.CMake"; ChocoId = "cmake"; Description = "CMake cross-platform build system" }
        @{ Name = "git-delta"; WingetId = "dandavison.delta"; ChocoId = "git-delta"; Description = "Git diff enhancer" }
        @{ Name = "lazygit"; WingetId = "jesseduffield.lazygit"; ChocoId = "lazygit"; Description = "Git TUI tool" }
        @{ Name = "direnv"; WingetId = "direnv.direnv"; ChocoId = "direnv"; Description = "Environment variable manager" }
    )
    "Other Tools" = @(
        @{ Name = "dust"; WingetId = "bootandy.dust"; ChocoId = "dust"; Description = "Modern du replacement" }
        @{ Name = "procs"; WingetId = "dalance.procs"; ChocoId = "procs"; Description = "Modern ps replacement" }
    )
}

# ============================================
# 交互式选择函数
# ============================================
function Show-InteractiveMenu {
    <#
    .SYNOPSIS
        显示交互式菜单，让用户选择要操作的工具
    #>
    Write-Host "`n===========================================" -ForegroundColor Cyan
    Write-Host "    Windows Common Tools Manager - Interactive Mode" -ForegroundColor Cyan
    Write-Host "===========================================" -ForegroundColor Cyan
    Write-Host ""
    
    $actionText = switch ($Script:CurrentAction) {
        "Install" { "Install" }
        "Update" { "Update" }
        "Uninstall" { "Uninstall" }
        default { "Manage" }
    }
    
    Write-Host "Current Action: $actionText" -ForegroundColor Yellow
    Write-Host ""
    
    $Script:SelectedPackages = @()
    
    foreach ($category in $Script:Tools.Keys) {
        Write-Host "`n[$category]" -ForegroundColor Yellow
        $tools = $Script:Tools[$category]
        
        for ($i = 0; $i -lt $tools.Count; $i++) {
            $tool = $tools[$i]
            
            # 检测工具状态
            $status = ""
            $statusColor = "White"
            if ($Script:CurrentAction -eq "Update" -or $Script:CurrentAction -eq "Uninstall") {
                $wingetId = $tool.WingetId
                $chocoId = $tool.ChocoId
                $checkResult = $null
                
                # 特殊处理：gcc 使用 MSYS2 检测方式
                if ($tool.Name -eq "gcc") {
                    $msys2Check = Test-MSYS2Installed
                    if ($msys2Check.Installed) {
                        try {
                            $gccVersion = & $msys2Check.GccPath --version 2>&1 | Select-Object -First 1
                            $versionMatch = $gccVersion | Select-String -Pattern "(\d+\.\d+\.\d+[^\s]*)"
                            $version = if ($versionMatch) { $versionMatch.Matches[0].Groups[1].Value } else { "Unknown" }
                            $checkResult = @{ Installed = $true; Version = $version }
                        } catch {
                            $checkResult = @{ Installed = $true; Version = "Unknown" }
                        }
                    } else {
                        $checkResult = @{ Installed = $false; Version = $null }
                    }
                } elseif ($wingetId -and (Test-PackageManager -Manager "winget") -eq "installed") {
                    $checkResult = Test-ProgramInstalled -PackageId $wingetId -PackageName $tool.Name -Manager "winget"
                } elseif ($chocoId -and (Test-PackageManager -Manager "chocolatey") -eq "installed") {
                    $checkResult = Test-ProgramInstalled -PackageId $chocoId -PackageName $tool.Name -Manager "chocolatey"
                }
                
                if ($checkResult -and $checkResult.Installed) {
                    $status = " [Installed: $($checkResult.Version)]"
                    $statusColor = "Green"
                } else {
                    $status = " [Not Installed]"
                    $statusColor = "Gray"
                }
            }
            
            Write-Host "  [$($i + 1)] $($tool.Name) - $($tool.Description)$status" -ForegroundColor $statusColor
        }
        
        Write-Host "  [A] $actionText all tools in this category" -ForegroundColor Green
        Write-Host "  [N] Skip this category" -ForegroundColor Gray
        
        $choice = Read-Host "`nPlease select (1-$($tools.Count)/A/N)"
        
        if ($choice -eq "A" -or $choice -eq "a") {
            # 选择所有工具
            $Script:SelectedPackages += $tools
        } elseif ($choice -eq "N" -or $choice -eq "n") {
            # 跳过此分类
            continue
        } else {
            # 选择特定工具
            $index = [int]$choice - 1
            if ($index -ge 0 -and $index -lt $tools.Count) {
                $Script:SelectedPackages += $tools[$index]
            }
        }
    }
    
    Write-Host "`nSelected $($Script:SelectedPackages.Count) tools for $actionText" -ForegroundColor Green
}

function Show-SingleToolMenu {
    <#
    .SYNOPSIS
        显示单个工具的详细操作菜单
    #>
    param(
        [Parameter(Mandatory)]
        [string]$ToolName
    )
    
    # 查找工具
    $foundTool = $null
    foreach ($category in $Script:Tools.Keys) {
        foreach ($tool in $Script:Tools[$category]) {
            if ($tool.Name -eq $ToolName) {
                $foundTool = $tool
                break
            }
        }
        if ($foundTool) { break }
    }
    
    if (-not $foundTool) {
        Write-Error "Tool not found: $ToolName"
        return
    }
    
    Write-Host "`n===========================================" -ForegroundColor Cyan
    Write-Host "    Tool: $($foundTool.Name)" -ForegroundColor Cyan
    Write-Host "===========================================" -ForegroundColor Cyan
    Write-Host "Description: $($foundTool.Description)" -ForegroundColor White
    Write-Host ""
    
    # 检测安装状态
    $wingetId = $foundTool.WingetId
    $chocoId = $foundTool.ChocoId
    $installed = $false
    $version = "Unknown"
    
    # 特殊处理：gcc 使用 MSYS2 检测方式
    if ($foundTool.Name -eq "gcc") {
        $msys2Check = Test-MSYS2Installed
        if ($msys2Check.Installed) {
            $installed = $true
            try {
                $gccVersion = & $msys2Check.GccPath --version 2>&1 | Select-Object -First 1
                $versionMatch = $gccVersion | Select-String -Pattern "(\d+\.\d+\.\d+[^\s]*)"
                $version = if ($versionMatch) { $versionMatch.Matches[0].Groups[1].Value } else { "Unknown" }
            } catch {
                $version = "Unknown"
            }
        }
    } elseif ($wingetId -and (Test-PackageManager -Manager "winget") -eq "installed") {
        $checkResult = Test-ProgramInstalled -PackageId $wingetId -PackageName $foundTool.Name -Manager "winget"
        if ($checkResult.Installed) {
            $installed = $true
            $version = $checkResult.Version
        }
    } elseif ($chocoId -and (Test-PackageManager -Manager "chocolatey") -eq "installed") {
        $checkResult = Test-ProgramInstalled -PackageId $chocoId -PackageName $foundTool.Name -Manager "chocolatey"
        if ($checkResult.Installed) {
            $installed = $true
            $version = $checkResult.Version
        }
    }
    
    Write-Host "Status: $(if ($installed) { "Installed (version: $version)" } else { "Not Installed" })" -ForegroundColor $(if ($installed) { "Green" } else { "Yellow" })
    Write-Host ""
    
    # 显示操作选项
    Write-Host "Please select an action:" -ForegroundColor Yellow
    if (-not $installed) {
        Write-Host "  [1] Install" -ForegroundColor Green
    } else {
        Write-Host "  [1] Update" -ForegroundColor Cyan
        Write-Host "  [2] Uninstall" -ForegroundColor Red
    }
    Write-Host "  [0] Cancel" -ForegroundColor Gray
    
    $choice = Read-Host "`nPlease select"
    
    if ($choice -eq "1") {
        if (-not $installed) {
            Install-Program -Package $foundTool
        } else {
            Update-Program -Package $foundTool
        }
    } elseif ($choice -eq "2" -and $installed) {
        Uninstall-Program -Package $foundTool
    }
}

# ============================================
# 主安装逻辑
# ============================================
function Start-Installation {
    <#
    .SYNOPSIS
        开始安装流程
    #>
    
    # 初始化日志文件（清空旧日志，开始新会话）
    try {
        # 清空日志文件，准备记录新会话（不写入空行）
        $null = New-Item -Path $Script:LogFile -ItemType File -Force -ErrorAction SilentlyContinue
    } catch {
        # 如果无法创建日志文件，继续执行（不影响主流程）
    }
    
    $actionText = switch ($Action) {
        "Install" { "Installation" }
        "Update" { "Update" }
        "Uninstall" { "Uninstallation" }
        default { "Management" }
    }
    
    Write-Host-Log "`n===========================================" -ForegroundColor Cyan
    Write-Host-Log "    Windows Common Tools $actionText Script" -ForegroundColor Cyan
    Write-Host-Log "===========================================" -ForegroundColor Cyan
    Write-Host-Log ""
    
    # 默认代理：优先尝试本地 127.0.0.1:7890
    if (-not $env:http_proxy -and -not $env:https_proxy) {
        Write-Info "Applying default proxy http://127.0.0.1:7890"
        Set-ProxySettings -ProxyUrl "http://127.0.0.1:7890"
    } else {
        Write-Info "Using existing proxy configuration"
    }
    
    # 备份 PATH（在开始操作前，参考 winutil 的实现）
    if ($Action -eq "Install" -and -not $Script:PathBackedUp) {
        Write-Info "Backing up current PATH to path.bak..."
        if (Backup-EnvironmentPath) {
            Write-Success "PATH backup completed successfully"
            $Script:PathBackedUp = $true
        } else {
            Write-Warning "PATH backup failed, but continuing..."
        }
        Write-Host ""
    }
    
    # 检测是否在中国大陆，如果是则设置代理
    if (Test-IsMainlandChina) {
        Write-Info "Mainland China detected, setting up proxy..."
        Set-ProxySettings
    }
    
    # 确定包管理器
    if ($PackageManager -eq "auto") {
        Write-Info "Auto-detecting package manager..."
        
        $wingetStatus = Test-PackageManager -Manager "winget"
        $chocoStatus = Test-PackageManager -Manager "chocolatey"
        
        if ($wingetStatus -eq "installed") {
            $Script:PackageManager = "winget"
            Write-Success "Using Winget as package manager"
        } elseif ($chocoStatus -eq "installed") {
            $Script:PackageManager = "chocolatey"
            Write-Success "Using Chocolatey as package manager"
        } else {
            Write-Info "No package manager detected, attempting to install Winget..."
            if (Install-Winget) {
                $Script:PackageManager = "winget"
            } else {
                Write-Info "Attempting to install Chocolatey..."
                if (Install-Chocolatey) {
                    $Script:PackageManager = "chocolatey"
                } else {
                    Write-Error "Failed to install package manager, script exiting"
                    exit 1
                }
            }
        }
    } else {
        $Script:PackageManager = $PackageManager
        
        # 确保指定的包管理器已安装
        if ($PackageManager -eq "winget") {
            if ((Test-PackageManager -Manager "winget") -ne "installed") {
                if (-not (Install-Winget)) {
                    Write-Error "Winget installation failed, script exiting"
                    exit 1
                }
            }
        } elseif ($PackageManager -eq "chocolatey") {
            if ((Test-PackageManager -Manager "chocolatey") -ne "installed") {
                if (-not (Install-Chocolatey)) {
                    Write-Error "Chocolatey installation failed, script exiting"
                    exit 1
                }
            }
        }
    }
    
    # 设置当前操作类型
    $Script:CurrentAction = $Action
    
    # 如果指定了单个工具，显示单独操作菜单
    if ($ToolName) {
        Show-SingleToolMenu -ToolName $ToolName
        return
    }
    
    # 确定要操作的工具列表
    if ($Interactive) {
        Show-InteractiveMenu
        $packagesToOperate = $Script:SelectedPackages
    } else {
        # 自动模式
        if ($Action -eq "Update") {
            # 更新模式：只选择已安装的工具
            $packagesToOperate = @()
            foreach ($category in $Script:Tools.Keys) {
                foreach ($tool in $Script:Tools[$category]) {
                    $wingetId = $tool.WingetId
                    $chocoId = $tool.ChocoId
                    $installed = $false
                    
                    # 特殊处理：gcc 使用 MSYS2 检测方式
                    if ($tool.Name -eq "gcc") {
                        $msys2Check = Test-MSYS2Installed
                        $installed = $msys2Check.Installed
                    } elseif ($wingetId -and (Test-PackageManager -Manager "winget") -eq "installed") {
                        $checkResult = Test-ProgramInstalled -PackageId $wingetId -PackageName $tool.Name -Manager "winget"
                        $installed = $checkResult.Installed
                    } elseif ($chocoId -and (Test-PackageManager -Manager "chocolatey") -eq "installed") {
                        $checkResult = Test-ProgramInstalled -PackageId $chocoId -PackageName $tool.Name -Manager "chocolatey"
                        $installed = $checkResult.Installed
                    }
                    
                    if ($installed) {
                        $packagesToOperate += $tool
                    }
                }
            }
        } elseif ($Action -eq "Uninstall") {
            # 卸载模式：只选择已安装的工具
            $packagesToOperate = @()
            foreach ($category in $Script:Tools.Keys) {
                foreach ($tool in $Script:Tools[$category]) {
                    $wingetId = $tool.WingetId
                    $chocoId = $tool.ChocoId
                    $installed = $false
                    
                    # 特殊处理：gcc 使用 MSYS2 检测方式
                    if ($tool.Name -eq "gcc") {
                        $msys2Check = Test-MSYS2Installed
                        $installed = $msys2Check.Installed
                    } elseif ($wingetId -and (Test-PackageManager -Manager "winget") -eq "installed") {
                        $checkResult = Test-ProgramInstalled -PackageId $wingetId -PackageName $tool.Name -Manager "winget"
                        $installed = $checkResult.Installed
                    } elseif ($chocoId -and (Test-PackageManager -Manager "chocolatey") -eq "installed") {
                        $checkResult = Test-ProgramInstalled -PackageId $chocoId -PackageName $tool.Name -Manager "chocolatey"
                        $installed = $checkResult.Installed
                    }
                    
                    if ($installed) {
                        $packagesToOperate += $tool
                    }
                }
            }
        } else {
            # 安装模式：所有工具
            $packagesToOperate = @()
            foreach ($category in $Script:Tools.Keys) {
                $packagesToOperate += $Script:Tools[$category]
            }
        }
    }
    
    if ($packagesToOperate.Count -eq 0) {
        $actionText = switch ($Action) {
            "Install" { "install" }
            "Update" { "update" }
            "Uninstall" { "uninstall" }
            default { "operate" }
        }
        Write-Warning "No tools selected to $actionText"
        exit 0
    }
    
    # 开始操作
    $actionText = switch ($Action) {
        "Install" { "install" }
        "Update" { "update" }
        "Uninstall" { "uninstall" }
        default { "operate" }
    }
    
    $startMsg = "Starting to $actionText $($packagesToOperate.Count) tools..."
    Write-Host-Log "`n$startMsg" -ForegroundColor Cyan
    Write-Host-Log ""
    
    $total = $packagesToOperate.Count
    $current = 0
    
    foreach ($package in $packagesToOperate) {
        $current++
        $progressMsg = "[$current/$total] "
        Write-Host-Log $progressMsg -NoNewline -ForegroundColor Gray
        
        switch ($Action) {
            "Install" {
                Install-Program -Package $package
            }
            "Update" {
                Update-Program -Package $package
            }
            "Uninstall" {
                Uninstall-Program -Package $package
            }
        }
    }
    
    # 安装字体
    if (-not $SkipFonts) {
        Write-Host "`n"
        Write-Log ""
        Install-NerdFonts
    }
    
    # 最后刷新一次 PATH，确保所有工具都可用（包括 Git Bash）
    # 参考 winutil 的实现，进行多重刷新确保生效
    Write-Host "`n"
    Write-Log ""
    Write-Info "Performing final PATH refresh (winutil-style multiple refresh methods)..."
    
    # 备份 PATH（在最终刷新前，如果尚未备份）
    if (-not $Script:PathBackedUp) {
        Write-Info "Backing up current PATH to path.bak..."
        if (Backup-EnvironmentPath) {
            $Script:PathBackedUp = $true
        }
    }
    
    # 多次刷新以提高成功率（跳过备份，避免重复）
    $refreshSuccess = $false
    for ($i = 1; $i -le 3; $i++) {
        Write-Info "PATH refresh attempt $i/3..."
        if (Refresh-EnvironmentPath -SkipBackup) {
            $refreshSuccess = $true
        }
        Start-Sleep -Milliseconds 300
    }
    
    if ($refreshSuccess) {
        Write-Success "PATH refreshed successfully using multiple methods."
    } else {
        Write-Warning "PATH refresh completed with warnings. Some tools may require a terminal restart."
    }
    
    Write-Info "All installed tools should be available in:"
    Write-Info "  - PowerShell (new sessions will have updated PATH)"
    Write-Info "  - Git Bash (new sessions will inherit updated PATH from Windows)"
    Write-Info "  - Command Prompt (new sessions will have updated PATH)"
    Write-Warning "Note: Currently open terminals may need to be restarted to see PATH changes."
    
    # 显示详细报告
    $actionText = switch ($Action) {
        "Install" { "Installation" }
        "Update" { "Update" }
        "Uninstall" { "Uninstallation" }
        default { "Operation" }
    }
    
    Write-Host-Log "`n===========================================" -ForegroundColor Cyan
    Write-Host-Log "    $actionText Completed - Detailed Report" -ForegroundColor Cyan
    Write-Host-Log "===========================================" -ForegroundColor Cyan
    Write-Host-Log ""
    
    # 统计信息
    $newInstalled = ($Script:InstallationReport | Where-Object { $_.Status -eq "NewInstalled" }).Count
    $alreadyExists = ($Script:InstallationReport | Where-Object { $_.Status -eq "AlreadyExists" }).Count
    $updated = ($Script:InstallationReport | Where-Object { $_.Status -eq "Updated" }).Count
    $latest = ($Script:InstallationReport | Where-Object { $_.Status -eq "AlreadyLatest" }).Count
    $uninstalled = ($Script:InstallationReport | Where-Object { $_.Status -eq "Uninstalled" }).Count
    $failed = ($Script:InstallationReport | Where-Object { $_.Status -eq "Failed" }).Count
    
    Write-Host-Log "Statistics:" -ForegroundColor Yellow
    
    if ($Action -eq "Install") {
        Write-Host-Log "  New Installed: $newInstalled" -ForegroundColor Green
        Write-Host-Log "  Already Exists: $alreadyExists" -ForegroundColor Cyan
    } elseif ($Action -eq "Update") {
        Write-Host-Log "  Updated: $updated" -ForegroundColor Green
        Write-Host-Log "  Already Latest: $latest" -ForegroundColor Cyan
    } elseif ($Action -eq "Uninstall") {
        Write-Host-Log "  Uninstalled: $uninstalled" -ForegroundColor Green
    }
    
    Write-Host-Log "  Failed: $failed" -ForegroundColor $(if ($failed -gt 0) { "Red" } else { "Green" })
    Write-Host-Log ""
    
    # 详细列表
    Write-Host-Log "Detailed List:" -ForegroundColor Yellow
    Write-Host-Log ""
    
    # 按状态分组显示
    $grouped = $Script:InstallationReport | Group-Object -Property Status
    
    foreach ($group in $grouped) {
        $statusColor = switch ($group.Name) {
            "NewInstalled" { "Green" }
            "AlreadyExists" { "Cyan" }
            "Updated" { "Green" }
            "AlreadyLatest" { "Cyan" }
            "Uninstalled" { "Yellow" }
            "Failed" { "Red" }
            default { "White" }
        }
        
        Write-Host-Log "[$($group.Name)]" -ForegroundColor $statusColor
        foreach ($item in $group.Group) {
            $statusIcon = switch ($item.Status) {
                "NewInstalled" { "✓" }
                "AlreadyExists" { "○" }
                "Updated" { "↗" }
                "AlreadyLatest" { "○" }
                "Uninstalled" { "✗" }
                "Failed" { "✗" }
                default { " " }
            }
            
            $methodInfo = if ($item.InstallMethod -ne "Detected" -and $item.Status -ne "Uninstalled") {
                " (via $($item.InstallMethod))"
            } else {
                ""
            }
            
            Write-Host-Log "  $statusIcon $($item.Name) - Version: $($item.Version)$methodInfo" -ForegroundColor White
        }
        Write-Host-Log ""
    }
    
    # 字体安装状态
    if (-not $SkipFonts) {
        Write-Host-Log "[Fonts]" -ForegroundColor Yellow
        Write-Host-Log "  ○ Nerd Fonts FiraMono - Installed to system fonts directory" -ForegroundColor White
        Write-Host-Log ""
    }
    
    # 失败工具列表（如果有）
    if ($Script:FailedPackages.Count -gt 0) {
        Write-Host-Log "Failed Tools:" -ForegroundColor Red
        foreach ($package in $Script:FailedPackages) {
            Write-Host-Log "  - $package" -ForegroundColor Red
        }
        Write-Host-Log ""
    }
    
    Write-Host-Log "===========================================" -ForegroundColor Cyan
    Write-Host-Log ""
    
    # 询问是否关闭窗口
    Write-Host "Operation completed!" -ForegroundColor Green
    $closeWindow = Read-Host "Close this window? (Y/N, default: N)"
    
    if ($closeWindow -eq "Y" -or $closeWindow -eq "y") {
        Write-Host "Closing window..." -ForegroundColor Cyan
        Start-Sleep -Seconds 1
        exit 0
    } else {
        Write-Host "Window will remain open. You can review the results." -ForegroundColor Cyan
        Write-Host "Press any key to exit..." -ForegroundColor Gray
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }
}

# ============================================
# 脚本入口
# ============================================
# 检查管理员权限
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Error "This script requires administrator privileges"
    Write-Info "Please right-click PowerShell and select 'Run as administrator'"
    exit 1
}

# 检查执行策略
$executionPolicy = Get-ExecutionPolicy
if ($executionPolicy -eq "Restricted") {
    Write-Warning "Execution policy is Restricted, attempting to set to RemoteSigned temporarily..."
    try {
        Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process -Force | Out-Null
        Write-Success "Execution policy temporarily set to RemoteSigned (current session only)"
    } catch {
        Write-Error "Failed to set execution policy: $_"
        Write-Info ""
        Write-Info "Please manually set execution policy:"
        Write-Info "  Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process"
        Write-Info "Or run the script with:"
        Write-Info "  powershell -ExecutionPolicy Bypass -File .\install_common_tools.ps1"
        exit 1
    }
}

# 开始安装
Start-Installation

