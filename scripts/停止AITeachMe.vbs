Option Explicit

Dim objShell, objWMI, colProcesses, objProcess
Set objShell = CreateObject("WScript.Shell")
Set objWMI = GetObject("winmgmts:\.\root\cimv2")

Dim intCount
intCount = 0

Set colProcesses = objWMI.ExecQuery("SELECT * FROM Win32_Process WHERE CommandLine LIKE '%uvicorn%app.main:app%'")
For Each objProcess In colProcesses
    objProcess.Terminate()
    intCount = intCount + 1
Next

Set colProcesses = objWMI.ExecQuery("SELECT * FROM Win32_Process WHERE Name='node.exe' AND CommandLine LIKE '%npm%dev%'")
For Each objProcess In colProcesses
    objProcess.Terminate()
    intCount = intCount + 1
Next

Set objShell = Nothing
Set objWMI = Nothing

If intCount > 0 Then
    MsgBox "Stopped " & intCount & " AITeachMe processes", vbInformation
Else
    MsgBox "No running AITeachMe processes found", vbInformation
End If
