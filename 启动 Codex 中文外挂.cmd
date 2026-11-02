@echo off
set "GUI=%~dp0gui.ps1"
if not exist "%GUI%" (
    echo GUI files were not found.
    echo Keep the complete Codex-ZH-Localizer folder together.
    pause
    exit /b 1
)
start "" powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "%GUI%"
exit /b 0
