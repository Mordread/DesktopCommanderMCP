Option Explicit
Dim shell, ps, helper, command, rc
Set shell = CreateObject("WScript.Shell")
ps = shell.ExpandEnvironmentStrings("%SystemRoot%") & "\System32\WindowsPowerShell\v1.0\powershell.exe"
helper = "C:\Dev\AI\DesktopCommanderMCP\scripts\mainrig\restart-helper.ps1"
command = Chr(34) & ps & Chr(34) & _
          " -NoLogo -NoProfile -ExecutionPolicy Bypass -File " & Chr(34) & helper & Chr(34)
rc = shell.Run(command, 0, True)
WScript.Quit rc