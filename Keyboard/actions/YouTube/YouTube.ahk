#NoEnv
#Requires AutoHotkey v1.1
#SingleInstance Off
#Include %A_ScriptDir%\..\..\src\Keyboard-Setup-Action-Common.ahk
keyboard_project_dir := A_ScriptDir . "\..\.."
SetWorkingDir, %keyboard_project_dir%
SendMode, Input
if !keyboardRunBoundFile("Win+Y")
{
    activateYouTube()
}
ExitApp

/*
Open the YouTube homepage in a new Chrome window on every activation.
Existing browser windows and tabs are never reused by this action.
*/
activateYouTube()
{
    youtube_url := "https://www.youtube.com/"
    launch_command := "chrome.exe --new-window " . Chr(34) . youtube_url . Chr(34)
    Run, %launch_command%, , UseErrorLevel
    if (ErrorLevel)
    {
        TrayTip, Keyboard Setup, Could not start Google Chrome for YouTube., 6, 2
    }
}
