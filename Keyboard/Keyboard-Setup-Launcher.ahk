#NoEnv
#Requires AutoHotkey v1.1
#SingleInstance Off
#Persistent
#Include %A_ScriptDir%\src\Keyboard-Setup-Toolkit-Actions.ahk
; Both interpreted root AHK and compiled root EXE use the same project root.
keyboard_project_dir := A_ScriptDir
SetWorkingDir, %keyboard_project_dir%
SetTitleMatchMode, 2
SendMode, Input
keyboard_action_event_counter := 0

; Cross-launch mutex: the compiled EXE and AutoHotkey source share one
; resident instance even if started through different filenames.
keyboard_resident_has_mutex := keyboardAcquireResidentMutex()
; Restart is an explicit hand-off: the new instance waits for the old mutex
; holder to exit. Ordinary duplicate launches still exit immediately.
if (!keyboard_resident_has_mutex && A_Args.Length() > 0 && A_Args[1] == "--keyboard-restart")
{
    Loop, 120
    {
        Sleep, 250
        keyboard_resident_has_mutex := keyboardAcquireResidentMutex()
        if (keyboard_resident_has_mutex)
            break
    }
}
if (!keyboard_resident_has_mutex)
{
    ; A second launch (AHK or EXE) never creates a new tray process.
    ; Restore whichever Keyboard Manager window is already open.
    already_open_hwnd := keyboardFindSetupWindow()
    if (!already_open_hwnd)
        already_open_hwnd := keyboardFindHotkeyIndexWindow()
    if (already_open_hwnd)
        keyboardActivateUiWindow(already_open_hwnd)
    ExitApp
}

OnExit("keyboardCloseUiOnExit")

icon_path := keyboard_project_dir . "\assets\Keyboard-Setup.ico"
if FileExist(icon_path)
{
    Menu, Tray, Icon, %icon_path%
}

; Use a fully defined tray menu so Restart and Exit are always visible in
; the CURRENT resident build, not hidden among AutoHotkey's standard entries.
Menu, Tray, NoStandard
Menu, Tray, DeleteAll
Menu, Tray, Tip, Keyboard Setup v0.34
Menu, Tray, Add, Open Keyboard Setup, openKeyboardSetup
Menu, Tray, Add, Hotkey Index, openHotkeyIndex
Menu, Tray, Add
Menu, Tray, Add, Restart, restartKeyboardSetup
Menu, Tray, Add
Menu, Tray, Add, Exit, keyboardExitResident
Menu, Tray, Default, Open Keyboard Setup
Menu, Tray, Click, 1

ensureWindowsStartup()
SetTimer, keyboardCheckMaxImportRequest, 500
return

^u::
keyboardPublishShortcut("Ctrl+U")
keyboardLaunchAction("Ctrl+U")
return

^+u::
keyboardPublishShortcut("Ctrl+Shift+U")
keyboardLaunchAction("Ctrl+Shift+U")
return

^+SC028::
keyboardPublishShortcut("Ctrl+Shift+'")
keyboardLaunchAction("Ctrl+Shift+'")
return

; Force all resident Win-key overrides through the low-level keyboard hook.
; RegisterHotkey() can lose Win+G to the Xbox Game Bar registration.
; These hooks do NOT use ~ pass-through, so captured keys are swallowed.
#UseHook On
#y::
keyboardPublishShortcut("Win+Y")
keyboardLaunchAction("Win+Y")
return

#c::
keyboardPublishShortcut("Win+C")
keyboardLaunchAction("Win+C")
return

#g::
keyboardPublishShortcut("Win+G")
keyboardLaunchAction("Win+G")
return

#i::
keyboardPublishShortcut("Win+I")
keyboardLaunchAction("Win+I")
return


; Imported external AutoHotkey Toolkit actions. The Toolkit must release
;   these chords before Keyboard Manager can own them reliably. 
#f::
keyboardPublishShortcut("Win+F")
keyboardLaunchAction("Win+F")
return

^#n::
keyboardPublishShortcut("Ctrl+Win+N")
keyboardLaunchAction("Ctrl+Win+N")
return

^#F4::
keyboardPublishShortcut("Ctrl+Win+F4")
keyboardLaunchAction("Ctrl+Win+F4")
return

#Space::
keyboardPublishShortcut("Win+Space")
keyboardLaunchAction("Win+Space")
return

+#h::
keyboardPublishShortcut("Shift+Win+H")
keyboardLaunchAction("Shift+Win+H")
return

#t::
keyboardPublishShortcut("Win+T")
keyboardLaunchAction("Win+T")
return

