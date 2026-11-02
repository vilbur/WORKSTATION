param(
    [switch]$NoExecute,
    [switch]$ListOnly
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Identify only the compiled Window List Manager or a known AHK runner executing its script.
function isWindowListManagerProcess
{
    param([object]$process_info)

    if ($null -eq $process_info)
    {
        return $false
    }

    if ($process_info.Name -ieq 'Window-List-Manager.exe')
    {
        return $true
    }

    $runner_names = @('AutoHotkey.exe', 'AutoHotkey32.exe', 'AutoHotkey64.exe', 'AutoHotkeyU32.exe', 'AutoHotkeyU64.exe', 'AutoHotkey-v2.exe', 'AutoHotkey32_UIA.exe', 'AutoHotkey64_UIA.exe')
    if ($runner_names -notcontains $process_info.Name -or [string]::IsNullOrWhiteSpace($process_info.CommandLine))
    {
        return $false
    }

    # The first .ahk argument is the executed script; later arguments must not match.
    $script_match = [regex]::Match([string]$process_info.CommandLine, '(?i)(?:"([^"\r\n]+\.ahk)"|([^\s"]+\.ahk))(?=\s|$)')
    if (!$script_match.Success)
    {
        return $false
    }

    $script_path = if ($script_match.Groups[1].Success) { $script_match.Groups[1].Value } else { $script_match.Groups[2].Value }
    $script_name = [System.IO.Path]::GetFileName($script_path)
    return $script_name -match '^Window-List-Manager(?:-[0-9]+(?:\.[0-9]+)+)?\.ahk$'
}

if ($NoExecute)
{
    return
}

try
{
    $all_processes = @(Get-CimInstance -ClassName Win32_Process -ErrorAction Stop)
}
catch
{
    Write-Error ('Cannot enumerate processes: {0}' -f $_.Exception.Message)
    exit 1
}

$targets = @($all_processes | Where-Object { $_.ProcessId -ne $PID -and (isWindowListManagerProcess $_) })
if ($targets.Count -eq 0)
{
    Write-Host 'No running Window List Manager instances found.'
    exit 0
}

$stopped = 0
$failed = 0
foreach ($instance in $targets)
{
    $manager_process_id = [int]$instance.ProcessId
    if ($ListOnly)
    {
        Write-Host ('Would stop PID {0} ({1})' -f $manager_process_id, $instance.Name)
        continue
    }

    try
    {
        Stop-Process -Id $manager_process_id -Force -ErrorAction Stop
        $stopped++
        Write-Host ('Stopped PID {0} ({1})' -f $manager_process_id, $instance.Name)
    }
    catch
    {
        $failed++
        Write-Warning ('Could not stop PID {0}: {1}' -f $manager_process_id, $_.Exception.Message)
    }
}

if ($ListOnly)
{
    Write-Host ('Found {0} matching instance(s); no processes stopped.' -f $targets.Count)
    exit 0
}

Write-Host ('Stopped {0} Window List Manager instance(s).' -f $stopped)
if ($failed -gt 0)
{
    Write-Warning ('{0} instance(s) could not be stopped. Run the CMD launcher as administrator if necessary.' -f $failed)
    exit 1
}
exit 0
