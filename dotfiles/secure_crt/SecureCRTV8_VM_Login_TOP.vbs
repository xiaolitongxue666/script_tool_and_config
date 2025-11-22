#$language = "VBScript"
#$interface = "1.0"

crt.Screen.Synchronous = True

' 此自动生成的脚本可能需要
' 编辑才能正常工作

Sub Main
	crt.Screen.WaitForString "ogin:"
	crt.Sleep 500
	crt.Screen.Send "root" & chr(13)
	crt.Screen.WaitForString "assword:"
	crt.Sleep 500
	crt.Screen.Send "gospell" & chr(13)
	crt.Sleep 500
	crt.Screen.Send "top -d 1" & chr(13)
	crt.Sleep 500
	crt.Screen.Send "1" & chr(13)
End Sub
