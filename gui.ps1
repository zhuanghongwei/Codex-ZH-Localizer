param(
    [switch]$SelfTest
)

$ErrorActionPreference = "Stop"
$appDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$startScript = Join-Path $appDir "start-localizer.ps1"
$restoreScript = Join-Path $appDir "restore-localizer.ps1"
$versionFile = Join-Path $appDir "VERSION"
$stateDir = Join-Path $env:LOCALAPPDATA "CodexChineseOverlay"
$helperPidFile = Join-Path $stateDir "translator.pid"
$actionOutFile = Join-Path $stateDir "gui-action.out.log"
$actionErrFile = Join-Path $stateDir "gui-action.err.log"
$powershellExe = Join-Path $env:SystemRoot "System32\WindowsPowerShell\v1.0\powershell.exe"

foreach ($requiredFile in @($startScript, $restoreScript, $versionFile)) {
    if (-not (Test-Path -LiteralPath $requiredFile)) {
        throw "Required file was not found: $requiredFile"
    }
}

$nodeExe = (Get-Command node.exe -ErrorAction SilentlyContinue).Source
$version = (Get-Content -LiteralPath $versionFile -Raw).Trim()

if ($SelfTest) {
    if (-not $nodeExe) {
        throw "Node.js was not found."
    }
    [PSCustomObject]@{
        Status = "OK"
        Version = $version
        AppDirectory = $appDir
        Node = $nodeExe
        StartScript = $startScript
        RestoreScript = $restoreScript
    } | Format-List
    exit 0
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

[Windows.Forms.Application]::EnableVisualStyles()
[Windows.Forms.Application]::SetCompatibleTextRenderingDefault($false)

$script:activeProcess = $null
$script:activeKind = $null

function Get-HelperProcess {
    if (-not (Test-Path -LiteralPath $helperPidFile)) {
        return $null
    }

    $helperPid = 0
    [void][int]::TryParse((Get-Content -LiteralPath $helperPidFile -Raw).Trim(), [ref]$helperPid)
    if ($helperPid -le 0) {
        return $null
    }

    $process = Get-Process -Id $helperPid -ErrorAction SilentlyContinue
    if ($process -and $process.ProcessName -eq "node") {
        return $process
    }
    return $null
}

function Read-ActionLog {
    $parts = @()
    foreach ($path in @($actionOutFile, $actionErrFile)) {
        if ((Test-Path -LiteralPath $path) -and (Get-Item -LiteralPath $path).Length -gt 0) {
            $parts += (Get-Content -LiteralPath $path -Raw -Encoding UTF8).Trim()
        }
    }
    return ($parts -join "`r`n")
}

function Update-Interface {
    $helper = Get-HelperProcess

    if ($script:activeProcess -and -not $script:activeProcess.HasExited) {
        if ($script:activeKind -eq "start") {
            $statusText.Text = "正在启动汉化..."
            $detailText.Text = "正在重新打开 Codex，请稍候。"
        } else {
            $statusText.Text = "正在恢复原始界面..."
            $detailText.Text = "正在停止汉化辅助器并重新打开 Codex。"
        }
        $statusDot.ForeColor = [Drawing.Color]::FromArgb(217, 119, 6)
    } elseif ($helper) {
        $statusText.Text = "汉化已开启"
        $detailText.Text = "辅助进程正在运行，界面文字已应用。"
        $statusDot.ForeColor = [Drawing.Color]::FromArgb(22, 163, 74)
    } else {
        $statusText.Text = "当前为原始界面"
        $detailText.Text = "点击 '启动汉化' 即可切换为中文界面。"
        $statusDot.ForeColor = [Drawing.Color]::FromArgb(100, 116, 139)
    }

    $startButton.Enabled = (-not $script:activeProcess) -and (-not $helper)
    $restoreButton.Enabled = -not $script:activeProcess
}

function Start-Action {
    param(
        [ValidateSet("start", "restore")]
        [string]$Kind
    )

    New-Item -ItemType Directory -Force -Path $stateDir | Out-Null
    Set-Content -LiteralPath $actionOutFile -Value "" -Encoding UTF8
    Set-Content -LiteralPath $actionErrFile -Value "" -Encoding UTF8

    $scriptPath = if ($Kind -eq "start") { $startScript } else { $restoreScript }
    $arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`""

    try {
        $script:activeProcess = Start-Process `
            -FilePath $powershellExe `
            -ArgumentList $arguments `
            -WorkingDirectory $appDir `
            -WindowStyle Hidden `
            -RedirectStandardOutput $actionOutFile `
            -RedirectStandardError $actionErrFile `
            -PassThru
        $script:activeKind = $Kind
        $logBox.Text = if ($Kind -eq "start") {
            "正在启动汉化，Codex 将自动重新打开..."
        } else {
            "正在恢复原始界面，Codex 将自动重新打开..."
        }
        $actionTimer.Start()
        Update-Interface
    } catch {
        $script:activeProcess = $null
        $script:activeKind = $null
        $logBox.Text = "操作失败：$($_.Exception.Message)"
        Update-Interface
        [Windows.Forms.MessageBox]::Show(
            $_.Exception.Message,
            "Codex 中文外挂",
            [Windows.Forms.MessageBoxButtons]::OK,
            [Windows.Forms.MessageBoxIcon]::Error
        ) | Out-Null
    }
}

