#$language = "VBScript"
#$interface = "1.0"

crt.Screen.Synchronous = True

' This automatically generated script may need to be
' edited in order to work correctly.

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
