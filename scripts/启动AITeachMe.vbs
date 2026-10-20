Option Explicit

Dim objShell, objFSO, strEnvFile, strBackendDir, strFrontendDir
Dim strLLMKey, strLLMURL, strAppMode

Set objShell = CreateObject("WScript.Shell")
Set objFSO = CreateObject("Scripting.FileSystemObject")

strBackendDir = "C:\AITeachMe\AITeachMe\backend"
strEnvFile = strBackendDir & "\.env"

If Not objFSO.FileExists(strEnvFile) Then
    MsgBox "配置文件未找到，请先配置 .env 文件", vbExclamation
    WScript.Quit
End If

Dim objFile, strLine, intPos, strKey, strValue
Set objFile = objFSO.OpenTextFile(strEnvFile, 1)

strLLMKey = ""
strLLMURL = ""
strAppMode = "local"

While Not objFile.AtEndOfStream
    strLine = Trim(objFile.ReadLine)
    
    If Len(strLine) > 0 And Left(strLine, 1) <> "#" Then
        If InStr(strLine, "=") > 0 Then
            intPos = InStr(strLine, "=")
            strKey = Trim(Left(strLine, intPos - 1))
            strValue = Trim(Mid(strLine, intPos + 1))
            
            Select Case strKey
                Case "LLM_API_KEY"
                    strLLMKey = strValue
                Case "LLM_BASE_URL"
                    strLLMURL = strValue
                Case "APP_MODE"
                    strAppMode = strValue
            End Select
        End If
    End If
Wend
objFile.Close

If strLLMKey = "" Or strLLMKey = "YOUR_KIRORS_API_KEY_HERE" Then
    MsgBox "未配置 API 密钥，请编辑 backend\.env 文件", vbExclamation
    objShell.Run "notepad.exe " & strEnvFile, 1
    WScript.Quit
End If

Dim strRedisStatus
strRedisStatus = objShell.Run("sc query Memurai | find ""RUNNING""", 0, True)
If strRedisStatus <> 0 Then
    objShell.Run "net start Memurai", 0, True
End If

objShell.Run "cmd /c cd /d " & strBackendDir & " && .venv\Scripts\activate && set LLM_API_KEY=" & strLLMKey & " && set LLM_BASE_URL=" & strLLMURL & " && set APP_MODE=" & strAppMode & " && start /B uvicorn app.main:app --host 127.0.0.1 --port 9020 > C:\AITeachMe\backend.log 2>&1", 0, False

WScript.Sleep 8000

strFrontendDir = "C:\AITeachMe\AITeachMe\frontend"
objShell.Run "cmd /c cd /d " & strFrontendDir & " && start /B npm run dev > C:\AITeachMe\frontend.log 2>&1", 0, False

WScript.Sleep 5000

objShell.Run "http://127.0.0.1:5180", 1

Set objShell = Nothing
Set objFSO = Nothing
