Option Explicit

Dim shell, launcher, command, rc
Set shell = CreateObject("WScript.Shell")
launcher = "C:\Dev\AI\DesktopCommanderMCP\scripts\mainrig\start-remote.cmd"
command = Chr(34) & shell.ExpandEnvironmentStrings("%ComSpec%") & Chr(34) & _
          " /d /c " & Chr(34) & Chr(34) & launcher & Chr(34) & Chr(34)
rc = shell.Run(command, 0, True)
WScript.Quit rc
