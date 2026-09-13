$ErrorActionPreference = 'Stop'

$taskName = 'Desktop Commander MainRig'
$launcher = 'C:\Dev\AI\DesktopCommanderMCP\scripts\mainrig\start-remote.cmd'
$userId = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
$cmd = Join-Path $env:SystemRoot 'System32\cmd.exe'

$action = New-ScheduledTaskAction -Execute $cmd -Argument "/d /c `"`"$launcher`"`""
$trigger = New-ScheduledTaskTrigger -AtLogOn -User $userId
$principal = New-ScheduledTaskPrincipal -UserId $userId -LogonType Interactive -RunLevel Limited
$settings = New-ScheduledTaskSettingsSet `
  -MultipleInstances IgnoreNew `
  -RestartCount 10 `
  -RestartInterval (New-TimeSpan -Minutes 1) `
  -StartWhenAvailable `
  -ExecutionTimeLimit ([TimeSpan]::Zero) `
  -AllowStartIfOnBatteries `
  -DontStopIfGoingOnBatteries `
  -Hidden

Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger `
  -Principal $principal -Settings $settings -Description 'MainRig Desktop Commander downstream remote device' -Force | Out-Null

Get-ScheduledTask -TaskName $taskName | Get-ScheduledTaskInfo
