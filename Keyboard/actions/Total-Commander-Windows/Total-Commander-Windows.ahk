#NoEnv
#Requires AutoHotkey v1.1
#SingleInstance Off
#Include %A_ScriptDir%\..\..\src\Keyboard-Setup-Action-Common.ahk
keyboard_project_dir := A_ScriptDir . "\..\.."
SetWorkingDir, %keyboard_project_dir%
SendMode, Input
if !keyboardRunBoundFile("Win+C")
{
    cycleTotalCommander()
}
ExitApp

/*
Cycle open Total Commander windows, or start Total Commander when absent.
*/
cycleTotalCommander()
{
    if keyboardCycleWindows("ahk_class TTOTAL_CMD")
    {
        return
    }

    Run, TOTALCMD64.EXE, , UseErrorLevel
    if (ErrorLevel)
    {
        Run, TOTALCMD.EXE, , UseErrorLevel
        if (ErrorLevel)
        {
            TrayTip, Keyboard Setup, Could not locate Total Commander., 6, 2
        }
    }
}
