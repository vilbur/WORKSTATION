/*
3ds Max hotkey importer runtime module (AutoHotkey v1).
Included by the resident Keyboard-Setup-Launcher.ahk, not run on its own.
*/
keyboardCheckMaxImportRequest:
SetTimer, keyboardCheckMaxImportRequest, Off
keyboardImportProcessQueue()
SetTimer, keyboardCheckMaxImportRequest, 500
return

keyboardImportProcessQueue()
{
    global keyboard_project_dir
    request_file := A_Temp . "\KeyboardSetupMaxImport\request.ini"
    if !FileExist(request_file)
        return
    IniRead, state, %request_file%, Request, State, none
    if (state != "queued")
        return
    IniWrite, processing, %request_file%, Request, State
    IniRead, token, %request_file%, Request, Token, ERROR
    IniRead, max_exe, %request_file%, Request, MaxExe, ERROR
    IniRead, factory_file, %request_file%, Request, Factory, ERROR
    IniRead, overlay_file, %request_file%, Request, Overlay, ERROR
    status_file := A_Temp . "\KeyboardSetupMaxImport\status.ini"
    IniWrite, %token%, %status_file%, Export, Token
    IniWrite, running, %status_file%, Export, State
    old_result := A_Temp . "\KeyboardSetupMaxImport\ActionTables.tsv"
    FileDelete, %old_result%

    if (token == "ERROR" || !FileExist(max_exe) || !FileExist(factory_file) || !FileExist(overlay_file))
    {
        keyboardImportFailure(status_file, "Missing or invalid source file")
        return
    }
    script_path := keyboard_project_dir . "\import\3DsMax\3DsMax-Export.ms"
    if !FileExist(script_path)
    {
        keyboardImportFailure(status_file, "MaxScript exporter is missing")
        return
    }

    ; Do not touch a Max instance that is not the selected executable.
    running_pid := keyboardImportFindRunningMax(max_exe)
    if (running_pid)
    {
        if !keyboardImportToRunningMax(running_pid, script_path)
        {
            keyboardImportFailure(status_file, "Cannot access MAXScript Listener of running Max")
            return
        }
        if keyboardImportWait(status_file, token, 20000)
            keyboardImportSaveOutput()
        else
            keyboardImportFailure(status_file, "Running Max did not complete export")
        return
    }

    ; Start a new instance only when none of the selected version is running.
    RegExMatch(max_exe, "i)3ds Max (\d{4})\\3dsmax\.exe$", year)
    if (!year1)
    {
        keyboardImportFailure(status_file, "Cannot identify Max year")
        return
    }
    EnvGet, local_app_data, LOCALAPPDATA
    startup_dir := local_app_data . "\Autodesk\3dsMax\" . year1 . " - 64bit\ENU\scripts\startup"
    FileCreateDir, %startup_dir%
    Random, suffix, 10000, 99999
    temporary_script := startup_dir . "\KeyboardSetup_OneShot_" . token . "_" . suffix . ".ms"
    if FileExist(temporary_script)
    {
        keyboardImportFailure(status_file, "Temporary startup script collision")
        return
    }
    FileCopy, %script_path%, %temporary_script%, 0
    if (ErrorLevel)
    {
        keyboardImportFailure(status_file, "Cannot create temporary Max startup script")
        return
    }
    Run, % Chr(34) . max_exe . Chr(34), , UseErrorLevel, started_pid
    if (ErrorLevel || !started_pid)
    {
        FileDelete, %temporary_script%
        keyboardImportFailure(status_file, "3ds Max could not start")
        return
    }
    ; Allow a slow cold start; never force-terminate 3ds Max on failure.
    completed := keyboardImportWait(status_file, token, 180000)
    FileDelete, %temporary_script%
    if (!completed)
    {
        keyboardImportFailure(status_file, "3ds Max startup/export timed out; instance left running")
        return
    }
    ; Only close the new instance started by us. Existing instances are never closed.
    keyboardImportSaveOutput()
    keyboardImportCloseOwnMax(started_pid)
}

