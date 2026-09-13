$ErrorActionPreference = 'Stop'

$repo = 'C:\Dev\AI\DesktopCommanderMCP'
$taskName = 'Desktop Commander MainRig'
$deviceFile = Join-Path $env:USERPROFILE '.desktop-commander-device\device.json'
$expectedChild = Join-Path $repo 'dist\index.js'
$expectedWrapper = Join-Path $repo 'scripts\mainrig\start-remote-hidden.vbs'
$expectedWscript = Join-Path $env:SystemRoot 'System32\wscript.exe'
$problems = [System.Collections.Generic.List[string]]::new()

$commit = (& git -C $repo rev-parse --short HEAD 2>$null).Trim()
$branch = (& git -C $repo branch --show-current 2>$null).Trim()
$dirty = -not [string]::IsNullOrWhiteSpace((& git -C $repo status --porcelain 2>$null) -join '')

$remote = @(Get-CimInstance Win32_Process -Filter "Name='node.exe'" | Where-Object {
  $_.CommandLine -match 'dist[\\/]+index\.js\s+remote(?:\s|$)'
})
if ($remote.Count -ne 1) { $problems.Add("expected 1 remote process, found $($remote.Count)") }

$forkChild = $null
$ownerOk = $false
if ($remote.Count -eq 1) {
  $children = @(Get-CimInstance Win32_Process | Where-Object {
    $_.ParentProcessId -eq $remote[0].ProcessId -and $_.Name -eq 'node.exe' -and
    $_.CommandLine -like "*$expectedChild*"
  })
  if ($children.Count -ne 1) { $problems.Add("fork MCP child mismatch; found $($children.Count)") }
  else { $forkChild = $children[0] }

  $parent = Get-CimInstance Win32_Process -Filter "ProcessId=$($remote[0].ParentProcessId)"
  $grand = if ($parent) { Get-CimInstance Win32_Process -Filter "ProcessId=$($parent.ParentProcessId)" } else { $null }
  $ownerOk = ($parent -and $parent.Name -eq 'cmd.exe' -and $grand -and $grand.Name -eq 'wscript.exe' -and
    $grand.CommandLine -like "*$expectedWrapper*")
  if (-not $ownerOk) { $problems.Add('remote is not owned by windowless scheduled launcher') }
}

$task = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
if (-not $task) { $problems.Add('startup task missing') }
else {
  if ($task.State -ne 'Running') { $problems.Add("startup task is $($task.State), expected Running") }
  $action = @($task.Actions)[0]
  if (-not $action -or $action.Execute -ne $expectedWscript -or $action.Arguments -notlike "*$expectedWrapper*") {
    $problems.Add('startup task action is not the windowless wrapper')
  }
}
$taskInfo = if ($task) { $task | Get-ScheduledTaskInfo } else { $null }
$taskResult = if (-not $taskInfo) { 'n/a' }
  elseif ($task.State -eq 'Running' -and $taskInfo.LastTaskResult -eq 267009) { 'RUNNING (0x41301)' }
  else { [string]$taskInfo.LastTaskResult }
$deviceId = if (Test-Path $deviceFile) { (Get-Content $deviceFile -Raw | ConvertFrom-Json).deviceId } else { $null }
if (-not $deviceId) { $problems.Add('device identity missing') }

$wslOk = $false
try {
  $probe = & wsl.exe -d Ubuntu -- bash -lc 'printf WSL_OK' 2>$null
  $wslOk = ($LASTEXITCODE -eq 0 -and ($probe -join '') -eq 'WSL_OK')
} catch {}
if (-not $wslOk) { $problems.Add('Ubuntu WSL probe failed') }

Write-Output 'Desktop Commander MainRig'
Write-Output "  Repo:       $repo"
Write-Output "  Git:        $branch@$commit$(if($dirty){' (dirty)'})"
Write-Output "  Device:     $(if($deviceId){$deviceId}else{'MISSING'})"
Write-Output "  Remote PID: $(if($remote.Count -eq 1){$remote[0].ProcessId}else{"count=$($remote.Count)"})"
Write-Output "  Fork child: $(if($forkChild){$forkChild.ProcessId}else{'MISSING'})"
Write-Output "  Owner:      $(if($ownerOk){'windowless scheduled task'}else{'INVALID'})"
Write-Output "  Task:       $(if($task){$task.State}else{'MISSING'})"
Write-Output "  Last result: $taskResult"
Write-Output "  WSL Ubuntu: $(if($wslOk){'OK'}else{'FAIL'})"

if ($problems.Count -eq 0) { Write-Output 'STATUS: HEALTHY'; exit 0 }
Write-Output ('STATUS: UNHEALTHY - ' + ($problems -join '; '))
exit 1
