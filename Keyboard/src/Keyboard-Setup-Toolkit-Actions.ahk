; Compatibility defaults for a pre-v0.34 resident during staggered Drive sync.
; Current wrappers pass their own individual target and do not use this map.
; External actions imported from the user's AutoHotkey Toolkit screenshot.
;   File paths are defaults, not asserted to exist on this computer.
;   The original scripts retain their own behaviour and dependencies. 
keyboardToolkitDefaults()
{
    static targets := ""
    if IsObject(targets)
        return targets
    targets := {}
    targets["Win+F"] := "C:\GoogleDrive\ProgramsData\Core\FocusMe\Ahk\Focusme-Window-Toggle.ahk"
    targets["Ctrl+Win+N"] := "C:\GoogleDrive\ProgramsData\Core\Notepad++\AHK\Open-specific-file-types-from-clipboard-in-Notepad.ahk"
    targets["Ctrl+Win+F4"] := "C:\GoogleDrive\ProgramsData\Core\Windows\_AhkScripts\kill-ALL-PROCESESES-of-active-window.ahk"
    targets["Win+Space"] := "C:\GoogleDrive\ProgramsData\Core\ChatGPT\ahk\run-chat-and-start-or-stop-dictate-mode.ahk"
    targets["Shift+Win+H"] := "C:\GoogleDrive\ProgramsData\Core\AutoHotkey\Hotstrings\open-hotstrings-file.ahk"
    targets["Win+T"] := "D:\GoogleDrive\TotalCommander\_TC-commands\TC-Acivate.ahk"
    targets["Win+F4"] := "C:\GoogleDrive\ProgramsData\Core\Windows\_AhkScripts\kill-process-of-active-window.ahk"
    targets["Ctrl+Win+H"] := "C:\GoogleDrive\ProgramsData\Core\Windows\_AhkScripts\Hibernate-Windows.bat"
    targets["Win+Pause"] := "M:\MediaMonkey\Ahk\Mute-Temporary\Mute-Launcher.ahk"
    targets["Win+M"] := "C:\GoogleDrive\ProgramsData\Core\AutoHotkey\Lib\Window\SuspendKey-DoNothing.ahk"
    targets["Ctrl+Shift+Win+F"] := "C:\GoogleDrive\ProgramsData\Core\FocusMe\Ahk\Focusme-Window-Toggle.ahk"
    targets["Ctrl+Win+C"] := "D:\GoogleDrive\TotalCommander\_TC-commands\file\go_to_path.ahk"
    targets["Win+Enter"] := "M:\MediaMonkey\Ahk\Activate-mediamonkey.ahk"
    targets["Win+R"] := "C:\Users\vilbur\AppData\Local\ActiveState\KomodoIDE\12.0\tools\Scripts\3Ds Max\runMaxScript\run-maxscript-via-notepad-komodo.ahk"
    return targets
}

/*
Run one wrapper's explicitly declared original target. User file binding
takes priority, followed by the remembered Browse path and original target.
*/
keyboardRunToolkitAction(chord, default_target := "")
{
    global keyboard_project_dir
    if (chord == "")
        return false
    if (default_target == "")
    {
        legacy_defaults := keyboardToolkitDefaults()
        if !legacy_defaults.HasKey(chord)
            return false
        default_target := legacy_defaults[chord]
    }
    binding_ini := keyboard_project_dir . "\config\Keyboard-Setup-File-Bindings.ini"
    if !FileExist(binding_ini)
        binding_ini := keyboard_project_dir . "\Keyboard-Setup-File-Bindings.ini"
    override := ""
    if FileExist(binding_ini)
    {
        IniRead, override, %binding_ini%, Files, %chord%, %A_Space%
        override := Trim(override, " `t`r`n" . Chr(34))
    }
    settings_dir := keyboard_project_dir . "\config"
    settings_ini := settings_dir . "\Keyboard-Setup-Toolkit-Paths.ini"
    IniRead, saved, %settings_ini%, Paths, %chord%, %A_Space%
    saved := Trim(saved, " `t`r`n" . Chr(34))
    default := default_target
    if (override != "" && FileExist(override) && !InStr(FileExist(override), "D"))
        target := override
    else if (saved != "" && FileExist(saved) && !InStr(FileExist(saved), "D"))
        target := saved
    else if (FileExist(default) && !InStr(FileExist(default), "D"))
        target := default
    else
    {
        if (override != "")
            TrayTip, Keyboard Setup, % "Configured file missing for " . chord . ". Browse to restore it.", 4, 1
        FileSelectFile, target, 3, , % "Locate action file for " . chord, Scripts (*.ahk; *.bat; *.cmd; *.exe)
        if (target == "")
            return false
        if (!FileExist(target) || InStr(FileExist(target), "D"))
        {
            MsgBox, 48, Keyboard Setup, Please choose an existing action file.
            return false
        }
        FileCreateDir, %settings_dir%
        IniWrite, %target%, %settings_ini%, Paths, %chord%
    }
    SplitPath, target, , work_dir, extension
    if (work_dir == "")
        work_dir := keyboard_project_dir
    if (extension = "ahk")
    {
        interpreter := keyboardToolkitV1Interpreter()
        if (interpreter == "")
            return false
        command := Chr(34) . interpreter . Chr(34) . " " . Chr(34) . target . Chr(34)
    }
    else if (extension = "bat" || extension = "cmd")
    {
        EnvGet, comspec_path, ComSpec
        command := Chr(34) . comspec_path . Chr(34) . " /c " . Chr(34) . target . Chr(34)
    }
    else
        command := Chr(34) . target . Chr(34)
    Run, %command%, %work_dir%, UseErrorLevel
    if (ErrorLevel)
    {
        TrayTip, Keyboard Setup, % "Could not start action file: " . target, 6, 2
        return false
    }
    return true
}

; Do not accidentally run an AHK v1 action with a compiled Keyboard Manager
;   binary or with an AHK v2 file association. 
keyboardToolkitV1Interpreter()
{
    global keyboard_project_dir
    if (!A_IsCompiled && RegExMatch(A_AhkVersion, "^1\."))
        return A_AhkPath
    settings_ini := keyboard_project_dir . "\config\Keyboard-Setup-Toolkit-Paths.ini"
    IniRead, saved, %settings_ini%, General, AutoHotkeyV1, %A_Space%
    candidates := [saved, A_ProgramFiles . "\AutoHotkey\v1\AutoHotkeyU64.exe"
        , A_ProgramFiles . "\AutoHotkey\v1\AutoHotkeyU32.exe"
        , A_ProgramFiles . "\AutoHotkey\AutoHotkeyU64.exe"
        , A_ProgramFiles . "\AutoHotkey\AutoHotkeyU32.exe"]
    EnvGet, program_files_32, ProgramFiles(x86)
    candidates.Push(program_files_32 . "\AutoHotkey\v1\AutoHotkeyU32.exe")
    for index, path in candidates
    {
        if (path != "" && FileExist(path) && !InStr(FileExist(path), "D"))
            return path
    }
    FileSelectFile, selected, 3, , Select AutoHotkey v1 interpreter, AutoHotkey Executable (*.exe)
    if (selected == "")
        return ""
    if !RegExMatch(selected, "i)\\AutoHotkey(U32|U64|32|64)?\.exe$")
    {
        MsgBox, 48, Keyboard Setup, Please select an AutoHotkey v1 executable.
        return ""
    }
    FileCreateDir, % keyboard_project_dir . "\config"
    IniWrite, %selected%, %settings_ini%, General, AutoHotkeyV1
    return selected
}
