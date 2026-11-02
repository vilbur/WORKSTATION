#NoEnv
#Requires AutoHotkey v1.1
#SingleInstance Off
#Include %A_ScriptDir%\..\..\src\Keyboard-Setup-Action-Common.ahk
keyboard_project_dir := A_ScriptDir . "\..\.."
SetWorkingDir, %keyboard_project_dir%
SendMode, Input
keyboardReadIrfanCycleAnchor()
if !keyboardRunBoundFile("Win+I")
{
    keyboardOpenClipboardImageInIrfanView()
}
ExitApp

/*
Open a clipboard bitmap in IrfanView, or open an existing image file whose path
was copied as text or as an Explorer file object. The clipboard is never replaced.
*/
keyboardOpenClipboardImageInIrfanView()
{
    global keyboard_project_dir
    has_image := keyboardClipboardHasImage()
    image_path := has_image ? "" : keyboardClipboardImagePath()
    if (!has_image && image_path == "")
    {
        ; No clipboard source: cycle already-open IrfanView image windows.
        ; Do not browse for the executable or start a new instance in this case.
        if keyboardCycleIrfanViewWindows()
            return
        TrayTip, Keyboard Setup, No clipboard image or open IrfanView window., 4, 1
        return
    }

    irfan_exe := keyboardFindIrfanView()
    if (irfan_exe == "")
        irfan_exe := keyboardBrowseIrfanView()
    if (irfan_exe == "")
        return

    if (has_image)
        launch_command := Chr(34) . irfan_exe . Chr(34) . " /clippaste"
    else
        launch_command := Chr(34) . irfan_exe . Chr(34) . " " . Chr(34) . image_path . Chr(34)

    Run, %launch_command%, %keyboard_project_dir%, UseErrorLevel
    if (ErrorLevel)
        MsgBox, 16, Keyboard Setup, % "Could not open IrfanView:`n" . irfan_exe
}

/*
No usable clipboard image/path: activate an IrfanView main window, cycling
through all visible 32-bit and 64-bit instances in a stable HWND order.
Skip owned dialogs and remember the last chosen window if focus moves away.
*/
keyboardCycleIrfanViewWindows()
{
    global keyboard_last_irfan_hwnd
    window_handles := []
    for index, executable in ["i_view64.exe", "i_view32.exe"]
    {
        WinGet, irfan_window_count, List, % "ahk_exe " . executable
        Loop, %irfan_window_count%
        {
            hwnd := irfan_window_count%A_Index%
            ; A dialog belongs to a main window; do not cycle into it.
            if DllCall("GetWindow", "Ptr", hwnd, "UInt", 4, "Ptr") ; GW_OWNER
                continue
            window_handles.Push(hwnd)
        }
    }
    window_total := window_handles.Length()
    if (window_total == 0)
    {
        keyboard_last_irfan_hwnd := 0
        keyboardSaveIrfanCycleAnchor(0)
        return false
    }

    ; Stable order even though WinGet's list follows Windows Z-order.
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
    anchor_index := 0
    ; Prefer the currently active IrfanView; otherwise continue last cycle.
    for index, hwnd in window_handles
    {
        if (hwnd == active_handle)
        {
            anchor_index := index
            break
        }
    }
    if (anchor_index == 0)
    {
        for index, hwnd in window_handles
        {
            if (hwnd == keyboard_last_irfan_hwnd)
            {
                anchor_index := index
                break
            }
        }
    }
    if (anchor_index > 0)
        next_index := Mod(anchor_index, window_total) + 1

    target_hwnd := window_handles[next_index]
    WinGet, window_state, MinMax, % "ahk_id " . target_hwnd
    if (window_state == -1)
        WinRestore, % "ahk_id " . target_hwnd
    WinActivate, % "ahk_id " . target_hwnd
    keyboard_last_irfan_hwnd := target_hwnd
    keyboardSaveIrfanCycleAnchor(target_hwnd)
    return true
}

/*
Restore the previous cycle HWND so this separate action process can continue
cycling when focus moves to another application between hotkey presses.
*/
keyboardReadIrfanCycleAnchor()
{
    global keyboard_last_irfan_hwnd
    settings_file := A_Temp . "\KeyboardSetupIrfanCycle.ini"
    IniRead, previous_hwnd, %settings_file%, IrfanView, LastHwnd, 0
    keyboard_last_irfan_hwnd := previous_hwnd + 0
}

/*
Persist only the previous window handle in the user temp directory.
The next run ignores stale handles that no longer belong to an IrfanView window.
*/
keyboardSaveIrfanCycleAnchor(hwnd)
{
    settings_file := A_Temp . "\KeyboardSetupIrfanCycle.ini"
    IniWrite, %hwnd%, %settings_file%, IrfanView, LastHwnd
}