keyboardImportFindRunningMax(executable)
{
    WinGet, count, List, ahk_exe 3dsmax.exe
    Loop, %count%
    {
        handle := count%A_Index%
        WinGet, candidate_pid, PID, % "ahk_id " . handle
        WinGet, candidate_path, ProcessPath, % "ahk_id " . handle
        if (candidate_path != "" && candidate_path = executable)
            return candidate_pid
    }
    return 0
}

/*
Find the mini MAXScript Listener (MXS_Scintilla) belonging to this PID.
Send to the control directly, without changing the clipboard or keyboard focus.
This is the same Win32 route used by external MAXScript editor integrations.
*/
keyboardImportListenerControl(pid)
{
    WinGet, count, List, % "ahk_pid " . pid
    Loop, %count%
    {
        top_handle := count%A_Index%
        WinGet, controls, ControlListHwnd, % "ahk_id " . top_handle
        Loop, Parse, controls, `n, `r
        {
            control_handle := A_LoopField
            if (!control_handle)
                continue
            VarSetCapacity(class_name, 512, 0)
            DllCall("GetClassName", "Ptr", control_handle, "Str", class_name, "Int", 256, "Int")
            if (class_name == "MXS_Scintilla")
                return control_handle
        }
    }
    return 0
}

keyboardImportToRunningMax(pid, script_path)
{
    control_handle := keyboardImportListenerControl(pid)
    if (!control_handle)
    {
        ; Some layouts hide the mini listener. Open the normal Listener only
        ; as a fallback (F11 is configured as the Listener toggle on this Max).
        WinActivate, % "ahk_pid " . pid
        WinWaitActive, % "ahk_pid " . pid, , 4
        if (ErrorLevel)
            return false
        SendInput, {F11}
        Loop, 25
        {
            Sleep, 160
            control_handle := keyboardImportListenerControl(pid)
            if (control_handle)
                break
        }
    }
    if (!control_handle)
        return false

    ; The path is a locally generated trusted script; escape MaxScript quotes.
    quoted_path := StrReplace(script_path, Chr(34), "\" . Chr(34))
    command := "fileIn @" . Chr(34) . quoted_path . Chr(34)
    success := DllCall("SendMessage", "Ptr", control_handle, "UInt", 0x000C
        , "Ptr", 0, "Str", command, "Ptr") ; WM_SETTEXT
    if (!success)
        return false
    ; WM_CHAR Enter executes the command in the MAXScript mini listener.
    return DllCall("PostMessage", "Ptr", control_handle, "UInt", 0x0102
        , "Ptr", 13, "Ptr", 0, "Int") != 0
}

keyboardImportWait(status_file, token, timeout_ms)
{
    waited := 0
    while (waited < timeout_ms)
    {
        IniRead, result_token, %status_file%, Export, Token, ERROR
        IniRead, state, %status_file%, Export, State, none
        if (result_token == token)
        {
            if (state == "done")
                return true
            if (state == "error")
                return false
        }
        Sleep, 250
        waited += 250
    }
    return false
}

keyboardImportCloseOwnMax(pid)
{
    WinGet, windows, List, % "ahk_pid " . pid
    Loop, %windows%
    {
        hwnd := windows%A_Index%
        WinGetTitle, title, % "ahk_id " . hwnd
        if (!InStr(title, "Listener") && InStr(title, "3ds Max"))
        {
            Sleep, 900
            WinClose, % "ahk_id " . hwnd
            return
        }
    }
}

keyboardImportFailure(status_file, reason)
{
    ; IniWrite does not support preserving a newline in this reason field.
    IniWrite, %reason%, %status_file%, Export, Message
    IniWrite, error, %status_file%, Export, State
}

keyboardImportSaveOutput()
{
    global keyboard_project_dir
    source := A_Temp . "\KeyboardSetupMaxImport\ActionTables.tsv"
    target := keyboard_project_dir . "\import\3DsMax\ActionTables.tsv"
    if FileExist(source)
        FileCopy, %source%, %target%, 1
}
