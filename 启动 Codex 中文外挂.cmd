@echo off
set "SCRIPT=%~dp0start-localizer.ps1"
if not exist "%SCRIPT%" (
    echo Launcher files were not found.
    echo Keep the complete Codex-ZH-Localizer folder together.
    pause
    exit /b 1
)
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT%"
pause
