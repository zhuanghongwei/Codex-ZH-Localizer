param(
    [string]$ShortcutName = "启动 Codex 中文外挂",
    [string]$Destination
)

$ErrorActionPreference = "Stop"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$launcher = Join-Path $scriptDir "CodexZH.exe"

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
$shortcut.Arguments = ""
$shortcut.WorkingDirectory = $scriptDir
$shortcut.IconLocation = "$launcher,0"
$shortcut.Description = "打开 Codex 中文外挂控制面板"
$shortcut.WindowStyle = 1
$shortcut.Save()

Write-Host "Shortcut created: $shortcutPath"
