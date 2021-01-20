; Created by https://github.com/WhalePat
; Official repository https://github.com/WhalePat/copy-path-context-menu

; Sets LaunchArgument to false if there is no launch arguments
if A_Args.Length > 0 {
    LaunchArgument := A_Args[1]
} else {
    LaunchArgument := false
}

LOCALAPPDATA := EnvGet("LOCALAPPDATA")
InstallDirectoryName := "copy-path-context-menu"
InstallDirectoryPath := LOCALAPPDATA . "\Programs\" . InstallDirectoryName
ExecutableName := "copy-path-context-menu.exe"
ExecutablePath := InstallDirectoryPath . "\" . ExecutableName

QuoteMe(String) {
    String := "`"" . String . "`""
    return String
}

IsSubkey(KeyPath, KeyName) {
    Loop Reg, KeyPath, "K" {
        CurrentKeyName := A_LoopRegName
        if CurrentKeyName = KeyName {
            return true
        }
    }
}

IsKeyValue(KeyPath, ValueName) {
    Loop Reg, KeyPath, "V" {
        CurrentValueName := A_LoopRegName
        if CurrentValueName = ValueName {
            return true
        }
    }
}

if LaunchArgument = "/copypath" {
    A_Clipboard := A_Args[2]
} else if LaunchArgument = "/uninstall" {
    ; Tell Windows to delete the install folder once the computer restarts
    RegWrite(QuoteMe("C:\Windows\system32\cmd.exe") . " /c rmdir /q /s " . QuoteMe(InstallDirectoryPath), "REG_SZ", "HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce", InstallDirectoryName)

    ; Delete uninstall entry
    RegDeleteKey("HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\" . InstallDirectoryName)

    ; Delete context menu entry for directory backgrounds
    RegDeleteKey("HKEY_CURRENT_USER\SOFTWARE\Classes\Directory\Background\shell\" . InstallDirectoryName)

    ; Delete context menu entry for directory backgrounds
    RegDeleteKey("HKEY_CURRENT_USER\SOFTWARE\Classes\Directory\shell\" . InstallDirectoryName)

    ; Delete context menu entry for all files
    RegDeleteKey("HKEY_CURRENT_USER\SOFTWARE\Classes\*\shell\" . InstallDirectoryName)

    MsgBox("Restart your computer to complete the uninstallation.")
} else if LaunchArgument = false {
    UninstallMessage := "Hey it looks like you already have this awesome app installed! Uninstall your previous version before attempting to reinstall."

    ; Already installed checks
    if FileExist(InstallDirectoryPath) {
        MsgBox(UninstallMessage)
        ExitApp
    }

    if IsSubkey("HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall", InstallDirectoryName) {
        MsgBox(UninstallMessage)
        ExitApp
    }

    if IsSubkey("HKEY_CURRENT_USER\SOFTWARE\Classes\Directory\Background\shell", InstallDirectoryName) {
        MsgBox(UninstallMessage)
        ExitApp
    }

    if IsSubkey("HKEY_CURRENT_USER\SOFTWARE\Classes\Directory\shell", InstallDirectoryName) {
        MsgBox(UninstallMessage)
        ExitApp
    }

    if IsSubkey("HKEY_CURRENT_USER\SOFTWARE\Classes\*\shell", InstallDirectoryName) {
        MsgBox(UninstallMessage)
        ExitApp
    }

    if IsKeyValue("HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce", InstallDirectoryName) {
        MsgBox(UninstallMessage)
        ExitApp
    }

    DirCreate(InstallDirectoryPath)
    FileCopy(A_ScriptFullPath, ExecutablePath)

    ; Create uninstall entry
    RegWrite(ExecutablePath, "REG_SZ", "HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\" . InstallDirectoryName, "DisplayIcon")
    RegWrite("Copy path context menu", "REG_SZ", "HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\" . InstallDirectoryName, "DisplayName")
    RegWrite(InstallDirectoryPath, "REG_SZ", "HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\" . InstallDirectoryName, "InstallLocation")
    RegWrite(QuoteMe(ExecutablePath) . " /uninstall", "REG_SZ", "HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\" . InstallDirectoryName, "UninstallString")
    RegWrite("0x00000001", "REG_DWORD", "HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\" . InstallDirectoryName, "NoModify")
    RegWrite("0x00000001", "REG_DWORD", "HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\" . InstallDirectoryName, "NoRepair")

    ; Create context menu entry for directory backgrounds
    RegWrite("Copy folder path", "REG_SZ", "HKEY_CURRENT_USER\SOFTWARE\Classes\Directory\Background\shell\" . InstallDirectoryName)
    RegWrite(ExecutablePath, "REG_SZ", "HKEY_CURRENT_USER\SOFTWARE\Classes\Directory\Background\shell\" . InstallDirectoryName, "Icon")
    RegWrite(QuoteMe(ExecutablePath) . "/copypath " . QuoteMe("%V"), "REG_SZ", "HKEY_CURRENT_USER\SOFTWARE\Classes\Directory\Background\shell\" . InstallDirectoryName . "\command")

    ; Create context menu entry for folders
    RegWrite("Copy folder path", "REG_SZ", "HKEY_CURRENT_USER\SOFTWARE\Classes\Directory\shell\" . InstallDirectoryName)
    RegWrite(ExecutablePath, "REG_SZ", "HKEY_CURRENT_USER\SOFTWARE\Classes\Directory\shell\" . InstallDirectoryName, "Icon")
    RegWrite(QuoteMe(ExecutablePath) . "/copypath " . QuoteMe("%V"), "REG_SZ", "HKEY_CURRENT_USER\SOFTWARE\Classes\Directory\shell\" . InstallDirectoryName . "\command")

    ; Create context menu entry for all files
    RegWrite("Copy file path", "REG_SZ", "HKEY_CURRENT_USER\SOFTWARE\Classes\*\shell\" . InstallDirectoryName)
    RegWrite(ExecutablePath, "REG_SZ", "HKEY_CURRENT_USER\SOFTWARE\Classes\*\shell\" . InstallDirectoryName, "Icon")
    RegWrite(QuoteMe(ExecutablePath) . "/copypath " . QuoteMe("%V"), "REG_SZ", "HKEY_CURRENT_USER\SOFTWARE\Classes\*\shell\" . InstallDirectoryName . "\command")

    MsgBox("Installation complete! you may delete this executable.")
}
