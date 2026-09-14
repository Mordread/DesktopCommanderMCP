$ErrorActionPreference = 'Stop'

$taskName = 'Desktop Commander MainRig'
$wrapper = 'C:\Dev\AI\DesktopCommanderMCP\scripts\mainrig\start-remote-hidden.vbs'
$userId = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
$wscript = Join-Path $env:SystemRoot 'System32\wscript.exe'

$action = New-ScheduledTaskAction -Execute $wscript -Argument "//B //NoLogo `"$wrapper`""
$trigger = New-ScheduledTaskTrigger -AtLogOn -User $userId
$principal = New-ScheduledTaskPrincipal -UserId $userId -LogonType Interactive -RunLevel Limited
$settings = New-ScheduledTaskSettingsSet `
  -MultipleInstances IgnoreNew `
  -StartWhenAvailable `
  -ExecutionTimeLimit ([TimeSpan]::Zero) `
  -AllowStartIfOnBatteries `
  -DontStopIfGoingOnBatteries `
  -Hidden

Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger `
  -Principal $principal -Settings $settings `
  -Description 'MainRig Desktop Commander windowless supervised remote device' -Force | Out-Null

Get-ScheduledTask -TaskName $taskName | Get-ScheduledTaskInfo
