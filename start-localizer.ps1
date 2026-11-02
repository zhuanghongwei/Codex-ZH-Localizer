param(
    [int]$Port = 9337
)

$ErrorActionPreference = "Stop"
$stateDir = Join-Path $env:LOCALAPPDATA "CodexChineseOverlay"
$pidFile = Join-Path $stateDir "translator.pid"
$stdoutLog = Join-Path $stateDir "translator.out.log"
$stderrLog = Join-Path $stateDir "translator.err.log"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$translator = Join-Path $scriptDir "translator.mjs"

New-Item -ItemType Directory -Force -Path $stateDir | Out-Null

if (Test-Path $pidFile) {
    $oldPid = 0
    [void][int]::TryParse((Get-Content $pidFile -ErrorAction SilentlyContinue), [ref]$oldPid)
    if ($oldPid -gt 0) {
        Stop-Process -Id $oldPid -Force -ErrorAction SilentlyContinue
    }
    Remove-Item -LiteralPath $pidFile -Force -ErrorAction SilentlyContinue
}

$node = (Get-Command node.exe -ErrorAction SilentlyContinue).Source
if (-not $node) {
    throw "Node.js was not found."
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

if (-not $codexExe -or -not (Test-Path -LiteralPath $codexExe)) {
    throw "Codex was not found. Open Codex once, then try again."
}

$selectedPort = $Port
for ($attempt = 0; $attempt -lt 50; $attempt++) {
    $listener = [System.Net.Sockets.TcpListener]::new(
        [System.Net.IPAddress]::Loopback,
        $selectedPort
    )
    try {
        $listener.Start()
        $listener.Stop()
        break
    } catch {
        $selectedPort++
    }
}

Get-Process ChatGPT -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Seconds 2

Start-Process -FilePath $codexExe -ArgumentList @(
    "--remote-debugging-address=127.0.0.1",
    "--remote-debugging-port=$selectedPort",
    "--remote-allow-origins=*"
)

Start-Sleep -Seconds 4

$translatorProcess = Start-Process -FilePath $node -ArgumentList @(
    "`"$translator`"",
    "--port",
    "$selectedPort"
) -WindowStyle Hidden -RedirectStandardOutput $stdoutLog -RedirectStandardError $stderrLog -PassThru

Set-Content -LiteralPath $pidFile -Value $translatorProcess.Id -Encoding ascii
Write-Host "Codex restarted with the Chinese localizer enabled."
Write-Host "Log directory: $stateDir"
Write-Host "Run restore-localizer.cmd to restore the original interface."
