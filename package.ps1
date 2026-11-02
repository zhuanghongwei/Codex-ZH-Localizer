param(
    [string]$OutputDirectory
)

$ErrorActionPreference = "Stop"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$version = (Get-Content -LiteralPath (Join-Path $scriptDir "VERSION") -Raw).Trim()
$packageName = "Codex-ZH-Localizer-v$version"

if (-not $OutputDirectory) {
    $OutputDirectory = Join-Path $scriptDir "dist"
}

$outputPath = [IO.Path]::GetFullPath($OutputDirectory)
New-Item -ItemType Directory -Force -Path $outputPath | Out-Null

& (Join-Path $scriptDir "build.ps1") -OutputPath (Join-Path $scriptDir "CodexZH.exe") | Out-Null
if ($LASTEXITCODE -ne 0) {
    throw "Launcher build failed."
}

$stagingRoot = Join-Path ([IO.Path]::GetTempPath()) "codex-zh-package-$([Guid]::NewGuid().ToString('N'))"
$stagingFolder = Join-Path $stagingRoot "Codex-ZH-Localizer"

try {
    New-Item -ItemType Directory -Force -Path $stagingFolder | Out-Null

    $files = @(
        ".gitignore",
        "build.ps1",
        "CHANGELOG.md",
        "CodexZH.exe",
        "README.md",
        "VERSION",
        "install-shortcut.ps1",
        "overlay.js",
        "restore-localizer.ps1",
        "src\Launcher.cs",
        "start-localizer.ps1",
        "translator.mjs",
        "启动 Codex 中文外挂.cmd",
        "恢复 Codex 原界面.cmd",
        "说明.txt"
    )

    foreach ($relativePath in $files) {
        $source = Join-Path $scriptDir $relativePath
        if (-not (Test-Path -LiteralPath $source)) {
            throw "Distribution file was not found: $relativePath"
        }
        $destination = Join-Path $stagingFolder $relativePath
        New-Item -ItemType Directory -Force -Path (Split-Path -Parent $destination) | Out-Null
        Copy-Item -LiteralPath $source -Destination $destination
    }

    $zipPath = Join-Path $outputPath "$packageName.zip"
    Compress-Archive -LiteralPath $stagingFolder -DestinationPath $zipPath -CompressionLevel Optimal -Force
    Write-Host "Package created: $zipPath"
    Write-Output $zipPath
} finally {
    if (Test-Path -LiteralPath $stagingRoot) {
        Remove-Item -LiteralPath $stagingRoot -Recurse -Force
    }
}
