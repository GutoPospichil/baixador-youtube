' Abre o aplicativo sem exibir nenhuma janela de console
On Error Resume Next

Set fso = CreateObject("Scripting.FileSystemObject")
Set sh = CreateObject("WScript.Shell")

scriptDir = fso.GetParentFolderName(WScript.ScriptFullName)
sh.CurrentDirectory = scriptDir

sh.Run "pythonw.exe """ & scriptDir & "\app.py""", 0, False

If Err.Number <> 0 Then
    MsgBox "Nao foi possivel iniciar o programa." & vbCrLf & vbCrLf & _
           "Verifique se o Python esta instalado e marcado na opcao " & _
           "'Add Python to PATH'." & vbCrLf & vbCrLf & _
           "Download: https://www.python.org/downloads/", _
           16, "Baixador de Videos do YouTube"
End If
