/*
Execute an optional file binding in place of the built-in action.
*/
keyboardRunBoundFile(binding_code)
{
    global keyboard_project_dir
    ini_path := keyboard_project_dir . "\config\Keyboard-Setup-File-Bindings.ini"
    if !FileExist(ini_path)
        ini_path := keyboard_project_dir . "\Keyboard-Setup-File-Bindings.ini"
    if !FileExist(ini_path)
    {
        return false
    }

    IniRead, file_path, %ini_path%, Files, %binding_code%, ERROR
    file_path := Trim(file_path, " `t`r`n" . Chr(34))
    if (file_path == "" || file_path == "ERROR")
    {
        return false
    }
    if !FileExist(file_path)
    {
        TrayTip, Keyboard Setup, % "Missing assigned file: " . file_path, 6, 2
        return false
    }

    Run, % Chr(34) . file_path . Chr(34), %keyboard_project_dir%, UseErrorLevel
    if (ErrorLevel)
    {
        TrayTip, Keyboard Setup, % "Could not launch assigned file: " . file_path, 6, 2
        return false
    }
    return true
}

/*
Change a text selection with the calling action's own transformation function.
No other action-specific function is referenced from this shared module.
*/
keyboardApplyTextTransform(transform_function, select_word := false)
{
    keyboardWaitForModifiers()
    clipboard_backup := ClipboardAll
    Clipboard := ""
    SendInput, ^c
    ClipWait, 0.5
    selected_text := ErrorLevel ? "" : Clipboard

    if (selected_text == "" && select_word)
    {
        SendInput, ^{Left}^+{Right}
        Sleep, 60
        Clipboard := ""
        SendInput, ^c
        ClipWait, 0.5
        selected_text := ErrorLevel ? "" : Clipboard
    }

    if (selected_text != "")
    {
        replacement_text := transform_function.Call(selected_text)

        if (replacement_text != selected_text)
        {
            Clipboard := replacement_text
            SendInput, ^v
            Sleep, 180
        }
    }
    Clipboard := clipboard_backup
    VarSetCapacity(clipboard_backup, 0)
}

/*
Wait for physical hotkey modifiers to be released before sending Ctrl+C.
*/
keyboardWaitForModifiers()
{
    KeyWait, Control
    KeyWait, Shift
    KeyWait, LWin
    KeyWait, RWin
}

/*
Copy selected text without permanently changing clipboard contents.
*/
keyboardReadSelection()
{
    keyboardWaitForModifiers()
    clipboard_backup := ClipboardAll
    Clipboard := ""
    SendInput, ^c
    ClipWait, 0.5
    selected_text := ErrorLevel ? "" : Clipboard
    Clipboard := clipboard_backup
    VarSetCapacity(clipboard_backup, 0)
    return selected_text
}
/*
Activate the next window using a stable handle order despite z-order changes.
*/
keyboardCycleWindows(window_filter)
{
    WinGet, window_count, List, %window_filter%
    if (window_count < 1)
    {
        return false
    }

    window_handles := []
    Loop, %window_count%
    {
        window_handles.Push(window_count%A_Index%)
    }

    window_total := window_handles.Length()
    Loop, %window_total%
    {
        left_index := A_Index
        right_index := left_index + 1
        while (right_index <= window_total)
        {
            if (window_handles[right_index] < window_handles[left_index])
            {
                temporary_handle := window_handles[left_index]
                window_handles[left_index] := window_handles[right_index]
                window_handles[right_index] := temporary_handle
            }
            right_index += 1
        }
    }

    WinGet, active_handle, ID, A
    next_index := 1
    for window_index, current_handle in window_handles
    {
        if (current_handle == active_handle)
        {
            next_index := Mod(window_index, window_total) + 1
            break
        }
    }
    WinActivate, % "ahk_id " . window_handles[next_index]
    return true
}

/*
Open a web address in Chrome, falling back to the Windows default browser.
*/
keyboardOpenChromeUrl(url)
{
    Run, % "chrome.exe --new-tab " . Chr(34) . url . Chr(34), , UseErrorLevel
    if (ErrorLevel)
    {
        Run, %url%
    }
}
