$ErrorActionPreference = 'Stop'
$utility_path = Join-Path $PSScriptRoot '..\Library\Kill-Window-List-Manager.ps1'
. $utility_path -NoExecute

$cases = @(
    @{ label = 'compiled manager'; name = 'Window-List-Manager.exe'; command = '"G:\WORKSTATION\Windows\Window-List-Manager\Window-List-Manager.exe"'; expected = $true }
    @{ label = 'compiled name must be exact'; name = 'Window-List-Manager-Backup.exe'; command = '"G:\Tools\Window-List-Manager-Backup.exe"'; expected = $false }
    @{ label = 'root script'; name = 'AutoHotkey64.exe'; command = '"C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe" "G:\WORKSTATION\Windows\Window-List-Manager\Window-List-Manager.ahk"'; expected = $true }
    @{ label = 'versioned Lib script'; name = 'AutoHotkey-v2.exe'; command = '"G:\Runtime\AutoHotkey-v2.exe" "G:\WORKSTATION\Windows\Window-List-Manager\Lib\Window-List-Manager-0.238.ahk"'; expected = $true }
    @{ label = 'legacy multi-dot version'; name = 'AutoHotkey.exe'; command = 'AutoHotkey.exe G:\Window-List-Manager\Lib\Window-List-Manager-0.21.14.ahk'; expected = $true }
    @{ label = 'unrelated AHK process'; name = 'AutoHotkey64.exe'; command = '"AutoHotkey64.exe" "G:\Tools\Keyboard-Manager.ahk"'; expected = $false }
    @{ label = 'unrelated script with manager path as argument'; name = 'AutoHotkey64.exe'; command = 'AutoHotkey64.exe G:\Tools\Keyboard-Manager.ahk G:\Window-List-Manager\Window-List-Manager.ahk'; expected = $false }
    @{ label = 'recovery utility itself'; name = 'AutoHotkey64.exe'; command = 'AutoHotkey64.exe G:\Window-List-Manager\Kill-Window-List-Manager.ahk'; expected = $false }
    @{ label = 'unrelated process with matching command argument'; name = 'powershell.exe'; command = 'powershell.exe -File G:\Window-List-Manager\Window-List-Manager.ahk'; expected = $false }
    @{ label = 'inaccessible command line'; name = 'AutoHotkey64.exe'; command = $null; expected = $false }
)

$passed = 0
foreach ($case in $cases)
{
    $process_info = [pscustomobject]@{ Name = $case.name; CommandLine = $case.command; ProcessId = 999999 }
    $actual = isWindowListManagerProcess $process_info
    if ($actual -ne $case.expected)
    {
        throw ('FAIL: {0}; expected={1}; actual={2}' -f $case.label, $case.expected, $actual)
    }
    $passed++
}
Write-Host ("PASS: {0} process identification cases" -f $passed)
