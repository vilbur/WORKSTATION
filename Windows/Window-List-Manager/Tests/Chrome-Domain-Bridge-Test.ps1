# Run on Windows with PowerShell; the bridge port must be free.
$ErrorActionPreference = 'Stop'
$root = Join-Path ([IO.Path]::GetTempPath()) ('wlm-bridge-test-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $root | Out-Null
$output = Join-Path $root 'domains.tsv'
$cache = Join-Path $root 'cache.tsv'
$bridge = Join-Path $PSScriptRoot '../Library/Chrome-Domain-Bridge.ps1'
$child = $null
function Assert-True($Condition, [string]$Message) { if (-not $Condition) { throw $Message } }
function Send-Snapshot($Payload) {
    Invoke-RestMethod -Uri 'http://127.0.0.1:18763/domains' -Method Post -ContentType 'text/plain' -Body ($Payload | ConvertTo-Json -Depth 8 -Compress)
}
try {
    $shell = (Get-Process -Id $PID).Path
    $child = Start-Process -FilePath $shell -ArgumentList @('-NoProfile','-ExecutionPolicy','Bypass','-File',('"' + $bridge + '"'),'-OutputPath',('"' + $output + '"'),'-ManagerPid',$PID,'-CachePath',('"' + $cache + '"')) -PassThru -WindowStyle Hidden
    $window = @{ title = "Test`ttitle`nline"; domain = 'example.com'; left = 1; top = 2; width = 800; height = 600; url = 'https://example.com/a?q=1#part'; window_id = 7; tab_id = 8; visited_at = 1700000000123; visit_id = 'visit-a' }
    $a = @{ api_version = 2; client_id = 'profile-a'; windows = @($window); acks = @() }
    $ready = $false
    for ($attempt = 0; $attempt -lt 30; $attempt++) {
        try { $reply = Send-Snapshot $a; $ready = $true; break } catch { Start-Sleep -Milliseconds 100 }
    }
    Assert-True $ready 'Bridge did not start'
    $fields = [IO.File]::ReadAllText($output) -split "`t"
    Assert-True ($fields.Count -eq 12) 'Expected twelve v2 columns'
    Assert-True ($fields[0] -eq 'Test title line') 'Title must be TSV-safe'
    Assert-True ($fields[6] -ceq $window.url) 'Full URL must survive unchanged'
    Assert-True ($fields[7] -eq 'profile-a') 'Profile identity missing'
    Assert-True (([IO.File]::ReadAllText($cache) -split "`t").Count -eq 6) 'Cache must contain six columns only'
    $b = @{ api_version = 2; client_id = 'profile-b'; windows = @($window); acks = @() }
    $null = Send-Snapshot $b
    Assert-True (([IO.File]::ReadAllLines($output)).Count -eq 2) 'Profiles must aggregate'
    $queue = "$output.commands"
    New-Item -ItemType Directory -Path $queue | Out-Null
    $utf8 = [Text.UTF8Encoding]::new($false)
    [IO.File]::WriteAllText((Join-Path $queue 'request-a.tsv'), "profile-a`thttps://example.com/open?q=2#x", $utf8)
    [IO.File]::WriteAllText((Join-Path $queue 'invalid.tsv'), "profile-a`tjavascript:alert(1)", $utf8)
    [IO.File]::WriteAllText((Join-Path $queue 'expired.tsv'), "profile-a`thttps://example.com/old", $utf8)
    (Get-Item (Join-Path $queue 'expired.tsv')).LastWriteTimeUtc = [DateTime]::UtcNow.AddMinutes(-6)
    $b.acks = @('request-a')
    $reply = Send-Snapshot $b
    Assert-True ($reply.commands.Count -eq 0) 'Other profile must not receive commands'
    Assert-True (Test-Path (Join-Path $queue 'request-a.tsv')) 'Other profile cannot acknowledge a command'
    $reply = Send-Snapshot $a
    Assert-True ($reply.commands.Count -eq 1 -and $reply.commands[0].id -eq 'request-a') 'Only valid matching commands should be sent'
    Assert-True (-not (Test-Path (Join-Path $queue 'expired.tsv'))) 'Old commands must expire'
    $a.acks = @('request-a'); $null = Send-Snapshot $a
    Assert-True (-not (Test-Path (Join-Path $queue 'request-a.tsv'))) 'Matching acknowledgments must remove commands'
    $null = Send-Snapshot @{ windows = @($window) }
    Assert-True (([IO.File]::ReadAllLines($output)).Count -eq 3) 'Legacy snapshots must coexist with profiles'
    Assert-True (([IO.File]::ReadAllLines($output) | Where-Object { ($_ -split "`t").Count -eq 6 }).Count -eq 1) 'Legacy snapshot must retain old six columns'
    Write-Host 'PASS: v2 and legacy snapshots, exact URL, cache privacy, profiles, commands, acknowledgments and expiry'
} finally {
    if ($child -and -not $child.HasExited) { Stop-Process -Id $child.Id -Force }
    Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue
}
