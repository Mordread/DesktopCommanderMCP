@echo off
setlocal
set "REPO=C:\Dev\AI\DesktopCommanderMCP"
set "STATE=%LOCALAPPDATA%\DesktopCommanderMCP-MainRig"
set "LOG=%STATE%\remote.log"

if not exist "%STATE%" mkdir "%STATE%"
cd /d "%REPO%" || exit /b 1

> "%LOG%" echo [%date% %time%] Starting MainRig Desktop Commander fork
call npm.cmd run build >> "%LOG%" 2>&1 || exit /b 1
node.exe dist\index.js remote %* >> "%LOG%" 2>&1
