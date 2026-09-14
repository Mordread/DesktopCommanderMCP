@echo off
schtasks.exe /run /tn "Desktop Commander MainRig Restart" >nul 2>&1
if errorlevel 1 (
  echo Failed to start Desktop Commander MainRig Restart task.
  exit /b 1
)
echo Desktop Commander MainRig restart initiated.
exit /b 0
