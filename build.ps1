param(
    [string]$OutputPath
)

$ErrorActionPreference = "Stop"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$source = Join-Path $scriptDir "src\Launcher.cs"
$compiler = Join-Path $env:WINDIR "Microsoft.NET\Framework64\v4.0.30319\csc.exe"

if (-not (Test-Path -LiteralPath $compiler)) {
    throw ".NET Framework C# compiler was not found."
}
if (-not (Test-Path -LiteralPath $source)) {
    throw "Launcher source was not found."
}
if (-not $OutputPath) {
    $OutputPath = Join-Path $scriptDir "CodexZH.exe"
}

$output = [IO.Path]::GetFullPath($OutputPath)
& $compiler /nologo /target:winexe /optimize+ "/out:$output" `
    /reference:System.dll `
    /reference:System.Core.dll `
    /reference:System.Drawing.dll `
    /reference:System.Windows.Forms.dll `
    $source

if ($LASTEXITCODE -ne 0) {
    throw "Launcher compilation failed."
}

Get-Item -LiteralPath $output | Select-Object FullName, Length, LastWriteTime
