@echo off
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0arm-handoff.ps1" %*
exit /b %ERRORLEVEL%
