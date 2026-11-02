#NoEnv
#Requires AutoHotkey v1.1
#SingleInstance Off
#Include %A_ScriptDir%\..\..\src\Keyboard-Setup-Toolkit-Actions.ahk
; Run MAXScript from editor: delegates to the existing external tool without copying it.
keyboard_project_dir := A_ScriptDir . "\..\.."
SetWorkingDir, %keyboard_project_dir%
keyboardRunToolkitAction("Win+R", "C:\Users\vilbur\AppData\Local\ActiveState\KomodoIDE\12.0\tools\Scripts\3Ds Max\runMaxScript\run-maxscript-via-notepad-komodo.ahk")
ExitApp
