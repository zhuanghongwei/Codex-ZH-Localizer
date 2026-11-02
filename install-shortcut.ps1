param(
    [string]$ShortcutName = "Codex 中文外挂",
    [string]$Destination
)

$ErrorActionPreference = "Stop"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$launcher = Join-Path $scriptDir "启动 Codex 中文外挂.cmd"

if (-not (Test-Path -LiteralPath $launcher)) {
    throw "Launcher was not found. Keep the complete tool folder together."
}

if (-not $Destination) {
    $Destination = [Environment]::GetFolderPath("Desktop")
}

if (-not (Test-Path -LiteralPath $Destination)) {
    New-Item -ItemType Directory -Force -Path $Destination | Out-Null
}

$shortcutPath = Join-Path $Destination "$ShortcutName.lnk"
$shell = New-Object -ComObject WScript.Shell
$shortcut = $shell.CreateShortcut($shortcutPath)
$shortcut.TargetPath = $launcher
$shortcut.WorkingDirectory = $scriptDir
$shortcut.IconLocation = Join-Path $env:SystemRoot "System32\WindowsPowerShell\v1.0\powershell.exe,0"
$shortcut.Description = "启动 Codex 中文界面辅助工具"
$shortcut.WindowStyle = 1
$shortcut.Save()

Write-Host "Shortcut created: $shortcutPath"
