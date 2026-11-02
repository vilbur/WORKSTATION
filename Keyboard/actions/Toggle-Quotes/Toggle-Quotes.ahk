#NoEnv
#Requires AutoHotkey v1.1
#SingleInstance Off
#Include %A_ScriptDir%\..\..\src\Keyboard-Setup-Action-Common.ahk
keyboard_project_dir := A_ScriptDir . "\..\.."
SetWorkingDir, %keyboard_project_dir%
SendMode, Input
if !keyboardRunBoundFile("Ctrl+Shift+'")
{
    keyboardApplyTextTransform(Func("keyboardToggleQuotes"))
}
ExitApp

/*
Wrap selected text in double quotes or remove its matching outer quotes.
*/
keyboardToggleQuotes(input_text)
{
    quote_character := Chr(34)
    text_length := StrLen(input_text)
    if (text_length >= 2 && SubStr(input_text, 1, 1) == quote_character && SubStr(input_text, 0) == quote_character)
    {
        return SubStr(input_text, 2, text_length - 2)
    }
    return quote_character . input_text . quote_character
}
