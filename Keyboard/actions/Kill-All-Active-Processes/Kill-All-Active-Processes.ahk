#NoEnv
#Requires AutoHotkey v1.1
#SingleInstance Off
#Include %A_ScriptDir%\..\..\src\Keyboard-Setup-Toolkit-Actions.ahk
; Kill all active-window processes: delegates to the existing external tool without copying it.
keyboard_project_dir := A_ScriptDir . "\..\.."
SetWorkingDir, %keyboard_project_dir%
keyboardRunToolkitAction("Ctrl+Win+F4", "C:\GoogleDrive\ProgramsData\Core\Windows\_AhkScripts\kill-ALL-PROCESESES-of-active-window.ahk")
ExitApp