#F4::
keyboardPublishShortcut("Win+F4")
keyboardLaunchAction("Win+F4")
return

^#h::
keyboardPublishShortcut("Ctrl+Win+H")
keyboardLaunchAction("Ctrl+Win+H")
return

#Pause::
keyboardPublishShortcut("Win+Pause")
keyboardLaunchAction("Win+Pause")
return

#m::
keyboardPublishShortcut("Win+M")
keyboardLaunchAction("Win+M")
return

^+#f::
keyboardPublishShortcut("Ctrl+Shift+Win+F")
keyboardLaunchAction("Ctrl+Shift+Win+F")
return

^#c::
keyboardPublishShortcut("Ctrl+Win+C")
keyboardLaunchAction("Ctrl+Win+C")
return

#Enter::
keyboardPublishShortcut("Win+Enter")
keyboardLaunchAction("Win+Enter")
return

#r::
keyboardPublishShortcut("Win+R")
keyboardLaunchAction("Win+R")
return
#UseHook Off

openKeyboardSetup:
; Critical serialises fast tray clicks; all UI types share one launch controller.
Critical, On
keyboardOpenSingleUi("editor")
return

openHotkeyIndex:
Critical, On
keyboardOpenSingleUi("index")
return

keyboardExitResident:
ExitApp
return

restartKeyboardSetup:
Critical, On
keyboardRestartResident()
return

/*
Spawn the same script or compiled EXE with a restart marker, then exit the old
resident normally. The child retries the mutex while OnExit closes both UIs.
This avoids the usual race where a fresh process exits as a duplicate.
*/
keyboardRestartResident()
{
    global keyboard_project_dir
    if (A_IsCompiled)
        restart_command := Chr(34) . A_ScriptFullPath . Chr(34)
    else
        restart_command := Chr(34) . A_AhkPath . Chr(34) . " " . Chr(34) . A_ScriptFullPath . Chr(34)
    restart_command .= " --keyboard-restart"
    Run, %restart_command%, %keyboard_project_dir%, UseErrorLevel, restart_pid
    if (ErrorLevel || !restart_pid)
    {
        TrayTip, Keyboard Setup, Could not restart the launcher. The current process remains active., 4, 3
        return false
    }
    ExitApp
    return true
}

/*
Close the Keyboard Setup and Hotkey Index windows when the resident exits.
The callback is registered only by the mutex owner, never by a duplicate launch.
*/
keyboardCloseUiOnExit(exit_reason, exit_code)
{
    ; Called for AutoHotkey's standard tray Exit menu item and ExitApp.
    keyboardCloseOwnedUi("editor")
    keyboardCloseOwnedUi("index")
}

/*
Close only HTA windows positively identified as belonging to this tool.
Use graceful WM_CLOSE first; terminate a stuck HTA host after a short wait.
*/
keyboardCloseOwnedUi(ui_kind)
{
    Loop, 5
    {
        hwnd := keyboardFindUiWindow(ui_kind)
        if (!hwnd)
            break
        selector := "ahk_id " . hwnd
        WinClose, %selector%
        WinWaitClose, %selector%,, 1
        if (WinExist(selector) && keyboardFindUiWindow(ui_kind) == hwnd)
        {
            ; WinKill is restricted to a re-verified Keyboard Manager HTA HWND.
            WinKill, %selector%
            WinWaitClose, %selector%,, 1
        }
        if WinExist(selector)
            break
    }
}

/*
Find, restore, or launch exactly one window of a given kind. Launching from
another UI also uses HTA:APPLICATION SINGLEINSTANCE=yes to stop direct
mshta.exe / double-click duplicates from bypassing the tray controller.
*/
keyboardOpenSingleUi(ui_kind)
{
    global keyboard_project_dir, keyboard_last_ui_pid, keyboard_last_ui_start
    global keyboard_last_index_pid, keyboard_last_index_start

    if (ui_kind == "index")
    {
        ui_path := keyboard_project_dir . "\src\Keyboard-Setup-Hotkey-Index.hta"
        hwnd := keyboardFindHotkeyIndexWindow()
        pending_pid := keyboard_last_index_pid
        last_start := keyboard_last_index_start
        label := "Hotkey Index"
    }
    else
    {
        ui_path := keyboard_project_dir . "\Keyboard-Setup-Design-Options.hta"
        hwnd := keyboardFindSetupWindow()
        pending_pid := keyboard_last_ui_pid
        last_start := keyboard_last_ui_start
        label := "Keyboard Setup"
    }

    if (hwnd)
    {
        keyboardActivateUiWindow(hwnd)
        return
    }
    if !FileExist(ui_path)
    {
        MsgBox, 16, Keyboard Setup, % label . " file not found:`n" . ui_path
        return
    }

    ; A window might not yet have its final title. Never launch a second
    ; mshta.exe while the previous launch PID is still alive.
    if (pending_pid)
    {
        Process, Exist, %pending_pid%
        if (ErrorLevel == pending_pid)
            return
        pending_pid := 0
    }

    ; Guard the short interval when mshta hands off to its actual UI process.
    if (last_start && A_TickCount - last_start < 4000)
        return

    Run, % "mshta.exe " . Chr(34) . ui_path . Chr(34), %keyboard_project_dir%, UseErrorLevel, new_pid
    if (ErrorLevel || !new_pid)
    {
        MsgBox, 16, Keyboard Setup, % "Could not open " . label . "."
        return
    }
    if (ui_kind == "index")
    {
        keyboard_last_index_pid := new_pid
        keyboard_last_index_start := A_TickCount
    }
    else
    {
        keyboard_last_ui_pid := new_pid
        keyboard_last_ui_start := A_TickCount
    }
}

