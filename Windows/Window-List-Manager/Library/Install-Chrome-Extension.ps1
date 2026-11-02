# Installs the unpacked extension files for the current Windows user.
$ErrorActionPreference = 'Stop'
$sourceDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$archive = Join-Path $sourceDir 'Chrome-Extension.zip'
$unpacked = Join-Path $sourceDir 'Chrome-Extension'
$target = Join-Path $env:LOCALAPPDATA 'WindowListManager\Chrome-Extension'
if (-not $env:LOCALAPPDATA) { throw 'LOCALAPPDATA is unavailable. Run this on Windows.' }
if (-not (Test-Path -LiteralPath $archive) -and -not (Test-Path -LiteralPath (Join-Path $unpacked 'manifest.json'))) {
    throw 'Chrome-Extension.zip or the Chrome-Extension folder must be next to this installer.'
}
New-Item -ItemType Directory -Path $target -Force | Out-Null
if (Test-Path -LiteralPath $archive) {
    Expand-Archive -LiteralPath $archive -DestinationPath $target -Force
} else {
    Get-ChildItem -LiteralPath $unpacked | Copy-Item -Destination $target -Recurse -Force
}
if (-not (Test-Path -LiteralPath (Join-Path $target 'manifest.json'))) {
    throw "manifest.json was not found in $target. The archive layout may have changed."
}
$chromeRoots = @($env:ProgramFiles, ${env:ProgramFiles(x86)}, $env:LOCALAPPDATA) | Where-Object { $_ }
$chromeCandidates = @($chromeRoots | ForEach-Object { Join-Path $_ 'Google\Chrome\Application\chrome.exe' }) | Where-Object { Test-Path -LiteralPath $_ }
$chrome = $chromeCandidates | Select-Object -First 1
if (-not $chrome) {
    $found = Get-Command chrome.exe -ErrorAction SilentlyContinue
    if ($found) { $chrome = $found.Source }
}
Write-Host "Extension files ready: $target"
Write-Host 'In Chrome: enable Developer mode, click Load unpacked, then select the open folder.'
Start-Process -FilePath explorer.exe -ArgumentList ('"' + $target + '"')
if ($chrome) {
    Start-Process -FilePath $chrome -ArgumentList 'chrome://extensions/'
} else {
    Write-Warning 'Chrome was not found automatically. Open chrome://extensions/ yourself.'
}
