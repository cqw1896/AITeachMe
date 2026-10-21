Option Explicit

Dim objShell, objFSO, strScriptPath, strProjectRoot, strBackendDir, strFrontendDir
Dim strEnvFile, strLLMKey, strLLMURL, strAppMode

Set objShell = CreateObject("WScript.Shell")
Set objFSO = CreateObject("Scripting.FileSystemObject")

strScriptPath = objFSO.GetParentFolderName(WScript.ScriptFullName)

If objFSO.FolderExists(strScriptPath & "\backend") Then
    strProjectRoot = strScriptPath
ElseIf objFSO.FolderExists(objFSO.GetParentFolderName(strScriptPath) & "\backend") Then
    strProjectRoot = objFSO.GetParentFolderName(strScriptPath)
Else
    Dim strCurrentDir, strParentDir
    strCurrentDir = objShell.CurrentDirectory
    Do While Len(strCurrentDir) > 3
        If objFSO.FolderExists(strCurrentDir & "\backend\app\workflows\ingest\parsing") Then
            strProjectRoot = strCurrentDir
            Exit Do
        End If
        strParentDir = objFSO.GetParentFolderName(strCurrentDir)
        If strParentDir = strCurrentDir Then Exit Do
        strCurrentDir = strParentDir
    Loop
End If

If IsEmpty(strProjectRoot) Or strProjectRoot = "" Then
    strProjectRoot = InputBox("Cannot detect project path. Enter AITeachMe root path:", "AITeachMe Launcher")
    If strProjectRoot = "" Then WScript.Quit
End If

If Not objFSO.FolderExists(strProjectRoot & "\backend") Then
    MsgBox "Invalid path. Backend not found: " & strProjectRoot, vbExclamation
    WScript.Quit
End If

strBackendDir = strProjectRoot & "\backend"
strFrontendDir = strProjectRoot & "\frontend"
strEnvFile = strBackendDir & "\.env"

If Not objFSO.FileExists(strEnvFile) Then
    MsgBox "Config not found: " & strEnvFile, vbExclamation
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
    MsgBox "API key not configured", vbExclamation
    objShell.Run "notepad.exe " & strEnvFile, 1
    WScript.Quit
End If

Dim strRedisStatus
strRedisStatus = objShell.Run("sc query Memurai | find ""RUNNING""", 0, True)
If strRedisStatus <> 0 Then
    objShell.Run "net start Memurai", 0, True
End If

Dim strLogDir
strLogDir = objFSO.GetParentFolderName(strProjectRoot)

objShell.Run "cmd /c cd /d " & strBackendDir & " && .venv\Scripts\activate && set LLM_API_KEY=" & strLLMKey & " && set LLM_BASE_URL=" & strLLMURL & " && set APP_MODE=" & strAppMode & " && start /B uvicorn app.main:app --host 127.0.0.1 --port 9020 > " & strLogDir & "\backend.log 2>&1", 0, False

WScript.Sleep 8000

objShell.Run "cmd /c cd /d " & strFrontendDir & " && start /B npm run dev > " & strLogDir & "\frontend.log 2>&1", 0, False

WScript.Sleep 5000

objShell.Run "http://127.0.0.1:5180", 1

Set objShell = Nothing
Set objFSO = Nothing
