$ErrorActionPreference = 'Stop'

$taskName = 'Desktop Commander MainRig'
$watchTaskName = 'Desktop Commander MainRig Watchdog'
$restartTaskName = 'Desktop Commander MainRig Restart'
$root = 'C:\Dev\AI\DesktopCommanderMCP\scripts\mainrig'
$wrapper = Join-Path $root 'start-remote-hidden.vbs'
$watchdog = Join-Path $root 'watchdog-hidden.vbs'
$restartWrapper = Join-Path $root 'restart-hidden.vbs'
$userId = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
$wscript = Join-Path $env:SystemRoot 'System32\wscript.exe'

$action = New-ScheduledTaskAction -Execute $wscript -Argument "//B //NoLogo `"$wrapper`""
$trigger = New-ScheduledTaskTrigger -AtLogOn -User $userId
$principal = New-ScheduledTaskPrincipal -UserId $userId -LogonType Interactive -RunLevel Limited
$settings = New-ScheduledTaskSettingsSet -MultipleInstances IgnoreNew -StartWhenAvailable `
  -ExecutionTimeLimit ([TimeSpan]::Zero) -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -Hidden
Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal `
  -Settings $settings -Description 'MainRig Desktop Commander windowless supervised remote device' -Force | Out-Null

$watchAction = New-ScheduledTaskAction -Execute $wscript -Argument "//B //NoLogo `"$watchdog`""
$watchLogon = New-ScheduledTaskTrigger -AtLogOn -User $userId
$watchPoll = New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(1) -RepetitionInterval (New-TimeSpan -Minutes 1)
$watchSettings = New-ScheduledTaskSettingsSet -MultipleInstances IgnoreNew -StartWhenAvailable `
  -ExecutionTimeLimit (New-TimeSpan -Seconds 30) -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -Hidden
Register-ScheduledTask -TaskName $watchTaskName -Action $watchAction -Trigger @($watchLogon, $watchPoll) `
  -Principal $principal -Settings $watchSettings -Description 'MainRig Desktop Commander windowless outer watchdog' -Force | Out-Null

$restartAction = New-ScheduledTaskAction -Execute $wscript -Argument "//B //NoLogo `"$restartWrapper`""
$restartSettings = New-ScheduledTaskSettingsSet -MultipleInstances IgnoreNew `
  -ExecutionTimeLimit (New-TimeSpan -Minutes 1) -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -Hidden
Register-ScheduledTask -TaskName $restartTaskName -Action $restartAction -Principal $principal `
  -Settings $restartSettings -Description 'MainRig Desktop Commander windowless independent restart helper' -Force | Out-Null

Get-ScheduledTask -TaskName $taskName, $watchTaskName, $restartTaskName | `
  Select-Object TaskName, State