keyboardActivateUiWindow(hwnd)
{
    if (!hwnd)
        return false
    window_selector := "ahk_id " . hwnd
    ; Restore only minimized windows: do not unmaximize or resize the editor.
    WinGet, window_state, MinMax, %window_selector%
    if (window_state == -1)
        WinRestore, %window_selector%
    WinShow, %window_selector%
    WinActivate, %window_selector%
    return true
}

keyboardFindHotkeyIndexWindow()
{
    return keyboardFindUiWindow("index")
}

keyboardFindSetupWindow()
{
    return keyboardFindUiWindow("editor")
}

; The title is initially unversioned and changes during HTA initialization.
;   Search mshta.exe windows as well as the native HTA window class. 
keyboardFindUiWindow(ui_kind)
{
    WinGet, window_count, List, ahk_exe mshta.exe
    Loop, %window_count%
    {
        hwnd := window_count%A_Index%
        WinGetTitle, title, % "ahk_id " . hwnd
        if keyboardIsUiTitle(title, ui_kind)
            return hwnd
    }

    ; Fallback for systems on which the HTA host is not matched by ahk_exe.
    WinGet, window_count, List, ahk_class HTML Application Host Window Class
    Loop, %window_count%
    {
        hwnd := window_count%A_Index%
        WinGet, image_name, ProcessName, % "ahk_id " . hwnd
        if (image_name != "mshta.exe")
            continue
        WinGetTitle, title, % "ahk_id " . hwnd
        if keyboardIsUiTitle(title, ui_kind)
            return hwnd
    }
    return 0
}

keyboardIsUiTitle(title, ui_kind)
{
    if (ui_kind == "index")
        return RegExMatch(title, "i)^Keyboard Hotkey Index( v[0-9]+(\.[0-9]+)*)?$") != 0
    ; Ignore the independent Hotkey Index, and accept legacy initial titles.
    return RegExMatch(title, "i)^Keyboard Setup( v[0-9]+(\.[0-9]+)*| - Design Options)?$") != 0
}

keyboardPublishShortcut(chord)
{
    global keyboard_action_event_counter
    keyboard_action_event_counter += 1
    target := A_Temp . "\KeyboardSetupActionEvent.txt"
    temporary := target . ".tmp"
    event_text := "Shortcut=" . chord . "`r`nSerial=" . A_TickCount . "-" . keyboard_action_event_counter . "`r`n"
    ; Single atomic replace so the HTA never reads a partly written event.
    FileDelete, %temporary%
    FileAppend, %event_text%, %temporary%, UTF-8-RAW
    if (!ErrorLevel)
        FileMove, %temporary%, %target%, 1
}

/*
Keep one resident instance across compiled EXE and interpreted AHK v1 scripts.
Windows releases this process-owned mutex when the resident exits or crashes.
*/
keyboardAcquireResidentMutex()
{
    global keyboard_resident_mutex
    keyboard_resident_mutex := DllCall("kernel32\CreateMutexW", "Ptr", 0, "Int", 0
        , "WStr", "Local\KeyboardSetup_Resident_8A2DE942", "Ptr")
    error_code := A_LastError
    if (!keyboard_resident_mutex)
        return false
    if (error_code == 183) ; ERROR_ALREADY_EXISTS
    {
        DllCall("CloseHandle", "Ptr", keyboard_resident_mutex)
        keyboard_resident_mutex := 0
        return false
    }
    return true
}