; Clipboard image formats: CF_BITMAP, CF_DIB, CF_DIBV5, CF_ENHMETAFILE and PNG. 
keyboardClipboardHasImage()
{
    if (DllCall("IsClipboardFormatAvailable", "UInt", 2)
     || DllCall("IsClipboardFormatAvailable", "UInt", 8)
     || DllCall("IsClipboardFormatAvailable", "UInt", 17)
     || DllCall("IsClipboardFormatAvailable", "UInt", 14))
        return true
    png_format := DllCall("RegisterClipboardFormat", "Str", "PNG", "UInt")
    return png_format && DllCall("IsClipboardFormatAvailable", "UInt", png_format)
}

; Support pasted Windows paths and files copied in Explorer as CF_HDROP. 
keyboardClipboardImagePath()
{
    candidate := Trim(Clipboard, " `t`r`n" . Chr(34))
    if (keyboardIsImageFile(candidate))
        return candidate
    if !DllCall("IsClipboardFormatAvailable", "UInt", 15)
        return ""
    if !DllCall("OpenClipboard", "Ptr", 0)
        return ""

    hdrop := DllCall("GetClipboardData", "UInt", 15, "Ptr")
    candidate := ""
    if (hdrop)
    {
        count := DllCall("shell32\DragQueryFileW", "Ptr", hdrop, "UInt", 0xFFFFFFFF, "Ptr", 0, "UInt", 0)
        if (count == 1)
        {
            length := DllCall("shell32\DragQueryFileW", "Ptr", hdrop, "UInt", 0, "Ptr", 0, "UInt", 0)
            if (length > 0)
            {
                VarSetCapacity(file_name, (length + 1) * 2, 0)
                DllCall("shell32\DragQueryFileW", "Ptr", hdrop, "UInt", 0, "Ptr", &file_name, "UInt", length + 1)
                candidate := StrGet(&file_name, length, "UTF-16")
            }
        }
    }
    DllCall("CloseClipboard")
    return keyboardIsImageFile(candidate) ? candidate : ""
}

keyboardIsImageFile(path)
{
    if (path == "" || !FileExist(path) || InStr(FileExist(path), "D"))
        return false
    return RegExMatch(path, "i)\.(png|jpg|jpeg|gif|bmp|dib|tif|tiff|webp|ico|jp2|j2k|avif|heic|heif|psd|svg|pcx|tga|dds|exr|hdr|jxl|jfif)$") != 0
}

keyboardIsIrfanViewExe(path)
{
    if (path == "" || !FileExist(path) || InStr(FileExist(path), "D"))
        return false
    return RegExMatch(path, "i)\\i_view(32|64)\.exe$") != 0
}

keyboardFindIrfanView()
{
    global keyboard_project_dir
    settings_file := keyboard_project_dir . "\config\Keyboard-Setup-Applications.ini"
    IniRead, configured_path, %settings_file%, IrfanView, Executable, ERROR
    configured_path := Trim(configured_path, " `t`r`n" . Chr(34))
    if (keyboardIsIrfanViewExe(configured_path))
        return configured_path

    for index, exe_name in ["i_view64.exe", "i_view32.exe"]
    {
        for key_index, registry_root in ["HKCU", "HKLM"]
        {
            registry_key := "SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\" . exe_name
            RegRead, registry_path, %registry_root%, %registry_key%
            if (!ErrorLevel && keyboardIsIrfanViewExe(registry_path))
                return registry_path
        }
    }

    EnvGet, program_files_x86, ProgramFiles(x86)
    candidates := [A_ProgramFiles . "\IrfanView\i_view64.exe"
                , A_ProgramFiles . "\IrfanView\i_view32.exe"
                , program_files_x86 . "\IrfanView\i_view32.exe"
                , program_files_x86 . "\IrfanView\i_view64.exe"]
    for index, candidate in candidates
    {
        if keyboardIsIrfanViewExe(candidate)
            return candidate
    }
    return ""
}

; Ask for the executable once and remember it under config/. 
keyboardBrowseIrfanView()
{
    global keyboard_project_dir
    FileSelectFile, selected_path, 3, %A_ProgramFiles%, Locate IrfanView (i_view64.exe or i_view32.exe), Executables (*.exe)
    if (selected_path == "")
        return ""
    if !keyboardIsIrfanViewExe(selected_path)
    {
        MsgBox, 48, Keyboard Setup, Please choose i_view64.exe or i_view32.exe.
        return ""
    }
    settings_dir := keyboard_project_dir . "\config"
    FileCreateDir, %settings_dir%
    settings_file := settings_dir . "\Keyboard-Setup-Applications.ini"
    IniWrite, %selected_path%, %settings_file%, IrfanView, Executable
    if (ErrorLevel)
        TrayTip, Keyboard Setup, IrfanView path could not be saved. It will be requested next time., 5, 1
    return selected_path
}
