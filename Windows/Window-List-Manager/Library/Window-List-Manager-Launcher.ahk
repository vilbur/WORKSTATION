#Requires AutoHotkey v2.0
#SingleInstance Off

/* Launch the current external tool source instead of embedding a tool version.
*/
tool_source := A_ScriptDir "\Window-List-Manager.ahk"
runtime_path := A_ScriptDir "\Library\AutoHotkey-v2.exe"
check_only := A_Args.Length > 0 && A_Args[1] = "--check"
try
{
    if !FileExist(tool_source)
        throw Error("Tool source missing: " tool_source)
    if !FileExist(runtime_path)
        throw Error("Runtime missing: " runtime_path ". Run Build-EXE.cmd again.")
    if check_only
        ExitApp(0)
    quote := Chr(34)
    Run(quote runtime_path quote " " quote tool_source quote, A_ScriptDir)
}
catch as launch_error
{
    if check_only
        ExitApp(2)
    MsgBox(launch_error.Message, "Window List Manager Launcher")
    ExitApp(1)
}
ExitApp(0)
