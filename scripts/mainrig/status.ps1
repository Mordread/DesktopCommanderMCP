$ErrorActionPreference = 'Stop'

$repo = 'C:\Dev\AI\DesktopCommanderMCP'
$taskName = 'Desktop Commander MainRig'
$deviceFile = Join-Path $env:USERPROFILE '.desktop-commander-device\device.json'
$problems = [System.Collections.Generic.List[string]]::new()

$commit = (& git -C $repo rev-parse --short HEAD 2>$null).Trim()
$branch = (& git -C $repo branch --show-current 2>$null).Trim()
$dirty = -not [string]::IsNullOrWhiteSpace((& git -C $repo status --porcelain 2>$null) -join '')

$remote = @(Get-CimInstance Win32_Process -Filter "Name='node.exe'" | Where-Object {
  $_.CommandLine -match 'dist[\\/]+index\.js\s+remote(?:\s|$)'
})
if ($remote.Count -ne 1) { $problems.Add("expected 1 remote process, found $($remote.Count)") }

$task = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
if (-not $task) { $problems.Add('startup task missing') }
$taskInfo = if ($task) { $task | Get-ScheduledTaskInfo } else { $null }

$deviceId = if (Test-Path $deviceFile) {
  (Get-Content $deviceFile -Raw | ConvertFrom-Json).deviceId
} else { $null }
if (-not $deviceId) { $problems.Add('device identity missing') }
$wslOk = $false
try {
  $probe = & wsl.exe -d Ubuntu -- bash -lc 'printf WSL_OK' 2>$null
  $wslOk = ($LASTEXITCODE -eq 0 -and ($probe -join '') -eq 'WSL_OK')
} catch {}
if (-not $wslOk) { $problems.Add('Ubuntu WSL probe failed') }

Write-Output "Desktop Commander MainRig"
Write-Output "  Repo:       $repo"
Write-Output "  Git:        $branch@$commit$(if($dirty){' (dirty)'})"
Write-Output "  Device:     $(if($deviceId){$deviceId}else{'MISSING'})"
Write-Output "  Remote PID: $(if($remote.Count -eq 1){$remote[0].ProcessId}else{"count=$($remote.Count)"})"
Write-Output "  Task:       $(if($task){$task.State}else{'MISSING'})"
Write-Output "  Last result:$(if($taskInfo){' ' + $taskInfo.LastTaskResult}else{' n/a'})"
Write-Output "  WSL Ubuntu: $(if($wslOk){'OK'}else{'FAIL'})"

if ($problems.Count -eq 0) {
  Write-Output 'STATUS: HEALTHY'
  exit 0
}
Write-Output ('STATUS: UNHEALTHY - ' + ($problems -join '; '))
exit 1
