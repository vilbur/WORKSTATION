#NoEnv
#Requires AutoHotkey v1.1
#SingleInstance Off
#Include %A_ScriptDir%\..\..\src\Keyboard-Setup-Toolkit-Actions.ahk
; Mute launcher: delegates to the existing external tool without copying it.
keyboard_project_dir := A_ScriptDir . "\..\.."
SetWorkingDir, %keyboard_project_dir%
keyboardRunToolkitAction("Win+Pause", "M:\MediaMonkey\Ahk\Mute-Temporary\Mute-Launcher.ahk")
ExitApp
