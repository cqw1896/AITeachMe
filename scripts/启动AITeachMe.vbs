Option Explicit

' Auto-detect project root directory
Dim objShell, objFSO, strScriptPath, strProjectRoot, strBackendDir, strFrontendDir
Dim strEnvFile, strLLMKey, strLLMURL, strAppMode

Set objShell = CreateObject("WScript.Shell")
Set objFSO = CreateObject("Scripting.FileSystemObject")

' Get script directory
strScriptPath = objFSO.GetParentFolderName(WScript.ScriptFullName)

' Strategy 1: Script in project root
If objFSO.FolderExists(strScriptPath & "\backend") Then
    strProjectRoot = strScriptPath
' Strategy 2: Script in scripts/ subdirectory
ElseIf objFSO.FolderExists(objFSO.GetParentFolderName(strScriptPath) & "\backend") Then
    strProjectRoot = objFSO.GetParentFolderName(strScriptPath)
' Strategy 3: Search from current directory upward
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

' Strategy 4: Prompt user if not found
If IsEmpty(strProjectRoot) Or strProjectRoot = "" Then
    strProjectRoot = InputBox("无法自动检测项目路径" & vbCrLf & vbCrLf & _
                              "请输入 AITeachMe 项目根目录路径：" & vbCrLf & _
                              "（示例：C:\AITeachMe\AITeachMe）", _
                              "AITeachMe 启动器")
    If strProjectRoot = "" Then WScript.Quit
End If

' Verify project path
If Not objFSO.FolderExists(strProjectRoot & "\backend") Then
    MsgBox "无效的项目路径，找不到 backend 目录：" & vbCrLf & strProjectRoot, vbExclamation, "错误"
    WScript.Quit
End If

' Set directories
strBackendDir = strProjectRoot & "\backend"
strFrontendDir = strProjectRoot & "\frontend"
strEnvFile = strBackendDir & "\.env"

' Check .env file
If Not objFSO.FileExists(strEnvFile) Then
    MsgBox "配置文件未找到，请先配置 .env 文件：" & vbCrLf & strEnvFile, vbExclamation, "配置错误"
    WScript.Quit
End If

' Read .env configuration
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

' Validate API key
If strLLMKey = "" Or strLLMKey = "YOUR_KIRORS_API_KEY_HERE" Then
    MsgBox "未配置 API 密钥，请编辑 backend\.env 文件", vbExclamation, "配置错误"
    objShell.Run "notepad.exe " & strEnvFile, 1
    WScript.Quit
End If

' Start Redis (Memurai)
Dim strRedisStatus
strRedisStatus = objShell.Run("sc query Memurai | find ""RUNNING""", 0, True)
If strRedisStatus <> 0 Then
    objShell.Run "net start Memurai", 0, True
End If

' Get log directory (use parent directory of project root)
Dim strLogDir
strLogDir = objFSO.GetParentFolderName(strProjectRoot)

' Start backend
objShell.Run "cmd /c cd /d " & strBackendDir & " && .venv\Scripts\activate && set LLM_API_KEY=" & strLLMKey & " && set LLM_BASE_URL=" & strLLMURL & " && set APP_MODE=" & strAppMode & " && start /B uvicorn app.main:app --host 127.0.0.1 --port 9020 > " & strLogDir & "\backend.log 2>&1", 0, False

WScript.Sleep 8000

' Start frontend
objShell.Run "cmd /c cd /d " & strFrontendDir & " && start /B npm run dev > " & strLogDir & "\frontend.log 2>&1", 0, False

WScript.Sleep 5000

' Open browser
objShell.Run "http://127.0.0.1:5180", 1

Set objShell = Nothing
Set objFSO = Nothing
