#NoEnv
#Requires AutoHotkey v1.1
#SingleInstance Off
#Include %A_ScriptDir%\..\..\src\Keyboard-Setup-Action-Common.ahk
keyboard_project_dir := A_ScriptDir . "\..\.."
SetWorkingDir, %keyboard_project_dir%
SendMode, Input
if !keyboardRunBoundFile("Ctrl+Shift+U")
{
    keyboardApplyTextTransform(Func("keyboardCycleConvention"), true)
}
ExitApp

/*
Convert text to the next of eight naming conventions without removing line breaks.
*/
keyboardCycleConvention(input_text)
{
    line_break := InStr(input_text, "`r`n") ? "`r`n" : "`n"
    normalized_text := StrReplace(input_text, "`r`n", "`n")
    result_text := ""
    for line_index, line_text in StrSplit(normalized_text, "`n")
    {
        if (line_index > 1)
        {
            result_text .= line_break
        }
        result_text .= keyboardCycleConventionLine(line_text)
    }
    return result_text
}

/*
Detect and advance the naming style of one line.
*/
keyboardCycleConventionLine(line_text)
{
    if (Trim(line_text) == "")
    {
        return line_text
    }

    working_text := RegExReplace(line_text, "([A-Z])([A-Z][a-z])", "$1 $2")
    working_text := RegExReplace(working_text, "([a-z0-9])([A-Z])", "$1 $2")
    working_text := Trim(RegExReplace(working_text, "[_\s]+", " "))
    StringLower, working_text, working_text
    words := StrSplit(working_text, " ")

    next_style := 1
    Loop, 8
    {
        if (keyboardComposeConvention(words, A_Index) == line_text)
        {
            next_style := Mod(A_Index, 8) + 1
            break
        }
    }
    return keyboardComposeConvention(words, next_style)
}

/*
Compose a list of words using one of the eight supported styles.
*/
keyboardComposeConvention(words, style_index)
{
    result_text := ""
    for word_index, word_text in words
    {
        StringLower, lower_word, word_text
        StringUpper, upper_word, lower_word
        StringUpper, capital_word, lower_word, T

        if (style_index == 1 || style_index == 2 || style_index == 3)
        {
            separator := word_index > 1 ? " " : ""
        }
        else if (style_index >= 6)
        {
            separator := word_index > 1 ? "_" : ""
        }
        else
        {
            separator := ""
        }

        if (style_index == 1 || style_index == 6 || (style_index == 5 && word_index == 1))
        {
            converted_word := lower_word
        }
        else if (style_index == 3 || style_index == 8)
        {
            converted_word := upper_word
        }
        else
        {
            converted_word := capital_word
        }
        result_text .= separator . converted_word
    }
    return result_text
}
