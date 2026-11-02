# Verify that the currently running Keyboard Manager receives a real Win+G.
# This is read-only and does not change Windows/Game Bar settings.
$event_path = Join-Path $env:TEMP 'KeyboardSetupActionEvent.txt'
function getEventSerial
{
    if (-not (Test-Path -LiteralPath $event_path)) { return '' }
    try
    {
        $content = Get-Content -LiteralPath $event_path -Raw -ErrorAction Stop
        $chord = [regex]::Match($content, '(?m)^Shortcut=(.+?)\r?$').Groups[1].Value.Trim()
        $serial = [regex]::Match($content, '(?m)^Serial=(.+?)\r?$').Groups[1].Value.Trim()
        if ($chord -eq 'Win+G') { return $serial }
    }
    catch { }
    return ''
}
$before = getEventSerial
Write-Host 'Keep this PowerShell window focused. Press Win+G once within 15 seconds.'
Write-Host 'Expected: Chrome search/window action; NO Xbox Game Bar overlay.'
$deadline = (Get-Date).AddSeconds(15)
while ((Get-Date) -lt $deadline)
{
    Start-Sleep -Milliseconds 200
    $after = getEventSerial
    if ($after -and $after -ne $before)
    {
        Write-Host 'PASS: Keyboard Manager received a new Win+G event.' -ForegroundColor Green
        Write-Host 'Visually confirm Game Bar did not open; this test cannot prove OS suppression.'
        exit 0
    }
}
Write-Warning 'FAIL: No new Win+G event. Check the tray tooltip is Keyboard Setup v0.34 and restart the actual resident launcher.'
exit 1
