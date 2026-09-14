@echo off
setlocal EnableExtensions EnableDelayedExpansion
set "REPO=C:\Dev\AI\DesktopCommanderMCP"
set "STATE=%LOCALAPPDATA%\DesktopCommanderMCP-MainRig"
set "LOG=%STATE%\remote.log"
set "LAUNCHLOG=%STATE%\launcher.log"
set /a "RESTART_DELAY=5"
set /a "MAX_RESTART_DELAY=60"

if not exist "%STATE%" mkdir "%STATE%" 2>nul
powershell.exe -NoProfile -Command "$p=Get-CimInstance Win32_Process; if($p.CommandLine -match 'dist[\\/]+index\.js\s+remote(?:\s|$)'){exit 42}" >nul 2>&1
if errorlevel 42 (
  >> "%LAUNCHLOG%" echo [%date% %time%] Remote already running; launcher exiting.
  exit /b 0
)

cd /d "%REPO%" || exit /b 1
if not exist "dist\index.js" (
  >> "%LAUNCHLOG%" echo [%date% %time%] dist missing; building fork.
  call npm.cmd run build >> "%LOG%" 2>&1 || exit /b 1
)

:run_remote
powershell.exe -NoProfile -Command "$p=Get-CimInstance Win32_Process; if($p.CommandLine -match 'dist[\\/]+index\.js\s+remote(?:\s|$)'){exit 42}" >nul 2>&1
if errorlevel 42 (
  >> "%LAUNCHLOG%" echo [%date% %time%] Another remote appeared; supervisor exiting.
  exit /b 0
)

>> "%LAUNCHLOG%" echo [%date% %time%] Starting MainRig Desktop Commander fork.
node.exe dist\index.js remote %* >> "%LOG%" 2>&1
set "RC=!ERRORLEVEL!"
if "!RC!"=="0" (
  >> "%LAUNCHLOG%" echo [%date% %time%] Remote exited cleanly with code 0.
  exit /b 0
)

>> "%LAUNCHLOG%" echo [%date% %time%] Remote exited unexpectedly with code !RC!; restarting in !RESTART_DELAY! seconds.
timeout /t !RESTART_DELAY! /nobreak >nul
set /a "RESTART_DELAY*=2"
if !RESTART_DELAY! GTR !MAX_RESTART_DELAY! set /a "RESTART_DELAY=MAX_RESTART_DELAY"
goto run_remote
