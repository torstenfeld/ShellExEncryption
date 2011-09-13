#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Res_Comment=https://github.com/torstenfeld/ShellExEncryption
#AutoIt3Wrapper_Res_Description=Tool provides option to encrypt and decrypt files via Explorer shellextension
#AutoIt3Wrapper_Res_Fileversion=0.0.0.1
#AutoIt3Wrapper_Res_LegalCopyright=Copyright - Torsten Feld (feldstudie.net)
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****

#Include <WinAPI.au3>
#include <Crypt.au3>
#include <ButtonConstants.au3>
#include <EditConstants.au3>
#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
#Include <Crypt.au3>


Global $gDirTemp = @TempDir & "\shellexencryption"
Global $gDbgFile = $gDirTemp & "\shellexencryptiondbg.log"
Global $gFile = ""
Global $gAction = ""

If FileExists($gDbgFile) Then
	FileDelete($gDbgFile) ; cleaning old logfile
Else
	If Not FileExists($gDirTemp) Then DirCreate($gDirTemp)
EndIf

_CreateShellExHandler()

$gFile = _GetCommandLineParameters()
_CryptFile($gFile, $gAction)

;~ $gResultText = _GenerateChecksums($gFile)

Func _CreateShellExHandler()
	Local $lRegReturn
	Local $lRegKey = "HKEY_CLASSES_ROOT\*\shell\Encrypt or decrypt\command"

	$lRegReturn = RegRead($lRegKey, "")
	If @error Then
		_WriteDebug("WARN;_CreateShellExHandler;ShellExtension not set - creating")
		RegWrite($lRegKey, "", "REG_SZ", @ScriptFullPath & ' "%1"')
		If @error Then _WriteDebug("ERR ;_CreateShellExHandler;Error setting ShellEx: " & @error)
	Else
		_WriteDebug("INFO;_CreateShellExHandler;ShellExtension set")
		If Not ($lRegReturn = @ScriptFullPath & " %1") Then
			_WriteDebug("WARN;_CreateShellExHandler;ShellExtension not set correctly - changing")
			RegWrite($lRegKey, "", "REG_SZ", @ScriptFullPath & ' "%1"')
			If @error Then _WriteDebug("ERR ;_CreateShellExHandler;Error setting ShellEx: " & @error)
		EndIf
	EndIf

EndFunc

Func _CryptFile($lFile, $lAction)

	$Key = "123";_Crypt_DeriveKey(_GuiAskPassword(),$CALG_RC4)

	$lFile2 = $lFile & ".cry"

	If $lAction = "encrypt" Then
		_Crypt_EncryptFile($lFile, $lFile2, $Key, $CALG_AES_128)
		If @error Then MsgBox(16, "Error", "_Crypt_EncryptFile: " & @error)
	Else
		_Crypt_DecryptFile($lFile, $lFile2, $Key, $CALG_AES_128)
	EndIf
	_Crypt_DestroyKey($Key)

EndFunc

Func _GetCommandLineParameters() ; reading parameters

	If $CmdLine[0] <> "" Then
		Switch $CmdLine[1]
			Case "/encrypt"
				$gAction = "encrypt"
				_WriteDebug('INFO;_GetCommandLineParameters;Parameter "' & $CmdLine[1] & '" was chosen')
			Case "/decrypt"
				$gAction = "decrypt"
				_WriteDebug('INFO;_GetCommandLineParameters;Parameter "' & $CmdLine[1] & '" was chosen')
			Case Else
				_WriteDebug('INFO;_GetCommandLineParameters;Parameter "' & $CmdLine[1] & '" not known - Exiting')
				Exit 2
		EndSwitch

		_WriteDebug('INFO;_GetCommandLineParameters;File "' & $CmdLine[2] & '" found')
		Return $CmdLine[2] ;
	Else
		_WriteDebug('INFO;_GetCommandLineParameters;No Parameter found')
		MsgBox(16,"ChecksumGen - Error","No parameter was given",10)
		Exit 1
	EndIf
EndFunc   ;==>_GetCommandLineParameters

Func _GuiAskPassword() ; asks for the password

	Local $sInputBoxAnswer

	$sInputBoxAnswer = InputBox("ShellEncryption","Please enter the password for the encryption:","","*M60","-1","130","-1","-1")
	Select
		Case @Error = 0 ;OK - The string returned is valid
			_WriteDebug("INFO;_GuiAskPassword;User entered password")
			Return $sInputBoxAnswer
		Case @Error = 1 ;The Cancel button was pushed
			_WriteDebug("ERR ;_GuiAskPassword;User cancelled password dialog - Exiting")
			Exit 1
		Case @Error = 3 ;The InputBox failed to open
			_WriteDebug("ERR ;_GuiAskPassword;Password input field could not be created - Exiting")
			Exit 1
	EndSelect
EndFunc

Func _WriteDebug($lParam) ; $lType, $lFunc, $lString) ; creates debuglog for analyzing problems
	Local $lArray[4]
	Local $lResult

;~ 	$lArray[0] bleibt leer
;~ 	$lArray[1] = "Type: "
;~ 	$lArray[2] = "Func: "
;~ 	$lArray[3] = "Desc: "

	Local $lArrayTemp = StringSplit($lParam, ";")
	If @error Then
		Dim $lArrayTemp[4]
;~ 		$lArrayTemp[0] bleibt leer
		$lArrayTemp[1] = "ERR "
		$lArrayTemp[2] = "_WriteDebug"
		$lArrayTemp[3] = "StringSplit failed"
	EndIf

	For $i = 1 To $lArrayTemp[0]
		If $i > 1 Then $lResult = $lResult & @CRLF
		$lResult = $lResult & $lArray[$i] & $lArrayTemp[$i]
	Next

	FileWriteLine($gDbgFile, @MDAY & @MON & @YEAR & " " & @HOUR & ":" & @MIN & ":" & @SEC & "." & @MSEC & " - " & $lArrayTemp[1] & " - " & $lArrayTemp[2] & " - " & $lArrayTemp[3])
	If @error Then MsgBox(16, "ChecksumGen - Error", "Error in FileWriteLine: " & @error)
EndFunc   ;==>_WriteDebug