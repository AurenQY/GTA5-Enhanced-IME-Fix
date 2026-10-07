' Steam 启动项: wscript.exe "本文件完整路径" %command%
' 无控制台窗口: 后台隐藏运行 ps1 监视器, 前台启动游戏并等待其退出 (让 Steam 正确识别游戏状态)
Option Explicit
Dim sh, fso, dir, i, cmd, arg
Set sh = CreateObject("WScript.Shell")
Set fso = CreateObject("Scripting.FileSystemObject")
dir = fso.GetParentFolderName(WScript.ScriptFullName)

sh.Run "powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File """ & dir & "\GTA5_EN_IME.ps1""", 0, False

cmd = ""
For i = 0 To WScript.Arguments.Count - 1
    arg = WScript.Arguments(i)
    If InStr(arg, " ") > 0 Then arg = """" & arg & """"
    cmd = cmd & arg & " "
Next
If Len(cmd) > 0 Then sh.Run cmd, 1, True
