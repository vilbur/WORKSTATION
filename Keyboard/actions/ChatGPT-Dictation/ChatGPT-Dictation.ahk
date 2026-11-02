#NoEnv
#Requires AutoHotkey v1.1
#SingleInstance Off
#Include %A_ScriptDir%\..\..\src\Keyboard-Setup-Toolkit-Actions.ahk
; ChatGPT dictate mode: delegates to the existing external tool without copying it.
keyboard_project_dir := A_ScriptDir . "\..\.."
SetWorkingDir, %keyboard_project_dir%
keyboardRunToolkitAction("Win+Space", "C:\GoogleDrive\ProgramsData\Core\ChatGPT\ahk\run-chat-and-start-or-stop-dictate-mode.ahk")
ExitApp
