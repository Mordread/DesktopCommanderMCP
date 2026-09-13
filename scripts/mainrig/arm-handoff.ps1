$ErrorActionPreference = 'Stop'
$taskName = 'Desktop Commander MainRig Handoff'
$helper = 'C:\Dev\AI\DesktopCommanderMCP\scripts\mainrig\handoff-helper.ps1'
$userId = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
$remote = @(Get-CimInstance Win32_Process -Filter "Name='node.exe'" | Where-Object {
  $_.CommandLine -match 'dist[\\/]+index\.js\s+remote(?:\s|$)'
})
if ($remote.Count -ne 1) { throw "Expected exactly one remote process, found $($remote.Count)." }
$oldPid = [int]$remote[0].ProcessId
$powershell = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
$args = "-NoLogo -NoProfile -ExecutionPolicy Bypass -File `"$helper`" -OldPid $oldPid"
$action = New-ScheduledTaskAction -Execute $powershell -Argument $args
$principal = New-ScheduledTaskPrincipal -UserId $userId -LogonType Interactive -RunLevel Limited
$settings = New-ScheduledTaskSettingsSet -MultipleInstances IgnoreNew -ExecutionTimeLimit (New-TimeSpan -Minutes 3) -Hidden
Register-ScheduledTask -TaskName $taskName -Action $action -Principal $principal -Settings $settings -Force | Out-Null
Start-ScheduledTask -TaskName $taskName
Write-Output "HANDOFF_ARMED old_pid=$oldPid task=$taskName"
