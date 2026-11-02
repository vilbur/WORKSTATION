param([switch]$ValidateOnly)
# Run in PowerShell on Windows with AutoHotkey v2 and Ahk2Exe installed.
$ErrorActionPreference = 'Stop'
$library = Split-Path -Parent $MyInvocation.MyCommand.Path
$folder = Split-Path -Parent $library
$toolSource = Join-Path $folder 'Window-List-Manager.ahk'
$source = $toolSource
$icon = Join-Path $library 'Window-List-Manager.ico'
$output = Join-Path $folder 'Window-List-Manager.exe'
if (-not (Test-Path -LiteralPath $toolSource -PathType Leaf)) {
    throw "AHK source missing: $toolSource . Make this file available offline in Google Drive, then retry."
}
if (-not (Test-Path -LiteralPath $icon -PathType Leaf)) {
    $rootIcon = Join-Path $folder 'Window-List-Manager.ico'
    if (Test-Path -LiteralPath $rootIcon -PathType Leaf) { $icon = $rootIcon }
    else {
        Write-Warning "Icon missing: $icon . Building with the default icon."
        $icon = $null
    }
}
Write-Host "Launcher: $source"
Write-Host "Current tool: $toolSource"
Write-Host "Output: $output"
if ($ValidateOnly) {
    Write-Host 'Build paths validated. Compilation skipped.'
    exit 0
}
$roots = @(${env:ProgramFiles}, ${env:ProgramFiles(x86)}) | Where-Object { $_ }
$compilerCandidates = @($roots | ForEach-Object { Join-Path $_ 'AutoHotkey\Compiler\Ahk2Exe.exe' }) | Where-Object { Test-Path $_ }
$compiler = $compilerCandidates | Select-Object -First 1
if (-not $compiler) {
    $command = Get-Command Ahk2Exe.exe -ErrorAction SilentlyContinue
    if ($command) { $compiler = $command.Source }
}
if (-not $compiler) { throw 'Ahk2Exe.exe was not found. Install the AutoHotkey compiler first.' }
$baseCandidates = @($roots | ForEach-Object {
    Join-Path $_ 'AutoHotkey\v2\AutoHotkey64.exe'
    Join-Path $_ 'AutoHotkey\v2\AutoHotkey32.exe'
}) | Where-Object { Test-Path $_ }
$base = $baseCandidates | Select-Object -First 1
if (-not $base) { throw 'AutoHotkey v2 executable was not found in the standard installation directories.' }
$runtimePath = Join-Path $library 'AutoHotkey-v2.exe'
Copy-Item -LiteralPath $base -Destination $runtimePath -Force
$temporaryOutput = Join-Path $folder ('Window-List-Manager-build-' + [guid]::NewGuid().ToString('N') + '.exe')
$argumentLine = '/in "{0}" /out "{1}" /base "{2}"' -f $source, $temporaryOutput, $base
if ($icon) { $argumentLine += ' /icon "{0}"' -f $icon }
Write-Host "Compiler: $compiler"
Write-Host "AHK v2 base: $base"
Write-Host 'Compiling; waiting for Ahk2Exe to finish...'
try {
    $compilerProcess = Start-Process -FilePath $compiler -ArgumentList $argumentLine -WorkingDirectory $folder -Wait -PassThru
    if ($compilerProcess.ExitCode -ne 0) {
        throw "Ahk2Exe failed with exit code $($compilerProcess.ExitCode). Check the compiler error dialog."
    }
    if (-not (Test-Path -LiteralPath $temporaryOutput -PathType Leaf)) {
        throw "Ahk2Exe exited with code 0 but did not create: $temporaryOutput . Check the compiler error dialog."
    }
    if ((Get-Item -LiteralPath $temporaryOutput).Length -eq 0) {
        throw "Ahk2Exe created an empty executable: $temporaryOutput"
    }
    $launcherCheck = Start-Process -FilePath $temporaryOutput -ArgumentList '--check' -WorkingDirectory $folder -Wait -PassThru
    if ($launcherCheck.ExitCode -ne 0) {
        throw "Launcher self-test failed with exit code $($launcherCheck.ExitCode)."
    }
    try {
        Move-Item -LiteralPath $temporaryOutput -Destination $output -Force
    }
    catch {
        throw "Compilation succeeded but the EXE could not be replaced. Close the running Window List Manager and retry. New build: $temporaryOutput . $($_.Exception.Message)"
    }
}
catch {
    Write-Host "Build failed: $($_.Exception.Message)" -ForegroundColor Red
    throw
}
Write-Host "Created: $output"
Write-Host 'Launcher built and path self-test passed. Keep Window-List-Manager.ahk and Library beside this EXE.'
Write-Host 'The launcher selects the newest Lib/Window-List-Manager-<version>.ahk on each start.'


# Compile the user-facing setup/build entries; scripts remain in Library.
$entryDefinitions = @(
    @{ Source = 'Build-EXE-Entry.ahk'; Output = 'Build-EXE.exe' },
    @{ Source = 'Install-Chrome-Extension-Entry.ahk'; Output = 'Install-Chrome-Extension.exe' }
)
foreach ($entry in $entryDefinitions) {
    $entrySource = Join-Path $library $entry.Source
    $entryOutput = Join-Path $folder $entry.Output
    if (-not (Test-Path -LiteralPath $entrySource -PathType Leaf)) {
        throw "Entry source missing: $entrySource"
    }
    $entryTemporary = Join-Path $folder ('Entry-build-' + [guid]::NewGuid().ToString('N') + '.exe')
    $entryArguments = '/in "{0}" /out "{1}" /base "{2}"' -f $entrySource, $entryTemporary, $base
    if ($icon) { $entryArguments += ' /icon "{0}"' -f $icon }
    $entryCompiler = Start-Process -FilePath $compiler -ArgumentList $entryArguments -WorkingDirectory $folder -Wait -PassThru
    if ($entryCompiler.ExitCode -ne 0 -or -not (Test-Path -LiteralPath $entryTemporary -PathType Leaf)) {
        throw "Compilation failed for $($entry.Output). Compiler exit code: $($entryCompiler.ExitCode)"
    }
    $entryCheck = Start-Process -FilePath $entryTemporary -ArgumentList '--check' -WorkingDirectory $folder -Wait -PassThru
    if ($entryCheck.ExitCode -ne 0) {
        throw "Entry path self-test failed for $($entry.Output)."
    }
    if (Test-Path -LiteralPath $entryOutput) {
        try {
            Move-Item -LiteralPath $entryTemporary -Destination $entryOutput -Force
        }
        catch {
            # The build entry may be rebuilding itself. Keep the existing entry
            # only if its helper paths still pass the self-test.
            $existingCheck = Start-Process -FilePath $entryOutput -ArgumentList '--check' -WorkingDirectory $folder -Wait -PassThru
            if ($existingCheck.ExitCode -ne 0) { throw }
            Remove-Item -LiteralPath $entryTemporary
            Write-Host "Kept running entry: $entryOutput. External helper updated."
        }
    }
    else {
        Move-Item -LiteralPath $entryTemporary -Destination $entryOutput
    }
    Write-Host "Ready: $entryOutput"
}
Write-Host 'Use the three EXE files in the main folder. AHK, PS1 and CMD files are sources/helpers.'
