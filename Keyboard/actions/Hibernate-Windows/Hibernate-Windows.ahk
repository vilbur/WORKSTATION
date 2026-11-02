#NoEnv
#Requires AutoHotkey v1.1
#SingleInstance Off
#Include %A_ScriptDir%\..\..\src\Keyboard-Setup-Toolkit-Actions.ahk
; Hibernate Windows: delegates to the existing external tool without copying it.
keyboard_project_dir := A_ScriptDir . "\..\.."
SetWorkingDir, %keyboard_project_dir%
keyboardRunToolkitAction("Ctrl+Win+H", "C:\GoogleDrive\ProgramsData\Core\Windows\_AhkScripts\Hibernate-Windows.bat")
ExitApp
