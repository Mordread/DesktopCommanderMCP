@echo off
setlocal EnableExtensions
set "REPO=C:\Dev\AI\DesktopCommanderMCP"
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%REPO%\scripts\mainrig\ensure-build.ps1" -Build
if errorlevel 1 exit /b %ERRORLEVEL%
echo MainRig build stamped successfully. RDC was NOT restarted.
echo Run scripts\mainrig\restart.cmd only after explicit restart approval.
exit /b 0