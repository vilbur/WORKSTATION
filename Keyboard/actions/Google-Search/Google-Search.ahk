#NoEnv
#Requires AutoHotkey v1.1
#SingleInstance Off
#Include %A_ScriptDir%\..\..\src\Keyboard-Setup-Action-Common.ahk
keyboard_project_dir := A_ScriptDir . "\..\.."
SetWorkingDir, %keyboard_project_dir%
SendMode, Input
if !keyboardRunBoundFile("Win+G")
{
    searchOrCycleChrome()
}
ExitApp

/*
Percent-encode UTF-8 text for a web query string.
*/
keyboardUrlEncode(input_text)
{
    byte_count := StrPut(input_text, "UTF-8") - 1
    VarSetCapacity(buffer, byte_count + 1, 0)
    StrPut(input_text, &buffer, byte_count + 1, "UTF-8")
    encoded_text := ""
    Loop, %byte_count%
    {
        byte_value := NumGet(buffer, A_Index - 1, "UChar")
        if ((byte_value >= 0x30 && byte_value <= 0x39) || (byte_value >= 0x41 && byte_value <= 0x5A) || (byte_value >= 0x61 && byte_value <= 0x7A) || byte_value == 0x2D || byte_value == 0x2E || byte_value == 0x5F || byte_value == 0x7E)
        {
            encoded_text .= Chr(byte_value)
        }
        else
        {
            encoded_text .= "%" . Format("{:02X}", byte_value)
        }
    }
    return encoded_text
}

/*
Search selected text, otherwise cycle visible Chrome windows or start Chrome.
*/
searchOrCycleChrome()
{
    selected_text := keyboardReadSelection()
    if (Trim(selected_text) != "")
    {
        keyboardOpenChromeUrl("https://www.google.com/search?q=" . keyboardUrlEncode(selected_text))
        return
    }

    if !keyboardCycleWindows("ahk_exe chrome.exe")
    {
        Run, chrome.exe, , UseErrorLevel
        if (ErrorLevel)
        {
            Run, https://www.google.com/
        }
    }
}
