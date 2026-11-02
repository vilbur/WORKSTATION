#NoEnv
#Requires AutoHotkey v1.1
#SingleInstance Off
#Include %A_ScriptDir%\..\..\src\Keyboard-Setup-Toolkit-Actions.ahk
; Suspend key (no action): delegates to the existing external tool without copying it.
keyboard_project_dir := A_ScriptDir . "\..\.."
SetWorkingDir, %keyboard_project_dir%
keyboardRunToolkitAction("Win+M", "C:\GoogleDrive\ProgramsData\Core\AutoHotkey\Lib\Window\SuspendKey-DoNothing.ahk")
ExitApp
