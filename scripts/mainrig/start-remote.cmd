@echo off
setlocal
set "REPO=C:\Dev\AI\DesktopCommanderMCP"
set "HOME=%LOCALAPPDATA%\DesktopCommanderMCP-MainRig\home"

if not exist "%HOME%" mkdir "%HOME%"
cd /d "%REPO%" || exit /b 1

call npm.cmd run build || exit /b 1
node.exe dist\index.js remote %*
