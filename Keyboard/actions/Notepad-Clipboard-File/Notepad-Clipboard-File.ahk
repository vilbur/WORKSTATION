#NoEnv
#Requires AutoHotkey v1.1
#SingleInstance Off
#Include %A_ScriptDir%\..\..\src\Keyboard-Setup-Toolkit-Actions.ahk
; Open clipboard file in Notepad++: delegates to the existing external tool without copying it.
keyboard_project_dir := A_ScriptDir . "\..\.."
SetWorkingDir, %keyboard_project_dir%
keyboardRunToolkitAction("Ctrl+Win+N", "C:\GoogleDrive\ProgramsData\Core\Notepad++\AHK\Open-specific-file-types-from-clipboard-in-Notepad.ahk")
ExitApp