/*
Resolve a registered shortcut to its independently editable action entrypoint.
Only these project-relative paths are executable through the resident.
*/
keyboardActionRelativePath(chord)
{
    static paths := ""
    if !IsObject(paths)
    {
        paths := {}
        paths["Ctrl+U"] := "actions\Cycle-Text-Case\Cycle-Text-Case.ahk"
        paths["Ctrl+Shift+U"] := "actions\Cycle-Naming-Convention\Cycle-Naming-Convention.ahk"
        paths["Ctrl+Shift+'"] := "actions\Toggle-Quotes\Toggle-Quotes.ahk"
        paths["Win+Y"] := "actions\YouTube\YouTube.ahk"
        paths["Win+C"] := "actions\Total-Commander-Windows\Total-Commander-Windows.ahk"
        paths["Win+G"] := "actions\Google-Search\Google-Search.ahk"
        paths["Win+I"] := "actions\IrfanView-Image\IrfanView-Image.ahk"
        paths["Win+F"] := "actions\FocusMe-Window\FocusMe-Window.ahk"
        paths["Ctrl+Win+N"] := "actions\Notepad-Clipboard-File\Notepad-Clipboard-File.ahk"
        paths["Ctrl+Win+F4"] := "actions\Kill-All-Active-Processes\Kill-All-Active-Processes.ahk"
        paths["Win+Space"] := "actions\ChatGPT-Dictation\ChatGPT-Dictation.ahk"
        paths["Shift+Win+H"] := "actions\Open-Hotstrings\Open-Hotstrings.ahk"
        paths["Win+T"] := "actions\Total-Commander-Activate\Total-Commander-Activate.ahk"
        paths["Win+F4"] := "actions\Kill-Active-Process\Kill-Active-Process.ahk"
        paths["Ctrl+Win+H"] := "actions\Hibernate-Windows\Hibernate-Windows.ahk"
        paths["Win+Pause"] := "actions\Temporary-Mute\Temporary-Mute.ahk"
        paths["Win+M"] := "actions\Suspend-Key\Suspend-Key.ahk"
        paths["Ctrl+Shift+Win+F"] := "actions\FocusMe-Window-Alternate\FocusMe-Window-Alternate.ahk"
        paths["Ctrl+Win+C"] := "actions\Go-To-Path\Go-To-Path.ahk"
        paths["Win+Enter"] := "actions\MediaMonkey-Activate\MediaMonkey-Activate.ahk"
        paths["Win+R"] := "actions\Run-MaxScript\Run-MaxScript.ahk"
    }
    return paths.HasKey(chord) ? paths[chord] : ""
}

/*
Start the selected action in its own AutoHotkey v1 process. Missing files and
interpreter failure cannot bring down the resident hotkey manager.
*/
keyboardLaunchAction(chord)
{
    global keyboard_project_dir
    relative_path := keyboardActionRelativePath(chord)
    if (relative_path == "")
    {
        TrayTip, Keyboard Setup, % "No action registered for " . chord, 6, 2
        return false
    }

    action_path := keyboard_project_dir . "\\" . relative_path
    if !FileExist(action_path)
    {
        TrayTip, Keyboard Setup, % "Action file missing: " . action_path, 6, 2
        return false
    }

    interpreter := keyboardToolkitV1Interpreter()
    if (interpreter == "")
        return false
    command := Chr(34) . interpreter . Chr(34) . " " . Chr(34) . action_path . Chr(34)
    Run, %command%, %keyboard_project_dir%, UseErrorLevel, action_pid
    if (ErrorLevel || !action_pid)
    {
        TrayTip, Keyboard Setup, % "Could not launch action: " . action_path, 6, 2
        return false
    }
    return true
}

/*
Create or refresh the current user's Windows startup shortcut.
*/
ensureWindowsStartup()
{
    global keyboard_project_dir
    shortcut_path := A_Startup . "\Keyboard-Setup.lnk"
    icon_path := keyboard_project_dir . "\assets\Keyboard-Setup.ico"

    if (A_IsCompiled)
    {
        target_path := A_ScriptFullPath
        arguments := ""
    }
    else
    {
        target_path := A_AhkPath
        arguments := Chr(34) . A_ScriptFullPath . Chr(34)
    }

    FileCreateShortcut, %target_path%, %shortcut_path%, %keyboard_project_dir%, %arguments%, Keyboard Setup background manager, %icon_path%

    if (ErrorLevel)
    {
        TrayTip, Keyboard Setup, Could not create the Windows startup shortcut., 6, 2
    }
}

#Include %A_ScriptDir%\import\3DsMax\3DsMax-Importer.ahk
