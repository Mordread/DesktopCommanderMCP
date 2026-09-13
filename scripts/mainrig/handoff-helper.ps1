param(
  [Parameter(Mandatory = $true)][int]$OldPid,
  [int]$TimeoutSeconds = 90
)
$ErrorActionPreference = 'Stop'
$taskName = 'Desktop Commander MainRig'
$state = Join-Path $env:LOCALAPPDATA 'DesktopCommanderMCP-MainRig'
$log = Join-Path $state 'handoff.log'
if (-not (Test-Path $state)) { New-Item -ItemType Directory -Path $state | Out-Null }

Add-Content $log "[$(Get-Date -Format o)] Waiting for remote PID $OldPid to exit."
$deadline = (Get-Date).AddSeconds($TimeoutSeconds)
while (Get-Process -Id $OldPid -ErrorAction SilentlyContinue) {
  if ((Get-Date) -ge $deadline) {
    Add-Content $log "[$(Get-Date -Format o)] Timeout waiting for PID $OldPid."
    exit 2
  }
  Start-Sleep -Milliseconds 250
}

Start-Sleep -Milliseconds 500
Add-Content $log "[$(Get-Date -Format o)] PID $OldPid exited; starting $taskName."
Start-ScheduledTask -TaskName $taskName
exit 0