$form = New-Object Windows.Forms.Form
$form.Text = "Codex 中文外挂"
$form.ClientSize = New-Object Drawing.Size(640, 470)
$form.MinimumSize = New-Object Drawing.Size(656, 509)
$form.MaximumSize = New-Object Drawing.Size(656, 509)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedSingle"
$form.MaximizeBox = $false
$form.BackColor = [Drawing.Color]::FromArgb(244, 247, 251)
$form.Font = New-Object Drawing.Font("Microsoft YaHei UI", 9)
try {
    $form.Icon = [Drawing.Icon]::ExtractAssociatedIcon($powershellExe)
} catch {
}

$header = New-Object Windows.Forms.Panel
$header.Location = New-Object Drawing.Point(0, 0)
$header.Size = New-Object Drawing.Size(640, 96)
$header.BackColor = [Drawing.Color]::FromArgb(30, 58, 138)
$form.Controls.Add($header)

$title = New-Object Windows.Forms.Label
$title.Text = "Codex 中文外挂"
$title.Font = New-Object Drawing.Font("Microsoft YaHei UI", 20, [Drawing.FontStyle]::Bold)
$title.ForeColor = [Drawing.Color]::White
$title.AutoSize = $true
$title.Location = New-Object Drawing.Point(26, 17)
$header.Controls.Add($title)

$subtitle = New-Object Windows.Forms.Label
$subtitle.Text = "一键切换中文界面，也可随时恢复原界面"
$subtitle.Font = New-Object Drawing.Font("Microsoft YaHei UI", 9)
$subtitle.ForeColor = [Drawing.Color]::FromArgb(219, 234, 254)
$subtitle.AutoSize = $true
$subtitle.Location = New-Object Drawing.Point(29, 60)
$header.Controls.Add($subtitle)

$statusPanel = New-Object Windows.Forms.Panel
$statusPanel.Location = New-Object Drawing.Point(24, 118)
$statusPanel.Size = New-Object Drawing.Size(592, 112)
$statusPanel.BackColor = [Drawing.Color]::White
$form.Controls.Add($statusPanel)

$statusDot = New-Object Windows.Forms.Label
$statusDot.Text = "●"
$statusDot.Font = New-Object Drawing.Font("Microsoft YaHei UI", 18)
$statusDot.AutoSize = $true
$statusDot.Location = New-Object Drawing.Point(20, 23)
$statusPanel.Controls.Add($statusDot)

$statusText = New-Object Windows.Forms.Label
$statusText.Text = "正在检测状态..."
$statusText.Font = New-Object Drawing.Font("Microsoft YaHei UI", 14, [Drawing.FontStyle]::Bold)
$statusText.ForeColor = [Drawing.Color]::FromArgb(30, 41, 59)
$statusText.AutoSize = $true
$statusText.Location = New-Object Drawing.Point(53, 18)
$statusPanel.Controls.Add($statusText)

$detailText = New-Object Windows.Forms.Label
$detailText.Text = ""
$detailText.ForeColor = [Drawing.Color]::FromArgb(71, 85, 105)
$detailText.AutoSize = $false
$detailText.Size = New-Object Drawing.Size(515, 24)
$detailText.Location = New-Object Drawing.Point(56, 61)
$statusPanel.Controls.Add($detailText)

