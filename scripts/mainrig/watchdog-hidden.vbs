Option Explicit
Dim svc, procs, p, found, shell, fso, state, log, taskName, cmd, rc
found = False
taskName = "Desktop Commander MainRig"
Set svc = GetObject("winmgmts:\\.\root\cimv2")
Set procs = svc.ExecQuery("SELECT CommandLine FROM Win32_Process WHERE Name='node.exe'")
For Each p In procs
  If Not IsNull(p.CommandLine) Then
    If InStr(1, p.CommandLine, "dist\index.js remote", vbTextCompare) > 0 Or _
       InStr(1, p.CommandLine, "dist/index.js remote", vbTextCompare) > 0 Then found = True
  End If
Next
If found Then WScript.Quit 0
Set shell = CreateObject("WScript.Shell")
cmd = Chr(34) & shell.ExpandEnvironmentStrings("%SystemRoot%") & "\System32\schtasks.exe" & Chr(34) & _
      " /run /tn " & Chr(34) & taskName & Chr(34)
rc = shell.Run(cmd, 0, True)
Set fso = CreateObject("Scripting.FileSystemObject")
state = shell.ExpandEnvironmentStrings("%LOCALAPPDATA%") & "\DesktopCommanderMCP-MainRig"
If Not fso.FolderExists(state) Then fso.CreateFolder(state)
Set log = fso.OpenTextFile(state & "\watchdog.log", 8, True)
log.WriteLine Now & " remote missing; schtasks rc=" & rc
log.Close
WScript.Quit rc