﻿InstallFonts(runAgain=False) {
/*		Compare local and installed fonts file size
		If any font is not installed or is different, run FontReg.
*/
	global PROGRAM
	fontsFolder := PROGRAM.FONTS_FOLDER
	winFonts := A_WinDir "\Fonts"

	loc_FontFiles := []
	win_FontFiles := []

;	Get local fonts. Check if they're installed. Also check for duplicates (fontname_0.ttf)
	Loop, Files, %fontsFolder%\*.ttf
	{
		SplitPath, A_LoopFileName, , , , fileNameNoExt
		loc_FontFiles.Push(fileNameNoExt)
		if FileExist(winFonts "\" A_LoopFileName)
			win_FontFiles.Push(fileNameNoExt)
		Loop {
			fileNameDupe := fileNameNoExt "_" A_Index-1
			if !FileExist(winFonts "\" fileNameDupe ".ttf")
				break
			else
				win_FontFiles.Push(fileNameDupe)
		}
	}

;	Remove fonts that are already installed from fontsNeedInstall
	fontsNeedInstall := loc_FontFiles
	for locID, locFontFile in loc_FontFiles {
		for winID, winFontFile in win_FontFiles {
			if RegExMatch(winFontFile, locFontFile "_\d") || (locFontFile = winFontFile) {
				FileGetSize, locSize,% fontsFolder "\" locFontFile ".ttf"
				FileGetSize, winSize,% winFonts "\" winFontFile ".ttf"

				if (locSize = winSize){
					fontsNeedInstall[locID] := ""
				}
			}
		}
	}

;	Get font that need to be installed names and number
	fontsNeedInstall_Index := 0, fontsNeedsInstall_Names := ""
	for id, fontName in fontsNeedInstall {
		if (fontName)
			fontsNeedInstall_Index++, fontsNeedsInstall_Names .= fontName ","
	}
	StringTrimRight, fontsNeedsInstall_Names, fontsNeedsInstall_Names, 1 ; Remove latest comma

;	All fonts are already installed.
	if (!fontsNeedInstall_Index)
		Return

;	Not running as admin. We need UAC to install a font.
	if (!A_IsAdmin && !runAgain) {
		MsgBox(4096, PROGRAM.NAME, "Fonts need to be installed on your system for the tool to work correctly."
			. "`nThe following " fontsNeedInstall_Index " fonts will be installed: "
			. "`n" fontsNeedsInstall_Names
			. "`n"
			. "`nPlease allow the next UAC prompt if asked."
			. "`nRebooting may be neccessary afterwards.")
	}
;	Some fonts are still missing. Require user to install them manually.
	if (runAgain) {
		MsgBox(4096, PROGRAM.NAME, "These " fontsNeedInstall_Index " fonts failed to be installed on your system:"
			. "`n"  fontsNeedsInstall_Names
			. "`n"
			. "`nThe folder containing the fonts will be opening upon closing this box."
			. "`nPlease close " PROGRAM.NAME " and install the fonts manually."
			. "`nRebooting may be neccesary afterwards.")

		Run,% fontsFolder
	}

;	Run FontReg with /Copy to install fonts.
	if !(runAgain) {
		RunWait,% "*RunAs " fontsFolder "\FontReg.exe /Copy",% fontsFolder
		%A_ThisFunc%(True)
	}
}

LoadFonts() {
	Load_Or_Unload_Fonts("LOAD")
}

UnloadFonts() {
	Load_Or_Unload_Fonts("UNLOAD")
}

Load_Or_Unload_Fonts(whatDo) {
	global PROGRAM
	static hCollection
	fontsFolder := PROGRAM.FONTS_FOLDER

	if (whatDo = "LOAD") {
		PROGRAM["FONTS"] := {}
		DllCall(A_ScriptDir "\32_gdiplus.dll\GdipNewPrivateFontCollection", "uint*", hCollection)
	}

	Loop, Files, %fontsFolder%\*.ttf
	{
		fontFile := A_LoopFileFullPath, fontTitle := FGP_Value(A_LoopFileFullPath, 21)	; 21 = Title
		fontName := fontTitle
		if ( whatDo="LOAD") {

			if (!A_IsUnicode) {
				msgbox YOU SHOULDNT SEE THIS
				nSize:=DllCall("kernel32\MultiByteToWideChar", "Uint", 0, "Uint", 0, "Uint", &Fontfile, "int", -1, "Uint", 0, "int", 0)
				VarSetCapacity(wFontfile, nSize * 2 + 1)
				DllCall("kernel32\MultiByteToWideChar", "Uint", 0, "Uint", 0, "Uint", &Fontfile, "int", -1, "Uint", &wFontfile, "int", nSize + 1)

				nSize:=DllCall("kernel32\MultiByteToWideChar", "Uint", 0, "Uint", 0, "Uint", &FontName, "int", -1, "Uint", 0, "int", 0)
				VarSetCapacity(wFontName, nSize * 2 + 1)
				DllCall("kernel32\MultiByteToWideChar", "Uint", 0, "Uint", 0, "Uint", &FontName, "int", -1, "Uint", &wFontName, "int", nSize + 1)

				DllCall("gdiplus\GdipNewPrivateFontCollection", "uint*", hcollection)
				DllCall("gdiplus\GdipPrivateAddFontFile", "uint", hcollection, "uint", &wFontfile)
				DllCall("gdiplus\GdipCreateFontFamilyFromName", "uint", &wFontName, "uint", hcollection, "uint*", hFamily)
			}
    		else {
				; ret1 := DllCall(A_ScriptDir "\32_gdi32.dll\AddFontResourceEx", "Str", fontFile, "UInt", FR_PRIVATE:=0x10, "UInt", 0 ), ret1 .= " " A_LastError " " ErrorLevel
				ret2 := DllCall(A_ScriptDir "\32_gdiplus.dll\GdipPrivateAddFontFile", "uint", hcollection, "uint", &FontFile), ret2 .= " " A_LastError " " ErrorLevel
				hFamily := Gdip_FontFamilyCreate(fontTitle, ret3)
				; ret3 := DllCall(A_ScriptDir "\32_gdiplus.dll\GdipCreateFontFamilyFromName", "uint", &FontName, "uint", hcollection, "uint*", hFamily), ret3 .= " " A_LastError " " ErrorLevel
      		}

/*
			; ret1 := DllCall(A_ScriptDir "\32_gdi32.dll\AddFontResourceEx", "WStr", fontFile, "UInt", (FR_PRIVATE:=0x10), "Int", 0), ret1 .= " " A_LastError " " ErrorLevel
			ret1 := DllCall(A_ScriptDir "\32_gdi32.dll\AddFontResourceEx", "Str", fontFile, "UInt", FR_PRIVATE:=0x10, "UInt", 0 )


			Ptr := A_PtrSize ? "UPtr" : "UInt"
			ret2 := DllCall(A_ScriptDir "\32_gdiplus.dll\GdipPrivateAddFontFile", Ptr, hCollection, Ptr, &fontFile), ret2 .= " " A_LastError " " ErrorLevel

			hFamily := Gdip_FontFamilyCreate(fontTitle, ret3)
			; ret3 := DllCall(A_ScriptDir "\32_gdiplus.dll\GdipCreateFontFamilyFromName", A_PtrSize ? "UPtr" : "UInt", fontTitle, A_PtrSize ? "UPtr" : "UInt", hCollection, A_PtrSize ? "UPtr*" : "UInt*", hFamily), ret3 .= " " A_LastError " " ErrorLevel
*/
			if (hFamily) {
				PROGRAM.FONTS[fontTitle] := hFamily
				AppendToLogs(A_ThisFunc "(): Loaded font file """ A_LoopFileName """ with title """ fontTitle """ inside family """ hFamily """.")
			}
			else
				AppendToLogs(A_ThisFunc "(): Couldn't load font file """ A_LoopFileName """ with title """ fontTitle """ (family=""" hFamily """)!")

			msgStr := "Font title: " fontTitle " - Pointer: " &fontTitle
			. "`nFile: " fontFile " - Pointer: " &fontFile
			. "`nFont collection: " hCollection
			. "`nFont family: " hFamily
			; . "`nAddFontResourceEx(): " ret1
			. "`nGdipPrivateAddFontFile(): " ret2
			. "`nGdipCreateFontFamilyFromName(): " ret3

			fullMsgStr := fullMsgStr ? fullMsgStr "`n`n" msgStr : msgStr
		}
		else if ( whatDo="UNLOAD") {
			Gdip_DeleteFontFamily(PROGRAM.FONTS[fontTitle])
			DllCall( A_ScriptDir "\32_gdi32.dll\RemoveFontResourceEx",Str, A_LoopFileFullPath,UInt,(FR_PRIVATE:=0x10),Int,0)
			AppendToLogs(A_ThisFunc "(): Unloaded font with title """ fontTitle ".")
		}		
	}

	if (fullMsgStr) {
		; FileGetSize, gdi32dllSys32Size,% A_WinDir "\System32\gdi32.dll"
		; gdi32DllSys32Str := FileExist(A_WinDir "\System32\gdi32.dll") ? A_ScriptDir "\32_gdi32.dll found in " A_WinDir "\System32\gdi32.dll - Size: " gdi32dllSys32Size " bytes" : A_ScriptDir "\32_gdi32.dll NOT FOUND IN " A_WinDir "\System32\gdi32.dll"
		; FileGetSize, gdi32dllSys64Size,% A_WinDir "\SysWow64\gdi32.dll"
		; gdi32DllSys64Str := FileExist(A_WinDir "\SysWow64\gdi32.dll") ? A_ScriptDir "\32_gdi32.dll found in " A_WinDir "\SysWow64\gdi32.dll - Size: " gdi32dllSys64Size " bytes" : A_ScriptDir "\32_gdi32.dll NOT FOUND IN " A_WinDir "\SysWow64\gdi32.dll"
		; FileGetSize, gdiplusDllSys32Size,% A_WinDir "\System32\gdiplus.dll"
		; gdiplusDllSys32Str := FileExist(A_WinDir "\System32\gdiplus.dll") ? A_ScriptDir "\32_gdiplus.dll found in " A_WinDir "\System32\gdiplus.dll - Size: " gdiplusDllSys32Size " bytes" : A_ScriptDir "\32_gdiplus.dll NOT FOUND IN " A_WinDir "\System32\gdiplus.dll"
		; FileGetSize, gdiplusDllSys64Size,% A_WinDir "\SysWow64\gdiplus.dll"
		; gdiplusDllSys64Str := FileExist(A_WinDir "\SysWow64\gdiplus.dll") ? A_ScriptDir "\32_gdiplus.dll found in " A_WinDir "\SysWow64\gdiplus.dll - Size: " gdiplusDllSys64Size " bytes" : A_ScriptDir "\32_gdiplus.dll NOT FOUND IN " A_WinDir "\SysWow64\gdiplus.dll"
		; os64Or32Str := A_Is64bitOS ? "OS is 64 bits" : "OS is 32 bits"
		
		msgbox % "Send me the content of this box. Press ALT+PrintScreen to take a screenshot of this window only."
		. "`n`n" os64Or32Str
		. "`n`n" fullMsgStr
	}

	if (whatDo = "UNLOAD")
		PROGRAM["FONTS"] := {}

	; SendMessage, 0x1D,,,, ahk_id 0xFFFF
	PostMessage, 0x1D,,,, ahk_id 0xFFFF
}
