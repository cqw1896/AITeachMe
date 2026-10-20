' AITeachMe 停止脚本
Option Explicit

Dim objShell, intResult

Set objShell = CreateObject("WScript.Shell")

' 停止后端（uvicorn 进程）
objShell.Run "taskkill /F /IM uvicorn.exe /T", 0, True

' 停止前端（node 进程中的 vite）
objShell.Run "taskkill /F /FI ""WINDOWTITLE eq npm*"" /T", 0, True
objShell.Run "taskkill /F /FI ""IMAGENAME eq node.exe"" /FI ""COMMANDLINE eq *vite*"" /T", 0, True

WScript.Sleep 2000

Set objShell = Nothing
