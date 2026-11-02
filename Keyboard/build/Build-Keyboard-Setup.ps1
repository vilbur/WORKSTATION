$ErrorActionPreference = 'Stop'
$build_dir = Split-Path -Parent $MyInvocation.MyCommand.Path
$project_dir = Split-Path -Parent $build_dir
$source_path = Join-Path $project_dir 'Keyboard-Setup-Launcher.ahk'
$toolkit_path = Join-Path $project_dir 'src\Keyboard-Setup-Toolkit-Actions.ahk'
$action_common_path = Join-Path $project_dir 'src\Keyboard-Setup-Action-Common.ahk'
$index_path = Join-Path $project_dir 'src\Keyboard-Setup-Hotkey-Index.hta'
$catalog_path = Join-Path $project_dir 'data\Keyboard-Setup-Catalog.js'
$max_preset_path = Join-Path $project_dir 'data\Keyboard-Setup-Max-Preset.js'
$max_defaults_path = Join-Path $project_dir 'data\Keyboard-Setup-Max-Defaults.js'
$hta_path = Join-Path $project_dir 'Keyboard-Setup-Design-Options.hta'
$output_path = Join-Path $project_dir 'Keyboard-Setup-Launcher.exe'
$icon_path = Join-Path $project_dir 'assets\Keyboard-Setup.ico'
$shortcut_path = Join-Path $project_dir 'Keyboard-Setup.lnk'

if (-not (Test-Path -LiteralPath $source_path)) {
    throw "Launcher source is missing: $source_path"
}

foreach ($required in @($toolkit_path, $action_common_path)) {
    if (-not (Test-Path -LiteralPath $required)) { throw "Missing runtime action helper: $required" }
}

# Resolve the 21 action entrypoints from the launcher's own mapping so the
# build cannot silently ship an EXE beside incomplete Drive-synced actions.
$launcher_text = Get-Content -LiteralPath $source_path -Raw
$action_matches = [regex]::Matches($launcher_text, 'paths\["[^"]+"\]\s*:=\s*"(?<relative>actions\\[^"]+\.ahk)"')
$action_paths = @($action_matches | ForEach-Object { $_.Groups['relative'].Value })
if ($action_paths.Count -ne 21) {
    throw "Expected 21 registered action files; found $($action_paths.Count)."
}
foreach ($relative_path in $action_paths) {
    $action_file = Join-Path $project_dir $relative_path
    if (-not (Test-Path -LiteralPath $action_file)) { throw "Missing action file: $action_file" }
}

foreach ($required in @($index_path, $catalog_path)) {
    if (-not (Test-Path -LiteralPath $required)) { throw "Missing Hotkey Index dependency: $required" }
}

if (-not (Test-Path -LiteralPath $hta_path)) {
    throw "HTA is missing: $hta_path"
}

if (-not (Test-Path -LiteralPath $max_preset_path)) {
    throw "3ds Max preset snapshot is missing: $max_preset_path"
}

if (-not (Test-Path -LiteralPath $max_defaults_path)) {
    throw "3ds Max factory shortcut snapshot is missing: $max_defaults_path"
}

$importer_path = Join-Path $project_dir 'import\3DsMax\3DsMax-Importer.ahk'
$exporter_path = Join-Path $project_dir 'import\3DsMax\3DsMax-Export.ms'
$import_ui_path = Join-Path $project_dir 'import\3DsMax\3DsMax-Importer.js'
foreach ($required in @($importer_path, $exporter_path, $import_ui_path)) {
    if (-not (Test-Path -LiteralPath $required)) { throw "Missing runtime file: $required" }
}

if (-not (Test-Path -LiteralPath $icon_path)) {
    throw "Launcher icon is missing: $icon_path"
}

$compiler_candidates = @(
    (Join-Path $env:ProgramFiles 'AutoHotkey\v1\Compiler\Ahk2Exe.exe'),
    (Join-Path ${env:ProgramFiles(x86)} 'AutoHotkey\v1\Compiler\Ahk2Exe.exe'),
    (Join-Path $env:ProgramFiles 'AutoHotkey\Compiler\Ahk2Exe.exe'),
    (Join-Path ${env:ProgramFiles(x86)} 'AutoHotkey\Compiler\Ahk2Exe.exe')
)

$compiler = $compiler_candidates | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
if (-not $compiler) {
    $compiler_command = Get-Command 'Ahk2Exe.exe' -ErrorAction SilentlyContinue
    if ($compiler_command) {
        $compiler = $compiler_command.Source
    }
}

if (-not $compiler) {
    throw 'AutoHotkey v1 compiler Ahk2Exe.exe was not found. Install AutoHotkey v1 with its compiler, then run this script again.'
}

& $compiler /in $source_path /out $output_path /icon $icon_path
if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $output_path)) {
    throw 'AutoHotkey compiler did not create Keyboard-Setup-Launcher.exe.'
}

$shell = New-Object -ComObject WScript.Shell
$shortcut = $shell.CreateShortcut($shortcut_path)
$shortcut.TargetPath = $output_path
$shortcut.WorkingDirectory = $project_dir
$shortcut.Description = 'Open Keyboard Setup'
$shortcut.IconLocation = $icon_path + ',0'
$shortcut.Save()

Write-Host "Created: $output_path" -ForegroundColor Green
Write-Host "Created taskbar shortcut: $shortcut_path" -ForegroundColor Green
Write-Host 'Pin it: right-click Keyboard-Setup-Launcher.exe or Keyboard-Setup.lnk and choose Pin to taskbar.'


Write-Host 'Source: root Keyboard-Setup-Launcher.ahk | Helpers: src/ | UI data: data/'