$startButton = New-Object Windows.Forms.Button
$startButton.Text = "启动汉化"
$startButton.Location = New-Object Drawing.Point(24, 252)
$startButton.Size = New-Object Drawing.Size(286, 52)
$startButton.FlatStyle = "Flat"
$startButton.FlatAppearance.BorderSize = 0
$startButton.BackColor = [Drawing.Color]::FromArgb(37, 99, 235)
$startButton.ForeColor = [Drawing.Color]::White
$startButton.Font = New-Object Drawing.Font("Microsoft YaHei UI", 11, [Drawing.FontStyle]::Bold)
$startButton.Cursor = [Windows.Forms.Cursors]::Hand
$form.Controls.Add($startButton)

$restoreButton = New-Object Windows.Forms.Button
$restoreButton.Text = "恢复原界面"
$restoreButton.Location = New-Object Drawing.Point(330, 252)
$restoreButton.Size = New-Object Drawing.Size(286, 52)
$restoreButton.FlatStyle = "Flat"
$restoreButton.FlatAppearance.BorderColor = [Drawing.Color]::FromArgb(203, 213, 225)
$restoreButton.BackColor = [Drawing.Color]::White
$restoreButton.ForeColor = [Drawing.Color]::FromArgb(30, 41, 59)
$restoreButton.Font = New-Object Drawing.Font("Microsoft YaHei UI", 11, [Drawing.FontStyle]::Bold)
$restoreButton.Cursor = [Windows.Forms.Cursors]::Hand
$form.Controls.Add($restoreButton)

$logBox = New-Object Windows.Forms.TextBox
$logBox.Location = New-Object Drawing.Point(24, 324)
$logBox.Size = New-Object Drawing.Size(592, 70)
$logBox.Multiline = $true
$logBox.ReadOnly = $true
$logBox.ScrollBars = "Vertical"
$logBox.BackColor = [Drawing.Color]::White
$logBox.ForeColor = [Drawing.Color]::FromArgb(71, 85, 105)
$logBox.BorderStyle = "FixedSingle"
$logBox.Text = "准备就绪。"
$form.Controls.Add($logBox)

$folderLink = New-Object Windows.Forms.LinkLabel
$folderLink.Text = "打开工具目录"
$folderLink.AutoSize = $true
$folderLink.LinkColor = [Drawing.Color]::FromArgb(37, 99, 235)
$folderLink.Location = New-Object Drawing.Point(25, 415)
$form.Controls.Add($folderLink)

$logLink = New-Object Windows.Forms.LinkLabel
$logLink.Text = "查看运行日志"
$logLink.AutoSize = $true
$logLink.LinkColor = [Drawing.Color]::FromArgb(37, 99, 235)
$logLink.Location = New-Object Drawing.Point(131, 415)
$form.Controls.Add($logLink)

$versionLabel = New-Object Windows.Forms.Label
$versionLabel.Text = "v$version · 本机运行"
$versionLabel.AutoSize = $true
$versionLabel.ForeColor = [Drawing.Color]::FromArgb(148, 163, 184)
$versionLabel.Location = New-Object Drawing.Point(514, 415)
$form.Controls.Add($versionLabel)

$actionTimer = New-Object Windows.Forms.Timer
$actionTimer.Interval = 600
$actionTimer.Add_Tick({
    if ($script:activeProcess -and $script:activeProcess.HasExited) {
        $exitCode = $script:activeProcess.ExitCode
        $message = Read-ActionLog
        if ($exitCode -eq 0) {
            if ($script:activeKind -eq "start") {
                $message = if ($message) { $message } else { "汉化已启动，Codex 已重新打开。" }
            } else {
                $message = if ($message) { $message } else { "已恢复原始界面，Codex 已重新打开。" }
            }
        } elseif (-not $message) {
            $message = "操作失败，退出代码：$exitCode"
        }
        $logBox.Text = $message
        $script:activeProcess.Dispose()
        $script:activeProcess = $null
        $script:activeKind = $null
        $actionTimer.Stop()
    }
    Update-Interface
})

$startButton.Add_Click({
    Start-Action -Kind "start"
})

$restoreButton.Add_Click({
    Start-Action -Kind "restore"
})

$folderLink.Add_LinkClicked({
    Start-Process -FilePath "explorer.exe" -ArgumentList "`"$appDir`""
})

$logLink.Add_LinkClicked({
    New-Item -ItemType Directory -Force -Path $stateDir | Out-Null
    Start-Process -FilePath "explorer.exe" -ArgumentList "`"$stateDir`""
})

$form.Add_Shown({
    Update-Interface
})

$form.Add_FormClosed({
    $actionTimer.Stop()
})

[void]$form.ShowDialog()
