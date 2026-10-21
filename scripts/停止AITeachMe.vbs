Option Explicit

Dim objShell
Set objShell = CreateObject("WScript.Shell")

Dim intCount
intCount = 0

On Error Resume Next

objShell.Run "taskkill /F /IM uvicorn.exe", 0, True
If Err.Number = 0 Then
    intCount = intCount + 1
End If
Err.Clear

objShell.Run "taskkill /F /FI ""WINDOWTITLE eq npm*""", 0, True
If Err.Number = 0 Then
    intCount = intCount + 1
End If
Err.Clear

objShell.Run "taskkill /F /FI ""IMAGENAME eq node.exe"" /FI ""COMMANDLINE eq *vite*""", 0, True
If Err.Number = 0 Then
    intCount = intCount + 1
End If

Set objShell = Nothing

MsgBox "AITeachMe processes stopped", vbInformation, "AITeachMe Stopper"
