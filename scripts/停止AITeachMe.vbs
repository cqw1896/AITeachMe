Option Explicit

' Stop AITeachMe services
' No path detection needed - kills processes by name

Dim objShell, objWMI, colProcesses, objProcess
Set objShell = CreateObject("WScript.Shell")
Set objWMI = GetObject("winmgmts:\.\root\cimv2")

Dim intCount
intCount = 0

' Kill uvicorn (backend)
Set colProcesses = objWMI.ExecQuery("SELECT * FROM Win32_Process WHERE CommandLine LIKE '%uvicorn%app.main:app%'")
For Each objProcess In colProcesses
    objProcess.Terminate()
    intCount = intCount + 1
Next

' Kill node (frontend - npm run dev)
Set colProcesses = objWMI.ExecQuery("SELECT * FROM Win32_Process WHERE Name='node.exe' AND CommandLine LIKE '%npm%dev%'")
For Each objProcess In colProcesses
    objProcess.Terminate()
    intCount = intCount + 1
Next

Set objShell = Nothing
Set objWMI = Nothing

If intCount > 0 Then
    MsgBox "已停止 " & intCount & " 个 AITeachMe 相关进程", vbInformation, "AITeachMe 停止器"
Else
    MsgBox "未找到运行中的 AITeachMe 进程", vbInformation, "AITeachMe 停止器"
End If
