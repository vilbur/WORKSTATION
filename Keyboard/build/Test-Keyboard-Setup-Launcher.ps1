$ErrorActionPreference = 'Stop'
$build_dir = Split-Path -Parent $MyInvocation.MyCommand.Path
$project_dir = Split-Path -Parent $build_dir
$hta_path = Join-Path $project_dir 'Keyboard-Setup-Design-Options.hta'
$shortcut_path = Join-Path $project_dir 'Keyboard-Setup.lnk'
$launcher_path = Join-Path $project_dir 'Keyboard-Setup-Launcher.exe'
$icon_path = Join-Path $project_dir 'assets\Keyboard-Setup.ico'
$source_path = Join-Path $project_dir 'Keyboard-Setup-Launcher.ahk'

if (-not (Test-Path -LiteralPath $source_path)) { throw "FAIL: Fallback AHK is missing: $source_path" }

if (-not (Test-Path -LiteralPath $hta_path)) {
    throw "FAIL: HTA is missing: $hta_path"
}

if (-not (Test-Path -LiteralPath $shortcut_path)) {
    throw "FAIL: Run Build-Keyboard-Setup.cmd first; shortcut is missing: $shortcut_path"
}

$shell = New-Object -ComObject WScript.Shell
$shortcut = $shell.CreateShortcut($shortcut_path)
if (-not (Test-Path -LiteralPath $launcher_path)) {
    throw "FAIL: Launcher EXE is missing: $launcher_path"
}

if (-not (Test-Path -LiteralPath $icon_path)) {
    throw "FAIL: Launcher icon is missing: $icon_path"
}

if ($shortcut.TargetPath -ne $launcher_path) {
    throw "FAIL: Shortcut target is '$($shortcut.TargetPath)', expected '$launcher_path'."
}

if ($shortcut.IconLocation -notlike ($icon_path + '*')) {
    throw "FAIL: Shortcut icon is '$($shortcut.IconLocation)', expected '$icon_path'."
}

Write-Host 'PASS: Keyboard-Setup.lnk points to the launcher EXE and its custom icon.' -ForegroundColor Green
