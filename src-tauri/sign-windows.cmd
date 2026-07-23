@echo off
REM Called by Tauri bundle.windows.signCommand with the artifact path as %1
setlocal
set "SCRIPT=%~dp0..\scripts\sign-windows.ps1"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT%" %*
exit /b %ERRORLEVEL%
