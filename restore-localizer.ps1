$ErrorActionPreference = "Stop"
$stateDir = Join-Path $env:LOCALAPPDATA "CodexChineseOverlay"
$pidFile = Join-Path $stateDir "translator.pid"

if (Test-Path $pidFile) {
    $translatorPid = 0
    [void][int]::TryParse((Get-Content $pidFile -ErrorAction SilentlyContinue), [ref]$translatorPid)
    if ($translatorPid -gt 0) {
        Stop-Process -Id $translatorPid -Force -ErrorAction SilentlyContinue
    }
    Remove-Item -LiteralPath $pidFile -Force -ErrorAction SilentlyContinue
}

$codexProcess = Get-Process ChatGPT -ErrorAction SilentlyContinue |
    Where-Object { $_.Path } |
    Select-Object -First 1
$codexExe = $codexProcess.Path

if (-not $codexExe) {
    $package = Get-AppxPackage OpenAI.Codex | Select-Object -First 1
    if ($package) {
        $codexExe = Join-Path $package.InstallLocation "app\ChatGPT.exe"
    }
}

Get-Process ChatGPT -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Seconds 2

if ($codexExe -and (Test-Path -LiteralPath $codexExe)) {
    Start-Process -FilePath $codexExe
}

Write-Host "Chinese localizer stopped. Codex has been reopened normally."
