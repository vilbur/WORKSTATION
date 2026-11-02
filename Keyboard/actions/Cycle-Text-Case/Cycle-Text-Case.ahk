#NoEnv
#Requires AutoHotkey v1.1
#SingleInstance Off
#Include %A_ScriptDir%\..\..\src\Keyboard-Setup-Action-Common.ahk
keyboard_project_dir := A_ScriptDir . "\..\.."
SetWorkingDir, %keyboard_project_dir%
SendMode, Input
if !keyboardRunBoundFile("Ctrl+U")
{
    keyboardApplyTextTransform(Func("keyboardToggleThreeCase"))
}
ExitApp

/*
Cycle selected text through UPPERCASE, lowercase and Capital words.
*/
keyboardToggleThreeCase(input_text)
{
    if !RegExMatch(input_text, "\p{L}")
    {
        return input_text
    }

    StringLower, lower_text, input_text
    StringUpper, upper_text, input_text
    StringUpper, capital_text, lower_text, T

    if (input_text == upper_text)
    {
        return lower_text
    }
    if (input_text == lower_text)
    {
        return capital_text
    }
    return upper_text
}
