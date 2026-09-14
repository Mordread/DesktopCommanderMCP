$ErrorActionPreference = 'Stop'
$taskName = 'Desktop Commander MainRig'
$state = Join-Path $env:LOCALAPPDATA 'DesktopCommanderMCP-MainRig'
$log = Join-Path $state 'restart.log'
if (-not (Test-Path $state)) { New-Item -ItemType Directory -Path $state | Out-Null }
function Log([string]$m) { Add-Content $log "[$(Get-Date -Format o)] $m" }
$remote = @(Get-CimInstance Win32_Process -Filter "Name='node.exe'" | Where-Object { $_.CommandLine -match 'dist[\\/]+index\.js\s+remote(?:\s|$)' })
if ($remote.Count -gt 1) { Log "Refusing restart with $($remote.Count) remotes."; exit 5 }
$oldPid = if ($remote.Count -eq 1) { [int]$remote[0].ProcessId } else { 0 }
$cmdPid = 0
if ($oldPid) {
  $cmd = Get-CimInstance Win32_Process -Filter "ProcessId=$($remote[0].ParentProcessId)"
  if ($cmd.Name -ne 'cmd.exe' -or $cmd.CommandLine -notmatch 'start-remote\.cmd') { Log 'Remote supervisor shape invalid.'; exit 6 }
  $cmdPid = [int]$cmd.ProcessId
}
Log "Restart requested; old_remote=$oldPid supervisor=$cmdPid."
Stop-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
if ($cmdPid -and (Get-Process -Id $cmdPid -ErrorAction SilentlyContinue)) { & taskkill.exe /PID $cmdPid /T /F | Out-Null }
$deadline = (Get-Date).AddSeconds(15)
do { Start-Sleep -Milliseconds 250; $left = @(Get-CimInstance Win32_Process -Filter "Name='node.exe'" | Where-Object { $_.CommandLine -match 'dist[\\/]+index\.js\s+remote(?:\s|$)' }) } while ($left.Count -ne 0 -and (Get-Date) -lt $deadline)
if ($left.Count -ne 0) { Log "Old remote still present; count=$($left.Count)."; exit 3 }
Start-ScheduledTask -TaskName $taskName
$deadline = (Get-Date).AddSeconds(90)
do { Start-Sleep -Milliseconds 500; $new = @(Get-CimInstance Win32_Process -Filter "Name='node.exe'" | Where-Object { $_.CommandLine -match 'dist[\\/]+index\.js\s+remote(?:\s|$)' }) } while (($new.Count -ne 1 -or $new[0].ProcessId -eq $oldPid) -and (Get-Date) -lt $deadline)
if ($new.Count -ne 1 -or $new[0].ProcessId -eq $oldPid) { Log "Restart failed; new_count=$($new.Count)."; exit 4 }
Log "Restart complete; new_remote=$($new[0].ProcessId)."
