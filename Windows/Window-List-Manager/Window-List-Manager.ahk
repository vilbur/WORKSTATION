#Requires AutoHotkey v2.0
#SingleInstance Off

/* Compare dotted numeric tool versions without alphabetic filename sorting.
*/
isNewerVersion(candidate_version, current_version)
{
    candidate_parts := StrSplit(candidate_version, ".")
    current_parts := StrSplit(current_version, ".")
    Loop Max(candidate_parts.Length, current_parts.Length)
    {
        candidate_part := A_Index <= candidate_parts.Length ? Integer(candidate_parts[A_Index]) : 0
        current_part := A_Index <= current_parts.Length ? Integer(current_parts[A_Index]) : 0
        if (candidate_part != current_part)
            return candidate_part > current_part
    }
    return false
}

/* Select the highest numbered implementation from the project's Lib folder.
*/
findLatestTool(project_dir)
{
    selected_path := ""
    selected_version := "0"
    Loop Files project_dir "\Lib\Window-List-Manager-*.ahk", "F"
    {
        if !RegExMatch(A_LoopFileName, "^Window-List-Manager-(\d+(?:\.\d+){1,3})\.ahk$", &version_match)
            continue
        if (selected_path = "" || isNewerVersion(version_match[1], selected_version))
        {
            selected_path := A_LoopFileFullPath
            selected_version := version_match[1]
        }
    }
    return selected_path
}

/* Exercise version ordering without opening the tool.
*/
testLauncherVersions()
{
    if !isNewerVersion("0.221", "0.220")
        throw Error("Thousandth increment ordering failed.")
    if !isNewerVersion("0.010", "0.009")
        throw Error("Leading-zero ordering failed.")
    if !isNewerVersion("1.000", "0.999")
        throw Error("Major rollover ordering failed.")
    if !isNewerVersion("0.220", "0.22.0")
        throw Error("New format must take precedence over legacy filenames.")
    if !isNewerVersion("0.21.10", "0.21.9")
        throw Error("Numeric patch ordering failed.")
    if !isNewerVersion("0.22", "0.21.99")
        throw Error("Minor version ordering failed.")
    if isNewerVersion("0.21.8", "0.21.8")
        throw Error("Equal versions must not replace each other.")
    if isNewerVersion("0.21.7", "0.21.8")
        throw Error("Older version selected.")
}

check_only := A_Args.Length > 0 && A_Args[1] = "--check"
test_only := A_Args.Length > 0 && A_Args[1] = "--test"
try
{
    testLauncherVersions()
    if test_only
        ExitApp(0)
    tool_source := findLatestTool(A_ScriptDir)
    if (tool_source = "")
        throw Error("No versioned tool found in " A_ScriptDir "\Lib\Window-List-Manager-*.ahk")
    runtime_path := A_IsCompiled ? A_ScriptDir "\Library\AutoHotkey-v2.exe" : A_AhkPath
    if !FileExist(runtime_path)
        throw Error("AHK v2 runtime missing: " runtime_path ". Run Build-EXE.cmd.")
    if check_only
        ExitApp(0)
    quote := Chr(34)
    Run(quote runtime_path quote " " quote tool_source quote, A_ScriptDir)
}
catch as launch_error
{
    if (check_only || test_only)
        ExitApp(2)
    MsgBox(launch_error.Message, "Window List Manager Launcher")
    ExitApp(1)
}
ExitApp(0)
