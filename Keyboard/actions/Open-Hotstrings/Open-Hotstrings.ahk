#NoEnv
#Requires AutoHotkey v1.1
#SingleInstance Off
#Include %A_ScriptDir%\..\..\src\Keyboard-Setup-Toolkit-Actions.ahk
; Open hotstrings file: delegates to the existing external tool without copying it.
keyboard_project_dir := A_ScriptDir . "\..\.."
SetWorkingDir, %keyboard_project_dir%
keyboardRunToolkitAction("Shift+Win+H", "C:\GoogleDrive\ProgramsData\Core\AutoHotkey\Hotstrings\open-hotstrings-file.ahk")
ExitApp
