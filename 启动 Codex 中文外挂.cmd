@echo off
set "GUI=%~dp0CodexZH.exe"
if not exist "%GUI%" (
    echo CodexZH.exe was not found.
    echo Keep the complete Codex-ZH-Localizer folder together.
    pause
    exit /b 1
)
start "" "%GUI%"
exit /b 0
