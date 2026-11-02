#Requires AutoHotkey v2.0
#SingleInstance Off

/* Run the packaged PowerShell helper relative to the main executable.
*/
helper_path := A_ScriptDir "\Library\Install-Chrome-Extension.ps1"
powershell_path := A_WinDir "\System32\WindowsPowerShell\v1.0\powershell.exe"
check_only := A_Args.Length > 0 && A_Args[1] = "--check"
try
{
    if !FileExist(helper_path)
        throw Error("Helper missing: " helper_path)
    if !FileExist(powershell_path)
        throw Error("Windows PowerShell missing: " powershell_path)
    if check_only
        ExitApp(0)
    quote := Chr(34)
    exit_code := RunWait(quote powershell_path quote " -NoProfile -ExecutionPolicy Bypass -File " quote helper_path quote, A_ScriptDir)
    if exit_code
        throw Error("The operation failed with exit code " exit_code ". Check the PowerShell error.")
}
catch as operation_error
{
    if check_only
        ExitApp(2)
    MsgBox(operation_error.Message, "Window List Manager Setup")
    ExitApp(1)
}
ExitApp(0)
